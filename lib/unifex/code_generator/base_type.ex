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

  @optional_callbacks generate_arg_serialize: 2,
                      generate_initialization: 2,
                      generate_destruction: 2,
                      generate_native_type: 1,
                      generate_arg_parse: 3

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
      code_generator
    )
  end

  @doc """
  Generates a declaration of parameter (to be placed in function header) based on `c:generate_native_type/0` and
  provided `name`.

  Uses `type` as fallback for `c:generate_native_type/1`
  """
  # @spec generate_declaration(t, name :: atom) :: [CodeGenerator.code_t()]
  def generate_declaration(type, name, mode \\ :default, code_generator) do
    generate_native_type(type, mode, code_generator)
    |> Bunch.listify()
    |> Enum.map(fn
      {type, sufix} -> ~g<#{type} #{name}#{sufix}>
      type -> ~g<#{type} #{name}>
    end)
  end

  @doc """
  Generates an initialization of variable content. Should be paired with `generate_destruction/1`

  Returns an empty string if the type does not provide initialization
  """
  # @spec generate_initialization(t, name :: atom) :: CodeGenerator.code_t()
  def generate_initialization(type, name, code_generator) do
    call(type, :generate_initialization, [name], code_generator)
  end

  @doc """
  Generates an destrucition of variable content. Should be paired with `generate_initialization/1`

  Returns an empty string if the type does not provide destructor
  """
  # @spec generate_destruction(t, name :: atom) :: CodeGenerator.code_t()
  def generate_destruction(type, name, code_generator) do
    call(type, :generate_destruction, [name], code_generator)
  end

  @doc """
  Generates parsing of UNIFEX_TERM `argument` into the native variable
  """
  def generate_arg_parse(type, name, argument, postproc_fun \\ & &1, code_generator) do
    call(
      type,
      :generate_arg_parse,
      [argument, name],
      code_generator,
      %{postproc_fun: postproc_fun}
    )
    |> postproc_fun.()
  end

  def generate_arg_name(type, name, code_generator) do
    generate_native_type(type, code_generator)
    |> Bunch.listify()
    |> Enum.map(fn
      {_type, sufix} -> ~g<#{name}#{sufix}>
      _type -> ~g<#{name}>
    end)
  end

  def generate_native_type(type, mode \\ :default, code_generator) do
    call(type, :generate_native_type, [], code_generator, %{mode: mode})
  end

  defp call(full_type, callback, args, code_generator, ctx \\ %{}) do
    {type, subtype} =
      case full_type do
        {type, subtype} -> {type, subtype}
        type -> {type, nil}
      end

    module =
      Module.concat(Unifex.CodeGenerator.BaseTypes, type |> to_string() |> String.capitalize())

    gen_aware_module = Module.concat(module, code_generator)

    default_gen_aware_module =
      Module.concat(Unifex.CodeGenerator.BaseTypes.Default, code_generator)

    args =
      args ++ [Map.merge(%{generator: code_generator, type: full_type, subtype: subtype}, ctx)]

    [gen_aware_module, module, default_gen_aware_module]
    |> Enum.find(
      Unifex.CodeGenerator.BaseTypes.Default,
      &(Code.ensure_loaded?(&1) and function_exported?(&1, callback, length(args)))
    )
    |> apply(callback, args)
  end
end
