defmodule Unifex.CodeGenerator.TieHeader do
  @moduledoc false
  # Generates connective header file that includes proper header based
  # on selected interface.

  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]
  alias Unifex.CodeGenerator

  @spec generate_main_header(
          name :: Unifex.Specs.native_name_t(),
          generators :: [CodeGenerator.t()]
        ) ::
          CodeGenerator.code_t()
  def generate_main_header(name, generators) do
    ~g"""
    #pragma once
    #{generate_includes(name, :main, generators)}
    """
  end

  @spec generate_types_header(
          name :: Unifex.Specs.native_name_t(),
          generators :: [CodeGenerator.t()]
        ) ::
          CodeGenerator.code_t()
  def generate_types_header(name, generators) do
    ~g"""
    #pragma once
    #{generate_includes(name, :types, generators)}
    """
  end

  defp generate_includes(name, mode, generators) do
    Enum.map_join(generators, "\n", &generate_include(name, &1, mode))
  end

  defp generate_include(name, generator, mode) do
    maybe_main_header =
      if mode == :main,
        do: "#include \"#{generator.interface_io_name()}/#{name}.h\"",
        else: ""

    types_header =
      "#include \"#{generator.interface_io_name()}/#{Unifex.InterfaceIO.types_header_filename(name)}\""

    ~g"""
    #ifdef #{generator.identification_constant()}
    #{maybe_main_header}
    #{types_header}
    #endif
    """
  end
end
