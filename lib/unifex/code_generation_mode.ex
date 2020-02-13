defmodule Unifex.CodeGenerationMode do

  defstruct [:use_state, :cnode_mode]

  alias Unifex.BaseType

  @type t :: %__MODULE__{
          use_state: boolean(),
          cnode_mode: boolean()
        }

  @spec code_generation_mode(
          name :: String.t(),
          dir :: any,
          _specs :: Unifex.SpecsParser.parsed_specs_t()
        ) :: t()
  def code_generation_mode(name, dir, specs) do
    %__MODULE__{
      use_state: specs |> Keyword.get(:use_state, false),
      cnode_mode: specs |> Keyword.get(:cnode_mode, false)
    }
  end

  defp state_definition_exists(dir, name) do
    state_type = "UnifexState"
    contains_word(dir, name, state_type)
  end

  defp old_state_definition_exists(dir, name) do
    old_state_type = "UnifexNifState"
    contains_word(dir, name, old_state_type) 
  end

  defp contains_word(dir, header_name, word) do
    header_path = Path.join(dir, header_name <> ".h")

    File.stream!(header_path)
    |> Enum.any?(fn
      line -> line |> String.contains?(word)
    end)
  end
end
