defmodule Unifex.InterfaceIO do
  @moduledoc false

  @spec_name_sufix ".spec.exs"
  @generated_dir_name "_generated"

  def user_header_path(name) do
    "../../#{name}.h"
  end

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

  def out_path(name, dir, interface, extension \\ "") do
    Path.join(out_dir(dir, interface), "#{name}#{extension}")
  end

  def out_dir(base_dir, interface) do
    interface = interface |> inspect() |> String.downcase()
    Path.join([base_dir, @generated_dir_name, "#{interface}"])
  end

  def store_interface!(name, dir, code) do
    {header, source, interface} = code
    File.mkdir_p!(out_dir(dir, interface))
    out_base_path = out_path(name, dir, interface)
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
