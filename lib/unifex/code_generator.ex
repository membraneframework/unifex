defmodule Unifex.CodeGenerator do
  alias Unifex.InterfaceIO
  alias __MODULE__.BaseType

  defmacro __using__(_args) do
    quote do
      import unquote(__MODULE__), only: [sigil_g: 2, sigil_g: 3]
    end
  end

  def generate_code(name, specs) do
    module = specs |> Keyword.fetch!(:module)
    fun_specs = specs |> Keyword.get_values(:fun_specs)

    {functions, results} =
      fun_specs
      |> Enum.map(fn {name, args, results} -> {{name, args}, {name, results}} end)
      |> Enum.unzip()

    results = results |> Enum.flat_map(fn {name, specs} -> specs |> Enum.map(&{name, &1}) end)
    header = generate_header(name, functions, results)
    source = generate_source(name, module, functions, results)

    {header, source}
  end

  defp generate_header(name, functions, results) do
    ~g"""
    #pragma once

    #include <stdio.h>
    #include <erl_nif.h>
    #include <unifex/util.h>
    #include "#{InterfaceIO.user_header_path(name)}"

    #{functions |> Enum.map(&generate_implemented_function_header/1)}
    #{generate_lib_lifecycle_and_state_related_headers()}
    #{generate_result_functions_headers(results)}
    """
  end

  defp generate_source(name, module, functions, results) do
    ~g"""
    #include "#{name}.h"

    #{generate_result_functions(results)}
    #{generate_lib_lifecycle_and_state_related_stuff()}
    #{functions |> Enum.map(&generate_export_function/1)}
    #{generate_erlang_boilerplate(module, functions)}
    """
  end

  defp generate_implemented_function_header({name, args}) do
    args_declarations =
      [~g<UnifexEnv* env> | args |> Enum.map(&BaseType.generate_declaration/1)]
      |> Enum.join(", ")

    ~g<UNIFEX_TERM #{name}(#{args_declarations});>
  end

  defp generate_result_functions(results) do
    results
    |> Enum.map(&generate_result_function/1)
    |> Enum.join("\n")
  end

  defp generate_result_functions_headers(results) do
    results
    |> Enum.map(&generate_result_function_header/1)
    |> Enum.map(&(&1 <> ";"))
    |> Enum.join("\n")
  end

  defp generate_result_function({name, specs}) do
    ~g"""
    #{generate_result_function_header({name, specs})} {
      return #{generate_result_spec_traverse_helper(specs).return |> ~g<>it};
    }
    """
  end

  defp generate_result_function_header({name, specs}) do
    %{labels: labels, args: args} = generate_result_spec_traverse_helper(specs)

    args_declarations =
      [~g<UnifexEnv* env> | args |> Enum.map(&BaseType.generate_declaration/1)]
      |> Enum.join(", ")

    ~g<ERL_NIF_TERM #{[name, :result | labels] |> Enum.join("_")}(#{args_declarations})>
  end

  defp generate_result_spec_traverse_helper(node) do
    case node do
      atom when is_atom(atom) ->
        %{return: generate_const_atom_maker(atom), args: [], labels: []}

      {:::, _, [name, {:label, _, _}]} when is_atom(name) ->
        %{return: generate_const_atom_maker(name), args: [], labels: [name]}

      {:::, _, [{name, _, _}, {type, _, _}]} ->
        %{return: BaseType.generate_term_maker({name, type}), args: [{name, type}], labels: []}

      {a, b} ->
        generate_result_spec_traverse_helper({:{}, [], [a, b]})

      {:{}, _, content} ->
        results =
          content
          |> Enum.map(&generate_result_spec_traverse_helper/1)

        %{
          return: generate_tuple_maker(results |> Enum.map(& &1.return)),
          args: results |> Enum.flat_map(& &1.args),
          labels: results |> Enum.flat_map(& &1.labels)
        }

      {name, _, _} ->
        generate_result_spec_traverse_helper({:::, [], [{name, [], nil}, {name, [], nil}]})
    end
  end

  defp generate_tuple_maker(content) do
    ~g"""
    enif_make_tuple_from_array(
      env->nif_env,
      (ERL_NIF_TERM []) {
        #{content |> Enum.join(",\n") |> ~g<>iit}
      },
      #{length(content)}
    )
    """
  end

  defp generate_const_atom_maker(name) do
    ~g<enif_make_atom(env-\>nif_env, "#{name}")>
  end

  defp generate_lib_lifecycle_and_state_related_headers() do
    ~g"""
    State* unifex_alloc_state(UnifexEnv* env);
    void handle_destroy_state(UnifexEnv* env, State* state);
    """
  end

  defp generate_lib_lifecycle_and_state_related_stuff() do
    ~g"""
    ErlNifResourceType *STATE_RESOURCE_TYPE;

    State* unifex_alloc_state(UnifexEnv* env) {
      UNIFEX_UTIL_UNUSED(env);
      return enif_alloc_resource(STATE_RESOURCE_TYPE, sizeof(State));
    }

    static void destroy_state(ErlNifEnv* env, void* value) {
      State *state = (State*) value;
      #{generate_unifex_env()}
      handle_destroy_state(&unifex_env, state);
    }

    static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
      UNIFEX_UTIL_UNUSED(load_info);
      UNIFEX_UTIL_UNUSED(priv_data);

      int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
      STATE_RESOURCE_TYPE =
       enif_open_resource_type(env, NULL, "State", destroy_state, flags, NULL);
      return 0;
    }
    """
  end

  defp generate_export_function({name, args}) do
    ~g"""
    static ERL_NIF_TERM export_#{name}(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]){
      UNIFEX_UTIL_UNUSED(argc);
      #{if args |> Enum.empty?(), do: ~g<UNIFEX_UTIL_UNUSED(argv);>, else: ""}
      #{generate_unifex_env()}
      #{
      args |> Enum.with_index() |> Enum.map(&BaseType.generate_arg_parse/1) |> Enum.join("\n\t")
    }
      return #{name}(#{[:"&unifex_env" | args |> Keyword.keys()] |> Enum.join(", ")});
    }
    """
  end

  defp generate_erlang_boilerplate(module, functions) do
    ~g"""
    static ErlNifFunc nif_funcs[] =
    {
      #{
      functions
      |> Enum.map(fn {name, args} -> ~g<{"#{name}", #{length(args)}, export_#{name}, 0}> end)
      |> Enum.join(",\n\t")
    }
    };

    ERL_NIF_INIT(#{module}.Nif, nif_funcs, load, NULL, NULL, NULL)
    """
  end

  defp generate_unifex_env() do
    ~g<UnifexEnv unifex_env = {.nif_env = env};>
  end

  def sigil_g(content, "", flags) do
    sigil_g(content, flags)
  end

  def sigil_g(content, 't' ++ flags) do
    content = content |> String.trim()
    sigil_g(content, flags)
  end

  def sigil_g(content, 'i' ++ flags) do
    [first | rest] = content |> String.split("\n")
    content = [first | rest |> Enum.map(&"  #{&1}")] |> Enum.join("\n")
    sigil_g(content, flags)
  end

  def sigil_g(content, []) do
    content
  end
end
