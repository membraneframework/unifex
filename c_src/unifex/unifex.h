#pragma once

#include <erl_nif.h>
#include <time.h>
#include "membrane_shm_payload/lib.h"

#define UNIFEX_TERM ERL_NIF_TERM

#define UNIFEX_UTIL_UNUSED(x) (void)(x)
typedef ErlNifEnv UnifexEnv;

typedef enum {
  UNIFEX_PAYLOAD_BINARY,
  UNIFEX_PAYLOAD_SHM
} UnifexPayloadType;

struct _UnifexPayload {
  unsigned char* data;
  unsigned int size;
  union {
    ShmPayload shm;
    ErlNifBinary binary;
  } payload_struct;
  UnifexPayloadType type;
  int owned;
};
typedef struct _UnifexPayload UnifexPayload;



// args parse helpers
ERL_NIF_TERM unifex_util_raise_args_error(ErlNifEnv* env, const char* field, const char *description);

// term manipulation helpers
ERL_NIF_TERM unifex_util_make_and_release_resource(ErlNifEnv* env, void* resource);
int unifex_util_payload_from_term(ErlNifEnv* env, ERL_NIF_TERM binary_term, UnifexPayload* payload);
UNIFEX_TERM unifex_payload_to_term(UnifexEnv* env, UnifexPayload * payload);

// UnifexPayload
UnifexPayload * unifex_payload_alloc(UnifexEnv* env, UnifexPayloadType type, unsigned int size);
void unifex_payload_realloc(UnifexPayload * payload, unsigned int size);
void unifex_payload_release(UnifexPayload * payload);
void unifex_payload_release_ptr(UnifexPayload ** payload);
