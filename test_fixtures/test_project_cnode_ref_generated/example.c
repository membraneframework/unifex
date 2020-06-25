#include "example.h"
#include <stdio.h>

size_t unifex_state_wrapper_sizeof() {
  return sizeof(struct UnifexStateWrapper);
}

void unifex_release_state(UnifexEnv *env, UnifexState *state) {
  UnifexStateWrapper *wrapper =
      (UnifexStateWrapper *)malloc(sizeof(UnifexStateWrapper));
  wrapper->state = state;
  add_item(env->released_states, wrapper);
}

UnifexState *unifex_alloc_state(UnifexEnv *env) {
  return (UnifexState *)malloc(sizeof(UnifexState));
}

UNIFEX_TERM init_result_ok(cnode_context *ctx, UnifexState *state) {
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  prepare_result_buff(out_buff, ctx->node_name);

  ei_x_encode_atom(out_buff, "ok");
  ctx->wrapper->state = state;

  return out_buff;
}

UNIFEX_TERM foo_result_ok(cnode_context *ctx, int answer) {
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  prepare_result_buff(out_buff, ctx->node_name);

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    int answer_int = answer;
    ei_x_encode_longlong(out_buff, (long long)answer_int);
    printf("dupa\n");
  });

  return out_buff;
}

UNIFEX_TERM foo_result_error(cnode_context *ctx, const char *reason) {
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  prepare_result_buff(out_buff, ctx->node_name);

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "error");
  ei_x_encode_atom(out_buff, reason);

  return out_buff;
}

void init_caller(const char *in_buff, int *index, cnode_context *ctx) {

  ctx->released_states = new_state_linked_list();

  UNIFEX_TERM result = init(ctx);
  send_to_server_and_free(ctx, result);

  free_states(ctx, ctx->released_states, ctx->wrapper);
}

void foo_caller(const char *in_buff, int *index, cnode_context *ctx) {
  UnifexPid target;
  UnifexState *state;

  ei_decode_pid(in_buff, index, &target);
  state = ctx->wrapper->state;
  ctx->released_states = new_state_linked_list();

  UNIFEX_TERM result = foo(ctx, target, state);
  send_to_server_and_free(ctx, result);

  free_states(ctx, ctx->released_states, ctx->wrapper);
}

int send_example_msg(cnode_context *ctx, UnifexPid pid, int flags, int num) {
  UNIFEX_UNUSED(flags);
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  ei_x_new_with_version(out_buff);

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "example_msg");
  ({
    int num_int = num;
    ei_x_encode_longlong(out_buff, (long long)num_int);
    printf("dupa\n");
  });

  send_and_free(ctx, &pid, out_buff);
  free(out_buff);
  return 1;
}

int handle_message(int ei_fd, const char *node_name, erlang_msg emsg,
                   ei_x_buff *in_buff, struct UnifexStateWrapper *state) {
  int index = 0;
  int version;
  ei_decode_version(in_buff->buff, &index, &version);

  int arity;
  ei_decode_tuple_header(in_buff->buff, &index, &arity);

  char fun_name[2048];
  ei_decode_atom(in_buff->buff, &index, fun_name);

  cnode_context ctx = {.node_name = node_name,
                       .ei_fd = ei_fd,
                       .e_pid = &emsg.from,
                       .wrapper = state};

  if (strcmp(fun_name, "init") == 0) {
    init_caller(in_buff->buff, &index, &ctx);
  } else if (strcmp(fun_name, "foo") == 0) {
    foo_caller(in_buff->buff, &index, &ctx);
  } else {
    char err_msg[4000];
    strcpy(err_msg, "function ");
    strcat(err_msg, fun_name);
    strcat(err_msg, " not available");
    sending_error(&ctx, err_msg);
  }

  return 0;
}

void handle_destroy_state_wrapper(UnifexEnv *env,
                                  struct UnifexStateWrapper *wrapper) {
  handle_destroy_state(env, wrapper->state);
}

int wrappers_cmp(struct UnifexStateWrapper *a, struct UnifexStateWrapper *b) {
  return a->state == b->state ? 0 : 1;
}

void free_state(UnifexStateWrapper *wrapper) { free(wrapper->state); }

int main(int argc, char **argv) { return main_function(argc, argv); }
