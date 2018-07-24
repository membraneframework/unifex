defmodule Unifex.CodeGenerator do
  def generate_code(name, specs) do
    module = specs |> Keyword.fetch!(:module)
    functions = specs |> Keyword.get(:functions, [])

    {generate_header(name), generate_source(name, module, functions)}
  end

  defp generate_header(name) do
    ~g"""
    #pragma once

    #include <stdio.h>
    #include <erl_nif.h>
    #include <unifex/util.h>
    #include "#{name}.h"

    ErlNifResourceType *STATE_RESOURCE_TYPE;
    """
  end

  defp generate_source(name, module, functions) do
    ~g"""
    #include "#{name}_interface.h"

    #{generate_lib_loaders()}
    #{functions |> Enum.map(&generate_export_function/1)}
    #{generate_erlang_boilerplate(module, functions)}
    """
  end

  defp generate_lib_loaders() do
    ~g"""
    static void destroy_state(ErlNifEnv* env, void* value) {
      State *state = (State*) value;
      handle_destroy_state(env, state);
    }

    int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
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
      #{args |> Enum.with_index() |> Enum.map(&generate_arg_parse/1) |> Enum.join("\n\t")}
      return #{name}(#{[:env | args |> Keyword.keys()] |> Enum.join(", ")});
    }
    """
  end

  defp generate_arg_parse({{name, :buffer}, i}) do
    ~g<UNIFEX_UTIL_PARSE_BINARY_ARG(#{i}, #{name})>
  end

  defp generate_arg_parse({{name, :state}, i}) do
    ~g<UNIFEX_UTIL_PARSE_RESOURCE_ARG(#{i}, #{name}, State, STATE_RESOURCE_TYPE)>
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

  defp sigil_g(content, _) do
    content
  end
end
