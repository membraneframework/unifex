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

#ifdef __cplusplus
enum MyEnum {
  MY_ENUM_OPTION_ONE,
  MY_ENUM_OPTION_TWO,
  MY_ENUM_OPTION_THREE,
  MY_ENUM_OPTION_FOUR,
  MY_ENUM_OPTION_FIVE
};
#else
enum MyEnum_t {
  MY_ENUM_OPTION_ONE,
  MY_ENUM_OPTION_TWO,
  MY_ENUM_OPTION_THREE,
  MY_ENUM_OPTION_FOUR,
  MY_ENUM_OPTION_FIVE
};
typedef enum MyEnum_t MyEnum;
#endif

#ifdef __cplusplus
struct my_struct {
  int id;
  int *data;
  unsigned int data_length;
  char *name;
};
#else
struct my_struct_t {
  int id;
  int *data;
  unsigned int data_length;
  char *name;
};
typedef struct my_struct_t my_struct;
#endif

#ifdef __cplusplus
struct nested_struct {
  my_struct inner_struct;
  int id;
};
#else
struct nested_struct_t {
  my_struct inner_struct;
  int id;
};
typedef struct nested_struct_t nested_struct;
#endif

#ifdef __cplusplus
struct nested_struct_list {
  my_struct *struct_list;
  unsigned int struct_list_length;
  int id;
};
#else
struct nested_struct_list_t {
  my_struct *struct_list;
  unsigned int struct_list_length;
  int id;
};
typedef struct nested_struct_list_t nested_struct_list;
#endif

UNIFEX_TERM test_uint64(UnifexEnv *env, uint64_t in_uint);
UNIFEX_TERM test_int64(UnifexEnv *env, int64_t in_uint);
UNIFEX_TERM init(UnifexEnv *env);
UNIFEX_TERM test_nil(UnifexEnv *env);
UNIFEX_TERM test_atom(UnifexEnv *env, char *in_atom);
UNIFEX_TERM test_bool(UnifexEnv *env, int in_bool);
UNIFEX_TERM test_float(UnifexEnv *env, double in_float);
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
UNIFEX_TERM test_my_struct(UnifexEnv *env, my_struct in_struct);
UNIFEX_TERM test_nested_struct(UnifexEnv *env, nested_struct in_struct);
UNIFEX_TERM test_nested_struct_list(UnifexEnv *env,
                                    nested_struct_list in_struct);
UNIFEX_TERM test_my_enum(UnifexEnv *env, MyEnum in_enum);
UNIFEX_TERM test_uint64_result_ok(UnifexEnv *env, uint64_t out_uint);
UNIFEX_TERM test_int64_result_ok(UnifexEnv *env, int64_t out_uint);
UNIFEX_TERM init_result_ok(UnifexEnv *env, UnifexState *state);
UNIFEX_TERM test_nil_result_nil(UnifexEnv *env);
UNIFEX_TERM test_atom_result_ok(UnifexEnv *env, char const *out_atom);
UNIFEX_TERM test_bool_result_ok(UnifexEnv *env, int out_bool);
UNIFEX_TERM test_float_result_ok(UnifexEnv *env, double out_float);
UNIFEX_TERM test_uint_result_ok(UnifexEnv *env, unsigned int out_uint);
UNIFEX_TERM test_string_result_ok(UnifexEnv *env, char const *out_string);
UNIFEX_TERM test_list_result_ok(UnifexEnv *env, int const *out_list,
                                unsigned int out_list_length);
UNIFEX_TERM test_list_of_strings_result_ok(UnifexEnv *env, char **out_strings,
                                           unsigned int out_strings_length);
UNIFEX_TERM test_list_of_uints_result_ok(UnifexEnv *env,
                                         unsigned int const *out_uints,
                                         unsigned int out_uints_length);
UNIFEX_TERM test_list_with_other_args_result_ok(UnifexEnv *env,
                                                int const *out_list,
                                                unsigned int out_list_length,
                                                char const *other_param);
UNIFEX_TERM test_payload_result_ok(UnifexEnv *env, UnifexPayload *out_payload);
UNIFEX_TERM test_pid_result_ok(UnifexEnv *env, UnifexPid out_pid);
UNIFEX_TERM test_example_message_result_ok(UnifexEnv *env);
UNIFEX_TERM test_example_message_result_error(UnifexEnv *env,
                                              char const *reason);
UNIFEX_TERM test_my_struct_result_ok(UnifexEnv *env, my_struct out_struct);
UNIFEX_TERM test_nested_struct_result_ok(UnifexEnv *env,
                                         nested_struct out_struct);
UNIFEX_TERM test_nested_struct_list_result_ok(UnifexEnv *env,
                                              nested_struct_list out_struct);
UNIFEX_TERM test_my_enum_result_ok(UnifexEnv *env, MyEnum out_enum);
UNIFEX_TERM test_uint64_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_int64_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM init_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_nil_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_atom_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_bool_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_float_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
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
UNIFEX_TERM test_my_struct_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_nested_struct_caller(UnifexEnv *env,
                                      UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_nested_struct_list_caller(UnifexEnv *env,
                                           UnifexCNodeInBuff *in_buff);
UNIFEX_TERM test_my_enum_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff);
int send_example_msg(UnifexEnv *env, UnifexPid pid, int flags, int num);
int handle_main(int argc, char **argv);

#ifdef __cplusplus
}
#endif
