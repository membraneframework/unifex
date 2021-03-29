defmodule Unifex.CodeGenerator.BaseTypes.StructTemplate do
  alias Unifex.CodeGenerator.BaseType

  def generate_initialization(name, ctx, struct_fields) do
    struct_fields
    |> Enum.map(fn {field_name, field_type} ->
      BaseType.generate_initialization(field_type, :"#{name}.#{field_name}", ctx.generator)
    end)
    |> Enum.filter(&(&1 != ""))
    |> Enum.join("\n")
  end

  def generate_destruction(name, ctx, struct_fields) do
    struct_fields
    |> Enum.map(fn {field_name, field_type} ->
      BaseType.generate_destruction(field_type, :"#{name}.#{field_name}", ctx.generator)
    end)
    |> Enum.filter(&(&1 != ""))
    |> Enum.join("\n")
  end

  defmodule NIF do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    def generate_arg_serialize(name, ctx, struct_module_name, struct_fields) do
      struct_fields_number = length(struct_fields)

      fields_serialization =
        struct_fields
        |> Enum.zip(0..(struct_fields_number - 1))
        |> Enum.map(fn {{field_name, field_type}, idx} ->
          ~g"""
          keys[#{idx}] = enif_make_atom(env, "#{field_name}");
          values[#{idx}] = #{
            BaseType.generate_arg_serialize(field_type, :"#{name}.#{field_name}", ctx.generator)
          };
          """
        end)
        |> Enum.join("\n")

      ~g"""
      ({
        ERL_NIF_TERM keys[#{struct_fields_number + 1}];
        ERL_NIF_TERM values[#{struct_fields_number + 1}];

        #{fields_serialization}
        keys[#{struct_fields_number}] = enif_make_atom(env, "__struct__");
        values[#{struct_fields_number}] = enif_make_atom(env, "Elixir.#{
        struct_module_name |> Atom.to_string()
      }");

        ERL_NIF_TERM result;
        enif_make_map_from_arrays(env, keys, values, #{struct_fields_number + 1}, &result);
        result;
      })
      """
    end

    def generate_arg_parse(arg, var_name, ctx, struct_fields) do
      %{postproc_fun: postproc_fun, generator: generator} = ctx

      fields_parsing =
        struct_fields
        |> Enum.map(fn {field_name, field_type} ->
          ~g"""
          key = enif_make_atom(env, "#{field_name}");
          int get_#{field_name}_result = enif_get_map_value(env, #{arg}, key, &value);
          if (get_#{field_name}_result) {
            #{
            BaseType.generate_arg_parse(
              field_type,
              :"#{var_name}.#{field_name}",
              ~g<value>,
              postproc_fun,
              generator
            )
          }
          }
          """
        end)
        |> Enum.join("\n")

      result =
        struct_fields
        |> Enum.map(fn {field_name, _field_type} -> ~g<get_#{field_name}_result> end)
        |> Enum.join(" && ")

      ~g"""
      ({
        ERL_NIF_TERM key;
        ERL_NIF_TERM value;

        #{fields_parsing}
        #{result};
      })
      """
    end
  end

  defmodule CNode do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    def generate_arg_serialize(name, ctx, struct_module_name, struct_fields) do
      fields_serialization =
        struct_fields
        |> Enum.map(fn {field_name, field_type} ->
          ~g"""
          ei_x_encode_atom(out_buff, "#{field_name}");
          #{BaseType.generate_arg_serialize(field_type, :"#{name}.#{field_name}", ctx.generator)};
          """
        end)
        |> Enum.join("\n")

      ~g"""
      ({
        ei_x_encode_map_header(out_buff, #{length(struct_fields) + 1});
        #{fields_serialization}
        ei_x_encode_atom(out_buff, "__struct__");
        ei_x_encode_atom(out_buff, "Elixir.#{struct_module_name |> Atom.to_string()}");
      });
      """
    end

    def generate_arg_parse(arg, var_name, ctx, struct_fields) do
      %{postproc_fun: postproc_fun, generator: generator} = ctx

      fields_parsing =
        struct_fields
        |> Enum.map(fn {field_name, field_type} ->
          ~g"""
          if (strcmp(key, "#{field_name}") == 0) {
            #{
            BaseType.generate_arg_parse(
              field_type,
              :"#{var_name}.#{field_name}",
              arg,
              postproc_fun,
              generator
            )
          }
          }
          """
        end)
        |> Enum.concat([
          ~g"""
          if (strcmp(key, "__struct__") == 0) {
            char* elixir_module_name;
            #{
            BaseType.generate_arg_parse(:atom, :elixir_module_name, arg, postproc_fun, generator)
          }
          }
          """
        ])
        |> Enum.join(" else ")

      ~g"""
      ({
        int arity = 0;
        int decode_map_header_result = ei_decode_map_header(#{arg}->buff, #{arg}->index, &arity);
        if (decode_map_header_result == 0) {
          for (int i = 0; i < arity; ++i) {
            char key[MAXATOMLEN + 1];
            int decode_key_result = ei_decode_atom(#{arg}->buff, #{arg}->index, key);
            if (decode_key_result == 0) {
              #{fields_parsing}
            }
          }
        }

        decode_map_header_result;
      })
      """
    end
  end

  def compile_struct_module(struct_type_name, struct_module_name, struct_fields) do
    quoted_module_code(struct_type_name, struct_module_name, struct_fields)
    |> Code.compile_quoted()
  end

  defp quoted_module_code(struct_type_name, struct_module_name, struct_fields) do
    module_name =
      Unifex.CodeGenerator.BaseTypes
      |> Module.concat(struct_type_name |> Atom.to_string() |> String.capitalize())

    quote do
      defmodule unquote(module_name) do
        use Unifex.CodeGenerator.BaseType

        @impl BaseType
        def generate_initialization(name, ctx) do
          Unifex.CodeGenerator.BaseTypes.StructTemplate.generate_initialization(
            name,
            ctx,
            unquote(struct_fields)
          )
        end

        @impl BaseType
        def generate_destruction(name, ctx) do
          Unifex.CodeGenerator.BaseTypes.StructTemplate.generate_destruction(
            name,
            ctx,
            unquote(struct_fields)
          )
        end

        defmodule NIF do
          use Unifex.CodeGenerator.BaseType

          @impl BaseType
          def generate_arg_serialize(name, ctx) do
            Unifex.CodeGenerator.BaseTypes.StructTemplate.NIF.generate_arg_serialize(
              name,
              ctx,
              unquote(struct_module_name),
              unquote(struct_fields)
            )
          end

          @impl BaseType
          def generate_arg_parse(arg, var_name, ctx) do
            Unifex.CodeGenerator.BaseTypes.StructTemplate.NIF.generate_arg_parse(
              arg,
              var_name,
              ctx,
              unquote(struct_fields)
            )
          end
        end

        defmodule CNode do
          use Unifex.CodeGenerator.BaseType

          @impl BaseType
          def generate_arg_serialize(name, ctx) do
            Unifex.CodeGenerator.BaseTypes.StructTemplate.CNode.generate_arg_serialize(
              name,
              ctx,
              unquote(struct_module_name),
              unquote(struct_fields)
            )
          end

          @impl BaseType
          def generate_arg_parse(arg, var_name, ctx) do
            Unifex.CodeGenerator.BaseTypes.StructTemplate.CNode.generate_arg_parse(
              arg,
              var_name,
              ctx,
              unquote(struct_fields)
            )
          end
        end
      end
    end
  end
end
