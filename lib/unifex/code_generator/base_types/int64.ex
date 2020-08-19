defmodule Unifex.CodeGenerator.BaseTypes.Int64 do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for 64-bit integer.

  Maps `int64` Unifex type to an `int64_t` native type.

  Implemented only for NIF as function parameter as well as return type.
  """
  alias Unifex.CodeGenerator.BaseType
  use BaseType

  @impl BaseType
  def generate_native_type(_ctx) do
    ~g<int64_t>
  end
end
