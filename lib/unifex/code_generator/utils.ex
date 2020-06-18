defmodule Unifex.CodeGenerator.Utils do
  use Bunch

  alias Unifex.CodeGenerator.BaseType

  defmacro __using__(_args) do
    quote do
      import unquote(__MODULE__), only: [sigil_g: 2]
    end
  end

  defmacro spec_traverse_helper_generating_macro() do
    quote do
      defp generate_function_spec_traverse_helper(node) do
        Unifex.CodeGenerator.Utils.generate_function_spec_traverse_helper(
          node,
          __MODULE__
        )
      end
    end
  end

  @doc """
  Sigil used for templating generated code.
  """
  @spec sigil_g(String.t(), []) :: String.t()
  def sigil_g(content, flags) do
    if flags != [], do: raise("unsupported flags #{inspect(flags)}")
    content
  end

  def generate_function_spec_traverse_helper(node, implementation) do
    node
    |> case do
      {:__aliases__, [alias: als], atoms} ->
        generate_function_spec_traverse_helper(als || Module.concat(atoms), implementation)

      atom when is_atom(atom) ->
        {BaseType.generate_arg_serialize(:atom, :"\"#{atom}\"", NIF), []}

      {:"::", _, [name, {:label, _, _}]} when is_atom(name) ->
        {BaseType.generate_arg_serialize(:atom, :"\"#{name}\"", NIF), label: name}

      {:"::", _, [{name, _, _}, {type, _, _}]} ->
        {BaseType.generate_arg_serialize(type, name, NIF), arg: {name, type}}

      {:"::", meta, [name_var, [{type, type_meta, type_ctx}]]} ->
        generate_function_spec_traverse_helper(
          {:"::", meta, [name_var, {{:list, type}, type_meta, type_ctx}]},
          implementation
        )

      {a, b} ->
        generate_function_spec_traverse_helper({:{}, [], [a, b]}, implementation)

      {:{}, _, content} ->
        {results, meta} =
          content
          |> Enum.map(fn n -> generate_function_spec_traverse_helper(n, implementation) end)
          |> Enum.unzip()

        {implementation.generate_tuple_maker(results), meta}

      [{_name, _, _} = name_var] ->
        generate_function_spec_traverse_helper(
          {:"::", [], [name_var, [name_var]]},
          implementation
        )

      {_name, _, _} = name_var ->
        generate_function_spec_traverse_helper({:"::", [], [name_var, name_var]}, implementation)
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
