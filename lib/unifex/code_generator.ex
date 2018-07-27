defmodule Unifex.CodeGenerator do
  def generate_code(name, specs) do
    module = specs |> Keyword.fetch!(:module)
    functions = specs |> Keyword.get(:functions, [])
    results = specs |> Keyword.get(:results, [])

    result_functions = create_result_functions(results)

    header = generate_header(name, result_functions)
    source = generate_source(name, module, functions, result_functions)

    {header, source}
  end

  def create_result_functions(results, names \\ []) do
    results
    |> Enum.flat_map(fn {name, keyword} when is_atom(name) and is_list(keyword) ->
      values = keyword |> Keyword.values()

      cond do
        values |> Enum.all?(&is_atom/1) ->
          [{[name | names] |> Enum.reverse(), keyword}]

        values |> Enum.all?(&is_list/1) ->
          create_result_functions(keyword, [name | names])
      end
    end)
  end

  defp generate_header(name, result_functions) do
    ~g"""
    #pragma once

    #include <stdio.h>
    #include <erl_nif.h>
    #include <unifex/util.h>
    #include "#{name}.h"

    ErlNifResourceType *STATE_RESOURCE_TYPE;

    #{
      result_functions
      |> Enum.map(&generate_result_function_header/1)
      |> Enum.map(&(&1 <> ";"))
      |> Enum.join("\n")
    }
    """
  end

  defp generate_source(name, module, functions, result_functions) do
    ~g"""
    #include "#{name}_interface.h"

    #{result_functions |> Enum.map(&generate_result_function/1) |> Enum.join("\n")}
    #{generate_lib_loaders()}
    #{functions |> Enum.map(&generate_export_function/1)}
    #{generate_erlang_boilerplate(module, functions)}
    """
  end

  defp generate_result_function({names, args}) do
    result_payload =
      case args do
        [] ->
          []

        [arg] ->
          [generate_term_maker(arg)]

        args ->
          [
            ~g"""
            enif_make_tuple_from_array(
              env,
              (ERL_NIF_TERM []) {
                #{args |> Enum.map(&generate_term_maker/1) |> Enum.join(",\n\t\t")}
              },
              #{length(args)}
            )
            """it
          ]
      end

    return_value =
      names
      |> tl()
      |> Enum.map(fn name -> ~g<enif_make_atom(env, "#{name}")> end)
      |> Kernel.++(result_payload)
      |> Enum.reverse()
      |> Enum.reduce(fn atom_term, inner_term ->
        ~g"""
        enif_make_tuple2(
          env,
          #{atom_term},
          #{inner_term}
        )
        """it
      end)

    ~g"""
    #{generate_result_function_header({names, args})} {
      return #{return_value};
    }
    """
  end

  defp generate_result_function_header({names, args}) do
    args_declarations =
      [~g<ErlNifEnv* env> | args |> Enum.map(&generate_declaration/1)]
      |> Enum.join(", ")

    ~g<ERL_NIF_TERM #{names |> Enum.join("_")}_result(#{args_declarations})>
  end

  defp generate_term_maker({name, :state}) do
    ~g<unifex_util_make_and_release_resource(env, #{name})>
  end

  defp generate_term_maker({name, :buffer}) do
    ~g<#{name}>
  end

  defp generate_term_maker({name, type}) do
    ~g<enif_make_#{type}(env, #{name})>
  end

  defp generate_declaration({name, :state}) do
    ~g<State* #{name}>
  end

  defp generate_declaration({name, :buffer}) do
    ~g<ERL_NIF_TERM #{name}>
  end

  defp generate_declaration({name, type}) do
    ~g<#{type} #{name}>
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

  defp sigil_g(content, 't' ++ flags) do
    content = content |> String.trim()
    sigil_g(content, flags)
  end

  defp sigil_g(content, 'i' ++ flags) do
    [first | rest] = content |> String.split("\n")
    content = [first | rest |> Enum.map(&"  #{&1}")] |> Enum.join("\n")
    sigil_g(content, flags)
  end

  defp sigil_g(content, []) do
    content
  end

  # defp tabs_to_spaces(string) do
  #   {a, _} = string
  #   |> String.split("\n")
  #   |> Enum.map_reduce("", fn current, prev ->
  #     current =
  #       case current |> String.trim_leading(" ") do
  #         "\t" <> trimmed ->
  #           indent = String.length(prev) - String.length(prev |> String.trim_leading(" "))
  #           trimmed |> String.pad_leading(indent, [" "])
  #         _ ->
  #           current
  #       end
  #     {current, current}
  #   end)
  #   a |> Enum.join("\n")
  # end
end
