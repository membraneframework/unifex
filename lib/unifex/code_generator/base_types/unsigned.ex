defmodule Unifex.CodeGenerator.BaseTypes.Unsigned do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for unsigned int.
  """
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_native_type(_ctx) do
    ~g<unsigned int>
  end

  defmodule NIF do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, _ctx) do
      ~g<enif_make_uint(env, #{name})>
    end

    @impl BaseType
    def generate_arg_parse(arg_term, var_name, _ctx) do
      ~g<enif_get_uint(env, #{arg_term}, &#{var_name})>
    end
  end
end
