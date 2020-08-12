defmodule Unifex.CodeGenerator.BaseTypes.String do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for strings.

  They are represented by NULL-terminated char arrays.
  """
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_native_type(ctx) do
    prefix = if ctx.mode == :const, do: "const ", else: ""
    ~g<#{prefix}char*>
  end

  @impl BaseType
  def generate_initialization(name, _ctx) do
    ~g<#{name} = NULL;>
  end

  @impl BaseType
  def generate_destruction(name, _ctx) do
    ~g<unifex_free(#{name});>
  end

  defmodule NIF do
    @moduledoc false
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, _ctx) do
      ~g<unifex_string_to_term(env, #{name})>
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, _ctx) do
      ~g<unifex_string_from_term(env, #{arg}, &#{var_name})>
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
        int str_len = strlen(#{name});
        ei_x_encode_binary(out_buff, #{name}, str_len);
      });
      """
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, _ctx) do
      ~g"""
      ({
        int type;
        int size;
        ei_get_type(#{arg}->buff, #{arg}->index, &type, &size);
        size = size + 1; // for NULL byte
        ei_decode_binary(#{arg}->buff, #{arg}->index, #{var_name}, (long *)&size);
      })
      """
    end
  end
end
