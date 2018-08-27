defmodule Unifex.ResultsParser do
  @moduledoc false
  alias Unifex.CodeGenerator.BaseType

  def parse_return_specs(rt) do
    rt |> Enum.map(&parse_case/1)
  end

  defp parse_case({{:::, [], [:ok, {:label, _, _}]}, result}) do
    {[{:ok, :atom}, parse_result(result)], :tuple}
  end

  defp parse_case({{:::, [], [:error, {:label, _, _}]}, reason}) do
    {[{:error, :atom}, parse_result(reason)], :tuple}
  end

  defp parse_result({:::, _, [left, right]}) do
    {parse_var(left), parse_type(right)}
  end

  defp parse_result({:{}, _, list}) when is_list(list) do
    {list |> Enum.map(&parse_result/1), :tuple}
  end

  defp parse_result({left, right}) do
    {[parse_result(left), parse_result(right)], :tuple}
  end

  defp parse_result({atom, _, Elixir}) when is_atom(atom) do
    {atom, atom}
  end

  defp parse_type({:label, _, Elixir}) do
    :atom
  end

  defp parse_type({atom, _, Elixir}) when is_atom(atom) do
    atom
  end

  defp parse_var({atom, _, Elixir}) when is_atom(atom) do
    atom
  end

  defp parse_var(atom) when is_atom(atom) do
    atom
  end

  def generate_pattern_ast({atom, :atom}) do
    atom
  end

  def generate_pattern_ast({val_list, :tuple}) do
    {:{}, [], val_list |> Enum.map(&generate_pattern_ast/1)}
  end

  def generate_pattern_ast({var, _type}) do
    Macro.var(var, nil)
  end

  def generate_postprocessing_ast({val_list, :tuple}) do
    {:{}, [], val_list |> Enum.map(&generate_postprocessing_ast/1)}
  end

  def generate_postprocessing_ast({atom, :atom}) do
    atom
  end

  def generate_postprocessing_ast({var, type}) do
    quote do
      unquote(BaseType.generate_elixir_postprocessing({var, type}))
    end
  end
end
