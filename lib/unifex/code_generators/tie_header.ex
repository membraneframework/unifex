defmodule Unifex.CodeGenerators.TieHeader do
  @moduledoc """
  """

  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]

  # TODO

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
