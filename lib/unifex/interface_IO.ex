defmodule Unifex.InterfaceIO do
  @moduledoc false

  alias Unifex.{CodeGenerator, Specs}

  @spec_name_sufix ".spec.exs"
  @generated_dir_name "_generated"
  @types_header_sufix "_types"

  @spec user_header_path(Specs.native_name_t()) :: String.t()
  def user_header_path(name) do
    "../../#{name}.h"
  end

  @spec get_interfaces_specs!(dir :: String.t()) :: [
          {Specs.native_name_t(), dir :: String.t(), file :: String.t()}
        ]
  def get_interfaces_specs!(dir) do
    dir
    |> Path.join("**/?*#{@spec_name_sufix}")
    |> Path.wildcard()
    |> Enum.map(fn file ->
      name =
        file |> Path.basename() |> String.replace_suffix(@spec_name_sufix, "") |> String.to_atom()

      dir = file |> Path.dirname()
      {name, dir, file}
    end)
  end

  @spec out_path(
          Specs.native_name_t(),
          dir :: String.t(),
          CodeGenerator.t(),
          extension :: String.t()
        ) :: String.t()
  def out_path(name, dir, generator, extension \\ "") do
    out_dir(dir, generator) |> Path.join("#{name}#{extension}")
  end

  @spec out_dir(base_dir :: String.t(), CodeGenerator.t()) :: String.t()
  def out_dir(base_dir, generator) do
    Path.join([base_dir, @generated_dir_name, generator.interface_io_name()])
  end

  @spec store_interface!(
          Specs.native_name_t(),
          dir :: String.t(),
          code :: CodeGenerator.generated_code_t()
        ) :: :ok
  def store_interface!(name, dir, generated_code) do
    %{header: header, types_header: types_header, source: source, generator: generator} =
      generated_code

    File.mkdir_p!(out_dir(dir, generator))
    out_base_path = out_path(name, dir, generator)
    File.write!("#{out_base_path}.h", header)
    File.write!("#{out_base_path}#{@types_header_sufix}.h", types_header)
    File.write!("#{out_base_path}.c", source)
    File.write!("#{out_base_path}.cpp", source)

    # Format generated code only when clang-format is available
    if Unifex.Utils.clang_format_installed?() do
      System.cmd(
        "clang-format",
        [
          "-style={BasedOnStyle: llvm, IndentWidth: 2}",
          "-i",
          "#{out_base_path}.h",
          "#{out_base_path}#{@types_header_sufix}.h",
          "#{out_base_path}.c",
          "#{out_base_path}.cpp"
        ]
      )
    end

    :ok
  end

  @spec store_tie_header!(Specs.native_name_t(), dir :: String.t(), CodeGenerator.code_t()) ::
          :ok
  def store_tie_header!(name, dir, code), do: do_store_tie_header!(name, dir, code, :main)

  @spec store_types_tie_header!(Specs.native_name_t(), dir :: String.t(), CodeGenerator.code_t()) ::
          :ok
  def store_types_tie_header!(name, dir, code), do: do_store_tie_header!(name, dir, code, :types)

  defp do_store_tie_header!(name, dir, code, mode) when mode in [:main, :types] do
    out_dir_name = Path.join(dir, @generated_dir_name)
    File.mkdir_p!(out_dir_name)

    filename =
      case mode do
        :main -> "#{name}.h"
        :types -> "#{name}#{@types_header_sufix}.h"
      end

    out_base_path = Path.join(out_dir_name, filename)
    File.write!(out_base_path, code)
  end

  @spec store_gitignore!(String.t()) :: :ok
  def store_gitignore!(dir) do
    out_dir_name = Path.join(dir, @generated_dir_name)
    File.mkdir_p!(out_dir_name)

    File.write!(Path.join(out_dir_name, ".gitignore"), """
    **/*.h
    **/*.c
    **/*.cpp
    """)

    :ok
  end

  @spec types_header_filename(Specs.native_name_t()) :: String.t()
  def types_header_filename(name) do
    "#{name}#{@types_header_sufix}.h"
  end
end
