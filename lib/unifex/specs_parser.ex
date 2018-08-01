defmodule Unifex.SpecsParser do
  @config_store_name :unifex_config__

  def parse_specs(specs) do
    {_res, binds} =
      Code.eval_string(
        specs,
        [{@config_store_name, []}],
        macros: [{__MODULE__, module: 1, spec: 1}] ++ Unifex.SpecsParser.Env.env().macros
      )

    binds |> Keyword.fetch!(@config_store_name) |> Enum.reverse()
  end

  defmacro module(module) do
    store_config(:module, module)
  end

  defmacro spec(spec) do
    store_config(:fun_specs, spec |> parse_fun_spec() |> enquote())
  end

  defp store_config(key, value) when is_atom(key) do
    config_store = Macro.var(@config_store_name, nil)

    quote generated: true do
      unquote(config_store) = [{unquote(key), unquote(value)} | unquote(config_store)]
    end
  end

  defp enquote(value) do
    {:quote, [], [[do: value]]}
  end

  defp parse_fun_spec({:::, _, [{fun_name, _, args}, results]}) do
    args =
      args
      |> Enum.map(fn
        {:::, _, [{name, _, _}, {type, _, _}]} -> {name, type}
        {name, _, _} -> {name, name}
      end)

    results =
      results
      |> parse_fun_spec_results_traverse_helper()

    {fun_name, args, results}
  end

  defp parse_fun_spec_results_traverse_helper({:|, _, [left, right]}) do
    parse_fun_spec_results_traverse_helper(left) ++ parse_fun_spec_results_traverse_helper(right)
  end

  defp parse_fun_spec_results_traverse_helper(value) do
    [value]
  end
end

defmodule Unifex.SpecsParser.Env do
  @moduledoc false
  def env, do: __ENV__
end
