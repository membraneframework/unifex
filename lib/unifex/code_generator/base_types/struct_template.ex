defmodule Unifex.CodeGenerator.BaseTypes.StructTemplate do
  def compile_struct_module(struct_type_name, struct_fields) do
    quoted_struct_module(struct_type_name, struct_fields)
    |> Code.compile_quoted()
  end

  defp quoted_struct_module(struct_type_name, _struct_fields) do
    struct_module_name =
      struct_type_name
      |> Atom.to_string()
      |> Macro.camelize()
      |> String.to_atom()

    generate_native_type = fn _ctx -> "" end
    generate_initialization = fn _name, _ctx -> "" end
    generate_destruction = fn _name, _ctx -> "" end

    nif_generate_arg_serialize = fn _name, _ctx -> "" end
    nif_generate_arg_parse = fn _arg, _var_name, _ctx -> "" end

    cnode_generate_arg_serialize = fn _name, _ctx -> "" end
    cnode_generate_arg_parse = fn _arg, _var_name, _ctx -> "" end

    quote do
      defmodule Unigex.CodeGenerator.BaseTypes.unquote(struct_module_name) do
        use Unifex.CodeGenerator.BaseType
        alias Unifex.CodeGenerator.BaseType

        @impl BaseType
        def generate_native_type(ctx) do
          unquote(generate_native_type).(ctx)
        end

        @impl BaseType
        def generate_initialization(name, ctx) do
          unquote(generate_initialization).(name, ctx)
        end

        @impl BaseType
        def generate_destruction(name, ctx) do
          unquote(generate_destruction).(name, ctx)
        end

        defmodule NIF do
          use Unifex.CodeGenerator.BaseType
          alias Unifex.CodeGenerator.BaseType

          @impl BaseType
          def generate_arg_serialize(name, ctx) do
            unquote(nif_generate_arg_serialize).(name, ctx)
          end

          @impl BaseType
          def generate_arg_parse(arg, var_name, ctx) do
            unquote(nif_generate_arg_parse).(arg, var_name, ctx)
          end
        end

        defmodule CNode do
          use Unifex.CodeGenerator.BaseType
          alias Unifex.CodeGenerator.BaseType

          @impl BaseType
          def generate_arg_serialize(name, ctx) do
            unquote(cnode_generate_arg_serialize).(name, ctx)
          end

          @impl BaseType
          def generate_arg_parse(arg, var_name, ctx) do
            unquote(cnode_generate_arg_parse).(arg, var_name, ctx)
          end
        end
      end
    end
  end
end
