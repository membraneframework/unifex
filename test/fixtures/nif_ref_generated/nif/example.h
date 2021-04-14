#pragma once

#include "../../example.h"
#include <erl_nif.h>
#include <stdint.h>
#include <stdio.h>
#include <unifex/payload.h>
#include <unifex/unifex.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Functions that manage lib and state lifecycle
 * Functions with 'unifex_' prefix are generated automatically,
 * the user have to implement rest of them.
 */

typedef MyState UnifexState;

/**
 * Allocates the state struct. Have to be paired with 'unifex_release_state'
 * call
 */
UnifexState *unifex_alloc_state(UnifexEnv *env);

/**
 * Removes a reference to the state object.
 * The state is destructed when the last reference is removed.
 * Each call to 'unifex_release_state' must correspond to a previous
 * call to 'unifex_alloc_state' or 'unifex_keep_state'.
 */
void unifex_release_state(UnifexEnv *env, UnifexState *state);

/**
 * Increases reference count of state object.
 * Each call has to be balanced by 'unifex_release_state' call
 */
void unifex_keep_state(UnifexEnv *env, UnifexState *state);

/**
 * Callback called when the state struct is destroyed. It should
 * be responsible for releasing any resources kept inside state.
 */
void handle_destroy_state(UnifexEnv *env, UnifexState *state);

#ifdef __cplusplus
struct my_struct {
  int id;
  int *data;
  unsigned int data_length;
  char *name;
};
#else
struct my_struct_t {
  int id;
  int *data;
  unsigned int data_length;
  char *name;
};
typedef struct my_struct_t my_struct;
#endif

#ifdef __cplusplus
struct outer_struct {
  my_struct nested_struct;
  int id;
};
#else
struct outer_struct_t {
  my_struct nested_struct;
  int id;
};
typedef struct outer_struct_t outer_struct;
#endif

/*
 * Declaration of native functions for module Elixir.Example.
 * The implementation have to be provided by the user.
 */

UNIFEX_TERM init(UnifexEnv *env);
UNIFEX_TERM test_atom(UnifexEnv *env, char *in_atom);
UNIFEX_TERM test_float(UnifexEnv *env, double in_float);
UNIFEX_TERM test_int(UnifexEnv *env, int in_int);
UNIFEX_TERM test_list(UnifexEnv *env, int *in_list,
                      unsigned int in_list_length);
UNIFEX_TERM test_pid(UnifexEnv *env, UnifexPid in_pid);
UNIFEX_TERM test_state(UnifexEnv *env, UnifexState *state);
UNIFEX_TERM test_example_message(UnifexEnv *env, UnifexPid pid);
UNIFEX_TERM test_my_struct(UnifexEnv *env, my_struct in_struct);
UNIFEX_TERM test_outer_struct(UnifexEnv *env, outer_struct in_struct);

/*
 * Callbacks for nif lifecycle hooks.
 * Have to be implemented by user.
 */

int handle_load(UnifexEnv *env, void **priv_data);

/*
 * Functions that create the defined output from Nif.
 * They are automatically generated and don't need to be implemented.
 */

UNIFEX_TERM init_result_ok(UnifexEnv *env, int was_handle_load_called,
                           UnifexState *state);
UNIFEX_TERM test_atom_result_ok(UnifexEnv *env, const char *out_atom);
UNIFEX_TERM test_float_result_ok(UnifexEnv *env, double out_float);
UNIFEX_TERM test_int_result_ok(UnifexEnv *env, int out_int);
UNIFEX_TERM test_list_result_ok(UnifexEnv *env, int const *out_list,
                                unsigned int out_list_length);
UNIFEX_TERM test_pid_result_ok(UnifexEnv *env, UnifexPid out_pid);
UNIFEX_TERM test_state_result_ok(UnifexEnv *env, UnifexState *state);
UNIFEX_TERM test_example_message_result_ok(UnifexEnv *env);
UNIFEX_TERM test_example_message_result_error(UnifexEnv *env,
                                              const char *reason);
UNIFEX_TERM test_my_struct_result_ok(UnifexEnv *env, my_struct out_struct);
UNIFEX_TERM test_outer_struct_result_ok(UnifexEnv *env,
                                        outer_struct out_struct);

/*
 * Functions that send the defined messages from Nif.
 * They are automatically generated and don't need to be implemented.
 */

int send_example_msg(UnifexEnv *env, UnifexPid pid, int flags, int num);

#ifdef __cplusplus
}
#endif
