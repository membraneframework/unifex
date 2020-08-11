#pragma once

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// required for ei.h to work
#ifndef _REENTRANT
#define _REENTRANT
#endif

#include <ei.h>
#include <ei_connect.h>

#include "../../example.h"
#include <unifex/cnode.h>
#include <unifex/payload.h>
#include <unifex/unifex.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef MyState UnifexState;

UnifexState *unifex_alloc_state(UnifexEnv *env);
void unifex_release_state(UnifexEnv *env, UnifexState *state);
void handle_destroy_state(UnifexEnv *env, UnifexState *state);

UNIFEX_TERM init(UnifexEnv *env);
UNIFEX_TERM foo(UnifexEnv *env, UnifexPid target, UnifexPayload *in_payload,
                UnifexState *state);
UNIFEX_TERM init_result_ok(UnifexEnv *env, UnifexState *state);
UNIFEX_TERM foo_result_ok(UnifexEnv *env, int answer,
                          UnifexPayload *out_payload);
UNIFEX_TERM foo_result_error(UnifexEnv *env, const char *reason);
UNIFEX_TERM init_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM foo_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
int send_example_msg(UnifexEnv *env, UnifexPid pid, int flags, int num);
int handle_main(int argc, char **argv);

#ifdef __cplusplus
}
#endif
