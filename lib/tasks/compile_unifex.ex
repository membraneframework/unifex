defmodule Mix.Tasks.Compile.Unifex do
  @moduledoc """
  Generates native boilerplate code for all the `.spec.exs` files found in `c_src` dir
  """
  alias Unifex.{Helper, InterfaceIO, SpecsParser, CodeGenerator}
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Helper.get_source_dir()
    |> InterfaceIO.get_interfaces_specs!()
    |> Enum.each(fn {name, dir, specs} ->
      specs = specs |> SpecsParser.parse_specs()
      # code = NativeCodeGenerator.generate_code(name, specs)
      # code = CNodeNativeCodeGenerator.generate_code(name, specs)
      code = CodeGenerator.generate_native(name, specs)
      InterfaceIO.store_interface!(name, dir, code)
    end)

    :ok
  end
end

# @impl Mix.Task
# def run(_args) do
#   # src_dir = Helper.get_source_dir()

#   # generating(
#   #   src_dir,
#   #   &InterfaceIO.get_nif_interfaces_specs!/1,
#   #   &NativeCodeGenerator.generate_code/2
#   # )

#   # generating(
#   #   src_dir,
#   #   &InterfaceIO.get_cnode_interfaces_specs!/1,
#   #   &CNodeNativeCodeGenerator.generate_code/2
#   # )

#   Helper.get_source_dir()
#   |> InterfaceIO.get_interfaces_specs!()
#   |> Enum.each(fn {name, dir, specs} ->
#     specs = specs |> SpecsParser.parse_specs()

#     code = NativeCodeGenerator.generate_code(name, specs)
#     InterfaceIO.store_interface!(name, dir, code)
#   end)

#         # code = CNodeNativeCodeGenerator.generate_code(name, specs)

#   :ok
# end

# # defp generating(src_dir, spec_getter, code_generator) do
# #   src_dir
# #   |> spec_getter.()
# #   |> Enum.each(fn {name, dir, specs} ->
# #     specs = specs |> SpecsParser.parse_specs()
# #     code = code_generator.(name, specs)
# #     InterfaceIO.store_interface!(name, dir, code)
# #   end)
# # end
