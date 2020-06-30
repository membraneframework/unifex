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

typedef struct UnifexLinkedList {
  void *head;
  struct UnifexLinkedList *tail;
} UnifexLinkedList;

typedef struct UnifexCNodeContext {
  const char *node_name;
  int ei_fd;
  erlang_pid *e_pid;
  void *state;
  UnifexLinkedList *released_states;
} UnifexEnv;

#ifdef __cplusplus
}
#endif
