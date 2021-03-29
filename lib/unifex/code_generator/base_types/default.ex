defmodule Unifex.CodeGenerator.BaseTypes.Default do
  @moduledoc """
  Default `Unifex.CodeGenerator.BaseType` implementation for all types.

  If a callback is not implemented in a type-specific implementation,
  it defaults to this one.
  """
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_native_type(ctx) do
    ~g<#{ctx.type}>
    |> IO.inspect(label: "generate_native_type from #{__MODULE__}")
  end

  @impl BaseType
  def generate_initialization(_name, _ctx) do
    ""
    |> IO.inspect(label: "generate_initialization from #{__MODULE__}")
  end

  @impl BaseType
  def generate_destruction(_name, _ctx) do
    ""
    |> IO.inspect(label: "generate_destruction from #{__MODULE__}")
  end

  defmodule NIF do
    @moduledoc false
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      ~g<enif_make_#{ctx.type}(env, #{name})>
      |> IO.inspect(label: "generate_arg_serialize from #{__MODULE__}")
    end

    @impl BaseType
    def generate_arg_parse(argument, variable, ctx) do
      ~g<enif_get_#{ctx.type}(env, #{argument}, &#{variable})>
      |> IO.inspect(label: "generate_arg_parse from #{__MODULE__}")
    end
  end

  defmodule CNode do
    @moduledoc false
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_parse(argument, name, ctx) do
      ~g<ei_decode_#{ctx.type}(#{argument}-\>buff, #{argument}-\>index, &#{name})>
      |> IO.inspect(label: "generate_arg_parse from #{__MODULE__}")
    end

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      ~g<ei_x_encode_#{ctx.type}(out_buff, #{name});>
      |> IO.inspect(label: "generate_arg_serialize from #{__MODULE__}")
    end
  end
end
