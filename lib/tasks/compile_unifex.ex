defmodule Mix.Tasks.Compile.Unifex do
  @moduledoc """
  Generates native boilerplate code for all the `.spec.exs` files found in `c_src` dir
  """
  alias Unifex.{Helper, InterfaceIO, SpecsParser, CodeGenerator}
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
