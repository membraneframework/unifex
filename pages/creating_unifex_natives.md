# Creating Unifex Natives

## Introduction
In this section we present how to create Unifex Natives. 
We will show it by writing code that will be compiled both as NIF and CNode.

## Preparation

In order to start working, you need to prepare a few things:

1. First, you have to add unifex to your dependencies as well as unifex and bundlex compilers.
   Please refer to [Instalation](https://hexdocs.pm/unifex/readme.html#instalation) section to see how to do it. 
2. After successful installation we should take a look at [Bundlex](https://github.com/membraneframework/bundlex).
   Unifex uses Bundlex to compile the native code. 
   You can think of Bundlex as a tool that generates build scripts responsible for including proper libs,  
   compiling your native code and linking it with mentioned libs.
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
            deps: [unifex: :unifex],
            src_base: "example",
            sources: ["_generated/nif/example.c", "example.c"],
            interface: :nif
          ],
          example: [
           deps: [unifex: :unifex],
           src_base: "example",
           sources: ["_generated/cnode/example.c", "example.c"],
           interface: :cnode
          ] 
        ]
      end
    end
    ```
   This defines two natives, both are called `example` that will be implemented in two `.c` files. 
   The first one will be compiled as NIF and the second one as CNode. 
   In the future bundlex is intended to do it by specifying only one native like:
   ```elixir
      example: [
        deps: [unifex: :unifex],
        src_base: "example",
        sources: ["_generated/example.c", "example.c"],
        interface: [:nif, :cnode]
      ],
   ```
   but at this moment we have to do it in a little more descriptive way.
   Source files have to be located in `c_src/example` directory.
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

You may wonder where is the `_generated/nif/example.c` and `_generated/cnode/example.c`. 
Well, as the name suggests, it will be generated based on `example.spec.exs`!

Here are the contents of `example.spec.exs`:

```elixir
module Example

interface [NIF, CNode]

spec foo(num :: int) :: {:ok :: label, answer :: int}
```

Note that here we also specified an interface or even interfaces!
It is not necessary because if we didn't do it Unifex would take it from `bundlex.exs`.
However, this is a good practice that makes code clearer and is also a little faster than fetching info from `bundlex.exs.` 

More information on how `.spec.exs` files should be created can be found in docs for
`Unifex.Specs.DSL` module.
You can also check out our [test_projects](https://github.com/membraneframework/unifex/tree/master/test_projects)
to see a little more advanced examples or look how we use Unifex in a our repositories 
e.g. in [shmex](https://github.com/membraneframework).

Next step is to implement our `example.h`.
Since our example is very simple our `example.h` will be very simple too:
```c
#include "_generated/example.h"
```

It just includes generated header file that contains some function definitions we use in our `example.c`. 

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
Also check out how we use Unifex in our [repositories](https://github.com/membraneframework) e.g. in 
[shmex](https://github.com/membraneframework/shmex) and please refer to `Unifex.Specs.DSL` module's documentation 
to see how to create more advanced `*.spec.exs` files.
