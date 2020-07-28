defmodule Unifex.Helper do
  @moduledoc false
  @src_dir "c_src"

  def get_source_dir() do
    {:ok, dir} = Bundlex.Helper.MixHelper.get_project_dir()
    dir |> Path.join(@src_dir)
  end

  def get_module_string(module) do
    module |> Atom.to_string() |> String.replace(~r/Elixir\./, "")
  end
end
