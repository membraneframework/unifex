defmodule Unifex.CodeGenerator.BaseTypes.Payload do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for payloads.
  """
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_native_type(_ctx) do
    ~g<UnifexPayload *>
  end

  defmodule NIF do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_initialization(name, _ctx) do
      ~g<#{name} = (UnifexPayload *) unifex_alloc(sizeof (UnifexPayload));>
    end

    @impl BaseType
    def generate_arg_serialize(name, _ctx) do
      ~g<unifex_payload_to_term(env, #{name})>
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, _ctx) do
      ~g<unifex_payload_from_term(env, #{arg}, #{var_name})>
    end

    @impl BaseType
    def generate_destruction(name, _ctx) do
      ~g<unifex_payload_release_ptr(&#{name});>
    end
  end

  defmodule CNode do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_initialization(name, _ctx) do
      ~g<#{name} = NULL;>
    end

    @impl BaseType
    def generate_arg_serialize(name, _ctx) do
      ~g<unifex_payload_encode(env, out_buff, #{name});>
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, _ctx) do
      ~g<unifex_payload_decode(env, #{arg}, &#{var_name})>
    end

    @impl BaseType
    def generate_destruction(name, _ctx) do
      ~g"""
      if(#{name} && !#{name}->owned) {
        unifex_payload_release(#{name});
      }
      """
    end
  end
end
