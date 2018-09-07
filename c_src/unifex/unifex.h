#pragma once

#include <erl_nif.h>
#include <time.h>
#include "shmex/lib.h"

#define UNIFEX_TERM ERL_NIF_TERM

#define UNIFEX_UNUSED(x) (void)(x)

#define UNIFEX_NO_FLAGS 0

#define UNIFEX_SEND_THREADED 1

typedef ErlNifEnv UnifexEnv;

typedef ErlNifPid UnifexPid;

typedef enum {
  UNIFEX_PAYLOAD_BINARY,
  UNIFEX_PAYLOAD_SHM
} UnifexPayloadType;

struct _UnifexPayload {
  unsigned char* data;
  unsigned int size;
  union {
    Shmex shm;
    ErlNifBinary binary;
  } payload_struct;
  UnifexPayloadType type;
  int owned;
};
typedef struct _UnifexPayload UnifexPayload;


void* unifex_alloc(size_t size);

// args parse helpers
UNIFEX_TERM unifex_raise_args_error(ErlNifEnv* env, const char* field, const char *description);

// term manipulation helpers
UNIFEX_TERM unifex_make_and_release_resource(ErlNifEnv* env, void* resource);
int unifex_string_from_term(ErlNifEnv* env, ERL_NIF_TERM input_term, char** string);
UNIFEX_TERM unifex_string_to_term(ErlNifEnv* env, char* string);
int unifex_payload_from_term(ErlNifEnv* env, ERL_NIF_TERM binary_term, UnifexPayload* payload);
UNIFEX_TERM unifex_payload_to_term(UnifexEnv* env, UnifexPayload * payload);

// UnifexPayload
UnifexPayload * unifex_payload_alloc(UnifexEnv* env, UnifexPayloadType type, unsigned int size);
void unifex_payload_realloc(UnifexPayload * payload, unsigned int size);
void unifex_payload_release(UnifexPayload * payload);
void unifex_payload_release_ptr(UnifexPayload ** payload);

// send helpers
UNIFEX_TERM unifex_send(UnifexEnv* env, UnifexPid* pid, UNIFEX_TERM term, int flags);
int unifex_get_pid_by_name(UnifexEnv* env, char* name, UnifexPid* pid);
