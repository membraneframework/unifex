defmodule Unifex.CodeGenerator.BaseTypes.Bool do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for boolean atoms.

  Booleans in native code are converted to int with value either 0 or 1.
  """
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_native_type(_ctx) do
    ~g<int>
  end

  @impl BaseType
  def generate_arg_parse(arg_term, var_name, _ctx) do
    ~g<unifex_parse_bool(env, #{arg_term}, &#{var_name})>
  end

  defmodule NIF do
    @moduledoc false
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, _ctx) do
      ~g<enif_make_atom(env, #{name} ? "true" : "false")>
    end
  end
end
