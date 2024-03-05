defmodule Unifex.CodeGenerator.BaseTypes.Uint64 do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for 64-bit unsigned integer.

  Maps `uint64` Unifex type to a `uint64_t` native type.

  Implemented both for NIF and CNode as function parameter as well as return type.
  """
  use Unifex.CodeGenerator.BaseType

  @impl true
  def generate_native_type(_ctx) do
    ~g<uint64_t>
  end

  defmodule CNode do
    @moduledoc false
    use Unifex.CodeGenerator.BaseType

    @impl true
    def generate_arg_parse(argument, name, _ctx) do
      ~g"""
      ({
        unsigned long long tmp_ulonglong;
        int result = ei_decode_ulonglong(#{argument}->buff, #{argument}->index, &tmp_ulonglong);
        #{name} = (uint64_t)tmp_ulonglong;
        result;
      })
      """
    end

    @impl true
    def generate_arg_serialize(name, _ctx) do
      ~g"""
      ({
      uint64_t tmp_int = #{name};
      ei_x_encode_ulonglong(out_buff, (long long)tmp_int);
      });
      """
    end
  end
end
