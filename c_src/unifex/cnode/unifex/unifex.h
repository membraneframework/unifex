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

#ifdef __cplusplus
extern "C" {
#endif

typedef ei_x_buff *UNIFEX_TERM;

typedef erlang_pid UnifexPid;

#define UNIFEX_MAYBE_UNUSED(x) UNIFEX_UNUSED(x)

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

static inline void *unifex_alloc(size_t size) { return malloc(size); }

static inline void unifex_free(void *pointer) { free(pointer); }

static inline UnifexEnv *unifex_alloc_env(UnifexEnv *env) { return env; }

static inline void unifex_clear_env(UnifexEnv *_env) { UNIFEX_UNUSED(_env); }

static inline void unifex_free_env(UnifexEnv *_env) { UNIFEX_UNUSED(_env); }

static inline UnifexPid *unifex_self(UnifexEnv *env, UnifexPid *pid) {
  return (UnifexPid *) memcpy(pid, env->reply_to, sizeof(UnifexPid));
};

UNIFEX_TERM unifex_raise(UnifexEnv *env, const char *message);

#ifdef __cplusplus
}
#endif
