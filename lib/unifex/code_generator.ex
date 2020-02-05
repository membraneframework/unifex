defmodule Unifex.CodeGenerator do
  @type code_t :: String.t()

  @spec generate_native(name :: String.t(), specs :: Unifex.SpecsParser.parsed_specs_t()) ::
          {code_t(), code_t()}
  def generate_native(name, specs) do
    cnode_mode = specs |> Keyword.get(:cnode_mode, false)
    generate_code(name, specs, cnode_mode)
  end

  defp generate_code(name, specs, true = _cnode_mode) do
    Unifex.CNodeNativeCodeGenerator.generate_code(name, specs)
  end

  defp generate_code(name, specs, false = _cnode_mode) do
    Unifex.NativeCodeGenerator.generate_code(name, specs)
  end
end
