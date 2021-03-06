# Creating Unifex Natives

## Introduction
In this tutorial, you will learn how to use Unifex natives to write native code that can be compiled both as NIF and CNode.

## Preparation

In order to start working, you need to prepare a few things:

1. First, you have to add unifex to your dependencies as well as unifex and bundlex compilers.
   Please refer to [Instalation](https://hexdocs.pm/unifex/readme.html#instalation) section to see how to do it. 
2. After successful installation we should take a look at [Bundlex](https://github.com/membraneframework/bundlex).
   Unifex uses Bundlex to compile the native code. 
   You can think of Bundlex as a tool that generates build scripts responsible for including proper libs compiling your native code and linking it with mentioned libs.
   To make it work, create the `bundlex.exs` file in the project's root directory with the following content:
    ```elixir
    defmodule Example.BundlexProject do
      use Bundlex.Project

      def project() do
        [
          natives: natives(Bundlex.platform())
        ]
      end

      def natives(_platform) do
        [
          example: [
            sources: ["example.c"],
            interface: [:nif, :cnode],
            preprocessor: Unifex
          ]
        ]
      end
    end
    ```
   This defines a native called `example`, that should be implemented in the `example.c` file. We'll also need `example.spec.exs` file, that Unifex needs to generate boilerplate code for compiling the native as NIF and CNode. Both files should be located in the `c_src/example` folder. Setting `Unifex` as a preprocessor lets it extend the configuration with the generated code.
   More details on how to use bundlex can be found in its [documentation](https://hexdocs.pm/bundlex).

## Native code

Let's start by creating a `c_src/example` directory, and the files that will be needed:

```bash
mkdir -p c_src/example
cd c_src/example
touch example.c
touch example.h
touch example.spec.exs
```

Here are the contents of `example.spec.exs`:

```elixir
module Example

interface [NIF, CNode]

spec foo(num :: int) :: {:ok :: label, answer :: int}
```

Note that here we also specified an interface or even interfaces!
It is not necessary because if we didn't do it Unifex would take it from `bundlex.exs`.
However, this is a good practice that makes code clearer and is also a little faster than fetching info from `bundlex.exs.` 

Next step is to implement our `example.h`.
Since our example is very simple our `example.h` will be very simple too:
```c
#include "_generated/example.h"
```

It just includes generated header file that contains some function definitions we use in our `example.c`. The header will be generated by Unifex based on the `example.spec.exs` file.

Now, let's provide required implementation in `example.c`:

```c
#include "example.h"

UNIFEX_TERM foo(UnifexEnv* env, int num) {
  return foo_result_ok(env, num);
}
```
It is a very simple C code that always returns the same number it gets.

At this moment the project should successfully compile. 
Run `mix deps.get && mix compile` to make sure everything is fine.
In `c_src/_generated/` directory there should appear files both for usage as NIF and CNode.

## Running code

### NIF

All you have to do in order to access natively implemented functions is to create a module with the name as defined 
in `example.spec.exs` and to use `Unifex.Loader` there:

```elixir
defmodule Example do
  use Unifex.Loader
end
```

And that's it! You can now run `iex -S mix` and check it out yourself:

```elixir
iex(1)> Example.foo(10)
{:ok, 10}
```

### CNode
In case of `CNodes`, module with `Unifex.Loader` is unnecessary. We would just do:
```elixir
iex(2)> require Unifex.CNode
Unifex.CNode
iex(3)> {:ok, cnode} = Unifex.CNode.start_link(:example)
{:ok,
 %Unifex.CNode{
   bundlex_cnode: %Bundlex.CNode{
     node: :"bundlex_cnode_0_4eb957f2-fd47-47c2-b816-6e9c580e658a@michal",
     server: #PID<0.259.0>
   },
   node: :"bundlex_cnode_0_4eb957f2-fd47-47c2-b816-6e9c580e658a@michal",
   server: #PID<0.259.0>
 }}
iex(bundlex_app_4eb957f2-...)4> Unifex.CNode.call(cnode, :foo, [10])
{:ok, 10}
```

## More examples
You can find more complete projects [here](https://github.com/membraneframework/unifex/tree/master/test_projects).
Also check out how we use Unifex in our [repositories](https://github.com/membraneframework) 
and please refer to `Unifex.Specs.DSL` module's documentation to see how to create more advanced `*.spec.exs` files.
