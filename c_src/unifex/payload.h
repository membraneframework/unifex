#pragma once

#include <shmex/lib_nif.h>
#include "unifex.h"

typedef enum { UNIFEX_PAYLOAD_BINARY, UNIFEX_PAYLOAD_SHM } UnifexPayloadType;

struct _UnifexPayload {
  unsigned char *data;
  unsigned int size;
  union {
    Shmex shm;
    ErlNifBinary binary;
  } payload_struct;
  UnifexPayloadType type;
  int owned;
};
typedef struct _UnifexPayload UnifexPayload;

ErlNifResourceType *UNIFEX_PAYLOAD_GUARD_RESOURCE_TYPE;

int unifex_payload_from_term(ErlNifEnv *env, ERL_NIF_TERM binary_term,
                             UnifexPayload *payload);
UNIFEX_TERM unifex_payload_to_term(UnifexEnv *env, UnifexPayload *payload);
UnifexPayload *unifex_payload_alloc(UnifexEnv *env, UnifexPayloadType type,
                                    unsigned int size);
void unifex_payload_guard_destructor(UnifexEnv *env, void *resource);
int unifex_payload_realloc(UnifexPayload *payload, unsigned int size);
void unifex_payload_release(UnifexPayload *payload);
void unifex_payload_release_ptr(UnifexPayload **payload);
