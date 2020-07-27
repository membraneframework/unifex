#include "example.h"
#include <stdio.h>

void unifex_cnode_destroy_state(UnifexEnv *env, void *state) {}

UNIFEX_TERM foo_result_ok(UnifexEnv *env, int answer) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    int answer_int = answer;
    ei_x_encode_longlong(out_buff, (long long)answer_int);
  });

  return out_buff;
}

UNIFEX_TERM foo_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_TERM result;
  UNIFEX_UNUSED(in_buff);

  result = foo(env);
  goto exit_foo_caller;
exit_foo_caller:

  return result;
}

UNIFEX_TERM unifex_cnode_handle_message(UnifexEnv *env, char *fun_name,
                                        UnifexCNodeInBuff *in_buff) {
  if (strcmp(fun_name, "foo") == 0) {
    return foo_caller(env, in_buff);
  } else {
    return unifex_cnode_undefined_function_error(env, fun_name);
  }
}

int main(int argc, char **argv) {
  return unifex_cnode_main_function(argc, argv);
}
