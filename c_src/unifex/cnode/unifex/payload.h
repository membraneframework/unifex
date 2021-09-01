#pragma once

#include "cnode.h"
#include "unifex.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum { UNIFEX_PAYLOAD_BINARY } UnifexPayloadType;

struct _UnifexPayload {
  unsigned char *data;
  unsigned int size;
  union {
  } payload_struct;
  UnifexPayloadType type;
  int owned;
};
typedef struct _UnifexPayload UnifexPayload;

int unifex_payload_alloc(UnifexEnv *env, UnifexPayloadType type,
                                    unsigned int size, UnifexPayload *payload);
int unifex_payload_decode(UnifexEnv *env, UnifexCNodeInBuff *buff,
                          UnifexPayload **payload);
void unifex_payload_encode(UnifexEnv *env, UNIFEX_TERM buff,
                           UnifexPayload *payload);
void unifex_payload_release(UnifexPayload *payload);
#ifdef __cplusplus
}
#endif
