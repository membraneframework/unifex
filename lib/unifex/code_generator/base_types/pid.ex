defmodule Unifex.CodeGenerator.BaseTypes.Pid do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for Erlang PIDs.
  """
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_native_type(_ctx) do
    ~g<UnifexPid>
  end

  defmodule NIF do
    @moduledoc false
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_parse(arg, var_name, _ctx) do
      ~g<enif_get_local_pid(env, #{arg}, &#{var_name})>
    end
  end
end
