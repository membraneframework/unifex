/**
 * Unifex Logger - Non-blocking logging queue implementation.
 *
 * Provides a thread-safe queue for handling log messages from C code
 * without blocking the main execution thread.
 *
 * This implementation works with both NIF and CNode backends.
 * The user must provide a backend-specific send function via
 * unifex_logger_register_send_func().
 */

#include "logger.h"
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

// Global queue instance
static UnifexLoggerQueue queue;

// Target process name
static const char *target_pid_name = "Elixir.Unifex.Logger";

// Function to send a log message (to be provided by the backend)
static UnifexLoggerSendFunc send_log_func = NULL;

// Global environment reference (for backends that need it, like CNode)
// This is optional - if set, it will be passed to the send function
static void *global_env = NULL;

// Whether the queue/worker thread are currently initialized. Guards against
// double-cleanup: a CNode's unifex_cnode_destroy() calls unifex_logger_cleanup()
// explicitly before tearing down its socket, and the library destructor calls
// it again at process exit.
static bool logger_active = false;

// Forward declaration
void *unifex_logger_worker(void *arg);

static void free_tags_copy(char **tags, unsigned int tags_length) {
  if (!tags) {
    return;
  }
  for (unsigned int i = 0; i < tags_length; i++) {
    free((void *)tags[i]);
  }
  free(tags);
}

void unifex_logger_set_target(const char *name) {
  target_pid_name = name;
}

const char *unifex_logger_get_target() {
  return target_pid_name;
}

uint64_t unifex_logger_get_timestamp() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  // Convert to microseconds since epoch
  return (uint64_t)tv.tv_sec * 1000000 + (uint64_t)tv.tv_usec;
}

// Register the send function (to be called from backend initialization)
void unifex_logger_register_send_func(UnifexLoggerSendFunc func) {
  send_log_func = func;
}

// Set the global environment (for backends that need it)
void unifex_logger_set_env(void *env) {
  global_env = env;
}

// Get the global environment
void *unifex_logger_get_env() {
  return global_env;
}

void unifex_logger_init() {
  queue.head = 0;
  queue.tail = 0;
  queue.count = 0;
  queue.running = true;

  pthread_mutex_init(&queue.mutex, NULL);
  pthread_cond_init(&queue.cond, NULL);

  // Start worker thread
  pthread_create(&queue.worker_thread, NULL, unifex_logger_worker, NULL);

  logger_active = true;
}

void unifex_logger_cleanup() {
  if (!logger_active) {
    return;
  }
  logger_active = false;

  pthread_mutex_lock(&queue.mutex);
  queue.running = false;
  // Signal the worker thread to wake up and exit, while holding the mutex so
  // the signal can't be missed between the worker's `running` check and its
  // wait on the condition variable.
  pthread_cond_signal(&queue.cond);
  pthread_mutex_unlock(&queue.mutex);

  // Wait for worker thread to finish
  pthread_join(queue.worker_thread, NULL);

  pthread_mutex_destroy(&queue.mutex);
  pthread_cond_destroy(&queue.cond);
}

bool unifex_log(const char *level, const char *message, const char **tags,
                unsigned int tags_length) {
  uint64_t timestamp = unifex_logger_get_timestamp();

  return unifex_logger_queue_push((char *)level, (char *)message, timestamp,
                                  (char **)tags, tags_length);
}

bool unifex_logger_queue_push(char *level, char *message, uint64_t timestamp,
                              char **tags, unsigned int tags_length) {
  // Create deep copies of the strings since we'll own them now
  char *level_copy = strdup(level);
  char *message_copy = strdup(message);

  // For tags, we need to copy the array and each string
  char **tags_copy = NULL;
  bool tags_alloc_failed = false;
  if (tags && tags_length > 0) {
    tags_copy = malloc(tags_length * sizeof(char *));
    if (!tags_copy) {
      tags_alloc_failed = true;
    } else {
      for (unsigned int i = 0; i < tags_length; i++) {
        tags_copy[i] = tags[i] ? strdup(tags[i]) : NULL;
        if (tags[i] && !tags_copy[i]) {
          tags_alloc_failed = true;
        }
      }
    }
  }

  if (!level_copy || !message_copy || tags_alloc_failed) {
    free((void *)level_copy);
    free((void *)message_copy);
    free_tags_copy(tags_copy, tags_length);
    return false;
  }

  pthread_mutex_lock(&queue.mutex);

  // If queue is full, return false (non-blocking) and free the copies
  if (queue.count >= UNIFEX_LOGGER_MAX_QUEUE_SIZE) {
    pthread_mutex_unlock(&queue.mutex);
    free((void *)level_copy);
    free((void *)message_copy);
    free_tags_copy(tags_copy, tags_length);
    return false;
  }

  // Add to queue
  queue.messages[queue.tail].level = level_copy;
  queue.messages[queue.tail].message = message_copy;
  queue.messages[queue.tail].timestamp = timestamp;
  queue.messages[queue.tail].tags = tags_copy;
  queue.messages[queue.tail].tags_length = tags_length;

  queue.tail = (queue.tail + 1) % UNIFEX_LOGGER_MAX_QUEUE_SIZE;
  queue.count++;

  // Signal worker thread
  pthread_cond_signal(&queue.cond);

  pthread_mutex_unlock(&queue.mutex);

  return true;
}

// Worker thread function
void *unifex_logger_worker(void *arg) {
  (void)arg;

  while (queue.running) {
    pthread_mutex_lock(&queue.mutex);

    // Wait for messages or shutdown
    while (queue.count == 0 && queue.running) {
      pthread_cond_wait(&queue.cond, &queue.mutex);
    }

    // Only stop once shutdown was requested AND the queue has been fully
    // drained, so messages queued right before shutdown are not lost.
    if (!queue.running && queue.count == 0) {
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

      // If a send function is registered, use it
      if (send_log_func) {
        // Call the registered send function with the global environment
        // The send function is responsible for:
        // 1. Using the environment (or creating one if needed)
        // 2. Finding the target PID
        // 3. Creating the message term
        // 4. Sending the message
        send_log_func(global_env, msg.level, msg.message, msg.timestamp,
                      msg.tags, msg.tags_length);
      }
      
      // Clean up the message data
      free((void *)msg.level);
      free((void *)msg.message);
      free_tags_copy(msg.tags, msg.tags_length);

      // Re-acquire the mutex for the next iteration
      pthread_mutex_lock(&queue.mutex);
    }

    pthread_mutex_unlock(&queue.mutex);
  }

  return NULL;
}

// Initialize the queue when the library is loaded. Runs at priority
// UNIFEX_LOGGER_QUEUE_CTOR_PRIORITY (see logger.h), after the backend's own
// constructor (UNIFEX_LOGGER_BACKEND_CTOR_PRIORITY) has registered the send
// function, so the worker thread never starts draining before a send
// function is available.
static void __attribute__((
    constructor(UNIFEX_LOGGER_QUEUE_CTOR_PRIORITY))) unifex_logger_constructor() {
  unifex_logger_init();
}

// Cleanup the queue when the library is unloaded
static void __attribute__((destructor)) unifex_logger_destructor() {
  unifex_logger_cleanup();
}
