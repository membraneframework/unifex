defmodule Unifex.CodeGenerator.BaseTypes.Payload do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for payloads.
  """
  alias Unifex.CodeGenerator.BaseType
  use BaseType

  @impl BaseType
  def generate_arg_serialize(name, _ctx) do
    ~g<unifex_payload_to_term(env, #{name})>
  end

  @impl BaseType
  def generate_native_type(_ctx) do
    ~g<UnifexPayload *>
  end

  @impl BaseType
  def generate_initialization(name, _ctx) do
    ~g<#{name} = (UnifexPayload *) enif_alloc(sizeof (UnifexPayload));>
  end

  @impl BaseType
  def generate_destruction(name, _ctx) do
    ~g<unifex_payload_release_ptr(&#{name});>
  end

  @impl BaseType
  def generate_arg_parse(arg, var_name, _ctx) do
    ~g<unifex_payload_from_term(env, #{arg}, #{var_name})>
  end
end
