defmodule Unifex.CodeGenerators.TieHeader do
  @moduledoc """
  Generates connective header file that includes proper header based
  on selected interface.
  """

  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]

  def generate_header(name) do
    ~g"""
    #pragma once

    #ifdef NIF
    #include "nif/#{name}.h"
    #endif

    #ifdef CNODE
    #include "cnode/#{name}.h"
    #endif
    """
  end
end
