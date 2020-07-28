defmodule Unifex.CodeGenerator.TieHeader do
  @moduledoc """
  Generates connective header file that includes proper header based
  on selected interface.
  """

  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]

  def generate_tie_header(name, interfaces) do
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
    interface = Unifex.Helper.get_module_string(interface)

    ~g"""
    #ifdef BUNDLEX_#{interface |> String.upcase()}
    #include "#{interface |> String.downcase()}/#{name}.h"
    #endif
    """
  end
end
