defmodule Unifex.BaseType.Atom do
  @moduledoc """
  Module implementing `Unifex.BaseType` behaviour for atoms.

  Atoms in native code are representec by C-strings (`char *`)
  """
  alias Unifex.BaseType
  use BaseType

  @impl BaseType
  def generate_native_type() do
    ~g<char*>
  end

  @impl BaseType
  def generate_initialization(name) do
    ~g<#{name} = NULL;>
  end

  @impl BaseType
  def generate_destruction(name) do
    ~g<if (#{name} != NULL) enif_free(#{name});>
  end

  @impl BaseType
  def generate_arg_parse(arg_term, var_name) do
    ~g<unifex_alloc_and_get_atom(env, #{arg_term}, &#{var_name})>
  end
end
