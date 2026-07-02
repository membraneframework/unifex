#pragma once
/**
 * Unifex Logger - Non-blocking logging queue for NIFs.
 *
 * Provides a thread-safe queue for handling log messages from C code
 * without blocking the main execution thread.
 */

#include <pthread.h>
#include <stdbool.h>

// Include unifex.h for type definitions
#include "../nif/unifex/unifex.h"

#ifdef __cplusplus
extern "C" {
#endif

#define UNIFEX_LOGGER_MAX_QUEUE_SIZE 1024

// Log message structure
typedef struct {
  char *level;
  char *message;
  char *time;
  char **tags;
  unsigned int tags_length;
  int is_threaded;
} UnifexLoggerMessage;

// Queue structure
typedef struct {
  UnifexLoggerMessage messages[UNIFEX_LOGGER_MAX_QUEUE_SIZE];
  unsigned int head;
  unsigned int tail;
  unsigned int count;
  pthread_mutex_t mutex;
  pthread_cond_t cond;
  bool running;
  pthread_t worker_thread;
} UnifexLoggerQueue;

// Initialize the logger queue
void unifex_logger_init();

// Cleanup the logger queue
void unifex_logger_cleanup();

// Add a message to the queue (non-blocking, returns false if queue is full)
bool unifex_logger_queue_push(char *level, char *message, char *time,
                              char **tags, unsigned int tags_length,
                              int is_threaded);

// Register a custom send function (optional)
// If not registered, messages are sent directly using unifex_send
void unifex_logger_register_send_func(int (*func)(UnifexEnv *env, UnifexPid pid,
                                                  int flags, char const *level,
                                                  char const *message,
                                                  char const *time, char **tags,
                                                  unsigned int tags_length));

#ifdef __cplusplus
}
#endif
