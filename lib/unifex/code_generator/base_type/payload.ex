defmodule Unifex.CodeGenerator.BaseType.Payload do
  alias Unifex.CodeGenerator.BaseType
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
  def generate_initialization(name) do
    ~g<#{name} = enif_alloc(sizeof (UnifexPayload))>
  end

  @impl BaseType
  def generate_destruction(name) do
    ~g<unifex_payload_free_ptr(&#{name})>
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