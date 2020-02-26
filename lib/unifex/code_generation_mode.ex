defmodule Unifex.CodeGenerationMode do
  defstruct [:use_state, :cnode_mode]

  @type t :: %__MODULE__{
          use_state: boolean(),
          cnode_mode: boolean()
        }

  @spec code_generation_mode(
          _name :: String.t(),
          _dir :: any,
          specs :: Unifex.SpecsParser.parsed_specs_t()
        ) :: t()
  def code_generation_mode(_name, _dir, specs) do
    %__MODULE__{
      use_state: specs |> Keyword.get(:use_state, false),
      cnode_mode: specs |> Keyword.get(:cnode_mode, false)
    }
  end
end
