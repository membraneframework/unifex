#pragma once
/**
 * Unifex Logger CNode - Convenience header for CNode backend.
 *
 * Include this header to use the logger with CNode backend.
 * It automatically registers the CNode send function.
 */

#include "../cnode/unifex/unifex.h"
#include "logger.h"
#include "logger_backend.h"

#ifdef __cplusplus
extern "C" {
#endif

static inline void unifex_logger_cnode_init(UnifexEnv *env) {
  unifex_logger_set_env(env);
  unifex_logger_register_send_func(unifex_logger_cnode_send);
}

#ifdef __cplusplus
}
#endif
