defmodule Unifex.BaseType.Atom do
  @moduledoc """
  Module implementing `Unifex.BaseType` behaviour for Unifex state.
  """
  alias Unifex.BaseType
  use BaseType

  @impl BaseType
  def generate_native_type() do
    ~g<char*>
  end
end
