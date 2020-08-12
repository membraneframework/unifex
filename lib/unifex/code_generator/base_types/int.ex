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
        long long tmp_longlong;
        int result = ei_decode_longlong(#{argument}->buff, #{argument}->index, &tmp_longlong);
        #{name} = (int)tmp_longlong;
        result;
      })
      """
    end

    @impl BaseType
    def generate_arg_serialize(name, _ctx) do
      ~g"""
      ({
      ei_x_encode_longlong(out_buff, (long long)#{name});
      });
      """
    end
  end
end
