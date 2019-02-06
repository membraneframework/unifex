defmodule Unifex.BaseType.Int64 do
  @moduledoc """
  Module implementing `Unifex.BaseType` behaviour for 64-bit integer.

  Maps `int64` Unifex type to an `int64_t` native type.
  """
  alias Unifex.BaseType
  use BaseType

  @impl BaseType
  def generate_native_type() do
    ~g<int64_t>
  end
end
