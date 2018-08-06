defmodule Unifex.CodeGenerator.BaseType.State do
  alias Unifex.CodeGenerator.BaseType
  use BaseType

  @impl BaseType
  def generate_term_maker(name) do
    ~g<unifex_util_make_and_release_resource(env-\>nif_env, #{name})>
  end

  @impl BaseType
  def generate_declaration(name) do
    ~g<State* #{name}>
  end

  @impl BaseType
  def generate_arg_parse(name, i) do
    ~g<UNIFEX_UTIL_PARSE_RESOURCE_ARG(#{i}, #{name}, State, STATE_RESOURCE_TYPE);>
  end
end
