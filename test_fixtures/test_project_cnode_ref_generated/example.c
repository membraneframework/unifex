#include "example.h"
#include <stdio.h>

void unifex_release_state(UnifexEnv *env, UnifexState *state) {
  add_item(env, state);
}

UnifexState *unifex_alloc_state(UnifexEnv *_env) {
  UNIFEX_UNUSED(_env);
  return (UnifexState *)malloc(sizeof(UnifexState));
}

UNIFEX_TERM init_result_ok(UnifexEnv *env, UnifexState *state) {
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_atom(out_buff, "ok");
  env->state = ({
    UnifexState *unifex_state = state;
    unifex_state;
  });

  return out_buff;
}

UNIFEX_TERM foo_result_ok(UnifexEnv *env, int answer) {
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  prepare_ei_x_buff(env, out_buff, "result");

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
  prepare_ei_x_buff(env, out_buff, "result");

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

  send_and_free(env, &pid, out_buff);
  free(out_buff);
  return 1;
}

void handle_message(UnifexEnv *env, char *fun_name, int *index,
                    ei_x_buff *in_buff) {
  if (strcmp(fun_name, "init") == 0) {
    UNIFEX_TERM result = init_caller(env, in_buff->buff, index);
    send_to_server_and_free(env, result);
  } else if (strcmp(fun_name, "foo") == 0) {
    UNIFEX_TERM result = foo_caller(env, in_buff->buff, index);
    send_to_server_and_free(env, result);
  } else {
    char err_msg[4000];
    strcpy(err_msg, "function ");
    strcat(err_msg, fun_name);
    strcat(err_msg, " not available");
    sending_error(env, err_msg);
  }
}

void unifex_destroy_state(UnifexEnv *env, void *state) {
  handle_destroy_state(env, (UnifexState *)state);
  free(state);
}

int main(int argc, char **argv) { return main_function(argc, argv); }
