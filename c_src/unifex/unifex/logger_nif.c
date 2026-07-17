/**
 * Unifex Logger - NIF-specific send implementation.
 *
 * This file provides the NIF-specific implementation for sending log messages.
 * It should be compiled and linked with NIF-based projects.
 */

#include "logger_nif.h"
#include "../nif/unifex/unifex.h"
#include "logger.h"

static UnifexEnv *fallback_env = NULL;

int unifex_logger_nif_send(void *env_ptr, const char *level,
                           const char *message, uint64_t timestamp, char **tags,
                           unsigned int tags_length) {
  UnifexEnv *env = (UnifexEnv *)env_ptr;
  UnifexEnv *send_env = env;
  if (!send_env) {
    if (!fallback_env) {
      fallback_env = unifex_alloc_env(NULL);
      if (!fallback_env) {
        return 0;
      }
    }
    send_env = fallback_env;
  }

  UnifexPid target_pid;
  const char *target_name = unifex_logger_get_target();

  if (unifex_get_pid_by_name(send_env, (char *)target_name,
                             UNIFEX_FROM_CREATED_THREAD, &target_pid) == 0) {
    if (send_env == fallback_env) {
      unifex_clear_env(send_env);
    }
    return 0;
  }

  ERL_NIF_TERM level_atom = enif_make_atom(send_env, level);
  ERL_NIF_TERM message_term = unifex_string_to_term(send_env, message);
  ERL_NIF_TERM timestamp_term = enif_make_uint64(send_env, timestamp);

  ERL_NIF_TERM tags_list = enif_make_list(send_env, 0);
  for (int i = tags_length - 1; i >= 0; i--) {
    ERL_NIF_TERM tag_term =
        unifex_string_to_term(send_env, tags[i] ? tags[i] : "");
    tags_list = enif_make_list_cell(send_env, tag_term, tags_list);
  }

  // Create the tuple
  ERL_NIF_TERM tuple_terms[] = {enif_make_atom(send_env, "unifex_logger"),
                                level_atom, message_term, timestamp_term,
                                tags_list};
  ERL_NIF_TERM msg_term = enif_make_tuple_from_array(send_env, tuple_terms, 5);

  // Send the message. unifex_send() with UNIFEX_SEND_THREADED already clears
  // send_env internally after enif_send(), so it's ready for reuse (if it's
  // fallback_env) with no further cleanup here.
  return unifex_send(send_env, &target_pid, msg_term, UNIFEX_SEND_THREADED);
}

// Automatically wire up the NIF send function as soon as this file's object
// is loaded, so callers of unifex_log() don't have to remember to invoke
// unifex_logger_nif_init() themselves (e.g. from a :load callback). No
// UnifexEnv is required here: unifex_logger_nif_send() falls back to its own
// persistent env when passed a NULL env, which is what global_env is
// until/unless something calls unifex_logger_set_env() explicitly.
static void __attribute__((constructor(UNIFEX_LOGGER_BACKEND_CTOR_PRIORITY)))
unifex_logger_nif_backend_constructor() {
  unifex_logger_nif_init();
}
