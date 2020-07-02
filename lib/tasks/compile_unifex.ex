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
    |> Enum.each(fn {name, dir, specs_code} ->
      code = specs_code |> Specs.parse(name) |> CodeGenerator.generate_code()
      InterfaceIO.store_interface!(name, dir, code)
    end)
  end
end
