defmodule Unifex.BaseType.Uint64 do
  @moduledoc """
  Module implementing `Unifex.BaseType` behaviour for 64-bit unsigned integer.

  Maps `uint64` Unifex type to a `uint64_t` native type.
  """
  alias Unifex.BaseType
  use BaseType

  @impl BaseType
  def generate_native_type() do
    ~g<uint64_t>
  end
end
