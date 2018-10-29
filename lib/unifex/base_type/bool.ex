defmodule Unifex.BaseType.Bool do
  @moduledoc """
  Module implementing `Unifex.BaseType` behaviour for boolean atoms.

  Booleans in native code are converted to int with value either 0 or 1.
  """
  alias Unifex.BaseType
  use BaseType

  @impl BaseType
  def generate_native_type() do
    ~g<int>
  end

  @impl BaseType
  def generate_arg_serialize(name) do
    ~g<enif_make_atom(env, #{name} ? "true" : "false")>
  end

  @impl BaseType
  def generate_arg_parse(arg_term, var_name) do
    ~g<unifex_parse_bool(env, #{arg_term}, &#{var_name})>
  end
end
