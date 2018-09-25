defmodule Unifex.SpecsParser do
  @moduledoc """
  Module that handles parsing Unifex specs for native boilerplate code generation.

  ## Unifex specs
  The format for specs imitates Elixir specs. The example looks like this:

      module Membrane.Element.Mad.Decoder.Native

      spec create() :: {:ok :: label, state}

      spec decode_frame(payload, offset :: int, state) ::
             {:ok :: label, {payload, bytes_used :: long, sample_rate :: long, channels :: int}}
             | {:error :: label, :buflen :: label}
             | {:error :: label, :malformed :: label}
             | {:error :: label, {:recoverable :: label, bytes_to_skip :: int}}

      sends {:example_msg ::label, number :: int}

  It means that module `Membrane.Element.Mad.Decoder.Native` should contain 2 functions: `create/0`
  and `decode_frame/3`
  That module should use `Unifex.Loader` to provide access to these functions.

  The specs for functions (preceded by word `spec`) should contain function name, specs for parameters and then for
  the returned value.

  ## Parameters

  Specs for parameters can either take the form of `offset :: int` which will generate parameter with name `offset`
  and of type `int`. The other form - just a name, like `payload` - will generate parameter `payload` of type
  defined in `Unifex.BaseType.Payload` (which in this case is `UnifexPayload *`).

  More custom types can be added by creating modules `Unifex.BaseType.Type` that implement `Unifex.BaseType` behaviour.
  Then, they can by used in specs as `type`.

  Each generated function gets additional `UnifexEnv* env` as the first parameter implicitly.

  In the example above, the generated boilerplate would require implementation of the following functions:

      UNIFEX_TERM create(UnifexEnv* env);
      UNIFEX_TERM decode_frame(UnifexEnv* env, UnifexPayload * payload, int offset, State* state);


  ## Returned values

  Specs for returned values contain a special type - `label`. An atom of type `label` will be put literally in returned
  values by the special function generated for each spec. Names of the generated functions start with Elixir function name
  (e.g. `create`) followed by `_result_` part and then all the labels joined with `_`. So for the example above,
  genereted return functions will look like this:

      UNIFEX_TERM create_result_ok(UnifexEnv* env, State* state);
      UNIFEX_TERM decode_frame_result_ok(UnifexEnv* env, UnifexPayload * payload,
                                         long bytes_used, long sample_rate, int channels);
      UNIFEX_TERM decode_frame_result_error_buflen(UnifexEnv* env);
      UNIFEX_TERM decode_frame_result_error_malformed(UnifexEnv* env);
      UNIFEX_TERM decode_frame_result_error_recoverable(UnifexEnv* env, int bytes_to_skip);

  ## Messages that the nif sends

  Specs starting with `sends` keyword declare messages that the nif can send. The rules are similiar to ones for returned values,
  although prefix for all the genereted message-sending functions is simply `send_`
  For the example above there will be generated the following function:

      int send_example_msg(UnifexEnv* env, UnifexPid pid, int flags, int num);

  The value returned from `send_` functions is boolean indicating whether the send succeeded.
  """

  @type parsed_specs_t :: [{:module, module()} | {:fun_specs, tuple()}]

  @doc """
  Parses Unifex specs of native functions.
  """
  @spec parse_specs(specs :: Macro.t()) :: parsed_specs_t()
  def parse_specs(specs) do
    {_res, binds} = Code.eval_string(specs, [{:unifex_config__, []}], make_env())
    binds |> Keyword.fetch!(:unifex_config__) |> Enum.reverse()
  end

  # Returns clear __ENV__ with proper functions/macros imported. Useful for invoking
  # user code without possibly misleading macros and aliases from the current scope,
  # while providing needed functions/macros.
  defp make_env() do
    {env, _binds} =
      Code.eval_quoted(
        quote do
          import unquote(__MODULE__.Exports)
          __ENV__
        end
      )

    env
  end

  defmodule Exports do
    @doc """
    Macro used for defining module in Unifex specs
    """
    defmacro module(module) do
      store_config(:module, module)
    end

    @doc """
    Macro used for defining function spec in Unifex specs
    """
    defmacro spec(spec) do
      store_config(:fun_specs, spec |> parse_fun_spec() |> enquote())
    end

    @doc """
    Macro used for defining what can be sent from the native code to elixir processes.

    Creates native function that can be invoked to send specified data. Name of the
    function starts with `send_` and is constructed from `label`s.
    """
    defmacro sends(spec) do
      store_config(:sends, spec |> enquote())
    end

    defp store_config(key, value) when is_atom(key) do
      config_store = Macro.var(:unifex_config__, nil)

      quote generated: true do
        unquote(config_store) = [{unquote(key), unquote(value)} | unquote(config_store)]
      end
    end

    defp parse_fun_spec({:::, _, [{fun_name, _, args}, results]}) do
      args =
        args
        |> Enum.map(fn
          {:::, _, [{name, _, _}, [{type, _, _}]]} -> {name, {:list, type}}
          [{name, _, _}] -> {name, {:list, name}}
          {:::, _, [{name, _, _}, {type, _, _}]} -> {name, type}
          {name, _, _} -> {name, name}
        end)

      results =
        results
        |> parse_fun_spec_results_traverse_helper()

      {fun_name, args, results}
    end

    defp parse_fun_spec_results_traverse_helper({:|, _, [left, right]}) do
      parse_fun_spec_results_traverse_helper(left) ++
        parse_fun_spec_results_traverse_helper(right)
    end

    defp parse_fun_spec_results_traverse_helper(value) do
      [value]
    end

    # Embeds code in a `quote` block. Useful when willing to store the code and parse
    # it in runtime instead of compile time.
    defp enquote(value) do
      {:quote, [], [[do: value]]}
    end
  end
end
