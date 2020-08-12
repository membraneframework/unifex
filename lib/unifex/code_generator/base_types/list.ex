defmodule Unifex.CodeGenerator.BaseTypes.List do
  @moduledoc """
  Module implementing `Unifex.CodeGenerator.BaseType` behaviour for lists.

  They are represented in the native code as arrays with sizes passed
  via separate arguments.
  """
  use Unifex.CodeGenerator.BaseType
  alias Unifex.CodeGenerator.BaseType

  @impl BaseType
  def generate_initialization(name, _ctx) do
    ~g<#{name} = NULL;>
  end

  defmodule NIF do
    @moduledoc false
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType
    @impl BaseType
    def generate_native_type(ctx) do
      prefix = if ctx.mode == :const, do: "const ", else: ""

      [
        "#{prefix}#{BaseType.generate_native_type(ctx.subtype, ctx.generator)}*",
        {"unsigned int", "_length"}
      ]
    end

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      ~g"""
      ({
        ERL_NIF_TERM list = enif_make_list(env, 0);
        for(int i = #{name}_length-1; i >= 0; i--) {
          list = enif_make_list_cell(
            env,
            #{BaseType.generate_arg_serialize(ctx.subtype, :"#{name}[i]", ctx.generator)},
            list
          );
        }
        list;
      })
      """
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, ctx) do
      elem_name = :"#{var_name}[i]"
      len_var_name = "#{var_name}_length"

      ~g"""
      ({
      int get_list_length_result = enif_get_list_length(env, #{arg}, &#{len_var_name});
      if(get_list_length_result){
        #{var_name} = enif_alloc(
          sizeof(#{BaseType.generate_native_type(ctx.subtype, ctx.generator)}) * #{len_var_name});

        for(unsigned int i = 0; i < #{len_var_name}; i++) {
          #{BaseType.generate_initialization(ctx.subtype, elem_name, ctx.generator)}
        }

        ERL_NIF_TERM list = #{arg};
        for(unsigned int i = 0; i < #{len_var_name}; i++) {
          ERL_NIF_TERM elem;
          enif_get_list_cell(env, list, &elem, &list);
          #{
        BaseType.generate_arg_parse(
          ctx.subtype,
          elem_name,
          ~g<elem>,
          ctx.postproc_fun,
          ctx.generator
        )
      }
        }
      }
      get_list_length_result;
      })
      """
    end

    @impl BaseType
    def generate_destruction(name, ctx) do
      ~g"""
      if(#{name} != NULL) {
        for(unsigned int i = 0; i < #{name}_length; i++) {
          #{BaseType.generate_destruction(ctx.subtype, :"#{name}[i]", ctx.generator)}
        }
        unifex_free(#{name});
      }
      """
    end
  end

  defmodule CNode do
    @moduledoc false
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType
    @impl BaseType
    def generate_native_type(ctx) do
      prefix = if ctx.mode == :const, do: "const ", else: ""

      [
        "#{prefix}#{BaseType.generate_native_type(ctx.subtype, ctx.generator)}*",
        {"int", "_length"}
      ]
    end

    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      ~g"""
      ({
        ei_x_encode_list_header(out_buff, #{name}_length);
        for(int i = 0; i < #{name}_length; i++) {
          #{BaseType.generate_arg_serialize(ctx.subtype, :"#{name}[i]", ctx.generator)}
        }
        ei_x_encode_empty_list(out_buff);
      });
      """
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, ctx) do
      elem_name = :"#{var_name}[i]"
      len_var_name = "#{var_name}_length"

      ~g"""
      ({
        int res = 1;
        int type;
        char *p;
        ei_get_type(#{arg}->buff, #{arg}->index, &type, &#{len_var_name});
        if(type == ERL_LIST_EXT) {
          res = ei_decode_list_header(#{arg}->buff, #{arg}->index, &#{len_var_name});
          #{var_name} = malloc(sizeof(#{BaseType.generate_native_type(ctx.subtype, ctx.generator)}) * #{len_var_name});

          for(int i = 0; i < #{len_var_name}; i++) {
            #{BaseType.generate_initialization(ctx.subtype, elem_name, ctx.generator)}
          }

          for(int i = 0; i < #{len_var_name}; i++) {
            #{BaseType.generate_arg_parse(
              ctx.subtype,
              elem_name,
              arg,
              ctx.postproc_fun,
              ctx.generator
            )}
          }
        } else if(type == ERL_STRING_EXT) {
          p = malloc(sizeof(char)*#{len_var_name});
          res = ei_decode_string(#{arg}->buff, #{arg}->index, p);
          #{var_name} = malloc(sizeof(int) * #{len_var_name});
          for(int i = 0; i < #{len_var_name}; i++) {
            #ifdef __CHAR_UNSIGNED
              #{elem_name} = (int)p[i];
            #else
              #{elem_name} = (int)p[i];
              if(#{elem_name} < 0) {
                #{elem_name} = #{elem_name} + 256;
              }
            #endif
            }
        }
        res;
      })
      """
    end

    @impl BaseType
    def generate_destruction(name, ctx) do
      ~g"""
      if(#{name} != NULL) {
        for(int i = 0; i < #{name}_length; i++) {
          #{BaseType.generate_destruction(ctx.subtype, :"#{name}[i]", ctx.generator)}
        }
        unifex_free(#{name});
      }
      """
    end
  end
end
