defmodule Mix.Tasks.Compile.Unifex do
  @moduledoc """
  Generates native boilerplate code for all the `.spec.exs` files found in `c_src` dir
  """
  alias Unifex.{Helper, InterfaceIO, SpecsParser, CodeGenerator, CodeGenerationMode}
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Helper.get_source_dir()
    |> InterfaceIO.get_interfaces_specs!()
    |> Enum.each(fn {name, dir, specs} ->
      specs = specs |> SpecsParser.parse_specs()
      mode = CodeGenerationMode.code_generation_mode(name, dir, specs)
      code = CodeGenerator.generate_code(name, specs, mode)
      InterfaceIO.store_interface!(name, dir, code)
    end)

    :ok
  end
end
