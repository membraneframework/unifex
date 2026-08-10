#include "logger_test.h"
#include <stdio.h>   // for snprintf

UNIFEX_TERM log_debug(UnifexEnv* env, char* message) {
  const char *tags[] = {"test", "debug"};
  unifex_log(UNIFEX_LOG_LEVEL_DEBUG, message, tags, 2);
  return log_debug_result_ok(env);
}

UNIFEX_TERM log_info(UnifexEnv* env, char* message) {
  const char *tags[] = {"test", "info"};
  unifex_log(UNIFEX_LOG_LEVEL_INFO, message, tags, 2);
  return log_info_result_ok(env);
}

UNIFEX_TERM log_warning(UnifexEnv* env, char* message) {
  const char *tags[] = {"test", "warning"};
  unifex_log(UNIFEX_LOG_LEVEL_WARN, message, tags, 2);
  return log_warning_result_ok(env);
}

UNIFEX_TERM log_error(UnifexEnv* env, char* message) {
  const char *tags[] = {"test", "error"};
  unifex_log(UNIFEX_LOG_LEVEL_ERROR, message, tags, 2);
  return log_error_result_ok(env);
}

UNIFEX_TERM log_with_tags(UnifexEnv* env, char* message, char** tags, unsigned int tags_length) {
  unifex_log(UNIFEX_LOG_LEVEL_INFO, message, (const char **)tags, tags_length);
  return log_with_tags_result_ok(env);
}

UNIFEX_TERM log_with_timestamp(UnifexEnv* env, char* message, uint64_t timestamp) {
  // Note: timestamp is generated automatically in unifex_log, so this just tests basic logging
  const char *tags[] = {"test", "timestamp"};
  unifex_log(UNIFEX_LOG_LEVEL_INFO, message, tags, 2);
  return log_with_timestamp_result_ok(env);
}

UNIFEX_TERM log_many_messages(UnifexEnv* env, int count) {
  // Test logging many messages to test queue handling
  for (int i = 0; i < count; i++) {
    char message[64];
    snprintf(message, sizeof(message), "Message %d", i);
    const char *tags[] = {"test", "bulk"};
    unifex_log(UNIFEX_LOG_LEVEL_INFO, message, tags, 2);
  }
  return log_many_messages_result_ok(env);
}

UNIFEX_TERM test_queue_overflow(UnifexEnv* env) {
  // Send more messages than UNIFEX_LOGGER_MAX_QUEUE_SIZE (256) to trigger a
  // "queue overflowed" warning about the dropped messages.
  for (int i = 0; i < 300; i++) {
    char message[64];
    snprintf(message, sizeof(message), "Overflow test message %d", i);
    const char *tags[] = {"test", "overflow"};
    unifex_log(UNIFEX_LOG_LEVEL_INFO, message, tags, 2);
  }
  return test_queue_overflow_result_ok(env);
}
