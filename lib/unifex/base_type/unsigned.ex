defmodule Unifex.BaseType.Unsigned do
  @moduledoc """
  Module implementing `Unifex.BaseType` behaviour for unsigned int.
  """
  alias Unifex.BaseType
  use BaseType

  @impl BaseType
  def generate_arg_serialize(name) do
    ~g<enif_make_uint(env, #{name})>
  end

  @impl BaseType
  def generate_native_type() do
    ~g<unsigned int>
  end

  @impl BaseType
  def generate_arg_parse(arg_term, var_name) do
    ~g<enif_get_uint(env, #{arg_term}, &#{var_name})>
  end
end
