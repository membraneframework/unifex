defmodule Unifex.CodeGenerator.BaseType.Payload do
  alias Unifex.CodeGenerator.BaseType
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
    ~g<#{name} = enif_alloc(sizeof (UnifexPayload))>
  end

  @impl BaseType
  def generate_destruction(name) do
    ~g<unifex_payload_free_ptr(&#{name})>
  end

  @impl BaseType
  def generate_arg_parse(arg, var_name) do
    ~g<unifex_util_payload_from_term(env, #{arg}, #{var_name})>
  end
end
