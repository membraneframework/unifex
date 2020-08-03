defmodule Unifex.CodeGenerator.BaseTypes.Int do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for integers.
  """

  defmodule CNode do
    @moduledoc false
    alias Unifex.CodeGenerator.BaseType
    use BaseType

    @impl BaseType
    def generate_arg_parse(argument, name, _ctx) do
      ~g"""
      ({
        long long #{name}_longlong;
        int result = ei_decode_longlong(#{argument}->buff, #{argument}->index, &#{name}_longlong);
        #{name} = (int)#{name}_longlong;
        result;
      })
      """
    end

    @impl BaseType
    def generate_arg_serialize(name, _ctx) do
      ~g"""
      ({
      int #{name}_int = #{name};
      ei_x_encode_longlong(out_buff, (long long)#{name}_int);
      });
      """
    end
  end
end
