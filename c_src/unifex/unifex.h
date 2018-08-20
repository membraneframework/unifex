#pragma once

#include <erl_nif.h>
#include <uuid/uuid.h>
#include "membrane_shm_payload/lib.h"

#define UNIFEX_TERM ERL_NIF_TERM

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


UnifexPayload * unifex_payload_alloc(UnifexEnv* env, UnifexPayloadType type, unsigned int size);
void unifex_payload_realloc(UnifexPayload * payload, unsigned int size);
void unifex_payload_free(UnifexPayload * payload);
void unifex_payload_free_ptr(UnifexPayload ** payload);
