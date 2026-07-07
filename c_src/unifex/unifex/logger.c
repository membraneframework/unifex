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

// Required for strdup, which is POSIX (not ISO C) and thus not declared by
// string.h unless a feature test macro requesting it is defined before any
// system header is included.
#define _POSIX_C_SOURCE 200809L

#include "logger.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

// Global queue instance
static UnifexLoggerQueue queue;

// Target process name
static const char *target_pid_name = "Elixir.Unifex.Logger";

// Function to send a log message (to be provided by the backend). Process-wide
// by design, not per-env: a CNode process hosts exactly one UnifexEnv for its
// entire lifetime (see unifex_cnode_main_function), and a NIF's log target is
// resolved by process name (unifex_logger_get_target()), not by which env
// logged - so there is never more than one backend to route to in a process.
static UnifexLoggerSendFunc send_log_func = NULL;

// Environment passed through to send_log_func (for backends that need it,
// like CNode - see the comment on send_log_func above for why one process-wide
// value is sufficient). Optional: NULL if the backend supplies its own (e.g.
// the NIF backend's fallback_env, see logger_nif.c).
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

static void free_pending_message(char *level, char *message, char **tags,
                                 unsigned int tags_length) {
  free((void *)level);
  free((void *)message);
  free_tags_copy(tags, tags_length);
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

void unifex_logger_init() {
  queue.head = 0;
  queue.tail = 0;
  queue.count = 0;
  queue.dropped_count = 0;
  queue.running = true;

  pthread_mutex_init(&queue.mutex, NULL);
  pthread_cond_init(&queue.cond, NULL);

  // Start worker thread. If this fails, leave logger_active false so
  // unifex_logger_cleanup() doesn't later join a thread that was never
  // created (undefined behavior) - logging is simply unavailable instead.
  if (pthread_create(&queue.worker_thread, NULL, unifex_logger_worker, NULL) ==
      0) {
    logger_active = true;
  } else {
    pthread_mutex_destroy(&queue.mutex);
    pthread_cond_destroy(&queue.cond);
  }
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
  if (!message) {
    return false;
  }

  // Fast-reject before doing any allocation if the queue is already full.
  pthread_mutex_lock(&queue.mutex);
  bool full = queue.count >= UNIFEX_LOGGER_MAX_QUEUE_SIZE;
  if (full) {
    queue.dropped_count++;
  }
  pthread_mutex_unlock(&queue.mutex);
  if (full) {
    return false;
  }

  uint64_t timestamp = unifex_logger_get_timestamp();

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
    free_pending_message(level_copy, message_copy, tags_copy, tags_length);
    return false;
  }

  pthread_mutex_lock(&queue.mutex);

  // The queue could have filled up since the check above; re-check before
  // committing to the insert (non-blocking: free the copies and give up).
  if (queue.count >= UNIFEX_LOGGER_MAX_QUEUE_SIZE) {
    queue.dropped_count++;
    pthread_mutex_unlock(&queue.mutex);
    free_pending_message(level_copy, message_copy, tags_copy, tags_length);
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

    // Drain every currently queued message into a local batch under a single
    // lock/unlock pair, instead of re-acquiring queue.mutex per message.
    unsigned int batch_size = queue.count;
    UnifexLoggerMessage batch[UNIFEX_LOGGER_MAX_QUEUE_SIZE];
    for (unsigned int i = 0; i < batch_size; i++) {
      batch[i] = queue.messages[queue.head];
      queue.head = (queue.head + 1) % UNIFEX_LOGGER_MAX_QUEUE_SIZE;
    }
    queue.count -= batch_size;

    // Report and reset any messages dropped due to a full queue since the
    // last report, now that the queue has been drained and there's room to
    // enqueue (or, here, directly send) a report about it.
    uint64_t dropped = queue.dropped_count;
    queue.dropped_count = 0;

    pthread_mutex_unlock(&queue.mutex);

    // Send and free the batch outside the lock so producers aren't blocked
    // while messages are delivered.
    for (unsigned int i = 0; i < batch_size; i++) {
      if (send_log_func) {
        send_log_func(global_env, batch[i].level, batch[i].message,
                      batch[i].timestamp, batch[i].tags, batch[i].tags_length);
      }
      free_pending_message(batch[i].level, batch[i].message, batch[i].tags,
                           batch[i].tags_length);
    }

    if (dropped > 0 && send_log_func) {
      char overflow_message[128];
      snprintf(overflow_message, sizeof(overflow_message),
                "Unifex logger queue overflowed: dropped %llu log message(s)",
                (unsigned long long)dropped);
      send_log_func(global_env, UNIFEX_LOG_LEVEL_WARN, overflow_message,
                    unifex_logger_get_timestamp(), NULL, 0);
    }
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
