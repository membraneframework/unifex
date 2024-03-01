#pragma once

#include "../../example.h"
#include <erl_nif.h>
#include <stdint.h>
#include <stdio.h>
#include <unifex/payload.h>
#include <unifex/unifex.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Functions that manage lib and state lifecycle
 * Functions with 'unifex_' prefix are generated automatically,
 * the user have to implement rest of them.
 */

/*
 * Declaration of native functions for module Elixir.Example.
 * The implementation have to be provided by the user.
 */

UNIFEX_TERM foo(UnifexEnv *env, int num);

/*
 * Callbacks for nif lifecycle hooks.
 * Have to be implemented by user.
 */

/*
 * Functions that create the defined output from Nif.
 * They are automatically generated and don't need to be implemented.
 */
UNIFEX_TERM foo_result_ok(UnifexEnv *env, int answer);

/*
 * Bugged version of functions returning nil, left for backwards compabiliy with
 * older code using unifex Generating of these functions should be removed in
 * unifex v2.0.0 For more information check:
 * https://github.com/membraneframework/membrane_core/issues/758
 */

/*
 * Functions that send the defined messages from Nif.
 * They are automatically generated and don't need to be implemented.
 */

#ifdef __cplusplus
}
#endif
