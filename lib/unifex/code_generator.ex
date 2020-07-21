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
  @spec generate_code(Specs.t()) :: [{header :: code_t, source :: code_t}]
  def generate_code(specs) do
    generators = get_generators(specs)

    generators
    |> Enum.map(fn {interface, generator} ->
      header = generator.generate_header(specs)
      source = generator.generate_source(specs)
      {header, source, interface}
    end)
  end

  defp get_generators(%Specs{name: name, interface: nil}) do
    {:ok, bundlex_project} = Bundlex.Project.get()
    config = bundlex_project.config

    interfaces = [:natives, :libs] |> Enum.find_value(&get_in(config, [&1, name, :interface]))

    case interfaces do
      [] -> raise "Interface for native #{name} is not specified.
        Please specify it in your *.spec.exs or bundlex.exs file."
      _ -> interfaces |> Enum.map(&get_generator_module_name(&1))
    end
  end

  defp get_generators(%Specs{interface: interfaces}) do
    interfaces |> Bunch.listify() |> Enum.map(&get_generator_module_name(&1))
  end

  defp get_generator_module_name(interface) do
    module_name =
      case interface do
        :nif -> :NIF
        :cnode -> :CNode
        other -> raise "Valid interfaces are :nif and :cnode. Passed #{other}"
      end

    module = Module.concat(Unifex.CodeGenerators, module_name)
    {interface, module}
  end
end
