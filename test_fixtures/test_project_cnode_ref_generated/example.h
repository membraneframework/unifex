#pragma once

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef _REENTRANT
#define _REENTRANT

#endif
#include <ei_connect.h>
#include <erl_interface.h>

#include "../example.h"
#include <unifex/unifex.h>

#ifdef __cplusplus
extern "C" {
#endif

struct UnifexStateWrapper {
  UnifexState *state;
};

void unifex_release_state(UnifexEnv *env, UnifexState *state);
UnifexState *unifex_alloc_state(UnifexEnv *env);
void handle_destroy_state(UnifexEnv *env, UnifexState *state);

UNIFEX_TERM init(cnode_context *ctx);
UNIFEX_TERM foo(cnode_context *ctx, UnifexPid target, UnifexState *state);
UNIFEX_TERM init_result_ok(cnode_context *ctx, UnifexState *state);
UNIFEX_TERM foo_result_ok(cnode_context *ctx, int answer);
UNIFEX_TERM foo_result_error(cnode_context *ctx, const char *reason);
void init_caller(const char *in_buff, int *index, cnode_context *ctx);
void foo_caller(const char *in_buff, int *index, cnode_context *ctx);
int send_example_msg(cnode_context *ctx, UnifexPid pid, int flags, int num);

#ifdef __cplusplus
}
#endif
