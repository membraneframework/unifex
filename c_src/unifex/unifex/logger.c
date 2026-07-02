/**
 * Unifex Logger - Non-blocking logging queue implementation.
 *
 * Provides a thread-safe queue for handling log messages from C code
 * without blocking the main execution thread.
 */

#include "logger.h"
#include <erl_nif.h>
#include <stdlib.h>
#include <string.h>

// Global queue instance
static UnifexLoggerQueue queue;

// Target process name
static const char *target_pid_name = "Elixir.Unifex.UnifexLogger";

// Function to send a log message (defined in the user's code or generated)
static int (*send_log_func)(UnifexEnv *env, UnifexPid pid, int flags,
                            char const *level, char const *message,
                            char const *time, char **tags,
                            unsigned int tags_length) = NULL;

// Register the send function (to be called from NIF load)
void unifex_logger_register_send_func(int (*func)(UnifexEnv *env, UnifexPid pid,
                                                  int flags, char const *level,
                                                  char const *message,
                                                  char const *time, char **tags,
                                                  unsigned int tags_length)) {
  send_log_func = func;
}

// Note: target_pid_name is const, so this function is not implemented
// To change the target, modify the target_pid_name constant and recompile
// void unifex_logger_set_target(const char *name) {
//   (void)name;
// }

// Forward declaration
void *unifex_logger_worker(void *arg);

void unifex_logger_init() {
  queue.head = 0;
  queue.tail = 0;
  queue.count = 0;
  queue.running = true;

  pthread_mutex_init(&queue.mutex, NULL);
  pthread_cond_init(&queue.cond, NULL);

  // Start worker thread
  pthread_create(&queue.worker_thread, NULL, unifex_logger_worker, NULL);
}

void unifex_logger_cleanup() {
  queue.running = false;

  // Signal the worker thread to wake up and exit
  pthread_cond_signal(&queue.cond);

  // Wait for worker thread to finish
  pthread_join(queue.worker_thread, NULL);

  pthread_mutex_destroy(&queue.mutex);
  pthread_cond_destroy(&queue.cond);
}

bool unifex_logger_queue_push(char *level, char *message, char *time,
                              char **tags, unsigned int tags_length,
                              int is_threaded) {
  // Create deep copies of the strings since we'll own them now
  char *level_copy = strdup(level);
  char *message_copy = strdup(message);
  char *time_copy = strdup(time);

  // For tags, we need to copy the array and each string
  char **tags_copy = NULL;
  if (tags && tags_length > 0) {
    tags_copy = malloc(tags_length * sizeof(char *));
    for (unsigned int i = 0; i < tags_length; i++) {
      tags_copy[i] = tags[i] ? strdup(tags[i]) : NULL;
    }
  }

  pthread_mutex_lock(&queue.mutex);

  // If queue is full, return false (non-blocking) and free the copies
  if (queue.count >= UNIFEX_LOGGER_MAX_QUEUE_SIZE) {
    pthread_mutex_unlock(&queue.mutex);
    free(level_copy);
    free(message_copy);
    free(time_copy);
    if (tags_copy) {
      for (unsigned int i = 0; i < tags_length; i++) {
        free(tags_copy[i]);
      }
      free(tags_copy);
    }
    return false;
  }

  // Add to queue
  queue.messages[queue.tail].level = level_copy;
  queue.messages[queue.tail].message = message_copy;
  queue.messages[queue.tail].time = time_copy;
  queue.messages[queue.tail].tags = tags_copy;
  queue.messages[queue.tail].tags_length = tags_length;
  queue.messages[queue.tail].is_threaded = is_threaded;

  queue.tail = (queue.tail + 1) % UNIFEX_LOGGER_MAX_QUEUE_SIZE;
  queue.count++;

  // Signal worker thread
  pthread_cond_signal(&queue.cond);

  pthread_mutex_unlock(&queue.mutex);

  return true;
}

// Worker thread function
void *unifex_logger_worker(void *arg) {
  UNIFEX_UNUSED(arg);

  while (queue.running) {
    pthread_mutex_lock(&queue.mutex);

    // Wait for messages or shutdown
    while (queue.count == 0 && queue.running) {
      pthread_cond_wait(&queue.cond, &queue.mutex);
    }

    if (!queue.running) {
      pthread_mutex_unlock(&queue.mutex);
      break;
    }

    // Process all available messages
    while (queue.count > 0) {
      UnifexLoggerMessage msg = queue.messages[queue.head];
      queue.head = (queue.head + 1) % UNIFEX_LOGGER_MAX_QUEUE_SIZE;
      queue.count--;

      // Release the mutex while processing to allow more messages to be queued
      pthread_mutex_unlock(&queue.mutex);

      // Send the message to the target process
      UnifexPid target_pid;
      int get_pid_flags =
          msg.is_threaded ? UNIFEX_FROM_CREATED_THREAD : UNIFEX_NO_FLAGS;

      // Try to get the target PID
      // Note: We pass NULL as env since we're in a worker thread
      if (unifex_get_pid_by_name(NULL, target_pid_name, get_pid_flags,
                                 &target_pid)) {
        // Create an environment for this thread
        UnifexEnv *env = enif_alloc_env();
        if (env && send_log_func) {
          int send_flags =
              msg.is_threaded ? UNIFEX_SEND_THREADED : UNIFEX_NO_FLAGS;
          // Call the registered send function
          send_log_func(env, target_pid, send_flags, msg.level, msg.message,
                        msg.time, msg.tags, msg.tags_length);
          // Clear the environment
          unifex_clear_env(env);
        } else if (env) {
          // If no send function registered, create the message manually
          // and send it directly
          int send_flags =
              msg.is_threaded ? UNIFEX_SEND_THREADED : UNIFEX_NO_FLAGS;

          // Create the message tuple: {:unifex_logger, level, message, time,
          // [tags]}
          ERL_NIF_TERM term = ({
            const ERL_NIF_TERM terms[] = {
                enif_make_atom(env, "unifex_logger"),
                enif_make_atom(env, msg.level),
                unifex_string_to_term(env, msg.message),
                unifex_string_to_term(env, msg.time), ({
                  ERL_NIF_TERM list = enif_make_list(env, 0);
                  for (int i = msg.tags_length - 1; i >= 0; i--) {
                    list = enif_make_list_cell(
                        env, enif_make_atom(env, msg.tags[i]), list);
                  }
                  list;
                })};
            enif_make_tuple_from_array(env, terms, 5);
          });

          // Send directly using unifex_send
          unifex_send(env, &target_pid, term, send_flags);
          unifex_clear_env(env);
        }
        // If we couldn't create an env, just free the message
      }

      // Clean up the message data
      free(msg.level);
      free(msg.message);
      free(msg.time);
      if (msg.tags) {
        for (unsigned int i = 0; i < msg.tags_length; i++) {
          free(msg.tags[i]);
        }
        free(msg.tags);
      }

      // Re-acquire the mutex for the next iteration
      pthread_mutex_lock(&queue.mutex);
    }

    pthread_mutex_unlock(&queue.mutex);
  }

  return NULL;
}

// Initialize the queue when the library is loaded
static void __attribute__((constructor)) unifex_logger_constructor() {
  unifex_logger_init();
}

// Cleanup the queue when the library is unloaded
static void __attribute__((destructor)) unifex_logger_destructor() {
  unifex_logger_cleanup();
}
