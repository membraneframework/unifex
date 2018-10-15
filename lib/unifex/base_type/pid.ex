defmodule Unifex.BaseType.Pid do
  @moduledoc """
  Module implementing `Unifex.BaseType` behaviour for Erlang PIDs
  """
  alias Unifex.BaseType
  use BaseType

  @impl BaseType
  def generate_native_type() do
    ~g<UnifexPid>
  end

  @impl BaseType
  def generate_arg_parse(arg, var_name) do
    ~g<enif_get_local_pid(env, #{arg}, &#{var_name})>
  end
end
