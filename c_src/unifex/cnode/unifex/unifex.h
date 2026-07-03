#pragma once

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

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

// Flags for send operations
#define UNIFEX_NO_FLAGS 0
#define UNIFEX_SEND_THREADED 1
#define UNIFEX_FROM_CREATED_THREAD UNIFEX_SEND_THREADED

typedef struct UnifexLinkedList {
  void *head;
  struct UnifexLinkedList *tail;
} UnifexLinkedList;

typedef struct UnifexCNodeContext {
  char *node_name;
  ei_cnode ec;
  int ei_socket_fd;
  int listen_fd;
  UnifexPid *reply_to;
  void *state;
  UnifexLinkedList *released_states;
  UNIFEX_TERM error;
  // Guards every ei_send/ei_reg_send on ei_socket_fd, since the logger's
  // worker thread can write to the socket concurrently with the main thread.
  pthread_mutex_t socket_mutex;
} UnifexEnv;

// Function declarations for send operations
int unifex_send(UnifexEnv *env, UnifexPid *pid, UNIFEX_TERM term, int flags);

static inline void *unifex_alloc(size_t size) { return malloc(size); }

static inline void unifex_free(void *pointer) { free(pointer); }

// Env
static inline UnifexEnv *unifex_alloc_env(UnifexEnv *env) { return env; }
static inline void unifex_clear_env(UnifexEnv *_env) { UNIFEX_UNUSED(_env); }
static inline void unifex_free_env(UnifexEnv *_env) { UNIFEX_UNUSED(_env); }

// Threads
typedef pthread_t UnifexTid;
static inline int unifex_thread_create(char *name, UnifexTid *tid, void *(*func)(void *), void *args) {
  UNIFEX_UNUSED(name);
  return pthread_create(tid, NULL, func, args);
}
static inline void unifex_thread_exit(void *exit_val) {
  pthread_exit(exit_val);
}
static inline int unifex_thread_join(UnifexTid tid, void **exit_val) {
  return pthread_join(tid, exit_val);
}

// pid
static inline UnifexPid *unifex_self(UnifexEnv *env, UnifexPid *pid) {
  return (UnifexPid *) memcpy(pid, env->reply_to, sizeof(UnifexPid));
};

UNIFEX_TERM unifex_raise(UnifexEnv *env, const char *message);

#ifdef __cplusplus
}
#endif
