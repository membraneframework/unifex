defmodule Unifex.CodeGenerator.BaseType do
  @moduledoc """
  This module provides different generators allowing to map the types from Unifex specs into proper native types

  The generators from this module are trying to delegate the calls to the callbacks in modules adequate for the type
  but provide fallback values (all the callbacks are optional)
  """
  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]
  alias Unifex.CodeGenerator

  @type t :: atom | {:list, atom}
  @type spec_tuple_t :: {name :: atom(), type :: t}
  @type arg_parse_ctx_t :: %{
          result_var: CodeGenerator.code_t(),
          exit_label: CodeGenerator.code_t()
        }

  @doc """
  Provides a way to convert native variable `name` into `UNIFEX_TERM`
  """
  @callback generate_arg_serialize(name :: atom, ctx :: map) :: CodeGenerator.code_t()

  @doc """
  Generates an initialization of variable content. Should be paired with `c:generate_destruction/1`
  """
  @callback generate_initialization(name :: atom, ctx :: map) :: CodeGenerator.code_t()

  @doc """
  Generates a destruction of variable content. Should be paired with `c:generate_initialization/1`
  """
  @callback generate_destruction(name :: atom, ctx :: map) :: CodeGenerator.code_t()

  @doc """
  Generates a native counterpart for the type.
  """
  @callback generate_native_type(ctx :: map) :: CodeGenerator.code_t()

  @doc """
  Generates function call parsing UNIFEX_TERM `argument` into the native variable with name `variable`. Function should
  return boolean value.
  """
  @callback generate_arg_parse(
              argument :: String.t(),
              variable :: String.t(),
              ctx :: map
            ) ::
              CodeGenerator.code_t()

  @doc """
  Generates Elixir post-processing of the value returned from native function.

  Should return quoted code. The value can be referenced using `Macro.var/2` call.
  Useful when some call cannot be made from native code (e.g. call to another NIF from NIF)
  """
  @callback generate_elixir_postprocessing(name :: atom) :: Macro.t()

  @optional_callbacks generate_arg_serialize: 2,
                      generate_initialization: 2,
                      generate_destruction: 2,
                      generate_native_type: 1,
                      generate_arg_parse: 3,
                      generate_elixir_postprocessing: 1

  defmacro __using__(_args) do
    quote do
      @behaviour unquote(__MODULE__)
      import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]
    end
  end

  @doc """
  Provides a way to convert native variable `name` into `UNIFEX_TERM`

  Tries to get value from type-specific module, uses `enif_make_\#\{type}` as fallback value.
  """
  # @spec generate_arg_serialize(t, name :: atom) :: CodeGenerator.code_t()
  def generate_arg_serialize(type, name, code_generator) do
    call(
      type,
      :generate_arg_serialize,
      [name],
      fn ->
        ~g<enif_make_#{type}(env, #{name})>
      end,
      code_generator
    )
  end

  @doc """
  Generates a declaration of parameter (to be placed in function header) based on `c:generate_native_type/0` and
  provided `name`.

  Uses `type` as fallback for `c:generate_native_type/1`
  """
  # @spec generate_declaration(t, name :: atom) :: [CodeGenerator.code_t()]
  def generate_declaration(type, name, code_generator) do
    [~g<#{generate_native_type(type, code_generator)} #{name}>]
  end

  @doc """
  Generates an initialization of variable content. Should be paired with `generate_destruction/1`

  Returns an empty string if the type does not provide initialization
  """
  # @spec generate_initialization(t, name :: atom) :: CodeGenerator.code_t()
  def generate_initialization(type, name, code_generator) do
    call(type, :generate_initialization, [name], fn -> "" end, code_generator)
  end

  @doc """
  Generates an destrucition of variable content. Should be paired with `generate_initialization/1`

  Returns an empty string if the type does not provide destructor
  """
  # @spec generate_destruction(t, name :: atom) :: CodeGenerator.code_t()
  def generate_destruction(type, name, code_generator) do
    call(type, :generate_destruction, [name], fn -> "" end, code_generator)
  end

  @doc """
  Generates parsing of UNIFEX_TERM `argument` into the native variable
  """
  def generate_arg_parse(type, name, argument, postproc_fun, code_generator) do
    call(
      type,
      :generate_arg_parse,
      [argument, name],
      fn ->
        ~g<enif_get_#{type}(env, #{argument}, &#{name})>
      end,
      code_generator,
      %{postproc_fun: postproc_fun}
    )
    |> postproc_fun.()
  end

  def generate_arg_name({name, {:list, _type}}) do
    [~g<#{name}>, ~g<#{name}_length>]
  end

  def generate_arg_name({name, _type}) do
    [~g<#{name}>]
  end

  @doc """
  Generates Elixir post-processing of the value returned from native function.

  Fallbacks to simply passing the value (as variable reference)
  """
  @spec generate_elixir_postprocessing(spec_tuple_t()) :: Macro.t()
  def generate_elixir_postprocessing({name, type}) do
    call(
      type,
      :generate_elixir_postprocessing,
      [name],
      fn ->
        Macro.var(name, nil)
      end,
      nil
    )
  end

  def generate_native_type(type, code_generator) do
    call(type, :generate_native_type, [], fn -> ~g<#{type}> end, code_generator)
  end

  defp call(type, callback, args, default_f, code_generator, ctx \\ %{}) do
    module =
      Module.concat(Unifex.CodeGenerator.BaseTypes, type |> to_string() |> String.capitalize())

    gen_aware_module = Module.concat(module, code_generator)
    args = args ++ [Map.merge(%{generator: code_generator, type: type}, ctx)]

    cond do
      Code.ensure_loaded?(gen_aware_module) and
          function_exported?(gen_aware_module, callback, length(args)) ->
        apply(gen_aware_module, callback, args)

      Code.ensure_loaded?(module) and function_exported?(module, callback, length(args)) ->
        apply(module, callback, args)

      true ->
        apply(default_f, [])
    end
  end

  @doc """
  Adds 'const' keyword to pointer types, except for state pointer
  """
  @spec make_ptr_const(declaration :: String.t()) :: String.t()
  def make_ptr_const(declaration) do
    state_type = generate_native_type(:state, NIF)

    if String.match?(declaration, ~r<\*>) and not String.contains?(declaration, state_type) do
      "const " <> declaration
    else
      declaration
    end
  end
end
