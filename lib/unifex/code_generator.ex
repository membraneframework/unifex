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
    config = bundlex_project.config

    type =
      [:natives, :libs]
      |> Enum.find(&(config |> Keyword.get(&1, []) |> Keyword.has_key?(name)))

    interfaces = Keyword.get(config[type][name], :interface, [])

    case interfaces do
      [] -> Unifex.CodeGenerators.NIF
      _ -> get_generator_module_name(List.first(interfaces))
    end
  end

  defp get_generator(%Specs{interface: interface}) do
    get_generator_module_name(interface)
  end

  defp get_generator_module_name(interface) do
    module_name =
      case interface do
        :nif -> :NIF
        :cnode -> :CNode
        other -> other
      end

    Module.concat(Unifex.CodeGenerators, module_name)
  end
end
