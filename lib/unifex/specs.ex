defmodule Unifex.Specs do
  @moduledoc """
  Module that handles parsing Unifex specs for native boilerplate code generation.

  For information on how to create such specs, see `Unifex.Specs.DSL` module.
  """

  @type t :: [
          {:module, module()}
          | {:fun_specs,
             {fun_name :: atom, [{arg_name :: atom, arg_type :: atom | {:list, atom}}],
              return_type :: Macro.t()}}
          | {:sends, sent_term_type :: Macro.t()}
          | {:dirty, [{{fun_name :: atom, fun_arity :: non_neg_integer}, :cpu | :io}]}
        ]

  @enforce_keys [
    :name,
    :module,
    :functions_args,
    :functions_results,
    :sends,
    :dirty_funs,
    :callbacks,
    :cnode_mode,
    :use_state
  ]

  defstruct @enforce_keys

  @doc """
  Parses Unifex specs of native functions.
  """
  @spec parse(specs_code :: String.t(), name :: String.t()) :: t()
  def parse(specs_code, name) do
    {_res, binds} = Code.eval_string(specs_code, [{:unifex_config__, []}], make_env())
    config = binds |> Keyword.fetch!(:unifex_config__) |> Enum.reverse()

    {functions_args, functions_results} =
      config
      |> Keyword.get_values(:function)
      |> Enum.map(fn {name, args, results} -> {{name, args}, {name, results}} end)
      |> Enum.unzip()

    functions_results =
      Enum.flat_map(functions_results, fn {name, results} -> Enum.map(results, &{name, &1}) end)

    %__MODULE__{
      name: name,
      module: Keyword.get(config, :module),
      functions_args: functions_args,
      functions_results: functions_results,
      sends: Keyword.get_values(config, :sends),
      dirty_funs: config |> Keyword.get_values(:dirty) |> List.flatten() |> Map.new(),
      callbacks: Keyword.get_values(config, :callbacks),
      cnode_mode: Keyword.get(config, :cnode_mode, false),
      use_state: Keyword.get(config, :use_state, false)
    }
  end

  # Returns clear __ENV__ with proper functions/macros imported. Useful for invoking
  # user code without possibly misleading macros and aliases from the current scope,
  # while providing needed functions/macros.
  defp make_env() do
    {env, _binds} =
      Code.eval_quoted(
        quote do
          import Unifex.Specs.DSL
          __ENV__
        end
      )

    env
  end
end
