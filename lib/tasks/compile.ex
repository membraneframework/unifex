defmodule Mix.Tasks.Compile.Unifex do
  alias Unifex.{CodeGenerator, InterfaceIO}
  use Mix.Task

  @src_dir "c_src"

  @impl Mix.Task
  def run(_args) do
    {:ok, dir} = Bundlex.Helper.MixHelper.get_project_dir()
    dir = dir |> Path.join(@src_dir)

    InterfaceIO.get_interfaces_specs!(dir)
    |> Enum.each(fn {name, dir, specs} ->
      code = CodeGenerator.generate_code(name, specs)
      InterfaceIO.store_interface!(name, dir, code)
    end)

    :ok
  end
end
