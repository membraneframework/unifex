#pragma once

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// required for erl_interface.h to work
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

typedef struct UnifexLinkedList {
  void *head;
  struct UnifexLinkedList *tail;
} UnifexLinkedList;

typedef struct UnifexCNodeContext {
  char *node_name;
  int ei_socket_fd;
  int listen_fd;
  UnifexPid *reply_to;
  void *state;
  UnifexLinkedList *released_states;
  UNIFEX_TERM error;
} UnifexEnv;

void *unifex_alloc(size_t size);
void unifex_free(void *pointer);
UNIFEX_TERM unifex_raise(UnifexEnv *env, const char *message);

#ifdef __cplusplus
}
#endif
