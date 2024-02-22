defmodule Unifex.CodeGenerator.BaseTypes.Int64 do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for 64-bit integer.

  Maps `int64` Unifex type to an `int64_t` native type.

  Implemented only for NIF as function parameter as well as return type.
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
    def generate_arg_parse(argument, variable, ctx) do
      ~g<({
        ErlNifSInt64 temp = 0;
        int success = enif_get_int64(env, #{argument}, &temp);
        #{variable} = (int64_t)temp;
        success;
        })>
    end
  end
end
