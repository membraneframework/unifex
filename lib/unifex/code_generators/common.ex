defmodule Unifex.CodeGenerators.Common do
  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]
  alias Unifex.CodeGenerator.BaseType

  def get_ctx(specs) do
    customized_types =
      specs.structs
      |> Enum.map(fn {struct_alias, struct_module_name, struct_fields} ->
        {
          struct_alias,
          %{
            struct_alias: struct_alias,
            struct_module_name: struct_module_name,
            struct_fields: struct_fields
          }
        }
      end)
      |> Enum.into(%{})

    %{customized_types: customized_types}
  end

  def generate_struct_native_definition(
        {struct_type_name, _struct_module_name, struct_fields},
        code_generator,
        ctx
      ) do
    struct_fields_definition =
      struct_fields
      |> Enum.map(fn {field_name, field_type} ->
        BaseType.generate_declaration(field_type, field_name, code_generator, ctx)
      end)
      |> Enum.map(&Bunch.listify/1)
      |> Enum.flat_map(fn x -> x end)
      |> Enum.map(fn declaration -> ~g<#{declaration};> end)
      |> Enum.join("\n")

    ~g"""
    #ifdef __cplusplus
      struct #{struct_type_name} {
        #{struct_fields_definition}
      };
    #else
      struct #{struct_type_name}_t {
        #{struct_fields_definition}
      };
      typedef struct #{struct_type_name}_t #{struct_type_name};
    #endif
    """
  end
end
