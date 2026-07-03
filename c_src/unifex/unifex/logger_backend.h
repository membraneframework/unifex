#pragma once
/**
 * Unifex Logger Backend - Send function declarations for NIF and CNode.
 *
 * This header provides declarations for backend-specific send functions.
 * Include the appropriate backend implementation in your project.
 */

#ifdef __cplusplus
extern "C" {
#endif

// NIF backend send function
// env is the real backend UnifexEnv*, passed as void* so this header does
// not need to know its definition (see logger.h's UnifexLoggerSendFunc).
int unifex_logger_nif_send(void *env, const char *level, const char *message,
                           uint64_t timestamp, char **tags,
                           unsigned int tags_length);

// CNode backend send function
int unifex_logger_cnode_send(void *env, const char *level, const char *message,
                              uint64_t timestamp, char **tags,
                              unsigned int tags_length);

#ifdef __cplusplus
}
#endif
