defmodule Unifex.BaseType.State do
  @moduledoc """
  Module implementing `Unifex.BaseType` behaviour for Unifex state.
  """
  alias Unifex.BaseType
  use BaseType

  @impl BaseType
  def generate_arg_serialize(name) do
    ~g<unifex_make_and_release_resource(env, #{name})>
  end

  @impl BaseType
  def generate_native_type() do
    ~g<State*>
  end

  @impl BaseType
  def generate_arg_parse(arg, var_name) do
    ~g<enif_get_resource(env, #{arg}, STATE_RESOURCE_TYPE, (void **)&#{var_name})>
  end
end