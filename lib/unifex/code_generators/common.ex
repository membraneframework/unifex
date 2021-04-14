defmodule Unifex.CodeGenerators.Common do
  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]
  alias Unifex.CodeGenerator.{BaseType, BaseTypes}

  @moduledoc """
  Contains function used in both Unifex.CodeGenerators.NIF and Unifex.CodeGenerators.CNode modules
  """

  @doc """
  Createx ctx passed to functions generating native code
  """
  def get_ctx(specs) do
    structs =
      specs.structs
      |> Enum.map(fn {struct_alias, module_name, fields} ->
        %BaseTypes.Struct{
          struct_alias: struct_alias,
          module_name: module_name,
          fields: fields
        }
      end)

    enums =
      specs.enums
      |> Enum.map(fn {name, types} ->
        %BaseTypes.Enum{
          name: name,
          types: types
        }
      end)

    user_types =
      (structs ++ enums)
      |> Map.new(fn
        %BaseTypes.Struct{} = struct ->
          {struct.struct_alias, struct}

        %BaseTypes.Enum{} = enum ->
          {enum.name, enum}
      end)

    %{user_types: user_types}
  end

  @doc """
  Generates native definition of struct
  """
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

  def generate_enum_native_definition({enum_name, enum_types}, _ctx) do
    enum_name =
      enum_name
      |> Atom.to_string()
      |> Macro.camelize()

    enum_types =
      enum_types
      |> Enum.map(&Atom.to_string/1)
      |> Enum.map(&String.upcase/1)
      |> Enum.join(",\n")

    ~g"""
    #ifdef __cplusplus
      enum #{enum_name}{
        #{enum_types}
      };
    #else
      enum #{enum_name}_t{
        #{enum_types}
      };
      typedef enum #{enum_name}_t #{enum_name};
    #endif
    """
  end
end
