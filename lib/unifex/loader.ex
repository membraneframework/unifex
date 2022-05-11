defmodule Unifex.Loader do
  @moduledoc """
  This module allows to generate definitions for native functions described in Unifex specs.

  To achieve that simply use this module:

      use Unifex.Loader

  """

  alias Unifex.{Helper, InterfaceIO, Specs}

  defmacro __using__(_args) do
    {specs, specs_path} =
      Helper.get_source_dir()
      |> InterfaceIO.get_interfaces_specs!()
      |> Enum.map(fn {name, _dir, specs_path} -> {Specs.parse(specs_path, name), specs_path} end)
      |> Enum.find(fn {specs, _specs_path} -> specs.module == __CALLER__.module end)

    funs =
      specs.functions_args
      |> Enum.map(fn {name, args} ->
        wrapped_name = name |> to_string() |> (&"unifex_#{&1}").() |> String.to_atom()
        arg_names = args |> Keyword.keys() |> Enum.map(&Macro.var(&1, nil))

        quote do
          defnifp unquote(wrapped_name)(unquote_splicing(arg_names))

          @compile {:inline, [unquote({name, length(args)})]}
          # credo:disable-for-next-line Credo.Check.Readability.Specs
          def unquote(name)(unquote_splicing(arg_names)) do
            unquote({wrapped_name, [], arg_names})
          end
        end
      end)

    overrides =
      specs.functions_args
      |> Enum.map(fn {name, args} ->
        {name, length(args)}
      end)

    quote do
      @external_resource unquote(specs_path)

      use Bundlex.Loader, nif: unquote(specs.name)

      unquote_splicing(funs)

      defoverridable unquote(overrides)
    end
  end
end
