# Creating Unifex Nif

## Preparation

In order to start working on NIF, you need to prepare a few things:

1. Add [Unifex](https://github.com/membraneframework/unifex) to deps in `mix.exs`:
    ```elixir
    defp deps do
        [
          {:unifex, "~> 0.1"}
        ]
    end
    ```
2. And compilers to the project definition:
    ```elixir
    def project do
        [
          compilers: [:unifex, :bundlex] ++ Mix.compilers(),
          (..)
        ]
    end
    ```
3. Unifex uses [Bundlex](https://github.com/membraneframework/bundlex) to compile the native code.
   To make it work, create the `bundlex.exs` file in the project's root directory with the following content:
    ```elixir
    defmodule Example.BundlexProject do
      use Bundlex.Project

      def project() do
        [
          nifs: nifs(Bundlex.platform())
        ]
      end

      def nifs(_platform) do
        [
          example: [
            deps: [unifex: :unifex],
            src_base: "example",
            sources: ["_generated/example.c", "example.c"]
          ]
        ]
      end
    end
    ```
   This defines a nif called `example` that will be implemented in two `.c` files.
   [Bundlex](https://github.com/membraneframework/bundlex) expects these files to be located in `c_src/example` directory.
   More details on how to use it can be found in [its documentation](https://hexdocs.pm/bundlex).

## Native code

Let's start by creating a `c_src/example` directory and the files that will be needed:

```bash
mkdir -p c_src/example
cd c_src/example
touch example.c
touch example.h
touch example.spec.exs
```

You may wonder where is the `_generated/example.c`. Well, as the name suggests, it will be generated based on `example.spec.exs`!

Here are the contents of `example.spec.exs`:

```elixir
module Example.Native

spec init() :: {:ok :: label, state}

spec foo(target :: pid, state) :: {:ok :: label, answer :: int} | {:error :: label, reason :: atom}

sends {:example_msg :: label, num :: int}
```

This will result in generating the following header:

```c
#pragma once

#include <stdio.h>
#include <erl_nif.h>
#include <unifex/unifex.h>
#include <unifex/payload.h>
#include "../example.h"

/*
 * Declaration of native functions for module Elixir.Example.Native.
 * The implementation have to be provided by the user.
 */

UNIFEX_TERM init(UnifexEnv* env);
UNIFEX_TERM foo(UnifexEnv* env, UnifexNifState* state);

/*
 * Functions that manage lib and state lifecycle
 * Functions with 'unifex_' prefix are generated automatically,
 * the user have to implement rest of them.
 */

/**
 * Allocates the state struct. Have to be paired with 'unifex_release_state' call
 */
UnifexNifState* unifex_alloc_state(UnifexEnv* env);

/**
 * Releases state stuct allocated via 'unifex_alloc_state'.
 * State struct should be considered invalid after this call.
 */
void unifex_release_state(UnifexEnv* env, UnifexNifState* state);

/**
 * Callback called when the state struct is destroyed. It should
 * be responsible for releasing any resources kept inside state.
 */
void handle_destroy_state(UnifexEnv* env, UnifexNifState* state);

/*
 * Functions that create the defined output from Nif.
 * They are automatically generated and don't need to be implemented.
 */

UNIFEX_TERM init_result_ok(UnifexEnv* env, UnifexNifState* state);
UNIFEX_TERM foo_result_ok(UnifexEnv* env, int answer);
UNIFEX_TERM foo_result_error(UnifexEnv* env, char* reason);
/*
 * Functions that send the defined messages from Nif.
 * They are automatically generated and don't need to be implemented.
 */

int send_example_msg(UnifexEnv* env, UnifexPid pid, int flags, int num);
```

More information on how `.spec.exs` files should be created can be found in docs for
`Unifex.Specs` module.

Along with the header, `_generated/example.c` file will be created, providing definitions for some of the functions
you see in the header.

Next step is to create struct that will be used as state for created nif and include generated header inside `example.h`.
Since there is no name collision, `typdef` can be used to create an alias for `UnifexNifState` and refer to it as `State`.

```c
#pragma once

typedef struct MyState UnifexNifState;

struct MyState {
  int a;
};

typedef UnifexNifState State;

#include "_generated/example.h"
```

Finally, let's provide required implementations in `example.c`:

```c
#include "example.h"

UNIFEX_TERM init(UnifexEnv* env) {
  State * state = unifex_alloc_state(env);
  state->a = 42;
  UNIFEX_TERM res = init_result_ok(env, state);
  unifex_release_state(env, state);
  return res;
}

UNIFEX_TERM foo(UnifexEnv* env, UnifexPid pid, State* state) {
  int res = send_example_msg(env, pid, 0, state->a);
  if (!res) {
    return foo_result_error(env, "send_failed");
  }
  return foo_result_ok(env, state->a);
}

void handle_destroy_state(UnifexEnv* env, State* state) {
  UNIFEX_UNUSED(env);
  state->a = 0;
}
```

Now the project should sucessfully compile. Run `mix deps.get && mix compile` to make sure everything is fine.

## Elixir module

All you have to do in order to access natively implemented functions is to create a module with the name as defined in `example.spec.exs` and to use `Unifex.Loader` there:

```elixir
defmodule Example.Native do
  use Unifex.Loader
end
```

And that's it! You can now run `iex -S mix` and check it out yourself:

```elixir
iex(1)> alias Example.Native
iex(2)> {:ok, state} = Native.init()
{:ok, #Reference<0.3961161465.633208834.69562>}
iex(3)> Native.foo(self(), state)
{:ok, 42}
iex(4)> flush()
{:example_msg, 42}
:ok
```
