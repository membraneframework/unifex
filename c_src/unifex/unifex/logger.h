#pragma once
/**
 * Unifex Logger - Non-blocking logging queue for both NIFs and CNodes.
 *
 * Provides a thread-safe queue for handling log messages from C code
 * without blocking the main execution thread.
 *
 * This logger is designed to work with both NIF and CNode backends.
 * The user must register a send function that knows how to create terms
 * and send messages for the specific backend.
 */

#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define UNIFEX_LOGGER_MAX_QUEUE_SIZE 256

#define UNIFEX_LOGGER_BACKEND_CTOR_PRIORITY 1000
#define UNIFEX_LOGGER_QUEUE_CTOR_PRIORITY 2000

// Log level constants
#define UNIFEX_LOG_LEVEL_DEBUG "debug"
#define UNIFEX_LOG_LEVEL_INFO "info"
#define UNIFEX_LOG_LEVEL_WARN "warning"
#define UNIFEX_LOG_LEVEL_ERROR "error"

typedef struct {
  char *level;
  char *message;
  uint64_t timestamp;
  char **tags;
  unsigned int tags_length;
} UnifexLoggerMessage;

typedef struct {
  UnifexLoggerMessage messages[UNIFEX_LOGGER_MAX_QUEUE_SIZE];
  unsigned int head;
  unsigned int tail;
  unsigned int count;
  uint64_t dropped_count;
  pthread_mutex_t mutex;
  pthread_cond_t cond;
  bool running;
  pthread_t worker_thread;
} UnifexLoggerQueue;

typedef int (*UnifexLoggerSendFunc)(void *env, const char *level,
                                    const char *message, uint64_t timestamp,
                                    char **tags, unsigned int tags_length);

void unifex_logger_init();

void unifex_logger_cleanup();

bool unifex_log(const char *level, const char *message, const char **tags,
                unsigned int tags_length);

void unifex_logger_register_send_func(UnifexLoggerSendFunc func);

void unifex_logger_set_env(void *env);

const char *unifex_logger_get_target();

uint64_t unifex_logger_get_timestamp();

#ifdef __cplusplus
}
#endif
