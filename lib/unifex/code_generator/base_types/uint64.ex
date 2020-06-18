defmodule Unifex.CodeGenerator.BaseTypes.Uint64 do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for 64-bit unsigned integer.

  Maps `uint64` Unifex type to a `uint64_t` native type.
  """
  alias Unifex.CodeGenerator.BaseType
  use BaseType

  @impl BaseType
  def generate_native_type(_ctx) do
    ~g<uint64_t>
  end
end
