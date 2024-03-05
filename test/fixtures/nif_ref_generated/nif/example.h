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
enum MyEnum {
  MY_ENUM_OPTION_ONE,
  MY_ENUM_OPTION_TWO,
  MY_ENUM_OPTION_THREE,
  MY_ENUM_OPTION_FOUR,
  MY_ENUM_OPTION_FIVE
};
#else
enum MyEnum_t {
  MY_ENUM_OPTION_ONE,
  MY_ENUM_OPTION_TWO,
  MY_ENUM_OPTION_THREE,
  MY_ENUM_OPTION_FOUR,
  MY_ENUM_OPTION_FIVE
};
typedef enum MyEnum_t MyEnum;
#endif

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
struct simple_struct {
  int id;
  char *name;
};
#else
struct simple_struct_t {
  int id;
  char *name;
};
typedef struct simple_struct_t simple_struct;
#endif

#ifdef __cplusplus
struct nested_struct {
  my_struct inner_struct;
  int id;
};
#else
struct nested_struct_t {
  my_struct inner_struct;
  int id;
};
typedef struct nested_struct_t nested_struct;
#endif

/*
 * Declaration of native functions for module Elixir.Example.
 * The implementation have to be provided by the user.
 */

UNIFEX_TERM init(UnifexEnv *env);
UNIFEX_TERM test_atom(UnifexEnv *env, char *in_atom);
UNIFEX_TERM test_float(UnifexEnv *env, double in_float);
UNIFEX_TERM test_int(UnifexEnv *env, int in_int);
UNIFEX_TERM test_nil(UnifexEnv *env);
UNIFEX_TERM test_nil_tuple(UnifexEnv *env, int in_int);
UNIFEX_TERM test_string(UnifexEnv *env, char *in_string);
UNIFEX_TERM test_list(UnifexEnv *env, int *in_list,
                      unsigned int in_list_length);
UNIFEX_TERM test_list_of_strings(UnifexEnv *env, char **in_strings,
                                 unsigned int in_strings_length);
UNIFEX_TERM test_pid(UnifexEnv *env, UnifexPid in_pid);
UNIFEX_TERM test_state(UnifexEnv *env, UnifexState *state);
UNIFEX_TERM test_example_message(UnifexEnv *env, UnifexPid pid);
UNIFEX_TERM test_my_struct(UnifexEnv *env, my_struct in_struct);
UNIFEX_TERM test_nested_struct(UnifexEnv *env, nested_struct in_struct);
UNIFEX_TERM test_list_of_structs(UnifexEnv *env, simple_struct *struct_list,
                                 unsigned int struct_list_length);
UNIFEX_TERM test_my_enum(UnifexEnv *env, MyEnum in_enum);
UNIFEX_TERM test_nil_bugged(UnifexEnv *env);
UNIFEX_TERM test_nil_tuple_bugged(UnifexEnv *env, int in_int);

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
UNIFEX_TERM test_atom_result_ok(UnifexEnv *env, char const *out_atom);
UNIFEX_TERM test_float_result_ok(UnifexEnv *env, double out_float);
UNIFEX_TERM test_int_result_ok(UnifexEnv *env, int out_int);
UNIFEX_TERM test_nil_result_nil(UnifexEnv *env);
UNIFEX_TERM test_nil_tuple_result_nil(UnifexEnv *env, int out_int);
UNIFEX_TERM test_string_result_ok(UnifexEnv *env, char const *out_string);
UNIFEX_TERM test_list_result_ok(UnifexEnv *env, int const *out_list,
                                unsigned int out_list_length);
UNIFEX_TERM test_list_of_strings_result_ok(UnifexEnv *env, char **out_strings,
                                           unsigned int out_strings_length);
UNIFEX_TERM test_pid_result_ok(UnifexEnv *env, UnifexPid out_pid);
UNIFEX_TERM test_state_result_ok(UnifexEnv *env, UnifexState *state);
UNIFEX_TERM test_example_message_result_ok(UnifexEnv *env);
UNIFEX_TERM test_example_message_result_error(UnifexEnv *env,
                                              char const *reason);
UNIFEX_TERM test_my_struct_result_ok(UnifexEnv *env, my_struct out_struct);
UNIFEX_TERM test_nested_struct_result_ok(UnifexEnv *env,
                                         nested_struct out_struct);
UNIFEX_TERM test_list_of_structs_result_ok(UnifexEnv *env,
                                           simple_struct const *out_struct_list,
                                           unsigned int out_struct_list_length);
UNIFEX_TERM test_my_enum_result_ok(UnifexEnv *env, MyEnum out_enum);
UNIFEX_TERM test_nil_bugged_result_nil(UnifexEnv *env);
UNIFEX_TERM test_nil_tuple_bugged_result_nil(UnifexEnv *env, int out_int);

/*
 * Bugged version of functions returning nil, left for backwards compabiliy with
 * older code using unifex Generating of these functions should be removed in
 * unifex v2.0.0 For more information check:
 * https://github.com/membraneframework/membrane_core/issues/758
 */
UNIFEX_TERM test_nil_result_(UnifexEnv *env);
UNIFEX_TERM test_nil_tuple_result_(UnifexEnv *env, int out_int);
UNIFEX_TERM test_nil_bugged_result_(UnifexEnv *env);
UNIFEX_TERM test_nil_tuple_bugged_result_(UnifexEnv *env, int out_int);

/*
 * Functions that send the defined messages from Nif.
 * They are automatically generated and don't need to be implemented.
 */

int send_example_msg(UnifexEnv *env, UnifexPid pid, int flags, int num);

#ifdef __cplusplus
}
#endif
