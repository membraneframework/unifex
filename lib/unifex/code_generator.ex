defmodule Unifex.CodeGenerator do
  alias Unifex.CodeGenerator.{CNodeCodeGenerator, NIFCodeGenerator, CodeGenerationMode}

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

  @spec generate_code(
          name :: String.t(),
          specs :: Unifex.SpecsParser.parsed_specs_t(),
          mode :: CodeGenerationMode.t()
        ) ::
          {code_t(), code_t()}
  def generate_code(name, specs, mode) do
    implementation = specs |> Keyword.get(:cnode_mode, false) |> choose_implementation()

    module = specs |> Keyword.get(:module)
    fun_specs = specs |> Keyword.get_values(:fun_specs)
    dirty_funs = specs |> Keyword.get_values(:dirty) |> List.flatten() |> Map.new()
    sends = specs |> Keyword.get_values(:sends)
    callbacks = specs |> Keyword.get_values(:callbacks)

    {functions, results} =
      fun_specs
      |> Enum.map(fn {name, args, results} -> {{name, args}, {name, results}} end)
      |> Enum.unzip()

    results = results |> Enum.flat_map(fn {name, specs} -> specs |> Enum.map(&{name, &1}) end)

    header =
      implementation.generate_header(name, module, functions, results, sends, callbacks, mode)

    source =
      implementation.generate_source(
        name,
        module,
        functions,
        results,
        dirty_funs,
        sends,
        callbacks,
        mode
      )

    {header, source}
  end

  defp choose_implementation(false = _cnode_mode) do
    NIFCodeGenerator
  end

  defp choose_implementation(true = _cnode_mode) do
    CNodeCodeGenerator
  end
end
