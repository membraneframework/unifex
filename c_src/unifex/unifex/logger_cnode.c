/**
 * Unifex Logger - CNode-specific send implementation.
 *
 * This file provides the CNode-specific implementation for sending log messages.
 * It should be compiled and linked with CNode-based projects.
 */

#include "logger.h"
#include "logger_backend.h"
#include "../cnode/unifex/unifex.h"
#include "../cnode/unifex/cnode.h"

// CNode-specific send function for logger
// This function creates an Erlang term from the log message using ei_x_* functions
// and sends it directly to the registered target process (see
// unifex_logger_set_target/unifex_logger_get_target), matching the NIF
// backend's target-based delivery. It deliberately does not use
// env->reply_to: that field is the pid of whoever most recently called into
// the CNode, is mutated by the main thread on every incoming message, and
// reusing it here would race with the main thread and could deliver (or
// misdeliver) the log to an unrelated caller.
int unifex_logger_cnode_send(void *env_ptr, const char *level, const char *message,
                              uint64_t timestamp, char **tags,
                              unsigned int tags_length) {
  UnifexEnv *env = (UnifexEnv *)env_ptr;
  if (!env) {
    // Cannot send without an environment in CNode
    return 0;
  }

  ei_x_buff out_buff;
  ei_x_new_with_version(&out_buff);

  // Message format: {unifex_logger, Level, Message, Timestamp, Tags}
  ei_x_encode_tuple_header(&out_buff, 5);

  // Function name (atom)
  ei_x_encode_atom(&out_buff, "unifex_logger");

  // Level (atom)
  ei_x_encode_atom(&out_buff, level);

  // Message (binary, to match the NIF backend's unifex_string_to_term)
  ei_x_encode_binary(&out_buff, message, strlen(message));

  // Timestamp, encoded as an actual integer to match the NIF backend's
  // enif_make_uint64 (Unifex.Logger expects an integer, not a charlist)
  ei_x_encode_ulonglong(&out_buff, timestamp);

  // Tags (list of binaries)
  ei_x_encode_list_header(&out_buff, tags_length);
  for (unsigned int i = 0; i < tags_length; i++) {
    const char *tag = tags[i] ? tags[i] : "";
    ei_x_encode_binary(&out_buff, tag, strlen(tag));
  }
  ei_x_encode_empty_list(&out_buff);

  const char *target_name = unifex_logger_get_target();
  int result = unifex_cnode_locked_reg_send(env, target_name, out_buff.buff,
                                            out_buff.index);

  ei_x_free(&out_buff);

  return result >= 0 ? 1 : 0;
}
