defmodule Unifex.Loader do
  @moduledoc """
  This module allows to generate definitions for native functions described in Unifex specs.

  To acheive that simply use this module:

      use Unifex.Loader

  """

  alias Unifex.{Helper, InterfaceIO, PostprocessingAstGenerator, SpecsParser}

  defmacro __using__(_args) do
    {name, specs} =
      Helper.get_source_dir()
      |> InterfaceIO.get_interfaces_specs!()
      |> Enum.map(fn {name, _dir, specs} ->
        specs = specs |> SpecsParser.parse_specs()
        {name, specs}
      end)
      |> Enum.find(fn {_name, specs} ->
        specs |> Keyword.fetch!(:module) == __CALLER__.module
      end)

    fun_specs = specs |> Keyword.get_values(:fun_specs)

    funs =
      fun_specs
      |> Enum.map(fn {name, args, results} ->
        wrapped_name = name |> to_string() |> (&"unifex_#{&1}").() |> String.to_atom()
        arg_names = args |> Keyword.keys() |> Enum.map(&Macro.var(&1, nil))

        clauses = PostprocessingAstGenerator.generate_postprocessing_clauses(results)

        quote do
          defnifp unquote(wrapped_name)(unquote_splicing(arg_names))

          @compile {:inline, [unquote({name, length(args)})]}
          def unquote(name)(unquote_splicing(arg_names)) do
            result = unquote({wrapped_name, [], arg_names})

            case result do
              unquote(clauses)
            end
          end
        end
      end)

    overrides =
      fun_specs
      |> Enum.map(fn {name, args, _results} ->
        {name, length(args)}
      end)

    quote do
      use Bundlex.Loader, nif: unquote(name)

      unquote_splicing(funs)

      defoverridable unquote(overrides)
    end
  end
end
