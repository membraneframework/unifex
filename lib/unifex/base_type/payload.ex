defmodule Unifex.BaseType.Payload do
  @moduledoc """
  Module implementing `Unifex.BaseType` behaviour for `Membrane.Payload`
  """
  alias Unifex.BaseType
  use BaseType

  @impl BaseType
  def generate_arg_serialize(name) do
    ~g<unifex_payload_to_term(env, #{name})>
  end

  @impl BaseType
  def generate_native_type() do
    ~g<UnifexPayload *>
  end

  @impl BaseType
  def generate_parsed_arg_declaration(name) do
    ~g<#{generate_native_type()} #{name} = NULL;>
  end

  @impl BaseType
  def generate_allocation(name) do
    ~g<#{name} = enif_alloc(sizeof (UnifexPayload));>
  end

  @impl BaseType
  def generate_destruction(name) do
    ~g<unifex_payload_release_ptr(&#{name});>
  end

  @impl BaseType
  def generate_elixir_postprocessing(name) do
    var = Macro.var(name, nil)

    quote do
      case unquote(var) do
        %Membrane.Payload.Shm{guard: nil} ->
          {:ok, guarded_shm} = Membrane.Payload.Shm.Native.add_guard(unquote(var))
          guarded_shm

        _ ->
          unquote(var)
      end
    end
  end

  @impl BaseType
  def generate_arg_parse(arg, var_name) do
    ~g<unifex_util_payload_from_term(env, #{arg}, #{var_name})>
  end
end
