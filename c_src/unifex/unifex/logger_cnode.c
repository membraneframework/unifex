/**
 * Unifex Logger - CNode-specific send implementation.
 *
 * This file provides the CNode-specific implementation for sending log
 * messages. It should be compiled and linked with CNode-based projects.
 */

#include "../cnode/unifex/cnode.h"
#include "../cnode/unifex/unifex.h"
#include "logger.h"
#include "logger_backend.h"

int unifex_logger_cnode_send(void *env_ptr, UnifexLogLevel level,
                             const char *message, uint64_t timestamp,
                             char **tags, unsigned int tags_length) {
  UnifexEnv *env = (UnifexEnv *)env_ptr;
  if (!env) {
    return 0;
  }

  ei_x_buff out_buff;
  ei_x_new_with_version(&out_buff);

  ei_x_encode_tuple_header(&out_buff, 5);

  ei_x_encode_atom(&out_buff, "unifex_logger");

  ei_x_encode_atom(&out_buff, unifex_log_level_to_string(level));

  ei_x_encode_binary(&out_buff, message, strlen(message));

  ei_x_encode_ulonglong(&out_buff, timestamp);

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
