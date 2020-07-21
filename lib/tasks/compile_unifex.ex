defmodule Mix.Tasks.Compile.Unifex do
  @moduledoc """
  Generates native boilerplate code for all the `.spec.exs` files found in `c_src` dir
  """
  use Mix.Task
  alias Unifex.{Helper, InterfaceIO, Specs, CodeGenerator}

  @impl Mix.Task
  def run(_args) do
    Helper.get_source_dir()
    |> InterfaceIO.get_interfaces_specs!()
    |> Enum.each(fn {name, dir, specs_file} ->
      tie_header = Unifex.CodeGenerators.TieHeader.generate_header(name)
      InterfaceIO.store_tie_header!(name, dir, tie_header)
      InterfaceIO.store_gitignore!(dir)
      codes = specs_file |> Specs.parse(name) |> CodeGenerator.generate_code()
      codes |> Enum.map(&InterfaceIO.store_interface!(name, dir, &1))
    end)
  end
end
