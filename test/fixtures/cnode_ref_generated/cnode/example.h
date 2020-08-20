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
UNIFEX_TERM test_atom(UnifexEnv *env, char *in_atom);
UNIFEX_TERM test_uint(UnifexEnv *env, unsigned int in_uint);
UNIFEX_TERM test_string(UnifexEnv *env, char *in_string);
UNIFEX_TERM test_list(UnifexEnv *env, int *in_list,
                      unsigned int in_list_length);
UNIFEX_TERM test_list_of_strings(UnifexEnv *env, char **in_strings,
                                 unsigned int in_strings_length);
UNIFEX_TERM test_list_of_uints(UnifexEnv *env, unsigned int *in_uints,
                               unsigned int in_uints_length);
UNIFEX_TERM test_list_with_other_args(UnifexEnv *env, int *in_list,
                                      unsigned int in_list_length,
                                      char *other_param);
UNIFEX_TERM test_payload(UnifexEnv *env, UnifexPayload *in_payload);
UNIFEX_TERM test_pid(UnifexEnv *env, UnifexPid in_pid);
UNIFEX_TERM test_example_message(UnifexEnv *env);
UNIFEX_TERM init_result_ok(UnifexEnv *env, UnifexState *state);
UNIFEX_TERM test_atom_result_ok(UnifexEnv *env, const char *out_atom);
UNIFEX_TERM test_uint_result_ok(UnifexEnv *env, unsigned int out_uint);
UNIFEX_TERM test_string_result_ok(UnifexEnv *env, const char *out_string);
UNIFEX_TERM test_list_result_ok(UnifexEnv *env, const int *out_list,
                                unsigned int out_list_length);
UNIFEX_TERM test_list_of_strings_result_ok(UnifexEnv *env,
                                           const char **out_strings,
                                           unsigned int out_strings_length);
UNIFEX_TERM test_list_of_uints_result_ok(UnifexEnv *env,
                                         const unsigned int *out_uints,
                                         unsigned int out_uints_length);
UNIFEX_TERM test_list_with_other_args_result_ok(UnifexEnv *env,
                                                const int *out_list,
                                                unsigned int out_list_length,
                                                const char *other_param);
UNIFEX_TERM test_payload_result_ok(UnifexEnv *env, UnifexPayload *out_payload);
UNIFEX_TERM test_pid_result_ok(UnifexEnv *env, UnifexPid out_pid);
UNIFEX_TERM test_example_message_result_ok(UnifexEnv *env);
UNIFEX_TERM test_example_message_result_error(UnifexEnv *env,
                                              const char *reason);
UNIFEX_TERM init_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_atom_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_uint_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_string_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_list_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_list_of_strings_caller(UnifexEnv *env,
                                        UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_list_of_uints_caller(UnifexEnv *env,
                                      UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_list_with_other_args_caller(UnifexEnv *env,
                                             UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_payload_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_pid_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_example_message_caller(UnifexEnv *env,
                                        UnifexCNodeInBuff *in_buff);
int send_example_msg(UnifexEnv *env, UnifexPid pid, int flags, int num);
int handle_main(int argc, char **argv);

#ifdef __cplusplus
}
#endif
