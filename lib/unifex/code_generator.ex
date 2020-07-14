defmodule Unifex.CodeGenerator do
  @moduledoc """
  Behaviour for code generation.
  """
  alias Unifex.Specs

  @type code_t :: String.t()

  @callback generate_header(specs :: Specs.t()) :: code_t
  @callback generate_source(specs :: Specs.t()) :: code_t

  @doc """
  Generates boilerplate code using generator implementation from `Unifex.CodeGenerators`.
  """
  @spec generate_code(Specs.t()) :: {header :: code_t, source :: code_t}
  def generate_code(specs) do
    generator = get_generator(specs)
    header = generator.generate_header(specs)
    source = generator.generate_source(specs)
    {header, source}
  end

  defp get_generator(%Specs{name: name, interface: nil}) do
    {:ok, bundlex_project} = Bundlex.Project.get()

    [:nifs, :cnodes, :natives, :libs]
    |> Enum.find(&(bundlex_project.config |> Keyword.get(&1, []) |> Keyword.has_key?(name)))
    |> case do
      :nifs ->
        Unifex.CodeGenerators.NIF

      :cnodes ->
        Unifex.CodeGenerators.CNode

      :natives ->
        interfaces = bundlex_project.config[:natives][name][:interfaces]
        get_generator(get_generator_module_name(List.first(interfaces)))

      _ ->
        Unifex.CodeGenerators.NIF
    end
  end

  defp get_generator(%Specs{interface: interface}) do
    get_generator(interface)
  end

  defp get_generator(interface) do
    Module.concat(Unifex.CodeGenerators, interface)
  end

  defp get_generator_module_name(interface) do
    case interface do
      :nif -> :NIF
      :cnode -> :CNode
    end
  end
end
