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

#define EMPTY_UNIFEX_TERM NULL
#define UNIFEX_UNUSED(x) (void)(x)

struct UnifexStateWrapper;
typedef struct UnifexStateWrapper UnifexStateWrapper;

// initialized in generated files
size_t SIZEOF_UNIFEX_STATE;

struct state_node;
typedef struct state_node state_node;
struct state_node {
  UnifexStateWrapper *item;
  state_node *next;
};

typedef struct state_linked_list {
  state_node *head;
} state_linked_list;

typedef struct cnode_context {
  const char *node_name;
  int ei_fd;
  erlang_pid *e_pid;
  UnifexStateWrapper *wrapper;
  state_linked_list *released_states;
} cnode_context;

typedef cnode_context UnifexEnv;

void prepare_ei_x_buff(ei_x_buff *buff, const char *node_name,
                       const char *msg_type);
void prepare_result_buff(ei_x_buff *buff, const char *node_name);
void prepare_send_buff(ei_x_buff *buff);
void prepare_error_buff(ei_x_buff *buff, const char *node_name);
void send_and_free(cnode_context *ctx, ei_x_buff *out_buff);
void send_error(cnode_context *ctx, const char *msg);

void handle_destroy_state_wrapper(UnifexEnv *env, UnifexStateWrapper *state);

void add_item(state_linked_list *list, UnifexStateWrapper *item);
void rec_free_node(state_node *n);
void free_states(UnifexEnv *env, state_linked_list *list,
                 UnifexStateWrapper *main_state);
state_linked_list *new_state_linked_list();

int wrappers_cmp(UnifexStateWrapper *a, UnifexStateWrapper *b);

int handle_message(int ei_fd, const char *node_name, erlang_msg emsg,
                   ei_x_buff *in_buff, UnifexStateWrapper *state);

size_t unifex_state_wrapper_sizeof();
void free_state(UnifexStateWrapper *wrapper);

#ifdef __cplusplus
}
#endif
