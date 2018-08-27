defmodule Unifex.CodeGenerator.BaseType do
  @moduledoc """
  This mocule provides different generators allowing to map the types from Unifex specs into proper native types

  The generators from this module are trying to delegate the calls to the callbacks in modules adequate for the type
  but provide fallback values (all the callbacks are optional)
  """
  alias Unifex.CodeGenerator
  use CodeGenerator

  @type t :: atom
  @type spec_tuple_t :: {name :: atom(), type :: atom()}
  @type arg_parse_ctx_t :: %{
          result_var: CodeGenerator.code_t(),
          exit_label: CodeGenerator.code_t()
        }

  @doc """
  Provides a way to convert native variable `name` into `UNIFEX_TERM`
  """
  @callback generate_arg_serialize(name :: atom) :: CodeGenerator.code_t()

  @doc """
  Generates a declaration of variable holding parsed value of UNIFEX_TERM. May include initialization.
  """
  @callback generate_parsed_arg_declaration(name :: atom) :: CodeGenerator.code_t()

  @doc """
  Generates an allocation of variable content. Should be paired with `c:generate_destruction/1`
  """
  @callback generate_allocation(name :: atom) :: CodeGenerator.code_t()

  @doc """
  Generates a destrucition of variable content. Should be paired with `c:generate_allocation/1`
  """
  @callback generate_destruction(name :: atom) :: CodeGenerator.code_t()

  @doc """
  Generates a native type. 
  """
  @callback generate_native_type() :: CodeGenerator.code_t()

  @doc """
  Generates function call parsing UNIFEX_TERM `argument` into the native variable with name `variable`. Function should
  return boolean value.
  """
  @callback generate_arg_parse(argument :: String.t(), variable :: String.t()) ::
              CodeGenerator.code_t()

  @doc """
  Generates Elixir post-processing of the value returned from native function.

  Should return quoted code. The value can be referenced using `Macro.var/2` call.
  Useful when some call cannot be made from native code (e.g. call to another NIF from NIF)
  """
  @callback generate_elixir_postprocessing(name :: atom) :: Macro.t()

  @optional_callbacks generate_arg_serialize: 1,
                      generate_parsed_arg_declaration: 1,
                      generate_allocation: 1,
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

  @doc """
  Provides a way to convert native variable `name` into `UNIFEX_TERM`

  Tries to get value from type-specific module, uses `enif_make_\#\{type}` as fallback value.
  """
  @spec generate_arg_serialize(spec_tuple_t()) :: CodeGenerator.code_t()
  def generate_arg_serialize({name, type}) do
    call(type, :generate_arg_serialize, [name], fn ->
      ~g<enif_make_#{type}(env, #{name})>
    end)
  end

  @doc """
  Generates a declaration of parameter (to be placed in function header) based on `c:generate_native_type/1` and 
  provided `name`.

  Uses `type` as fallback for `c:generate_native_type/1`
  """
  @spec generate_parameter_declaration(spec_tuple_t()) :: CodeGenerator.code_t()
  def generate_parameter_declaration({name, type}) do
    native_type = call(type, :generate_native_type, [], fn -> ~g<#{type}> end)
    ~g<#{native_type} #{name}>
  end

  @doc """
  Generates a declaration of variable holding parsed value of UNIFEX_TERM. May include initialization.

  Tries to get value from type-specific module, uses parameter declaration with `;` as fallback value.
  """
  @spec generate_parsed_arg_declaration(spec_tuple_t()) :: CodeGenerator.code_t()
  def generate_parsed_arg_declaration({name, type}) do
    call(type, :generate_parsed_arg_declaration, [name], fn ->
      generate_parameter_declaration({name, type}) <> ";"
    end)
  end

  @doc """
  Generates an allocation of variable content. Should be paired with `generate_destruction/1`

  Returns an empty string if the type does not provide allocation
  """
  @spec generate_allocation(spec_tuple_t()) :: CodeGenerator.code_t()
  def generate_allocation({name, type}) do
    call(type, :generate_allocation, [name], fn -> "" end)
  end

  @doc """
  Generates an destrucition of variable content. Should be paired with `generate_allocation/1`

  Returns an empty string if the type does not provide destructor
  """
  @spec generate_destruction(spec_tuple_t()) :: CodeGenerator.code_t()
  def generate_destruction({name, type}) do
    call(type, :generate_destruction, [name], fn -> "" end)
  end

  @doc """
  Generates parsing of UNIFEX_TERM `argument` into the native variable
  """
  @spec generate_arg_parse({spec_tuple_t(), i :: non_neg_integer()}, ctx :: arg_parse_ctx_t()) ::
          CodeGenerator.code_t()
  def generate_arg_parse({{name, type}, i}, ctx) do
    argument = ~g<argv[#{i}]>

    arg_getter =
      call(type, :generate_arg_parse, [argument, name], fn ->
        ~g<enif_get_#{type}(env, #{argument}, &#{name})>
      end)

    ~g"""
    #{generate_allocation({name, type})}
    if(!#{arg_getter}) {
      #{ctx.result_var} = unifex_util_raise_args_error(env, "#{name}", "#{arg_getter}");
      goto #{ctx.exit_label};
    }
    """
  end

  @doc """
  Generates Elixir post-processing of the value returned from native function.

  Fallbacks to simply passing the value (as variable reference)
  """
  @spec generate_elixir_postprocessing(spec_tuple_t()) :: CodeGenerator.code_t()
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
