defmodule Unifex.CodeGenerator do
  alias Unifex.Specs

  @type code_t :: String.t()

  @callback generate_header(
              name :: any,
              module :: any,
              functions :: any,
              results :: any,
              sends :: any,
              callbacks :: any,
              mode :: CodeGenerationMode.t()
            ) :: code_t()
  @callback generate_source(
              name :: any,
              module :: any,
              functions :: any,
              results :: any,
              dirty_funs :: any,
              sends :: any,
              callbacks :: any,
              mode :: CodeGenerationMode.t()
            ) :: code_t()

  @spec generate_code(Specs.t()) :: {code_t(), code_t()}
  def generate_code(specs) do
    implementation = choose_implementation(specs)
    header = implementation.generate_header(specs)
    source = implementation.generate_source(specs)
    {header, source}
  end

  defp choose_implementation(%Specs{cnode_mode: false}) do
    Unifex.CodeGenerators.NIF
  end

  defp choose_implementation(%Specs{cnode_mode: true}) do
    Unifex.CodeGenerators.CNode
  end
end
