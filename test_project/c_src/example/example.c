#include "example.h"

int example_was_handle_load_called = 0;

int handle_load(UnifexEnv *env, void **priv_data) {
  UNIFEX_UNUSED(env);
  UNIFEX_UNUSED(priv_data);
  example_was_handle_load_called = 1;
  return 0;
}

UNIFEX_TERM init(UnifexEnv *env) {
  MyState *state = unifex_alloc_state(env);
  state->a = 42;
  UNIFEX_TERM res = init_result_ok(env, example_was_handle_load_called, state);
  unifex_release_state(env, state);
  return res;
}

UNIFEX_TERM foo(UnifexEnv *env, UnifexPid pid, int *list,
                unsigned int list_length, MyState *state) {
  int res = send_example_msg(env, pid, 0, state->a);
  if (!res) {
    return foo_result_error(env, "send_failed");
  }
  return foo_result_ok(env, list, list_length, state->a);
}

void handle_destroy_state(UnifexEnv *env, MyState *state) {
  UNIFEX_UNUSED(env);
  state->a = 0;
}