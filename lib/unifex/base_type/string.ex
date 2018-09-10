defmodule Unifex.BaseType.String do
  @moduledoc """
  Module implementing `Unifex.BaseType` behaviour for Unifex state.
  """
  alias Unifex.BaseType
  use BaseType

  @impl BaseType
  def generate_arg_serialize(name) do
    ~g<unifex_string_to_term(env, #{name})>
  end

  @impl BaseType
  def generate_native_type() do
    ~g<char*>
  end

  @impl BaseType
  def generate_arg_parse(arg, var_name) do
    ~g<unifex_string_from_term(env, #{arg}, &#{var_name})>
  end

  @impl BaseType
  def generate_initialization(name) do
    ~g<#{name} = NULL;>
  end

  @impl BaseType
  def generate_destruction(name) do
    ~g<enif_free(#{name});>
  end
end
