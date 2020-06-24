defmodule Unifex.CodeGenerator.BaseTypes.State do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for Unifex state.
  """
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_native_type(_ctx) do
    ~g<UnifexState*>
  end

  defmodule NIF do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, _ctx) do
      ~g<unifex_make_resource(env, #{name})>
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, _ctx) do
      ~g<enif_get_resource(env, #{arg}, STATE_RESOURCE_TYPE, (void **)&#{var_name})>
    end
  end

  defmodule CNode do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_parse(_argument, variable, _ctx) do
      ~g<#{variable} = ctx-\>wrapper-\>state;>
    end

    @impl BaseType
    def generate_arg_serialize(name, _ctx) do
      ~g<ctx-\>wrapper-\>state = #{name};>
    end
  end
end
