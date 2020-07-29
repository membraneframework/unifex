defmodule Unifex.CodeGenerator.TieHeader do
  @moduledoc """
  Generates connective header file that includes proper header based
  on selected interface.
  """
  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]
  alias Unifex.CodeGenerator

  @spec generate_header(name :: atom, interfaces :: [module]) :: CodeGenerator.code_t()
  def generate_header(name, interfaces) do
    ~g"""
    #pragma once

    #{generate_includes(name, interfaces)}
    """
  end

  defp generate_includes(name, interfaces) do
    interfaces
    |> Enum.map(&generate_include(name, &1))
    |> Enum.join("\n")
  end

  defp generate_include(name, interface) do
    interface = inspect(interface)
    module = Module.concat(Unifex.CodeGenerators, interface)

    ~g"""
    #ifdef #{module.identification_constant()}
    #include "#{interface |> String.downcase()}/#{name}.h"
    #endif
    """
  end
end
