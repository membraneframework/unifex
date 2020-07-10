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

    [:nifs, :cnodes]
    |> Enum.find(&(bundlex_project.config |> Keyword.get(&1, []) |> Keyword.has_key?(name)))
    |> case do
      :nifs -> Unifex.CodeGenerators.NIF
      :cnodes -> Unifex.CodeGenerators.CNode
    end
  end

  defp get_generator(%Specs{interface: interface}) do
    Module.concat(Unifex.CodeGenerators, interface)
  end
end
