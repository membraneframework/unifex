defmodule Unifex.Loader do
  alias Unifex.{Helper, InterfaceIO, SpecsParser}

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
      |> Enum.map(fn {name, args, _results} ->
        quote do
          defnif unquote(name)(
                   unquote_splicing(args |> Keyword.keys() |> Enum.map(&Macro.var(&1, nil)))
                 )
        end
      end)

    quote do
      use Bundlex.Loader, nif: unquote(name)

      unquote_splicing(funs)
    end
  end
end
