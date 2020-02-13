defmodule Unifex.CodeGenerationMode do
  @enforce_keys [:state_exists]
  defstruct @enforce_keys

  alias Unifex.BaseType

  @type t :: %__MODULE__{
          state_exists: boolean()
        }

  @spec code_generation_mode(
          name :: String.t(),
          dir :: any,
          _specs :: Unifex.SpecsParser.parsed_specs_t()
        ) :: t()
  def code_generation_mode(name, dir, _specs) do
    %__MODULE__{
      state_exists: state_definition_exists(dir, name)
    }
  end

  defp state_definition_exists(dir, name) do
    header_path = Path.join(dir, name <> ".h")
    state_type = "UnifexNifState"

    state_exists =
      File.stream!(header_path)
      |> Enum.any?(fn
        line -> line |> String.contains?(state_type)
      end)
  end
end
