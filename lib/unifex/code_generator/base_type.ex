defmodule Unifex.CodeGenerator.BaseType do
  alias Unifex.CodeGenerator
  use CodeGenerator

  @type t :: atom

  @callback generate_term_maker(name :: atom) :: CodeGenerator.code_t()
  @callback generate_declaration(name :: atom) :: CodeGenerator.code_t()
  @callback generate_arg_parse(name :: atom, arg_no :: integer) :: CodeGenerator.code_t()

  @optional_callbacks generate_term_maker: 1, generate_declaration: 1, generate_arg_parse: 2

  defmacro __using__(_args) do
    quote do
      @behaviour unquote(__MODULE__)
      use Unifex.CodeGenerator
    end
  end

  def generate_term_maker({name, type}) do
    call(type, :generate_term_maker, [name], fn type, name ->
      ~g<enif_make_#{type}(env-\>nif_env, #{name})>
    end)
  end

  def generate_declaration({name, type}) do
    call(type, :generate_declaration, [name], fn type, name -> ~g<#{type} #{name}> end)
  end

  def generate_arg_parse({{name, type}, i}) do
    call(type, :generate_arg_parse, [name, i], fn type, name, i ->
      ~g<UNIFEX_UTIL_PARSE_#{"#{type}" |> String.upcase()}_ARG(#{i}, #{name});>
    end)
  end

  defp call(type, callback, args, default_f) do
    module = Module.concat(__MODULE__, type |> to_string() |> String.capitalize())

    if !default_f ||
         (module |> Code.ensure_loaded?() and function_exported?(module, callback, length(args))) do
      apply(module, callback, args)
    else
      apply(default_f, [type | args])
    end
  end
end
