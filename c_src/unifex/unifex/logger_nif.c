/**
 * Unifex Logger - NIF-specific send implementation.
 *
 * This file provides the NIF-specific implementation for sending log messages.
 * It should be compiled and linked with NIF-based projects.
 */

#include "logger.h"
#include "logger_nif.h"
#include "../nif/unifex/unifex.h"

// NIF-specific send function for logger
// This function creates an Erlang term from the log message and sends it
// to the target process using NIF APIs.
int unifex_logger_nif_send(void *env_ptr, const char *level, const char *message,
                           uint64_t timestamp, char **tags,
                           unsigned int tags_length) {
  UnifexEnv *env = (UnifexEnv *)env_ptr;
  // Get or create an environment
  UnifexEnv *send_env = env;
  if (!send_env) {
    send_env = unifex_alloc_env(NULL);
    if (!send_env) {
      return 0;
    }
  }

  // Try to get the target PID
  UnifexPid target_pid;
  const char *target_name = unifex_logger_get_target();
  
  // This function only ever runs on the logger's own worker thread, never on
  // an ERTS scheduler thread, so caller_env must be NULL (UNIFEX_FROM_CREATED_THREAD).
  if (unifex_get_pid_by_name(send_env, (char *)target_name, UNIFEX_FROM_CREATED_THREAD, &target_pid) == 0) {
    // Could not find the target process
    if (!env) {
      unifex_clear_env(send_env);
      unifex_free_env(send_env);
    }
    return 0;
  }

  // Create the message tuple: {:unifex_logger, level, message, timestamp, [tags]}
  ERL_NIF_TERM level_atom = enif_make_atom(send_env, level);
  ERL_NIF_TERM message_term = unifex_string_to_term(send_env, message);
  ERL_NIF_TERM timestamp_term = enif_make_uint64(send_env, timestamp);

  // Create the tags list
  ERL_NIF_TERM tags_list = enif_make_list(send_env, 0);
  for (int i = tags_length - 1; i >= 0; i--) {
    ERL_NIF_TERM tag_term = unifex_string_to_term(send_env, tags[i] ? tags[i] : "");
    tags_list = enif_make_list_cell(send_env, tag_term, tags_list);
  }

  // Create the tuple
  ERL_NIF_TERM tuple_terms[] = {
    enif_make_atom(send_env, "unifex_logger"),
    level_atom,
    message_term,
    timestamp_term,
    tags_list
  };
  ERL_NIF_TERM msg_term = enif_make_tuple_from_array(send_env, tuple_terms, 5);

  // Send the message (non-threaded since we're in a worker thread)
  int result = unifex_send(send_env, &target_pid, msg_term, UNIFEX_SEND_THREADED);

  // Clear the environment if we created it
  if (!env) {
    unifex_clear_env(send_env);
    unifex_free_env(send_env);
  }

  return result;
}

// Automatically wire up the NIF send function as soon as this file's object
// is loaded, so callers of unifex_log() don't have to remember to invoke
// unifex_logger_nif_init() themselves (e.g. from a :load callback). No
// UnifexEnv is required here: unifex_logger_nif_send() creates its own via
// unifex_alloc_env() when passed a NULL env, which is what global_env is
// until/unless something calls unifex_logger_set_env() explicitly.
static void __attribute__((
    constructor(UNIFEX_LOGGER_BACKEND_CTOR_PRIORITY))) unifex_logger_nif_backend_constructor() {
  unifex_logger_nif_init();
}
