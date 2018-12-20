#pragma once

#include <erl_nif.h>
#include <string.h>
#include <time.h>

#define UNIFEX_TERM ERL_NIF_TERM

#define UNIFEX_UNUSED(x) (void)(x)

#define UNIFEX_NO_FLAGS 0

#define UNIFEX_SEND_THREADED 1

typedef ErlNifEnv UnifexEnv;

typedef ErlNifPid UnifexPid;

static inline void *unifex_alloc(size_t size) { return enif_alloc(size); }

static inline void *unifex_realloc(void *ptr, size_t size) {
  return enif_realloc(ptr, size);
}

static inline void unifex_free(void *ptr) { enif_free(ptr); }

static inline UnifexEnv *unifex_alloc_env() { return enif_alloc_env(); }

static inline void unifex_clear_env(UnifexEnv *env) { enif_clear_env(env); }

static inline void unifex_free_env(UnifexEnv *env) { enif_free_env(env); }

// Mutexes
typedef ErlNifMutex UnifexMutex;
static inline UnifexMutex *unifex_mutex_create(char *name) {
  return enif_mutex_create(name);
}
static inline void unifex_mutex_destroy(UnifexMutex *mtx) {
  enif_mutex_destroy(mtx);
}
static inline void unifex_mutex_lock(UnifexMutex *mtx) { enif_mutex_lock(mtx); }
static inline int unifex_mutex_trylock(UnifexMutex *mtx) {
  return enif_mutex_trylock(mtx);
}
static inline void unifex_mutex_unlock(UnifexMutex *mtx) {
  enif_mutex_unlock(mtx);
}

// args parse helpers
UNIFEX_TERM unifex_raise_args_error(ErlNifEnv *env, const char *field,
                                    const char *description);

// term manipulation helpers
UNIFEX_TERM unifex_make_resource(ErlNifEnv *env, void *resource);
void unifex_release_resource(void *resource);
int unifex_string_from_term(ErlNifEnv *env, ERL_NIF_TERM input_term,
                            char **string);
UNIFEX_TERM unifex_string_to_term(ErlNifEnv *env, char *string);
int unifex_alloc_and_get_atom(ErlNifEnv *env, ERL_NIF_TERM atom_term,
                              char **output);
int unifex_parse_bool(ErlNifEnv *env, ERL_NIF_TERM atom_term, int *output);

// send & pid helpers
int unifex_send(UnifexEnv *env, UnifexPid *pid, UNIFEX_TERM term, int flags);
int unifex_get_pid_by_name(UnifexEnv *env, char *name, UnifexPid *pid);
static inline UnifexPid *unifex_self(UnifexEnv *env, UnifexPid *pid) {
  return enif_self(env, pid);
}
