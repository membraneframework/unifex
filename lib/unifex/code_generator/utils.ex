defmodule Unifex.CodeGenerator.Utils do
  @moduledoc """
  Utilities for code generation.
  """
  use Bunch
  alias Unifex.CodeGenerator
  alias Unifex.CodeGenerator.BaseType

  @doc """
  Sigil used for templating generated code.
  """
  @spec sigil_g(String.t(), []) :: String.t()
  def sigil_g(content, flags) do
    if flags != [], do: raise("unsupported flags #{inspect(flags)}")
    content
  end

  @doc """
  Traverses Elixir specification AST and creates C data types serialization
  with `serializers`.
  """
  @spec generate_serialization(
          ast :: Macro.t(),
          serializers :: %{
            arg_serializer: (type :: BaseType.t(), name :: atom -> output),
            tuple_serializer: ([output] -> output)
          }
        ) ::
          {output, [{:label, atom} | {:arg, {name :: atom, type :: BaseType.t()}}]}
        when output: term
  def generate_serialization(ast, serializers) do
    ast
    |> case do
      {:__aliases__, [alias: als], atoms} ->
        generate_serialization(als || Module.concat(atoms), serializers)

      atom when is_atom(atom) ->
        {serializers.arg_serializer.(:atom, :"\"#{atom}\""), []}

      {:"::", _, [name, {:label, _, _}]} when is_atom(name) ->
        {serializers.arg_serializer.(:atom, :"\"#{name}\""), label: name}

      {:"::", _, [{name, _, _}, {type, _, _}]} ->
        {serializers.arg_serializer.(type, name), arg: {name, type}}

      {:"::", meta, [name_var, [{type, type_meta, type_ctx}]]} ->
        generate_serialization(
          {:"::", meta, [name_var, {{:list, type}, type_meta, type_ctx}]},
          serializers
        )

      {a, b} ->
        generate_serialization({:{}, [], [a, b]}, serializers)

      {:{}, _, content} ->
        {results, meta} =
          content
          |> Enum.map(fn ast -> generate_serialization(ast, serializers) end)
          |> Enum.unzip()

        {serializers.tuple_serializer.(results), meta}

      [{_name, _, _} = name_var] ->
        generate_serialization(
          {:"::", [], [name_var, [name_var]]},
          serializers
        )

      {_name, _, _} = name_var ->
        generate_serialization({:"::", [], [name_var, name_var]}, serializers)
    end
    |> case do
      {result, meta} -> {result, List.flatten(meta)}
    end
  end

  @spec generate_functions(
          config :: Enumerable.t(),
          generator :: (term -> CodeGenerator.code_t())
        ) :: CodeGenerator.code_t()
  def generate_functions(config, generator) do
    config
    |> Enum.map(generator)
    |> Enum.filter(&(&1 != ""))
    |> Enum.join("\n")
  end

  @spec generate_functions_declarations(
          config :: Enumerable.t(),
          generator :: (term -> CodeGenerator.code_t())
        ) :: CodeGenerator.code_t()
  def generate_functions_declarations(config, generator) do
    config
    |> Enum.map(generator)
    |> Enum.filter(&(&1 != ""))
    |> Enum.map(&(&1 <> ";"))
    |> Enum.join("\n")
  end

  @spec generate_maybe_unused_args_statements(args :: [String.t()]) :: [String.t()]
  def generate_maybe_unused_args_statements(args) do
    args |> Enum.map(fn arg -> ~g<UNIFEX_MAYBE_UNUSED(#{arg});> end)
  end
end
