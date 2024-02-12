#include "example.h"

UNIFEX_TERM init(UnifexEnv *env) {
  MyState *state = unifex_alloc_state(env);
  state->a = 42;
  UNIFEX_TERM res = init_result_ok(env, state);
  unifex_release_state(env, state);
  return res;
}

UNIFEX_TERM test_nil(UnifexEnv* env) {
  return test_nil_result_nil(env);
}

UNIFEX_TERM test_atom(UnifexEnv *env, char *in_atom) {
  return test_atom_result_ok(env, in_atom);
}

UNIFEX_TERM test_bool(UnifexEnv *env, int in_bool) {
  return test_bool_result_ok(env, in_bool);
}

UNIFEX_TERM test_float(UnifexEnv *env, double in_float) {
  return test_float_result_ok(env, in_float);
}

UNIFEX_TERM test_uint(UnifexEnv *env, unsigned int in_uint) {
  return test_uint_result_ok(env, in_uint);
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

UNIFEX_TERM test_list_of_uints(UnifexEnv *env, unsigned int *in_uints,
                               unsigned int list_length) {
  return test_list_of_uints_result_ok(env, in_uints, list_length);
}

UNIFEX_TERM test_list_with_other_args(UnifexEnv *env, int *in_list,
                                      unsigned int list_length,
                                      char *other_param) {
  return test_list_with_other_args_result_ok(env, in_list, list_length,
                                             other_param);
}

UNIFEX_TERM test_payload(UnifexEnv *env, UnifexPayload *in_payload) {
  UnifexPayload out_payload;
  unifex_payload_alloc(env, UNIFEX_PAYLOAD_BINARY, in_payload->size, &out_payload);
  memcpy(out_payload.data, in_payload->data, out_payload.size);
  out_payload.data[0]++;
  UNIFEX_TERM result = test_payload_result_ok(env, &out_payload);
  unifex_payload_release(&out_payload);
  return result;
}

UNIFEX_TERM test_pid(UnifexEnv *env, UnifexPid in_pid) {
  UNIFEX_UNUSED(in_pid);
  return test_pid_result_ok(env, in_pid);
}

UNIFEX_TERM test_example_message(UnifexEnv *env) {
  int res = send_example_msg(env, *env->reply_to, 0, 23);
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

UNIFEX_TERM test_nested_struct_list(UnifexEnv *env, nested_struct_list in_struct) {
  return test_nested_struct_list_result_ok(env, in_struct);
}

void handle_destroy_state(UnifexEnv *env, MyState *state) {
  UNIFEX_UNUSED(env);
  state->a = 0;
}

int handle_main(int argc, char **argv) {
  UnifexEnv env;
  if (unifex_cnode_init(argc, argv, &env)) {
    return 1;
  }

  while (!unifex_cnode_receive(&env))
    ;

  unifex_cnode_destroy(&env);
  return 0;
}
