#pragma once
/**
 * Unifex Logger NIF - Convenience header for NIF backend.
 *
 * Include this header to use the logger with NIF backend.
 * It automatically registers the NIF send function.
 */

#include "logger.h"
#include "logger_backend.h"

#ifdef __cplusplus
extern "C" {
#endif

static inline void unifex_logger_nif_init() {
  unifex_logger_register_send_func(unifex_logger_nif_send);
}

#ifdef __cplusplus
}
#endif
