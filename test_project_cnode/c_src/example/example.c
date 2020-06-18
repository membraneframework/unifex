#include "example.h"

UNIFEX_TERM init(UnifexEnv *env) {
  State *state = unifex_alloc_state(env);
  state->a = 42;
  UNIFEX_TERM res = init_result_ok(env, state);
  unifex_release_state(env, state);
  return res;
}

UNIFEX_TERM foo(UnifexEnv *env, UnifexPid pid, State *state) {
  int res = send_example_msg(env, pid, 0, state->a);
  if (!res) {
    return foo_result_error(env, "send_failed");
  }
  return foo_result_ok(env, state->a);
}

void handle_destroy_state(UnifexEnv *env, State *state) {
  UNIFEX_UNUSED(env);
  state->a = 0;
}