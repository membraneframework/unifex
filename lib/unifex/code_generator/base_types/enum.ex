defmodule Unifex.CodeGenerator.BaseTypes.Enum do
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

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
      %{postproc_fun: postproc_fun, generator: generator} = ctx

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
        char* enum_as_string;
        int res = 0;

        #{
        BaseType.generate_arg_parse(
          :atom,
          :enum_as_string,
          arg,
          postproc_fun,
          generator,
          ctx
        )
      };

        #{if_statements}

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
            #{
            BaseType.generate_arg_serialize(
              :atom,
              :enum_as_string,
              ctx.generator,
              ctx
            )
          }
          }
          """
        end)
        |> Enum.join(" else ")

      ~g"""
      ({
        #{if_statements}
      });
      """
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, ctx) do
      %{postproc_fun: postproc_fun, generator: generator} = ctx

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
        char* enum_as_string;
        #{
        BaseType.generate_arg_parse(
          :atom,
          :enum_as_string,
          arg,
          postproc_fun,
          generator,
          ctx
        )
      }

        #{if_statements}

        res;
      })
      """
    end
  end
end
