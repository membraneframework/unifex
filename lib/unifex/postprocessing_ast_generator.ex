defmodule Unifex.PostprocessingAstGenerator do
  alias Unifex.BaseType

  def generate_postprocessing_clauses(result_specs) do
    clauses =
      result_specs
      |> Enum.map(fn spec -> {spec |> generate_pattern(), spec |> generate_postprocessing()} end)
      |> Enum.reject(fn {pattern, postprocessing} -> pattern == postprocessing end)
      |> Enum.flat_map(fn {pattern, postprocessing} ->
        quote do
          unquote(pattern) -> unquote(postprocessing)
        end
      end)

    clauses ++ quote do: (default -> default)
  end

  defp generate_pattern(node) do
    case node do
      {:__aliases__, [alias: als], atoms} ->
        generate_pattern(als || Module.concat(atoms))

      atom when is_atom(atom) ->
        Macro.var(atom, nil)

      {:::, _, [name, {:label, _, _}]} when is_atom(name) ->
        name

      {:::, _, [{name, _, _}, {_type, _, _}]} ->
        Macro.var(name, nil)

      {:::, _, [{name, _, _}, [{_type, _, _}]]} ->
        Macro.var(name, nil)

      {a, b} ->
        generate_pattern({:{}, [], [a, b]})

      {:{}, _, content} ->
        {:{}, [], content |> Enum.map(&generate_pattern/1)}

      [{name, _, _}] ->
        Macro.var(name, nil)

      {name, _, _} ->
        Macro.var(name, nil)
    end
  end

  defp generate_postprocessing(node) do
    case node do
      {:__aliases__, [alias: als], atoms} ->
        generate_postprocessing(als || Module.concat(atoms))

      atom when is_atom(atom) ->
        BaseType.generate_elixir_postprocessing({atom, :atom})

      {:::, _, [name, {:label, _, _}]} when is_atom(name) ->
        name

      {:::, _, [{name, _, _}, {type, _, _}]} ->
        BaseType.generate_elixir_postprocessing({name, type})

      {:::, _, [{name, _, _}, [{type, _, _}]]} ->
        elem_name = :"#{name}_elem"
        elem_var = Macro.var(elem_name, nil)
        postprocessing = BaseType.generate_elixir_postprocessing({elem_name, type})

        if postprocessing == elem_var do
          Macro.var(name, nil)
        else
          quote do
            unquote(Macro.var(name, nil))
            |> Enum.map(fn unquote(elem_var) ->
              unquote(postprocessing)
            end)
          end
        end

      {a, b} ->
        generate_postprocessing({:{}, [], [a, b]})

      {:{}, _, content} ->
        {:{}, [], content |> Enum.map(&generate_postprocessing/1)}

      [{_name, _, _} = name_var] ->
        generate_postprocessing({:::, [], [name_var, [name_var]]})

      {name, _, _} ->
        BaseType.generate_elixir_postprocessing({name, name})
    end
  end
end
