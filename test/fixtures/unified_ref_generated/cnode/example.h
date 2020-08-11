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

UNIFEX_TERM foo(UnifexEnv *env, int num);
UNIFEX_TERM foo_result_ok(UnifexEnv *env, int answer);
UNIFEX_TERM foo_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);

int unifex_cnode_main_function(int argc, char **argv);

#ifdef __cplusplus
}
#endif
