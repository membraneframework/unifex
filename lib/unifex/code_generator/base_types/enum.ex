defmodule Unifex.CodeGenerator.BaseTypes.Enum do
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.{BaseType, BaseTypes}

  @enforce_keys [:name, :types]
  defstruct @enforce_keys

  @impl BaseType
  def generate_native_type(ctx) do
    ~g<#{ctx.type_spec.name |> Atom.to_string() |> Macro.camelize()}>
  end

  defmodule NIF do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.{BaseType, BaseTypes}

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      if_statements =
        BaseTypes.Enum.do_generate_arg_serialize_if_statements(name, ctx, fn type, ctx ->
          ~g"""
          char* enum_as_string = "#{type}";
          res = #{BaseTypes.Default.NIF.generate_arg_serialize(:enum_as_string, %{ctx | type: :atom})};\
          """
        end)

      ~g"""
      ({
        ERL_NIF_TERM res;
        #{if_statements}
        res;
      })
      """
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, ctx) do
      ~g"""
      ({
        int res = 0;
        char* enum_as_string = NULL;

        if (#{BaseTypes.Atom.NIF.generate_arg_parse(arg, :enum_as_string, ctx)}) {
          #{BaseTypes.Enum.do_generate_arg_parse_if_statements(var_name, 1, ctx)}

          if (enum_as_string != NULL) {
            unifex_free((void *) enum_as_string);
          }
        }

        res;
      })
      """
    end
  end

  defmodule CNode do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.{BaseType, BaseTypes}

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      if_statements =
        BaseTypes.Enum.do_generate_arg_serialize_if_statements(name, ctx, fn type, ctx ->
          ~g"""
          char* enum_as_string = "#{type}";
          #{BaseTypes.Default.CNode.generate_arg_serialize(:enum_as_string, %{ctx | type: :atom})}
          """
        end)

      ~g"""
      ({
        #{if_statements}
      });
      """
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, ctx) do
      ~g"""
      ({
        int res = 1;
        char* enum_as_string = NULL;

        if (!#{BaseTypes.Atom.CNode.generate_arg_parse(arg, :enum_as_string, ctx)}) {
          #{BaseTypes.Enum.do_generate_arg_parse_if_statements(var_name, 0, ctx)}

          if (enum_as_string != NULL) {
            unifex_free((void *) enum_as_string);
          }
        }

        res;
      })
      """
    end
  end

  def do_generate_arg_parse_if_statements(var_name, result_success_value, ctx) do
    ctx.type_spec.types
    |> Enum.map(&Atom.to_string/1)
    |> Enum.map(fn type ->
      ~g"""
      if (strcmp(enum_as_string, "#{type}") == 0) {
        #{var_name} = #{type |> String.upcase()};
        res = #{result_success_value};
      }
      """
    end)
    |> Enum.join(" else ")
  end

  def do_generate_arg_serialize_if_statements(name, ctx, serializator) do
    {last_type, types} = List.pop_at(ctx.type_spec.types, -1)
    last_type = Atom.to_string(last_type)

    types
    |> Enum.map(&Atom.to_string/1)
    |> Enum.map(fn type ->
      ~g"""
      if (#{name} == #{type |> String.upcase()}) {
        #{serializator.(type, ctx)}
      }
      """
    end)
    |> Enum.concat(["{ #{serializator.(last_type, ctx)} }"])
    |> Enum.join(" else ")
  end
end
