defmodule Unifex.CodeGenerator.BaseTypes.Int do
  defmodule CNode do
    alias Unifex.CodeGenerator.BaseType
    use BaseType

    @impl BaseType
    def generate_arg_parse(_argument, name, _ctx) do
      ~g<ei_decode_longlong(in_buff, index, &((long long)#{name}));>
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
