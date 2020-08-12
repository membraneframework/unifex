#include "example.h"

UNIFEX_TERM init(UnifexEnv *env) {
  MyState *state = unifex_alloc_state(env);
  state->a = 42;
  UNIFEX_TERM res = init_result_ok(env, state);
  unifex_release_state(env, state);
  return res;
}

UNIFEX_TERM foo(UnifexEnv *env, UnifexPid pid, UnifexPayload *in_payload, int *in_list, int list_length, MyState *state) {
  int res = send_example_msg(env, pid, 0, state->a);
  if (!res) {
    return foo_result_error(env, "send_failed");
  }
  UnifexPayload *out_payload =
      unifex_payload_alloc(env, UNIFEX_PAYLOAD_BINARY, in_payload->size);
  memcpy(out_payload->data, in_payload->data, out_payload->size);
  out_payload->data[0]++;
  UNIFEX_TERM result = foo_result_ok(env, state->a, out_payload, in_list, list_length);
  unifex_payload_release(out_payload);
  return result;
}

UNIFEX_TERM test_list(UnifexEnv *env, int *in_list, int list_length) {
    return test_list_result_ok(env, in_list, list_length);
}

UNIFEX_TERM test_string(UnifexEnv *env, char *str) {
    return test_string_result_ok(env, str);
}

UNIFEX_TERM test_strings_list(UnifexEnv *env, char **str, int list_length) {
    return test_strings_list_result_ok(env, str, list_length);
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
