defmodule Unifex.CodeGenerator.TieHeader do
  @moduledoc """
  Generates connective header file that includes proper header based
  on selected interface.
  """
  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]
  alias Unifex.CodeGenerator

  @spec generate_header(name :: String.t(), generators :: [module()]) :: CodeGenerator.code_t()
  def generate_header(name, generators) do
    ~g"""
    #pragma once

    #{generate_includes(name, generators)}
    """
  end

  defp generate_includes(name, generators) do
    generators
    |> Enum.map(&generate_include(name, &1))
    |> Enum.join("\n")
  end

  defp generate_include(name, generator) do
    ~g"""
    #ifdef #{generator.identification_constant()}
    #include "#{generator.interface_io_name()}/#{name}.h"
    #endif
    """
  end
end
