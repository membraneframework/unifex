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

int unifex_logger_nif_send(void *env, const char *level, const char *message,
                           uint64_t timestamp, char **tags,
                           unsigned int tags_length);

int unifex_logger_cnode_send(void *env, const char *level, const char *message,
                             uint64_t timestamp, char **tags,
                             unsigned int tags_length);

#ifdef __cplusplus
}
#endif
