#include "example.h"
#include <stdio.h>

UnifexState *unifex_alloc_state(UnifexEnv *_env) {
  UNIFEX_UNUSED(_env);
  return (UnifexState *)malloc(sizeof(UnifexState));
}

void unifex_release_state(UnifexEnv *env, UnifexState *state) {
  unifex_cnode_add_to_released_states(env, state);
}

void unifex_cnode_destroy_state(UnifexEnv *env, void *state) {
  handle_destroy_state(env, (UnifexState *)state);
  free(state);
}

UNIFEX_TERM init_result_ok(UnifexEnv *env, UnifexState *state) {
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_atom(out_buff, "ok");
  env->state = ({
    UnifexState *unifex_state = state;
    unifex_state;
  });

  return out_buff;
}

UNIFEX_TERM foo_result_ok(UnifexEnv *env, int answer) {
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    int answer_int = answer;
    ei_x_encode_longlong(out_buff, (long long)answer_int);
  });

  return out_buff;
}

UNIFEX_TERM foo_result_error(UnifexEnv *env, const char *reason) {
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "error");
  ei_x_encode_atom(out_buff, reason);

  return out_buff;
}

UNIFEX_TERM init_caller(UnifexEnv *env, const char *in_buff, int *index) {
  UNIFEX_UNUSED(in_buff);
  UNIFEX_UNUSED(index);

  return init(env);
}

UNIFEX_TERM foo_caller(UnifexEnv *env, const char *in_buff, int *index) {

  UnifexPid target;
  UnifexState *state;

  ei_decode_pid(in_buff, index, &target);
  state = (UnifexState *)env->state;

  return foo(env, target, state);
}

int send_example_msg(UnifexEnv *env, UnifexPid pid, int flags, int num) {
  UNIFEX_UNUSED(flags);
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  ei_x_new_with_version(out_buff);

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "example_msg");
  ({
    int num_int = num;
    ei_x_encode_longlong(out_buff, (long long)num_int);
  });

  unifex_cnode_send_and_free(env, &pid, out_buff);
  return 1;
}

UNIFEX_TERM unifex_cnode_handle_message(UnifexEnv *env, char *fun_name,
                                        int *index, ei_x_buff *in_buff) {
  if (strcmp(fun_name, "init") == 0) {
    return init_caller(env, in_buff->buff, index);
  } else if (strcmp(fun_name, "foo") == 0) {
    return foo_caller(env, in_buff->buff, index);
  } else {
    return unifex_cnode_undefined_function_error(env, fun_name);
  }
}

int main(int argc, char **argv) { return handle_main(argc, argv); }
