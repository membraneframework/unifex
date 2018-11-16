defmodule Unifex.BaseType do
  @moduledoc """
  This module provides different generators allowing to map the types from Unifex specs into proper native types

  The generators from this module are trying to delegate the calls to the callbacks in modules adequate for the type
  but provide fallback values (all the callbacks are optional)
  """
  alias Unifex.NativeCodeGenerator
  use NativeCodeGenerator

  @type t :: atom | {:list, atom}
  @type spec_tuple_t :: {name :: atom(), type :: t}
  @type arg_parse_ctx_t :: %{
          result_var: NativeCodeGenerator.code_t(),
          exit_label: NativeCodeGenerator.code_t()
        }

  @doc """
  Provides a way to convert native variable `name` into `UNIFEX_TERM`
  """
  @callback generate_arg_serialize(name :: atom) :: NativeCodeGenerator.code_t()

  @doc """
  Generates an initialization of variable content. Should be paired with `c:generate_destruction/1`
  """
  @callback generate_initialization(name :: atom) :: NativeCodeGenerator.code_t()

  @doc """
  Generates a destruction of variable content. Should be paired with `c:generate_initialization/1`
  """
  @callback generate_destruction(name :: atom) :: NativeCodeGenerator.code_t()

  @doc """
  Generates a native counterpart for the type.
  """
  @callback generate_native_type() :: NativeCodeGenerator.code_t()

  @doc """
  Generates an expression that will return how many bytes should be allocated for this type.
  """
  @callback generate_sizeof() :: NativeCodeGenerator.code_t()

  @doc """
  Generates function call parsing UNIFEX_TERM `argument` into the native variable with name `variable`. Function should
  return boolean value.
  """
  @callback generate_arg_parse(argument :: String.t(), variable :: String.t()) ::
              NativeCodeGenerator.code_t()

  @doc """
  Generates Elixir post-processing of the value returned from native function.

  Should return quoted code. The value can be referenced using `Macro.var/2` call.
  Useful when some call cannot be made from native code (e.g. call to another NIF from NIF)
  """
  @callback generate_elixir_postprocessing(name :: atom) :: Macro.t()

  @optional_callbacks generate_arg_serialize: 1,
                      generate_initialization: 1,
                      generate_destruction: 1,
                      generate_native_type: 0,
                      generate_sizeof: 0,
                      generate_arg_parse: 2,
                      generate_elixir_postprocessing: 1

  defmacro __using__(_args) do
    quote do
      @behaviour unquote(__MODULE__)
      use Unifex.NativeCodeGenerator
    end
  end

  @doc """
  Provides a way to convert native variable `name` into `UNIFEX_TERM`

  Tries to get value from type-specific module, uses `enif_make_\#\{type}` as fallback value.
  """
  @spec generate_arg_serialize(spec_tuple_t()) :: NativeCodeGenerator.code_t()
  def generate_arg_serialize({name, {:list, type}}) do
    ~g"""
    ({
      ERL_NIF_TERM list = enif_make_list(env, 0);
      for(int i = #{name}_length-1; i >= 0; i--) {
        list = enif_make_list_cell(
          env,
          #{generate_arg_serialize({:"#{name}[i]", type})},
          list
        );
      }
      list;
    })
    """t
  end

  def generate_arg_serialize({name, type}) do
    call(type, :generate_arg_serialize, [name], fn ->
      ~g<enif_make_#{type}(env, #{name})>
    end)
  end

  @doc """
  Generates a declaration of parameter (to be placed in function header) based on `c:generate_native_type/0` and
  provided `name`.

  Uses `type` as fallback for `c:generate_native_type/1`
  """
  @spec generate_declaration(spec_tuple_t()) :: [NativeCodeGenerator.code_t()]
  def generate_declaration({name, {:list, type}}) do
    do_generate_declaration(name, {:list, type}) ++ [~g<unsigned int #{name}_length>]
  end

  def generate_declaration({name, type}) do
    do_generate_declaration(name, type)
  end

  defp do_generate_declaration(name, type) do
    [~g<#{call_generate_native_type(type)} #{name}>]
  end

  @doc """
  Generates an initialization of variable content. Should be paired with `generate_destruction/1`

  Returns an empty string if the type does not provide initialization
  """
  @spec generate_initialization(spec_tuple_t()) :: NativeCodeGenerator.code_t()
  def generate_initialization({name, {:list, _type}}) do
    ~g<#{name} = NULL;>
  end

  def generate_initialization({name, type}) do
    call(type, :generate_initialization, [name], fn -> "" end)
  end

  @doc """
  Generates an destrucition of variable content. Should be paired with `generate_initialization/1`

  Returns an empty string if the type does not provide destructor
  """
  @spec generate_destruction(spec_tuple_t()) :: NativeCodeGenerator.code_t()
  def generate_destruction({name, {:list, type}}) do
    ~g"""
    if(#{name} != NULL) {
      for(unsigned int i = 0; i < #{name}_length; i++) {
        #{generate_destruction({:"#{name}[i]", type})}
      }
      enif_free(#{name});
    }
    """t
  end

  def generate_destruction({name, type}) do
    call(type, :generate_destruction, [name], fn -> "" end)
  end

  @doc """
  Generates parsing of UNIFEX_TERM `argument` into the native variable
  """
  @spec generate_arg_parse({spec_tuple_t(), i :: non_neg_integer()}, ctx :: arg_parse_ctx_t()) ::
          NativeCodeGenerator.code_t()
  def generate_arg_parse({{name, {:list, type}}, i}, ctx) do
    elem_name = :"#{name}[i]"
    len_var_name = "#{name}_length"
    argument = ~g<argv[#{i}]>

    ~g"""
    if(!enif_get_list_length(env, #{argument}, &#{len_var_name})){
      #{ctx.result_var} = unifex_raise_args_error(env, "#{name}", "enif_get_list_length");
      goto #{ctx.exit_label};
    }
    #{name} = enif_alloc(sizeof(#{call_generate_native_type(type)}) * #{len_var_name});

    for(unsigned int i = 0; i < #{len_var_name}; i++) {
      #{generate_initialization({elem_name, type})}
    }

    ERL_NIF_TERM list = #{argument};
    for(unsigned int i = 0; i < #{len_var_name}; i++) {
      ERL_NIF_TERM elem;
      enif_get_list_cell(env, list, &elem, &list);
      #{do_generate_arg_parse(elem_name, type, ~g<elem>, ctx) |> gen('i')}
    }
    """t
  end

  def generate_arg_parse({{name, type}, i}, ctx) do
    do_generate_arg_parse(name, type, ~g<argv[#{i}]>, ctx)
  end

  defp do_generate_arg_parse(name, type, argument, ctx) do
    arg_getter =
      call(type, :generate_arg_parse, [argument, name], fn ->
        ~g<enif_get_#{type}(env, #{argument}, &#{name})>
      end)

    ~g"""
    if(!#{arg_getter}) {
      #{ctx.result_var} = unifex_raise_args_error(env, "#{name}", "#{arg_getter}");
      goto #{ctx.exit_label};
    }
    """t
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
    call(type, :generate_elixir_postprocessing, [name], fn ->
      Macro.var(name, nil)
    end)
  end

  defp call_generate_native_type({:list, type}) do
    ~g<#{call_generate_native_type(type)}*>
  end

  defp call_generate_native_type(type) do
    call(type, :generate_native_type, [], fn -> ~g<#{type}> end)
  end

  defp call({:list, _type}, _callback, _args, default_f) do
    apply(default_f, [])
  end

  defp call(type, callback, args, default_f) do
    module = Module.concat(__MODULE__, type |> to_string() |> String.capitalize())

    if module |> Code.ensure_loaded?() and function_exported?(module, callback, length(args)) do
      apply(module, callback, args)
    else
      apply(default_f, [])
    end
  end
end
