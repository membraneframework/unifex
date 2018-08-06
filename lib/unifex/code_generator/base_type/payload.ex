defmodule Unifex.CodeGenerator.BaseType.Payload do
  alias Unifex.CodeGenerator.BaseType
  use BaseType

  @impl BaseType
  def generate_term_maker(name) do
    ~g<#{name}.term>
  end

  @impl BaseType
  def generate_declaration(name) do
    ~g<UnifexPayload #{name}>
  end
end
