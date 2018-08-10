defmodule Unifex.CodeGenerator.BaseType.Payload do
  alias Unifex.CodeGenerator.BaseType
  use BaseType

  @impl BaseType
  def generate_arg_serialize(name) do
    ~g<#{name}.term>
  end

  @impl BaseType
  def generate_native_type() do
    ~g<UnifexPayload>
  end

  @impl BaseType
  def generate_arg_parse(arg, var_name) do
    ~g<unifex_util_get_payload(env, #{arg}, &#{var_name})>
  end
end
