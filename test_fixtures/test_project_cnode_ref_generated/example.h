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
#include <unifex/unifex_cnode.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef MyState UnifexState;

UnifexState *unifex_alloc_state(UnifexEnv *env);
void unifex_release_state(UnifexEnv *env, UnifexState *state);
void handle_destroy_state(UnifexEnv *env, UnifexState *state);

UNIFEX_TERM init(UnifexEnv *env);
UNIFEX_TERM foo(UnifexEnv *env, UnifexPid target, UnifexState *state);
UNIFEX_TERM init_result_ok(UnifexEnv *env, UnifexState *state);
UNIFEX_TERM foo_result_ok(UnifexEnv *env, int answer);
UNIFEX_TERM foo_result_error(UnifexEnv *env, const char *reason);
UNIFEX_TERM init_caller(UnifexEnv *env, const char *in_buff, int *index);
UNIFEX_TERM foo_caller(UnifexEnv *env, const char *in_buff, int *index);
int send_example_msg(UnifexEnv *env, UnifexPid pid, int flags, int num);

#ifdef __cplusplus
}
#endif
