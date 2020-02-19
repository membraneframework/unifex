defmodule Unifex.CodeGenerator.CNodeCodeGenerator do
  alias Unifex.{BaseType, InterfaceIO, CodeGenerator, CodeGenerationMode}
  alias Unifex.CodeGenerator.CodeGeneratorUtils

  use Bunch
  use CodeGeneratorUtils

  @behaviour CodeGenerator

  CodeGeneratorUtils.spec_traverse_helper_generating_macro()

  def generate_tuple_maker(_content) do
    ""
  end

  defp generate_implemented_function_declaration({name, args, specs}) do
    args_declarations =
      ["cnode_context * ctx" | args |> Enum.flat_map(&BaseType.generate_declaration/1)]
      |> Enum.join(", ")

    return_type =
      if are_void_fun_specs(specs) do
        ~g<void>
      else
        ~g<UNIFEX_TERM>
      end

    ~g<#{return_type} #{name}(#{args_declarations})>
  end

  defp generate_args_decoding(args) do
    args
    |> Enum.map(fn
      {name, :atom} ->
        ~g"""
        char #{name}[2048];
        ei_decode_atom(in_buff, index, #{name}));
        """

      {name, :int} ->
        ~g"""
        long long #{name};
        ei_decode_longlong(in_buff, index, &#{name});
        """

      {name, :string} ->
        ~g"""
        char #{name}[2048];
          long #{name}_len;
          ei_decode_binary(in_buff, index, (void *) #{name}, &#{name}_len);
          #{name}[#{name}_len] = 0;
        """

      {_name, :state} ->
        ~g<>
    end)
    |> Enum.join("\n")
  end

  defp generate_result_encoding({_var_name, :void}) do
    ""
  end

  defp generate_result_encoding({var_name, :state}) do
    ~g"""
    ctx->wrapper->state = #{var_name};
    """
  end

  defp generate_result_encoding({var, :label}) do
    generate_result_encoding({var, :atom})
  end

  defp generate_result_encoding({var_name, :int}) do
    ~g"""
    long long casted_#{var_name} = (long long) #{var_name};
    ei_x_encode_longlong(out_buff, casted_#{var_name});
    """
  end

  defp generate_result_encoding({var_name, :string}) do
    ~g"""
      long #{var_name}_len = (long) strlen(#{var_name});
      ei_x_encode_binary(out_buff, #{var_name}, #{var_name}_len);
    """
  end

  defp generate_result_encoding({var_name, :atom}) do
    ~g<  ei_x_encode_atom(out_buff, #{var_name});>
  end

  defp generate_label_encoding(label_name) do
    var_name = ~g<label_#{label_name}>
    encoding = generate_result_encoding({var_name, :atom})

    ~g"""
    char #{var_name}[] = "#{label_name}";
    #{encoding}
    """
  end

  defp generate_encoding_block(meta) do
    encoding_labels =
      meta
      |> Keyword.get_values(:label)
      |> Enum.map(&generate_label_encoding/1)

    encoding_args =
      meta
      |> Keyword.get_values(:arg)
      |> Enum.map(&generate_result_encoding/1)

    encoding_labels ++ encoding_args
  end

  defp generate_result_function({name, specs}) do
    declaration = generate_result_function_declaration({name, specs})
    {_result, meta} = generate_function_spec_traverse_helper(specs)
    encodings = generate_encoding_block(meta)

    state_encodings_num =
      meta
      |> Keyword.get_values(:arg)
      |> Enum.count(fn
        {_var_name, :state} -> true
        _else -> false
      end)

    if declaration == "" do
      ""
    else
      ~g"""
      #{declaration} {
        ei_x_buff * out_buff = (ei_x_buff *) malloc(sizeof(ei_x_buff));
        prepare_result_buff(out_buff, ctx->node_name);

        ei_x_encode_tuple_header(out_buff, #{length(encodings) - state_encodings_num});

        #{encodings |> Enum.join("\n")}

        return out_buff;
      }
      """
    end
  end

  defp generate_result_function_declaration({name, specs}) do
    fun_name_prefix = [name, :result] |> Enum.join("_")
    function_declaration_template("UNIFEX_TERM", fun_name_prefix, specs)
  end

  defp generate_send_function_declaration(specs) do
    function_declaration_template("void", "send", specs)
  end

  defp generate_send_function(specs) do
    declaration = generate_send_function_declaration(specs)

    {_result, meta} = generate_function_spec_traverse_helper(specs)
    encodings = generate_encoding_block(meta)

    ~g"""
    #{declaration} {
      ei_x_buff * out_buff = (ei_x_buff *) malloc(sizeof(ei_x_buff));
      ei_x_new_with_version(out_buff);      
      ei_x_encode_tuple_header(out_buff, #{length(encodings)});

      #{encodings |> Enum.join("\n")}

      send_and_free(ctx, out_buff);
      free(out_buff);
    }
    """
  end

  defp are_void_fun_specs(specs) do
    {_result, meta} = generate_function_spec_traverse_helper(specs)
    are_void_fun_specs(specs, meta)
  end

  defp are_void_fun_specs(specs, meta) do
    :void in (meta
              |> Keyword.get_values(:label)
              |> (fn
                    labels when labels != [] ->
                      labels

                    _ ->
                      [head | _tail] = specs |> Tuple.to_list()
                      [head]
                  end).())
  end

  defp function_declaration_template(return_type, fun_name_prefix, specs) do
    {_result, meta} = generate_function_spec_traverse_helper(specs)
    args = meta |> Keyword.get_values(:arg)

    args_declarations =
      [
        "cnode_context * ctx"
        | args
          |> Enum.flat_map(&BaseType.generate_declaration/1)
          |> Enum.map(&BaseType.make_ptr_const/1)
      ]
      |> Enum.join(", ")

    labels =
      meta
      |> Keyword.get_values(:label)
      |> (fn
            labels when labels != [] ->
              labels

            _ ->
              [head | _tail] = specs |> Tuple.to_list()
              [head]
          end).()

    if are_void_fun_specs(specs, meta) do
      ""
    else
      fun_name = [fun_name_prefix | labels] |> Enum.join("_")
      ~g<#{return_type} #{fun_name}(#{args_declarations})>
    end
  end

  defp generate_handle_message_declaration() do
    "int handle_message(int ei_fd, const char *node_name, erlang_msg emsg,
            ei_x_buff *in_buff, struct UnifexStateWrapper* state)"
  end

  defp generate_handle_message(functions) do
    if_statements =
      functions
      |> Enum.map(fn
        {f_name, _args} ->
          ~g"""
          if (strcmp(fun_name, "#{f_name}") == 0) {
              #{f_name}_caller(in_buff->buff, &index, &ctx);
            }   
          """
      end)

    last_statement = """
    {
      char err_msg[4000];
      strcpy(err_msg, "function ");
      strcat(err_msg, fun_name);
      strcat(err_msg, " not available");
      send_error(&ctx, err_msg);
    }
    """

    handling = Enum.concat(if_statements, [last_statement]) |> Enum.join(" else ")

    ~g"""
    #{generate_handle_message_declaration()} {
      int index = 0;
      int version;
      ei_decode_version(in_buff->buff, &index, &version);

      int arity;
      ei_decode_tuple_header(in_buff->buff, &index, &arity);

      char fun_name[2048];
      ei_decode_atom(in_buff->buff, &index, fun_name);
                
      cnode_context ctx = {
        .node_name = node_name, 
        .ei_fd = ei_fd,
        .e_pid = &emsg.from,
        .wrapper = state
      };

      #{handling}

      return 0;
    }
    """r
  end

  defp generate_caller_function({name, args, specs}) do
    declaration = generate_caller_function_declaration(name)
    args_decoding = generate_args_decoding(args)

    implemented_fun_args =
      [
        "ctx"
        | args
          |> Enum.map(fn
            {_name, :state} -> "ctx->wrapper->state"
            {name, _type} -> to_string(name)
          end)
      ]
      |> Enum.join(", ")

    implemented_fun_call = ~g<#{name}(#{implemented_fun_args});>

    implemented_fun_call_ctx =
      if are_void_fun_specs(specs) do
        implemented_fun_call
      else
        ~g"""
        UNIFEX_TERM result = #{implemented_fun_call}
        if (result != EMPTY_UNIFEX_TERM) {
          send_and_free(ctx, result);
        }
        """
      end

    ~g"""
    #{declaration} {
      #{args_decoding}
      ctx->released_states = new_state_linked_list();
      
      #{implemented_fun_call_ctx}

      free_states(ctx, ctx->released_states, ctx->wrapper);
    }
    """
  end

  defp generate_caller_function_declaration({name, _args}) do
    generate_caller_function_declaration(name)
  end

  defp generate_caller_function_declaration(name) do
    ~g"void #{name}_caller(const char * in_buff, int * index, cnode_context * ctx)"
  end

  def optional_state_def(%CodeGenerationMode{use_state: false} = _mode) do
    ~g"""
    typedef struct UnifexState {
      void * field;
    } UnifexState;
    typedef UnifexState State;
    """
  end

  def optional_state_def(_mode) do
    ~g<>
  end

  def optional_state_related_functions_declaration(%CodeGenerationMode{use_state: false} = _mode) do
    ~g"""
    void handle_destroy_state(UnifexEnv *env, State *state);
    """
  end

  def optional_state_related_functions_declaration(_mode) do
    ~g<>
  end

  def optional_state_related_functions(%CodeGenerationMode{use_state: false} = _mode) do
    ~g"""
    void handle_destroy_state(UnifexEnv *env, State *state) {}
    """
  end

  def optional_state_related_functions(_mode) do
    ~g<>
  end

  @impl CodeGenerator
  def generate_header(name, _module, functions, results, sends, _callbacks, mode) do
    ~g"""
    #pragma once

    #include <stdio.h>
    #include <stdint.h>
    #include <string.h>
    #include <stdlib.h>

    #ifndef _REENTRANT
    #define _REENTRANT 
                      
    #endif
    #include <ei_connect.h>
    #include <erl_interface.h>

    #include <unifex/cnode_utils.h>
    #include "#{InterfaceIO.user_header_path(name)}"

    #ifdef __cplusplus
    extern "C" {
    #endif

    #{optional_state_def(mode)}

    struct UnifexStateWrapper {
      UnifexState *state;
    };

    void unifex_release_state(UnifexEnv *env, UnifexState *state);
    UnifexState *unifex_alloc_state(UnifexEnv *env);
    void handle_destroy_state(UnifexEnv *env, UnifexState *state);

    #{
      CodeGeneratorUtils.generate_functions_declarations(
        Enum.zip(functions, results)
        |> Enum.map(fn
          {{name, args}, {name, specs}} -> {name, args, specs}
        end),
        &generate_implemented_function_declaration/1
      )
    }
    #{
      CodeGeneratorUtils.generate_functions_declarations(
        results,
        &generate_result_function_declaration/1
      )
    }
    #{
      CodeGeneratorUtils.generate_functions_declarations(
        functions,
        &generate_caller_function_declaration/1
      )
    }
    #{
      CodeGeneratorUtils.generate_functions_declarations(
        sends,
        &generate_send_function_declaration/1
      )
    }

    #ifdef __cplusplus
    }
    #endif
    """r
  end

  @impl CodeGenerator
  def generate_source(name, _module, functions, results, _dirty_funs, sends, _callbacks, mode) do
    ~g"""
    #include <stdio.h>
    #include "#{name}.h"

    #{optional_state_related_functions(mode)}

    size_t unifex_state_wrapper_sizeof() {
      return sizeof(struct UnifexStateWrapper);
    }

    void unifex_release_state(UnifexEnv *env, UnifexState *state) {
      UnifexStateWrapper *wrapper = 
          (UnifexStateWrapper *) malloc(sizeof(UnifexStateWrapper));
      wrapper->state = state;
      add_item(env->released_states, wrapper);
    }

    UnifexState *unifex_alloc_state(UnifexEnv *env) {
      return (UnifexState *)malloc(sizeof(UnifexState));
    }

    #{CodeGeneratorUtils.generate_functions(results, &generate_result_function/1)}
    #{
      CodeGeneratorUtils.generate_functions(
        Enum.zip(functions, results)
        |> Enum.map(fn
          {{name, args}, {name, specs}} -> {name, args, specs}
        end),
        &generate_caller_function/1
      )
    }
    #{CodeGeneratorUtils.generate_functions(sends, &generate_send_function/1)}

    #{generate_handle_message(functions)}

    void handle_destroy_state_wrapper(UnifexEnv *env, struct UnifexStateWrapper *wrapper) {
      handle_destroy_state(env, wrapper->state);
    }

    int wrappers_cmp(struct UnifexStateWrapper *a, struct UnifexStateWrapper *b) {
      return a->state == b->state ? 0 : 1;
    }

    void free_state(UnifexStateWrapper *wrapper) {
      free(wrapper->state);
    }

    """r
  end
end
