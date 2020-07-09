defmodule Unifex.CodeGenerator.BaseTypes.Atom do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for atoms.

  Atoms in native code are represented by C-strings (`char *`)
  """
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_native_type(ctx) do
    prefix = if ctx.mode == :const, do: "const ", else: ""
    ~g<#{prefix} char*>
  end

  @impl BaseType
  def generate_initialization(name, _ctx) do
    ~g<#{name} = NULL;>
  end

  @impl BaseType
  def generate_destruction(name, _ctx) do
    ~g<if (#{name} != NULL) unifex_free(#{name});>
  end

  defmodule NIF do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_parse(arg_term, var_name, _ctx) do
      ~g<unifex_alloc_and_get_atom(env, #{arg_term}, &#{var_name})>
    end
  end

  defmodule CNode do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_parse(argument, name, _ctx) do
      ~g"""
      #{name} = unifex_alloc(MAXATOMLEN);
      ei_decode_atom(#{argument}->buff, #{argument}->index, #{name})
      """
    end
  end
end
