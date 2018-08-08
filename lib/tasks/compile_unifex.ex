defmodule Mix.Tasks.Compile.Unifex do
  alias Unifex.{CodeGenerator, Helper, InterfaceIO, SpecsParser}
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Helper.get_source_dir()
    |> InterfaceIO.get_interfaces_specs!()
    |> Enum.each(fn {name, dir, specs} ->
      specs = specs |> SpecsParser.parse_specs()
      code = CodeGenerator.generate_code(name, specs)
      InterfaceIO.store_interface!(name, dir, code)
    end)

    :ok
  end
end
