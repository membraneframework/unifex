#pragma once

#include <erl_nif.h>
#include <time.h>
#include <string.h>

#define UNIFEX_TERM ERL_NIF_TERM

#define UNIFEX_UNUSED(x) (void)(x)

#define UNIFEX_NO_FLAGS 0

#define UNIFEX_SEND_THREADED 1

typedef ErlNifEnv UnifexEnv;

typedef ErlNifPid UnifexPid;

static inline void* unifex_alloc(size_t size) {
  return enif_alloc(size);
}

static inline void* unifex_realloc(void* ptr, size_t size) {
  return enif_realloc(ptr, size);
}

static inline void unifex_free(void* ptr) {
  enif_free(ptr);
}

// args parse helpers
UNIFEX_TERM unifex_raise_args_error(ErlNifEnv* env, const char* field, const char *description);

// term manipulation helpers
UNIFEX_TERM unifex_make_resource(ErlNifEnv* env, void* resource);
void unifex_release_resource(void * resource);
int unifex_string_from_term(ErlNifEnv* env, ERL_NIF_TERM input_term, char** string);
UNIFEX_TERM unifex_string_to_term(ErlNifEnv* env, char* string);
int unifex_alloc_and_get_atom(ErlNifEnv* env, ERL_NIF_TERM atom_term, char ** output);

// send helpers
int unifex_send(UnifexEnv* env, UnifexPid* pid, UNIFEX_TERM term, int flags);
int unifex_get_pid_by_name(UnifexEnv* env, char* name, UnifexPid* pid);
