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
      codes = specs_file |> Specs.parse(name) |> CodeGenerator.generate_code()
      Enum.each(codes, &InterfaceIO.store_interface!(name, dir, &1))
      generators = Enum.map(codes, &elem(&1, 2))
      tie_header = Unifex.CodeGenerator.TieHeader.generate_header(name, generators)
      InterfaceIO.store_tie_header!(name, dir, tie_header)
      InterfaceIO.store_gitignore!(dir)
    end)
  end
end
