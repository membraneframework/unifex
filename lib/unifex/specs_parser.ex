defmodule Unifex.SpecsParser do
  @moduledoc """
  Module that handles parsing Unifex specs for native boilerplate code generation.

  For information on how to create such specs, see `Unifex.Specs` module.
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
          import Unifex.Specs
          __ENV__
        end
      )

    env
  end
end
