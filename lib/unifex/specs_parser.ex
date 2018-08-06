defmodule Unifex.SpecsParser do
  @config_store_name :unifex_config__

  def parse_specs(specs) do
    {_res, binds} = Code.eval_string(specs, [{@config_store_name, []}], make_env())
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

  # Returns clear __ENV__ with proper functions/macros imported. Useful for invoking
  # user code without possibly misleading macros and aliases from the current scope,
  # while providing needed functions/macros.
  defp make_env() do
    {env, _binds} =
      Code.eval_quoted(
        quote do
          import unquote(__MODULE__), only: [module: 1, spec: 1]
          __ENV__
        end
      )

    env
  end

  # Embeds code in a `quote` block. Useful when willing to store the code and parse
  # it in runtime instead of compile time.
  defp enquote(value) do
    {:quote, [], [[do: value]]}
  end
end
