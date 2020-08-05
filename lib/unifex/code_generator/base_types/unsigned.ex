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
    @moduledoc false
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

  defmodule CNode do
    @moduledoc false
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, _ctx) do
      ~g"""
      ({
        unsigned int #{name}_uint = #{name};
        ei_x_encode_ulonglong(out_buff, (unsigned long long)#{name}_uint);
      });
      """
    end

    @impl BaseType
    def generate_arg_parse(argument, name, _ctx) do
      ~g"""
      ({
        unsigned long long #{name}_ulonglong;
        int result = ei_decode_ulonglong(#{argument}->buff, #{argument}->index, &#{name}_ulonglong);
        #{name} = (unsigned int)#{name}_ulonglong;
        result;
      })
      """
    end
  end
end
