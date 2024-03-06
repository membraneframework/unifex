defmodule Unifex.CodeGenerator.BaseTypes.Int64 do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for 64-bit integer.

  Maps `int64` Unifex type to an `int64_t` native type.

  Implemented both for NIF and CNode as function parameter as well as return type.
  """
  use Unifex.CodeGenerator.BaseType

  @impl true
  def generate_native_type(_ctx) do
    ~g<int64_t>
  end

  defmodule NIF do
    @moduledoc false
    use Unifex.CodeGenerator.BaseType

    @impl true
    def generate_arg_parse(argument, variable, _ctx) do
      ~g<({
        ErlNifSInt64 temp = 0;
        int success = enif_get_int64(env, #{argument}, &temp);
        #{variable} = (int64_t)temp;
        success;
        })>
    end
  end

  defmodule CNode do
    @moduledoc false
    use Unifex.CodeGenerator.BaseType

    @impl true
    def generate_arg_parse(argument, name, _ctx) do
      ~g"""
      ({
        long long tmp_longlong;
        int result = ei_decode_longlong(#{argument}->buff, #{argument}->index, &tmp_longlong);
        #{name} = (int64_t)tmp_longlong;
        result;
      })
      """
    end

    @impl true
    def generate_arg_serialize(name, _ctx) do
      ~g<ei_x_encode_longlong(out_buff, (long long)#{name});>
    end
  end
end
