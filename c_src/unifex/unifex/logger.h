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

#define UNIFEX_LOGGER_MAX_QUEUE_SIZE 1024

// __attribute__((constructor(N))) priorities: lower N runs earlier. C gives
// no guaranteed relative order between plain (unnumbered) constructors in
// different translation units, so the backend's send-function registration
// (logger_nif.c) must be pinned to run strictly before the queue's worker
// thread is started (logger.c) - otherwise a message queued by some other
// early constructor could be dequeued and dropped before a send function is
// registered.
#define UNIFEX_LOGGER_BACKEND_CTOR_PRIORITY 1000
#define UNIFEX_LOGGER_QUEUE_CTOR_PRIORITY 2000

// Log level constants
#define UNIFEX_LOG_LEVEL_DEBUG "debug"
#define UNIFEX_LOG_LEVEL_INFO "info"
#define UNIFEX_LOG_LEVEL_WARN "warning"
#define UNIFEX_LOG_LEVEL_ERROR "error"

// Log message structure
typedef struct {
  char *level;
  char *message;
  uint64_t timestamp;
  char **tags;
  unsigned int tags_length;
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

// Callback type for sending log messages
// The backend-specific implementation should provide this function
// Note: env may be NULL, in which case the send function should create/use
// the appropriate environment. It is passed through as an opaque pointer
// here since its real type (UnifexEnv, defined by the NIF or CNode backend)
// is not known to this backend-agnostic header - the registered send
// function is responsible for casting it back to the real type.
typedef int (*UnifexLoggerSendFunc)(void *env, const char *level,
                                     const char *message, uint64_t timestamp,
                                     char **tags, unsigned int tags_length);

// Initialize the logger queue
void unifex_logger_init();

// Cleanup the logger queue
void unifex_logger_cleanup();

// Add a message to the queue (non-blocking, returns false if queue is full)
bool unifex_logger_queue_push(char *level, char *message, uint64_t timestamp,
                              char **tags, unsigned int tags_length);

// Simpler wrapper: log with level, message, and optional tags (auto-generates
// timestamp)
bool unifex_log(const char *level, const char *message, const char **tags,
                unsigned int tags_length);

// Register a custom send function
// This function MUST be called before any logging occurs
// The send_func should know how to create terms and send messages for the
// specific backend (NIF or CNode)
void unifex_logger_register_send_func(UnifexLoggerSendFunc func);

// Set the global environment (for backends that need it, like CNode)
// Accepts an opaque pointer for the same reason as UnifexLoggerSendFunc above.
void unifex_logger_set_env(void *env);

// Get the global environment
void *unifex_logger_get_env();

// Set the target process name for logging
// This is used by the default send implementation to find the target PID
void unifex_logger_set_target(const char *name);

// Get the current target process name
const char *unifex_logger_get_target();

// Helper to get timestamp in microseconds since epoch
uint64_t unifex_logger_get_timestamp();

#ifdef __cplusplus
}
#endif
