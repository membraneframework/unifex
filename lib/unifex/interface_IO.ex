defmodule Unifex.InterfaceIO do
  @moduledoc false

  @spec_name_sufix ".spec.exs"
  @generated_dir_name "_generated"

  def user_header_path(name) do
    "../#{name}.h"
  end

  def get_interfaces_specs!(dir) do
    dir
    |> Path.join("**/?*#{@spec_name_sufix}")
    |> Path.wildcard()
    |> Enum.map(fn file ->
      name = file |> Path.basename() |> String.replace_suffix(@spec_name_sufix, "")
      dir = file |> Path.dirname()
      specs = File.read!(file)
      {name, dir, specs}
    end)
  end

  def store_interface!(name, dir, code) do
    {header, source} = code
    out_dir_name = Path.join(dir, @generated_dir_name)
    File.mkdir_p!(out_dir_name)
    out_base_path = Path.join(out_dir_name, name)
    File.write!("#{out_base_path}.h", header)
    File.write!("#{out_base_path}.c", source)

    out_dir_name
    |> Path.join(".gitignore")
    |> File.write!("""
    *.c
    *.h
    """)

    :ok
  end
end
