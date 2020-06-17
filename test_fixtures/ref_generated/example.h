#pragma once

#include "../example.h"
#include <erl_nif.h>
#include <stdint.h>
#include <stdio.h>
#include <unifex/payload.h>
#include <unifex/unifex.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Declaration of native functions for module Elixir.Example.
 * The implementation have to be provided by the user.
 */

UNIFEX_TERM init(UnifexEnv *env);
UNIFEX_TERM foo(UnifexEnv *env, UnifexPid target, UnifexState *state);

/*
 * Functions that manage lib and state lifecycle
 * Functions with 'unifex_' prefix are generated automatically,
 * the user have to implement rest of them.
 * Available only and only if in ../example.h
 * exisis definition of UnifexNigState
 */

#define UNIFEX_MODULE "Elixir.Example"

/**
 * Allocates the state struct. Have to be paired with 'unifex_release_state'
 * call
 */
UnifexState *unifex_alloc_state(UnifexEnv *env);

/**
 * Removes a reference to the state object.
 * The state is destructed when the last reference is removed.
 * Each call to 'unifex_release_state' must correspond to a previous
 * call to 'unifex_alloc_state' or 'unifex_keep_state'.
 */
void unifex_release_state(UnifexEnv *env, UnifexState *state);

/**
 * Increases reference count of state object.
 * Each call has to be balanced by 'unifex_release_state' call
 */
void unifex_keep_state(UnifexEnv *env, UnifexState *state);

/**
 * Callback called when the state struct is destroyed. It should
 * be responsible for releasing any resources kept inside state.
 */
void handle_destroy_state(UnifexEnv *env, UnifexState *state);

/*
 * Callbacks for nif lifecycle hooks.
 * Have to be implemented by user.
 */

int handle_load(UnifexEnv *env, void **priv_data);

/*
 * Functions that create the defined output from Nif.
 * They are automatically generated and don't need to be implemented.
 */

UNIFEX_TERM init_result_ok(UnifexEnv *env, int was_handle_load_called,
                           UnifexState *state);
UNIFEX_TERM foo_result_ok(UnifexEnv *env, int answer);
UNIFEX_TERM foo_result_error(UnifexEnv *env, const char *reason);

/*
 * Functions that send the defined messages from Nif.
 * They are automatically generated and don't need to be implemented.
 */

int send_example_msg(UnifexEnv *env, UnifexPid pid, int flags, int num);

#ifdef __cplusplus
}
#endif
