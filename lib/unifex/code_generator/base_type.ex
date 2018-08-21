defmodule Unifex.CodeGenerator.BaseType do
  alias Unifex.CodeGenerator
  use CodeGenerator

  @type t :: atom

  @callback generate_arg_serialize(name :: atom) :: CodeGenerator.code_t()
  @callback generate_initialization(name :: atom) :: CodeGenerator.code_t()
  @callback generate_destruction(name :: atom) :: CodeGenerator.code_t()
  @callback generate_native_type() :: CodeGenerator.code_t()
  @callback generate_arg_parse(argument :: String.t(), variable :: String.t()) ::
              CodeGenerator.code_t()
  @callback generate_elixir_postprocessing(name :: atom) :: Macro.t()

  @optional_callbacks generate_arg_serialize: 1,
                      generate_initialization: 1,
                      generate_destruction: 1,
                      generate_native_type: 0,
                      generate_arg_parse: 2,
                      generate_elixir_postprocessing: 1

  defmacro __using__(_args) do
    quote do
      @behaviour unquote(__MODULE__)
      use Unifex.CodeGenerator
    end
  end

  def generate_arg_serialize({name, type}) do
    call(type, :generate_arg_serialize, [name], fn ->
      ~g<enif_make_#{type}(env, #{name})>
    end)
  end

  def generate_declaration({name, type}) do
    native_type = call(type, :generate_native_type, [], fn -> ~g<#{type}> end)
    ~g<#{native_type} #{name}>
  end

  def generate_initialization({name, type}) do
    call(type, :generate_initialization, [name], fn -> "" end)
  end

  def generate_destruction({name, type}) do
    call(type, :generate_destruction, [name], fn -> "" end)
  end

  def generate_arg_parse({{name, type}, i}) do
    argument = ~g<argv[#{i}]>

    arg_getter =
      call(type, :generate_arg_parse, [argument, name], fn ->
        ~g<enif_get_#{type}(env, #{argument}, &#{name})>
      end)

    initialization =
      case generate_initialization({name, type}) do
        "" -> ""
        non_empty -> non_empty <> ";"
      end

    ~g"""
    #{generate_declaration({name, type})};
    #{initialization}
    if(!#{arg_getter}) {
      return unifex_util_raise_args_error(env, "#{name}", "#{arg_getter}");
    }
    """
  end

  def generate_elixir_postprocessing({name, type}) do
    call(type, :generate_elixir_postprocessing, [name], fn ->
      Macro.var(name, nil)
    end)
  end

  defp call(type, callback, args, default_f) do
    module = Module.concat(__MODULE__, type |> to_string() |> String.capitalize())

    if !default_f ||
         (module |> Code.ensure_loaded?() and function_exported?(module, callback, length(args))) do
      apply(module, callback, args)
    else
      apply(default_f, [])
    end
  end
end