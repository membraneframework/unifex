defmodule Unifex.CodeGenerator.BaseTypes.Atom do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for atoms.

  Atoms in native code are represented by C-strings (`char *`)
  """
  alias Unifex.CodeGenerator.BaseType
  use BaseType

  @impl BaseType
  def generate_native_type(_ctx) do
    ~g<char*>
  end

  @impl BaseType
  def generate_initialization(name, _ctx) do
    ~g<#{name} = NULL;>
  end

  @impl BaseType
  def generate_destruction(name, _ctx) do
    ~g<if (#{name} != NULL) enif_free(#{name});>
  end

  @impl BaseType
  def generate_arg_parse(arg_term, var_name, _ctx) do
    ~g<unifex_alloc_and_get_atom(env, #{arg_term}, &#{var_name})>
  end
end
