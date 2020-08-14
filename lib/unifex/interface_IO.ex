defmodule Unifex.InterfaceIO do
  @moduledoc false

  alias Unifex.CodeGenerator

  @spec_name_sufix ".spec.exs"
  @generated_dir_name "_generated"

  def user_header_path(name) do
    "../../#{name}.h"
  end

  @spec get_interfaces_specs!(dir :: Path.t()) :: [
          {name :: String.t(), dir :: String.t(), file :: String.t()}
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

  def out_path(name, dir, generator, extension \\ "") do
    Path.join(out_dir(dir, generator), "#{name}#{extension}")
  end

  def out_dir(base_dir, generator) do
    Path.join([base_dir, @generated_dir_name, generator.interface_io_name()])
  end

  @spec store_interface!(
          name :: String.t(),
          dir :: String.t(),
          code :: CodeGenerator.generated_code_t()
        ) :: :ok
  def store_interface!(name, dir, {header, source, generator}) do
    File.mkdir_p!(out_dir(dir, generator))
    out_base_path = out_path(name, dir, generator)
    File.write!("#{out_base_path}.h", header)
    File.write!("#{out_base_path}.c", source)
    File.write!("#{out_base_path}.cpp", source)

    Mix.shell().cmd(
      "clang-format -style=\"{BasedOnStyle: llvm, IndentWidth: 2}\" -i " <>
        "#{out_base_path}.h #{out_base_path}.c #{out_base_path}.cpp"
    )

    :ok
  end

  def store_tie_header!(name, dir, code) do
    out_dir_name = Path.join(dir, @generated_dir_name)
    File.mkdir_p!(out_dir_name)
    out_base_path = Path.join(out_dir_name, "#{name}.h")
    File.write!(out_base_path, code)

    :ok
  end

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
end
