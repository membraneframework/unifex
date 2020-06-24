defmodule Unifex.CodeGenerator.Utils do
  use Bunch

  @doc """
  Sigil used for templating generated code.
  """
  @spec sigil_g(String.t(), []) :: String.t()
  def sigil_g(content, flags) do
    if flags != [], do: raise("unsupported flags #{inspect(flags)}")
    content
  end

  def generate_function_spec_traverse_helper(node, serializers) do
    node
    |> case do
      {:__aliases__, [alias: als], atoms} ->
        generate_function_spec_traverse_helper(als || Module.concat(atoms), serializers)

      atom when is_atom(atom) ->
        {serializers.arg_serializer.(:atom, :"\"#{atom}\""), []}

      {:"::", _, [name, {:label, _, _}]} when is_atom(name) ->
        {serializers.arg_serializer.(:atom, :"\"#{name}\""), label: name}

      {:"::", _, [{name, _, _}, {type, _, _}]} ->
        {serializers.arg_serializer.(type, name), arg: {name, type}}

      {:"::", meta, [name_var, [{type, type_meta, type_ctx}]]} ->
        generate_function_spec_traverse_helper(
          {:"::", meta, [name_var, {{:list, type}, type_meta, type_ctx}]},
          serializers
        )

      {a, b} ->
        generate_function_spec_traverse_helper({:{}, [], [a, b]}, serializers)

      {:{}, _, content} ->
        {results, meta} =
          content
          |> Enum.map(fn n -> generate_function_spec_traverse_helper(n, serializers) end)
          |> Enum.unzip()

        {serializers.tuple_serializer.(results), meta}

      [{_name, _, _} = name_var] ->
        generate_function_spec_traverse_helper(
          {:"::", [], [name_var, [name_var]]},
          serializers
        )

      {_name, _, _} = name_var ->
        generate_function_spec_traverse_helper({:"::", [], [name_var, name_var]}, serializers)
    end
    ~> ({result, meta} -> {result, meta |> List.flatten()})
  end

  def generate_functions(results, generator, mode) do
    results
    |> Enum.map(fn res -> res |> generator.(mode) end)
    |> Enum.filter(&(&1 != ""))
    |> Enum.join("\n")
  end

  def generate_functions(results, generator) do
    results
    |> Enum.map(generator)
    |> Enum.filter(&(&1 != ""))
    |> Enum.join("\n")
  end

  def generate_functions_declarations(results, generator, mode) do
    results
    |> Enum.map(fn res -> res |> generator.(mode) end)
    |> Enum.filter(&(&1 != ""))
    |> Enum.map(&(&1 <> ";"))
    |> Enum.join("\n")
  end

  def generate_functions_declarations(results, generator) do
    results
    |> Enum.map(generator)
    |> Enum.filter(&(&1 != ""))
    |> Enum.map(&(&1 <> ";"))
    |> Enum.join("\n")
  end
end
