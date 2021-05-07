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
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      last_type =
        ctx.type_spec.types
        |> List.last()
        |> Atom.to_string()

      if_statements =
        ctx.type_spec.types
        |> Enum.map(&Atom.to_string/1)
        |> Enum.map(fn type ->
          if_condition =
            if type != last_type do
              ~g"if (#{name} == #{type |> String.upcase()})"
            else
              ""
            end

          ~g"""
          #{if_condition} {
            char* enum_as_string = "#{type}";
            res = #{
            BaseType.generate_arg_serialize(
              :atom,
              :enum_as_string,
              ctx.generator,
              ctx
            )
          };
          }
          """
        end)
        |> Enum.join(" else ")

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
      if_statements =
        ctx.type_spec.types
        |> Enum.map(&Atom.to_string/1)
        |> Enum.map(fn type ->
          ~g"""
          if (strcmp(enum_as_string, "#{type}") == 0) {
            #{var_name} = #{type |> String.upcase()};
            res = 1;
          }
          """
        end)
        |> Enum.join(" else ")

      ~g"""
      ({
        char* enum_as_string = NULL;
        int res = 0;

        if (#{BaseTypes.Atom.NIF.generate_arg_parse(arg, :enum_as_string, ctx)}) {
          #{if_statements}

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
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      {last_type, types} = List.pop_at(ctx.type_spec.types, -1)
      last_type = Atom.to_string(last_type)

      if_statements =
        types
        |> Enum.map(&Atom.to_string/1)
        |> Enum.map(fn type ->
          ~g"""
          if (#{name} == #{type |> String.upcase()}) {
            #{do_serialize(type, ctx)}
          }
          """
        end)
        |> Enum.concat(["{ #{do_serialize(last_type, ctx)} }"])
        |> Enum.join(" else ")

      ~g"""
      ({
        #{if_statements}
      });
      """
    end

    defp do_serialize(type, ctx) do
      ~g"""
      char* enum_as_string = "#{type}";
      #{
        BaseType.generate_arg_serialize(
          :atom,
          :enum_as_string,
          ctx.generator,
          ctx
        )
      }\
      """
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, ctx) do
      if_statements =
        ctx.type_spec.types
        |> Enum.map(&Atom.to_string/1)
        |> Enum.map(fn type ->
          ~g"""
          if (strcmp(enum_as_string, "#{type}") == 0) {
            #{var_name} = #{type |> String.upcase()};
            res = 0;
          }
          """
        end)

      ~g"""
      ({
        int res = 1;
        char* enum_as_string = NULL;

        if (!#{BaseTypes.Atom.CNode.generate_arg_parse(arg, :enum_as_string, ctx)}) {
          #{if_statements}

          if (enum_as_string != NULL) {
            unifex_free((void *) enum_as_string);
          }
        }

        res;
      })
      """
    end
  end
end
