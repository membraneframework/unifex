defmodule Unifex do
  @moduledoc """
  Implementation of `Bundlex.Precompiler`.

  When added to a native configuration in `Bundlex.Project`, equips the native with
  the Unifex native dependency and generated sources.
  """
  alias Bundlex.Native
  alias Bundlex.Project.Precompiler
  alias Unifex.InterfaceIO

  @behaviour Precompiler

  @impl Precompiler
  def precompile_native_config(_name, _app, config) do
    unifex_deps = [unifex: :unifex]
    Keyword.update(config, :deps, unifex_deps, &(unifex_deps ++ &1))
  end

  @impl Precompiler
  def precompile_native(native) do
    %Native{app: app, name: name, interface: interface, language: language} = native

    {:ok, project_dir} = Bundlex.Helper.MixHelper.get_project_dir(app)

    interface =
      case interface do
        :nif -> NIF
        :cnode -> CNode
      end

    source =
      project_dir
      |> InterfaceIO.get_interfaces_specs!()
      |> Enum.find(fn {spec_name, _dir, _specs} -> spec_name == name end)
      |> case do
        {_spec_name, dir, _specs} -> InterfaceIO.out_path(name, dir, interface, ".#{language}")
        nil -> raise "Native #{inspect(name)} not found in app #{inspect(app)} specification"
      end

    %Native{native | sources: [source | native.sources]}
  end
end
