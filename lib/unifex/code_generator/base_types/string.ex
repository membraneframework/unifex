defmodule Unifex.CodeGenerator.BaseTypes.String do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for Unifex state.
  """
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_native_type(ctx) do
    prefix = if ctx.mode == :const, do: "const ", else: ""
    ~g<#{prefix}char*>
  end

  @impl BaseType
  def generate_initialization(name, _ctx) do
    ~g<#{name} = NULL;>
  end

  defmodule NIF do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, _ctx) do
      ~g<unifex_string_to_term(env, #{name})>
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, _ctx) do
      ~g<unifex_string_from_term(env, #{arg}, &#{var_name})>
    end

    @impl BaseType
    def generate_destruction(name, _ctx) do
      ~g<unifex_free(#{name});>
    end
  end
end
