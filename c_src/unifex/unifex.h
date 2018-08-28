#pragma once

#include <erl_nif.h>

#define UNIFEX_TERM ERL_NIF_TERM

struct _UnifexEnv {
  ErlNifEnv* nif_env;
};
typedef struct _UnifexEnv UnifexEnv;

struct _UnifexPayload {
  unsigned char* data;
  unsigned int size;
  ERL_NIF_TERM term;
};
typedef struct _UnifexPayload UnifexPayload;

UnifexPayload unifex_payload_alloc(UnifexEnv* env, unsigned int size);
