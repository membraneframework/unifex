defmodule Unifex.NativeCodeGenerator do
  @moduledoc """
  Module responsible for C code genearation based on Unifex specs
  """
  alias Unifex.{BaseType, InterfaceIO}
  use Bunch

  defmacro __using__(_args) do
    quote do
      import unquote(__MODULE__), only: [sigil_g: 2]
    end
  end

  @type code_t() :: String.t()

  @doc """
  Generates C boilerplate for a native code based on a spec

  Takes the name for the `.c` and `.h` files and the specs
  parsed by `Unifex.SpecsParser.parse_specs()/1` and generates code of header
  and source code, returning them in a tuple of 2 strings.
  """
  @spec generate_code(name :: String.t(), specs :: Unifex.SpecsParser.parsed_specs_t()) ::
          {code_t(), code_t()}
  def generate_code(name, specs) do
    module = specs |> Keyword.get(:module)
    fun_specs = specs |> Keyword.get_values(:fun_specs)
    sends = specs |> Keyword.get_values(:sends)

    {functions, results} =
      fun_specs
      |> Enum.map(fn {name, args, results} -> {{name, args}, {name, results}} end)
      |> Enum.unzip()

    results = results |> Enum.flat_map(fn {name, specs} -> specs |> Enum.map(&{name, &1}) end)
    header = generate_header(name, module, functions, results, sends)
    source = generate_source(name, module, functions, results, sends)

    {header, source}
  end

  @doc """
  Sigil used for indentation of generated code.

  By itself it does nothing, but has very useful flags:
  * `t` trims the string
  * `i` indents all but the first line. Helpful when used
    inside string interpolation that already has been indented
  * `I` indents every line of string
  """
  @spec sigil_g(String.t(), charlist()) :: String.t()
  def sigil_g(content, 'j(' ++ flags) when is_list(content) do
    {joiner, ')' ++ flags} = flags |> Enum.split_while(&([&1] != ')'))
    content = content |> Enum.join("#{joiner}")
    sigil_g(content, flags)
  end

  def sigil_g(content, 'n' ++ flags) when is_list(content) do
    sigil_g(content, 'j(\n)' ++ flags)
  end

  def sigil_g(content, flags) when is_list(content) do
    content |> Enum.map(&sigil_g(&1, flags))
  end

  def sigil_g(content, 'r' ++ flags) do
    content =
      content
      |> String.split("\n")
      |> Enum.map(&String.trim_trailing/1)
      |> Enum.reduce([], fn
        "", ["" | _] = acc -> acc
        v, acc -> [v | acc]
      end)
      |> Enum.reverse()
      |> Enum.join("\n")

    sigil_g(content, flags)
  end

  def sigil_g(content, 't' ++ flags) do
    content = content |> String.trim()
    sigil_g(content, flags)
  end

  def sigil_g(content, 'i' ++ flags) do
    [first | rest] = content |> String.split("\n")
    content = [first | rest |> Enum.map(&indent/1)] |> Enum.join("\n")
    sigil_g(content, flags)
  end

  def sigil_g(content, 'I' ++ flags) do
    lines = content |> String.split("\n")
    content = lines |> Enum.map(&indent/1) |> Enum.join("\n")
    sigil_g(content, flags)
  end

  def sigil_g(content, []) do
    content
  end

  defp indent(line) do
    "  #{line}"
  end

  defp generate_header(name, module, functions, results, sends) do
    ~g"""
    #pragma once

    #include <stdio.h>
    #include <erl_nif.h>
    #include <unifex/unifex.h>
    #include "#{InterfaceIO.user_header_path(name)}"

    #{generate_functions_declarations(functions, &generate_implemented_function_declaration/1)}
    #{generate_lib_lifecycle_and_state_related_declarations(module)}
    #{generate_functions_declarations(results, &generate_result_function_declaration/1)}
    #{generate_functions_declarations(sends, &generate_send_function_declaration/1)}
    """r
  end

  defp generate_source(name, module, functions, results, sends) do
    ~g"""
    #include "#{name}.h"

    #{generate_functions(results, &generate_result_function/1)}
    #{generate_functions(sends, &generate_send_function/1)}
    #{generate_lib_lifecycle_and_state_related_stuff(module)}
    #{generate_functions(functions, &generate_export_function/1)}
    #{generate_erlang_boilerplate(module, functions)}
    """r
  end

  defp generate_implemented_function_declaration({name, args}) do
    args_declarations =
      [~g<UnifexEnv* env> | args |> Enum.flat_map(&BaseType.generate_declaration/1)]
      |> Enum.join(", ")

    ~g<UNIFEX_TERM #{name}(#{args_declarations})>
  end

  defp generate_functions(results, generator) do
    results
    |> Enum.map(generator)
    |> Enum.join("\n")
  end

  defp generate_functions_declarations(results, generator) do
    results
    |> Enum.map(generator)
    |> Enum.map(&(&1 <> ";"))
    |> Enum.join("\n")
  end

  defp generate_result_function({name, specs}) do
    declaration = generate_result_function_declaration({name, specs})
    {result, _meta} = generate_function_spec_traverse_helper(specs)

    ~g"""
    #{declaration} {
      return #{result |> sigil_g('it')};
    }
    """
  end

  defp generate_result_function_declaration({name, specs}) do
    {_result, meta} = generate_function_spec_traverse_helper(specs)
    args = meta |> Keyword.get_values(:arg)
    labels = meta |> Keyword.get_values(:label)

    args_declarations =
      [~g<UnifexEnv* env> | args |> Enum.flat_map(&BaseType.generate_declaration/1)]
      |> Enum.join(", ")

    ~g<UNIFEX_TERM #{[name, :result | labels] |> Enum.join("_")}(#{args_declarations})>
  end

  defp generate_send_function(specs) do
    declaration = generate_send_function_declaration(specs)
    {result, _meta} = generate_function_spec_traverse_helper(specs)

    ~g"""
    #{declaration} {
      ERL_NIF_TERM term = #{result |> sigil_g('it')};
      return enif_send(env, &pid, NULL, term);
    }
    """
  end

  defp generate_send_function_declaration(specs) do
    {_result, meta} = generate_function_spec_traverse_helper(specs)
    args = meta |> Keyword.get_values(:arg)
    labels = meta |> Keyword.get_values(:label)

    args_declarations =
      [
        ~g<UnifexEnv* env>,
        ~g<UnifexPid pid> | args |> Enum.flat_map(&BaseType.generate_declaration/1)
      ]
      |> Enum.join(", ")

    ~g<int #{[:send | labels] |> Enum.join("_")}(#{args_declarations})>
  end

  defp generate_function_spec_traverse_helper(node) do
    node
    |> case do
      atom when is_atom(atom) ->
        {generate_const_atom_maker(atom), []}

      {:::, _, [name, {:label, _, _}]} when is_atom(name) ->
        {generate_const_atom_maker(name), label: name}

      {:::, _, [{name, _, _}, {type, _, _}]} ->
        {BaseType.generate_arg_serialize({name, type}), arg: {name, type}}

      {:::, meta, [name_var, [{type, type_meta, type_ctx}]]} ->
        generate_function_spec_traverse_helper(
          {:::, meta, [name_var, {{:list, type}, type_meta, type_ctx}]}
        )

      {a, b} ->
        generate_function_spec_traverse_helper({:{}, [], [a, b]})

      {:{}, _, content} ->
        {results, meta} =
          content
          |> Enum.map(&generate_function_spec_traverse_helper/1)
          |> Enum.unzip()

        {generate_tuple_maker(results), meta}

      [{_name, _, _} = name_var] ->
        generate_function_spec_traverse_helper({:::, [], [name_var, [name_var]]})

      {_name, _, _} = name_var ->
        generate_function_spec_traverse_helper({:::, [], [name_var, name_var]})
    end
    ~> ({result, meta} -> {result, meta |> List.flatten()})
  end

  defp generate_tuple_maker(content) do
    ~g"""
    enif_make_tuple_from_array(
      env,
      (ERL_NIF_TERM []) {
        #{content |> sigil_g('j(,\n)iit')}
      },
      #{length(content)}
    )
    """
  end

  defp generate_const_atom_maker(name) do
    ~g<enif_make_atom(env, "#{name}")>
  end

  defp generate_lib_lifecycle_and_state_related_declarations(nil) do
    ~g<>
  end

  defp generate_lib_lifecycle_and_state_related_declarations(_module) do
    ~g"""
    State* unifex_alloc_state(UnifexEnv* env);
    void handle_destroy_state(UnifexEnv* env, State* state);
    """
  end

  defp generate_lib_lifecycle_and_state_related_stuff(nil) do
    ~g<>
  end

  defp generate_lib_lifecycle_and_state_related_stuff(_module) do
    ~g"""
    ErlNifResourceType *STATE_RESOURCE_TYPE;

    State* unifex_alloc_state(UnifexEnv* env) {
      UNIFEX_UNUSED(env);
      return enif_alloc_resource(STATE_RESOURCE_TYPE, sizeof(State));
    }

    static void destroy_state(ErlNifEnv* env, void* value) {
      State *state = (State*) value;
      #{generate_unifex_env()}
      handle_destroy_state(unifex_env, state);
    }

    static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
      UNIFEX_UNUSED(load_info);
      UNIFEX_UNUSED(priv_data);

      int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
      STATE_RESOURCE_TYPE =
       enif_open_resource_type(env, NULL, "State", destroy_state, flags, NULL);
      return 0;
    }
    """
  end

  defp generate_export_function({name, args}) do
    ctx = %{:result_var => "result", :exit_label => "exit_export_#{name}"}

    args_declaration =
      args
      |> Enum.flat_map(&BaseType.generate_declaration/1)
      |> Enum.map(&~g<#{&1};>)
      |> sigil_g('nIt')

    args_initialization =
      args
      |> Enum.map(&BaseType.generate_initialization/1)
      |> sigil_g('nIt')

    args_parsing =
      args
      |> Enum.with_index()
      |> Enum.map(&BaseType.generate_arg_parse(&1, ctx))
      |> sigil_g('nIt')

    args_destruction =
      args
      |> Enum.map(&BaseType.generate_destruction/1)
      |> Enum.reject(&("" == &1))
      |> sigil_g('nIt')

    args_names = args |> Enum.flat_map(&BaseType.generate_arg_name/1)

    ~g"""
    static ERL_NIF_TERM export_#{name}(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]){
      UNIFEX_UNUSED(argc);
      ERL_NIF_TERM #{ctx.result_var};
      #{if args |> Enum.empty?(), do: ~g<UNIFEX_UNUSED(argv);>, else: ""}
      #{generate_unifex_env()}
      #{args_declaration}

      #{args_initialization}

      #{args_parsing}

      #{ctx.result_var} = #{name}(#{[:unifex_env | args_names] |> Enum.join(", ")});
      goto #{ctx.exit_label};
    #{ctx.exit_label}:
      #{args_destruction}
      return result;
    }
    """
  end

  defp generate_erlang_boilerplate(nil, _functions) do
    ~g<>
  end

  defp generate_erlang_boilerplate(module, functions) do
    printed_funcs =
      functions
      |> Enum.map(fn {name, args} ->
        ~g<{"unifex_#{name}", #{length(args)}, export_#{name}, 0}>ii
      end)
      |> sigil_g('j(,\n)i')

    ~g"""
    static ErlNifFunc nif_funcs[] =
    {
      #{printed_funcs}
    };

    ERL_NIF_INIT(#{module}.Nif, nif_funcs, load, NULL, NULL, NULL)
    """
  end

  defp generate_unifex_env() do
    ~g<UnifexEnv *unifex_env = env;>
  end
end
