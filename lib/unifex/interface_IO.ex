defmodule Unifex.InterfaceIO do
  @name_sufix "_interface"

  def get_interfaces_specs!(dir) do
    Path.wildcard(dir |> Path.join("**/?*#{@name_sufix}.exs"))
    |> Enum.map(fn file ->
      name = file |> Path.basename() |> String.replace_suffix("#{@name_sufix}.exs", "")
      dir = file |> Path.dirname()
      {specs, _bindings} = Code.eval_file(file)
      {name, dir, specs}
    end)
  end

  def store_interface!(name, dir, code) do
    {header, source} = code
    out_name = dir |> Path.join("#{name}#{@name_sufix}")
    File.write!("#{out_name}.h", header)
    File.write!("#{out_name}.c", source)
    :ok
  end
end
