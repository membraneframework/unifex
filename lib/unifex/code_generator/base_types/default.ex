defmodule Unifex.CodeGenerator.BaseTypes.Default do
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_native_type(ctx) do
    ~g<#{ctx.type}>
  end

  @impl BaseType
  def generate_initialization(_name, _ctx) do
    ""
  end

  @impl BaseType
  def generate_destruction(_name, _ctx) do
    ""
  end

  defmodule NIF do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      ~g<enif_make_#{ctx.type}(env, #{name})>
    end

    @impl BaseType
    def generate_arg_parse(argument, variable, ctx) do
      ~g<enif_get_#{ctx.type}(env, #{argument}, &#{variable})>
    end
  end

  defmodule CNode do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_parse(_argument, name, ctx) do
      ~g<ei_decode_#{ctx.type}(in_buff, index, &#{name});>
    end

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      ~g<ei_x_encode_#{ctx.type}(out_buff, #{name});>
    end
  end
end
