defmodule Unifex.CodeGenerator.BaseTypes.List do
  defmodule NIF do
    use Unifex.CodeGenerator.BaseType
    alias Unifex.CodeGenerator.BaseType
    @impl BaseType
    def generate_arg_serialize(name, ctx) do
      ~g"""
      ({
        ERL_NIF_TERM list = enif_make_list(env, 0);
        for(int i = #{name}_length-1; i >= 0; i--) {
          list = enif_make_list_cell(
            env,
            #{BaseType.generate_arg_serialize(ctx.type, :"#{name}[i]", ctx.generator)},
            list
          );
        }
        list;
      })
      """
    end

    @impl BaseType
    def generate_native_type(ctx) do
      {"#{BaseType.generate_native_type(ctx.type, ctx.generator)}*", [{"_length", "int"}]}
    end

    @impl BaseType
    def generate_arg_parse(arg, var_name, ctx) do
      elem_name = :"#{var_name}[i]"
      len_var_name = "#{var_name}_length"

      ~g"""
      if(!enif_get_list_length(env, #{arg}, &#{len_var_name})){
        #{ctx.result_var} = unifex_raise_args_error(env, "#{var_name}", "enif_get_list_length");
        goto #{ctx.exit_label};
      }
      #{var_name} = enif_alloc(sizeof(#{BaseType.generate_native_type(ctx.type, ctx.generator)}) * #{
        len_var_name
      });

      for(unsigned int i = 0; i < #{len_var_name}; i++) {
        #{BaseType.generate_initialization(ctx.type, elem_name, ctx.generator)}
      }

      ERL_NIF_TERM list = #{arg};
      for(unsigned int i = 0; i < #{len_var_name}; i++) {
        ERL_NIF_TERM elem;
        enif_get_list_cell(env, list, &elem, &list);
        #{
        BaseType.generate_arg_parse(
          ctx.type,
          elem_name,
          ~g<elem>,
          ctx.postproc_fun,
          ctx.generator
        )
      }
      }
      """
    end

    @impl BaseType
    def generate_initialization(name, _ctx) do
      ~g<#{name} = NULL;>
    end

    @impl BaseType
    def generate_destruction(name, ctx) do
      ~g"""
      if(#{name} != NULL) {
        for(unsigned int i = 0; i < #{name}_length; i++) {
          #{BaseType.generate_destruction(ctx.type, :"#{name}[i]", ctx.generator)}
        }
        enif_free(#{name});
      }
      """
    end
  end
end
