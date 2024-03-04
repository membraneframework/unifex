#include "example.h"

int example_was_handle_load_called = 0;

int handle_load(UnifexEnv *env, void **priv_data) {
  UNIFEX_UNUSED(env);
  UNIFEX_UNUSED(priv_data);
  example_was_handle_load_called = 1;
  return 0;
}

UNIFEX_TERM test_nil(UnifexEnv* env) {
  return test_nil_result_nil(env);
}

UNIFEX_TERM test_nil_tuple(UnifexEnv* env) {
  return test_nil_tuple_result_nil(env, 1);
}

UNIFEX_TERM init(UnifexEnv *env) {
  MyState *state = unifex_alloc_state(env);
  state->a = 42;
  UNIFEX_TERM res = init_result_ok(env, example_was_handle_load_called, state);
  unifex_release_state(env, state);
  return res;
}

UNIFEX_TERM test_atom(UnifexEnv *env, char *in_atom) {
  return test_atom_result_ok(env, in_atom);
}

UNIFEX_TERM test_float(UnifexEnv *env, double in_float) {
  return test_float_result_ok(env, in_float);
}

UNIFEX_TERM test_int(UnifexEnv *env, int in_int) {
  return test_int_result_ok(env, in_int);
}

UNIFEX_TERM test_string(UnifexEnv *env, char *str) {
  return test_string_result_ok(env, str);
}

UNIFEX_TERM test_list(UnifexEnv *env, int *in_list, unsigned int list_length) {
  return test_list_result_ok(env, in_list, list_length);
}

UNIFEX_TERM test_list_of_strings(UnifexEnv *env, char **in_strings,
                                 unsigned int list_length) {
  return test_list_of_strings_result_ok(env, in_strings, list_length);
}

UNIFEX_TERM test_pid(UnifexEnv *env, UnifexPid in_pid) {
  return test_pid_result_ok(env, in_pid);
}

UNIFEX_TERM test_state(UnifexEnv *env, MyState *state) {
  return test_state_result_ok(env, state);
}

UNIFEX_TERM test_example_message(UnifexEnv *env, UnifexPid pid) {
  int res = send_example_msg(env, pid, 0, 10);
  if (!res) {
    return test_example_message_result_error(env, "send_failed");
  }
  return test_example_message_result_ok(env);
}

UNIFEX_TERM test_my_struct(UnifexEnv *env, my_struct in_struct) {
  return test_my_struct_result_ok(env, in_struct);
}

UNIFEX_TERM test_my_enum(UnifexEnv *env, MyEnum in_enum) {
  return test_my_enum_result_ok(env, in_enum);
}

UNIFEX_TERM test_nested_struct(UnifexEnv *env, nested_struct in_struct) {
  return test_nested_struct_result_ok(env, in_struct);
}

UNIFEX_TERM test_list_of_structs(UnifexEnv *env, simple_struct* structs, unsigned int structs_length) {
  return test_list_of_structs_result_ok(env, structs, structs_length);
}

void handle_destroy_state(UnifexEnv *env, MyState *state) {
  UNIFEX_UNUSED(env);
  state->a = 0;
}

// tests for bugged version of functions returning nil.
// these tests should be removed in unifex v2.0.0. For more information check:
// https://github.com/membraneframework/membrane_core/issues/758

UNIFEX_TERM test_nil_bugged(UnifexEnv* env) {
  return test_nil_bugged_result_(env);
}

UNIFEX_TERM test_nil_tuple_bugged(UnifexEnv* env) {
  return test_nil_tuple_bugged_result_(env, 1);
}