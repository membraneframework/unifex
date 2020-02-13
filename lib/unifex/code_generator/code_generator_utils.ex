defmodule Unifex.CodeGenerator.CodeGeneratorUtils do
  use Bunch

  alias Unifex.BaseType
  alias Unifex.InterfaceIO

  defmacro __using__(_args) do
    quote do
      import unquote(__MODULE__), only: [gen: 2, sigil_g: 2]
    end
  end

  defmacro spec_traverse_helper_generating_macro() do
    quote do
      defp generate_function_spec_traverse_helper(node) do
        Unifex.CodeGenerator.CodeGeneratorUtils.generate_function_spec_traverse_helper(
          node,
          __MODULE__
        )
      end
    end
  end

  @doc """
  Sigil used for indentation of generated code.

  By itself it does nothing, but has very useful flags:
  * `r` trims trailing whitespaces of each line and removes subsequent empty
    lines
  * `t` trims the string
  * `i` indents all but the first line. Helpful when used
    inside string interpolation that already has been indented
  * `I` indents every line of string
  """
  @spec sigil_g(String.t(), charlist()) :: String.t()
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

  @doc """
  Helper for generating code. Uses `sigil_g/2` underneath.

  It supports all the flags supported by `sigil_g/2` and the following ones:
  * `j(joiner)` - joins list of strings using `joiner`
  * n - alias for `j(\\n)`

  If passed a list and flags supported by `sigil_g/2`, each flag will be executed
  on each element of the list, until the list is joined by using `j` or `n` flag.
  """
  @spec gen(String.Chars.t() | [String.Chars.t()], charlist()) :: String.t() | [String.t()]
  def gen(content, 'j(' ++ flags) when is_list(content) do
    {joiner, ')' ++ flags} = flags |> Enum.split_while(&([&1] != ')'))
    content = content |> Enum.join("#{joiner}")
    gen(content, flags)
  end

  def gen(content, 'n' ++ flags) when is_list(content) do
    gen(content, 'j(\n)' ++ flags)
  end

  def gen(content, flags) when is_list(content) do
    content |> Enum.map(&gen(&1, flags))
  end

  def gen(content, flags) do
    sigil_g(content, flags)
  end

  defp indent(line) do
    "  #{line}"
  end

  def generate_function_spec_traverse_helper(node, implementation) do
    node
    |> case do
      {:__aliases__, [alias: als], atoms} ->
        generate_function_spec_traverse_helper(als || Module.concat(atoms), implementation)

      atom when is_atom(atom) ->
        {BaseType.generate_arg_serialize({:"\"#{atom}\"", :atom}), []}

      {:"::", _, [name, {:label, _, _}]} when is_atom(name) ->
        {BaseType.generate_arg_serialize({:"\"#{name}\"", :atom}), label: name}

      {:"::", _, [{name, _, _}, {type, _, _}]} ->
        {BaseType.generate_arg_serialize({name, type}), arg: {name, type}}

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
