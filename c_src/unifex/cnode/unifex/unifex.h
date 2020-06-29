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

#ifdef __cplusplus
extern "C" {
#endif

typedef ei_x_buff *UNIFEX_TERM;

typedef erlang_pid UnifexPid;

#define UNIFEX_UNUSED(x) (void)(x)

typedef struct UnifexStateNode {
  void *state;
  struct UnifexStateNode *next;
} UnifexStateNode;

typedef struct UnifexCNodeContext {
  const char *node_name;
  int ei_fd;
  erlang_pid *e_pid;
  void *state;
  UnifexStateNode *released_states;
} UnifexEnv;

void prepare_ei_x_buff(UnifexEnv *env, ei_x_buff *buff, const char *msg_type);
void send_and_free(UnifexEnv *env, erlang_pid *pid, ei_x_buff *out_buff);
void send_to_server_and_free(UnifexEnv *env, ei_x_buff *out_buff);
void sending_error(UnifexEnv *env, const char *msg);

void unifex_destroy_state(UnifexEnv *env, void *state);

void add_item(UnifexEnv *env, void *state);
void free_states(UnifexEnv *env);

void handle_message(UnifexEnv *env, char *fun_name, int *index,
                    ei_x_buff *in_buff);

int main_function(int argc, char **argv);

#ifdef __cplusplus
}
#endif
