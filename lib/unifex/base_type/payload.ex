defmodule Unifex.BaseType.Payload do
  @moduledoc """
  Module implementing `Unifex.BaseType` behaviour for payloads.
  """
  alias Unifex.BaseType
  use BaseType

  @impl BaseType
  def generate_arg_serialize(name) do
    ~g<unifex_payload_to_term(env, #{name})>
  end

  @impl BaseType
  def generate_native_type() do
    ~g<UnifexPayload *>
  end

  @impl BaseType
  def generate_initialization(name) do
    ~g<#{name} = enif_alloc(sizeof (UnifexPayload));>
  end

  @impl BaseType
  def generate_destruction(name) do
    ~g<unifex_payload_release_ptr(&#{name});>
  end

  @impl BaseType
  def generate_arg_parse(arg, var_name) do
    ~g<unifex_payload_from_term(env, #{arg}, #{var_name})>
  end
end
