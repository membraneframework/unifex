defmodule Unifex.Loader do
  alias Unifex.{Helper, InterfaceIO, SpecsParser, ResultsParser}

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

        parsed_results = ResultsParser.parse_return_specs(results)

        patterns = parsed_results |> Enum.map(&ResultsParser.generate_pattern_ast/1)

        handlers =
          parsed_results
          |> Enum.map(&ResultsParser.generate_postprocessing_ast/1)

        cases =
          Enum.zip(patterns, handlers)
          |> Enum.reject(fn {pattern, handler} ->
            pattern == handler
          end)
          |> Enum.map(fn {pattern, handler} ->
            quote generated: true do
              unquote(pattern) -> unquote(handler)
            end
          end)
          |> List.flatten()

        # Catch'em all
        cases =
          cases ++
            quote do
              _ -> result
            end

        quote do
          defnifp unquote(wrapped_name)(unquote_splicing(arg_names))

          @compile {:inline, [unquote({name, length(args)})]}
          def unquote(name)(unquote_splicing(arg_names)) do
            result = unquote({wrapped_name, [], arg_names})

            case result do
              unquote(cases)
            end
          end
        end
      end)

    quote do
      use Bundlex.Loader, nif: unquote(name)

      unquote_splicing(funs)
    end
  end
end
