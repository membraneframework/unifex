defmodule Unifex.CodeGenerators.CNode do
  use Bunch

  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]
  alias Unifex.{CodeGenerationMode, CodeGenerator, InterfaceIO}
  alias Unifex.CodeGenerator.{BaseType, Utils}

  @behaviour CodeGenerator

  def generate_tuple_maker(content) do
    {types, results} = Enum.unzip(content)

    tuple_header =
      case {Enum.count(types), Enum.count(types, &(&1 != :state))} do
        {n, 1} when n > 1 ->
          []

        {_, tuple_size} ->
          [~g<ei_x_encode_tuple_header(out_buff, #{tuple_size});>]
      end

    Enum.join(tuple_header ++ results, "\n")
  end

  defp generate_implemented_function_declaration({name, args, specs}) do
    args_declarations =
      [
        "cnode_context * ctx"
        | Enum.flat_map(args, fn {name, type} ->
            BaseType.generate_declaration(type, name, CNode)
          end)
      ]
      |> Enum.join(", ")

    return_type =
      if are_void_fun_specs(specs) do
        ~g<void>
      else
        ~g<UNIFEX_TERM>
      end

    ~g<#{return_type} #{name}(#{args_declarations})>
  end

  defp generate_result_function({name, specs}) do
    declaration = generate_result_function_declaration({name, specs})
    {result, _meta} = generate_function_spec_traverse_helper(specs)

    if declaration == "" do
      ""
    else
      ~g"""
      #{declaration} {
        ei_x_buff * out_buff = (ei_x_buff *) malloc(sizeof(ei_x_buff));
        prepare_result_buff(out_buff, ctx->node_name);

        #{result}

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

    {result, _meta} = generate_function_spec_traverse_helper(specs)

    ~g"""
    #{declaration} {
      ei_x_buff * out_buff = (ei_x_buff *) malloc(sizeof(ei_x_buff));
      ei_x_new_with_version(out_buff);

      #{result}

      sending_and_freeing(ctx, out_buff);
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
        | Enum.flat_map(args, fn {name, type} ->
            BaseType.generate_declaration(type, name, CNode)
          end)
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
      sending_error(&ctx, err_msg);
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
    """
  end

  defp generate_caller_function({name, args, specs}) do
    declaration = generate_caller_function_declaration(name)

    args_declaration =
      args
      |> Enum.flat_map(fn {name, type} -> BaseType.generate_declaration(type, name, NIF) end)
      |> Enum.map(&~g<#{&1};>)
      |> Enum.join("\n")

    args_initialization =
      args
      |> Enum.map(fn {name, type} -> BaseType.generate_initialization(type, name, CNode) end)
      |> Enum.join("\n")

    args_parsing =
      args
      |> Enum.map(fn {name, type} ->
        BaseType.generate_arg_parse(type, name, nil, CNode)
      end)
      |> Enum.join("\n")

    implemented_fun_args =
      [
        "ctx"
        | Enum.map(args, fn {name, type} -> BaseType.generate_arg_name(type, name, CNode) end)
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
          sending_and_freeing(ctx, result);
        }
        """
      end

    ~g"""
    #{declaration} {
      #{args_declaration}
      #{args_initialization}
      #{args_parsing}
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
      CodeGenerator.Utils.generate_functions_declarations(
        Enum.zip(functions, results)
        |> Enum.map(fn
          {{name, args}, {name, specs}} -> {name, args, specs}
        end),
        &generate_implemented_function_declaration/1
      )
    }
    #{
      CodeGenerator.Utils.generate_functions_declarations(
        results,
        &generate_result_function_declaration/1
      )
    }
    #{
      CodeGenerator.Utils.generate_functions_declarations(
        functions,
        &generate_caller_function_declaration/1
      )
    }
    #{
      CodeGenerator.Utils.generate_functions_declarations(
        sends,
        &generate_send_function_declaration/1
      )
    }

    #ifdef __cplusplus
    }
    #endif
    """
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

    #{CodeGenerator.Utils.generate_functions(results, &generate_result_function/1)}
    #{
      CodeGenerator.Utils.generate_functions(
        Enum.zip(functions, results)
        |> Enum.map(fn
          {{name, args}, {name, specs}} -> {name, args, specs}
        end),
        &generate_caller_function/1
      )
    }
    #{CodeGenerator.Utils.generate_functions(sends, &generate_send_function/1)}

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

    int main(int argc, char ** argv) {
      return main_function(argc, argv);
    }
    """
  end

  defp generate_function_spec_traverse_helper(specs) do
    specs
    |> Utils.generate_function_spec_traverse_helper(%{
      arg_serializer: fn type, name ->
        {type, BaseType.generate_arg_serialize(type, name, CNode)}
      end,
      tuple_serializer: &{:tuple, generate_tuple_maker(&1)}
    })
    |> case do
      {{_type, result}, meta} -> {result, meta}
    end
  end
end
