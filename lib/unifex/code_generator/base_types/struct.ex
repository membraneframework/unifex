defmodule Unifex.CodeGenerator.BaseTypes.Struct do
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_initialization(name, ctx) do
    ctx.type_spec.struct_fields
    |> Enum.map(fn {field_name, field_type} ->
      BaseType.generate_initialization(field_type, :"#{name}.#{field_name}", ctx.generator, ctx)
    end)
    |> Enum.filter(&(&1 != ""))
    |> Enum.join("\n")
  end

  @impl BaseType
  def generate_destruction(name, ctx) do
    ctx.type_spec.struct_fields
    |> Enum.map(fn {field_name, field_type} ->
      BaseType.generate_destruction(field_type, :"#{name}.#{field_name}", ctx.generator, ctx)
    end)
    |> Enum.filter(&(&1 != ""))
    |> Enum.join("\n")
  end

  defmodule NIF do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      struct_fields_number = length(ctx.type_spec.struct_fields)

      fields_serialization =
        ctx.type_spec.struct_fields
        |> Enum.zip(0..(struct_fields_number - 1))
        |> Enum.map(fn {{field_name, field_type}, idx} ->
          ~g"""
          keys[#{idx}] = enif_make_atom(env, "#{field_name}");
          values[#{idx}] = #{
            BaseType.generate_arg_serialize(
              field_type,
              :"#{name}.#{field_name}",
              ctx.generator,
              ctx
            )
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
        ctx.type_spec.struct_module_name |> Atom.to_string()
      }");

        ERL_NIF_TERM result;
        enif_make_map_from_arrays(env, keys, values, #{struct_fields_number + 1}, &result);
        result;
      })
      """
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, ctx) do
      %{postproc_fun: postproc_fun, generator: generator} = ctx

      unique_sufix =
        var_name
        |> Atom.to_string()
        |> String.replace(".", "_")

      fields_parsing =
        ctx.type_spec.struct_fields
        |> Enum.map(fn {field_name, field_type} ->
          ~g"""
          key_#{unique_sufix} = enif_make_atom(env, "#{field_name}");
          int get_#{field_name}_result = enif_get_map_value(env, #{arg}, key_#{unique_sufix}, &value_#{
            unique_sufix
          });
          if (get_#{field_name}_result) {
            #{
            BaseType.generate_arg_parse(
              field_type,
              :"#{var_name}.#{field_name}",
              ~g<value_#{unique_sufix}>,
              postproc_fun,
              generator,
              ctx
            )
          }
          }
          """
        end)
        |> Enum.join("\n")

      result =
        ctx.type_spec.struct_fields
        |> Enum.map(fn {field_name, _field_type} -> ~g<get_#{field_name}_result> end)
        |> Enum.join(" && ")

      ~g"""
      ({
        ERL_NIF_TERM key_#{unique_sufix};
        ERL_NIF_TERM value_#{unique_sufix};

        #{fields_parsing}
        #{result};
      })
      """
    end
  end

  defmodule CNode do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      fields_serialization =
        ctx.type_spec.struct_fields
        |> Enum.map(fn {field_name, field_type} ->
          ~g"""
          ei_x_encode_atom(out_buff, "#{field_name}");
          #{
            BaseType.generate_arg_serialize(
              field_type,
              :"#{name}.#{field_name}",
              ctx.generator,
              ctx
            )
          };
          """
        end)
        |> Enum.join("\n")

      ~g"""
      ({
        ei_x_encode_map_header(out_buff, #{length(ctx.type_spec.struct_fields) + 1});
        #{fields_serialization}
        ei_x_encode_atom(out_buff, "__struct__");
        ei_x_encode_atom(out_buff, "Elixir.#{ctx.type_spec.struct_module_name |> Atom.to_string()}");
      });
      """
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, ctx) do
      %{postproc_fun: postproc_fun, generator: generator} = ctx

      fields_parsing =
        ctx.type_spec.struct_fields
        |> Enum.map(fn {field_name, field_type} ->
          ~g"""
          if (strcmp(key, "#{field_name}") == 0) {
            #{
            BaseType.generate_arg_parse(
              field_type,
              :"#{var_name}.#{field_name}",
              arg,
              postproc_fun,
              generator,
              ctx
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
            BaseType.generate_arg_parse(
              :atom,
              :elixir_module_name,
              arg,
              postproc_fun,
              generator,
              ctx
            )
          }
            #{BaseType.generate_destruction(:atom, :elixir_module_name, generator, ctx)}
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
end
