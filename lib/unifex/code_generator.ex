defmodule Unifex.CodeGenerator do
  alias Unifex.Specs

  @type code_t :: String.t()

  @callback generate_header(Specs.t()) :: code_t
  @callback generate_source(Specs.t()) :: code_t

  @spec generate_code(Specs.t()) :: [{header :: code_t, source :: code_t}]
  def generate_code(specs) do
    generator = Module.concat(Unifex.CodeGenerators, specs.interface)
    header = generator.generate_header(specs)
    source = generator.generate_source(specs)
    {header, source}
  end
end
