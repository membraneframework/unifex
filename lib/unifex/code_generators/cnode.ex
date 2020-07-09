defmodule Unifex.CodeGenerators.CNode do
  use Bunch

  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]
  alias Unifex.{CodeGenerator, InterfaceIO, Specs}
  alias Unifex.CodeGenerator.{BaseType, Utils}

  @behaviour CodeGenerator

  @impl CodeGenerator
  def generate_header(specs) do
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

    #include <unifex/unifex.h>
    #include <unifex/unifex_cnode.h>
    #include <unifex/payload.h>
    #include "#{InterfaceIO.user_header_path(specs.name)}"

    #ifdef __cplusplus
    extern "C" {
    #endif

    #{generate_state_related_declarations(specs)}

    #{
      CodeGenerator.Utils.generate_functions_declarations(
        specs.functions_args,
        &generate_implemented_function_declaration/1
      )
    }
    #{
      CodeGenerator.Utils.generate_functions_declarations(
        specs.functions_results,
        &generate_result_function_declaration/1
      )
    }
    #{
      CodeGenerator.Utils.generate_functions_declarations(
        specs.functions_args,
        &generate_caller_function_declaration/1
      )
    }
    #{
      CodeGenerator.Utils.generate_functions_declarations(
        specs.sends,
        &generate_send_function_declaration/1
      )
    }
    #{generate_main_function_declaration(specs.callbacks)}

    #ifdef __cplusplus
    }
    #endif
    """
  end

  @impl CodeGenerator
  def generate_source(specs) do
    ~g"""
    #include <stdio.h>
    #include "#{specs.name}.h"

    #{generate_state_related_functions(specs)}

    #{
      CodeGenerator.Utils.generate_functions(specs.functions_results, &generate_result_function/1)
    }
    #{CodeGenerator.Utils.generate_functions(specs.functions_args, &generate_caller_function/1)}
    #{CodeGenerator.Utils.generate_functions(specs.sends, &generate_send_function/1)}

    #{generate_handle_message(specs.functions_args)}

    #{generate_main_function(specs.callbacks)}
    """
  end

  defp generate_main_function_declaration(callbacks) do
    main = Map.get(callbacks, :main, "unifex_cnode_main_function")
    ~g<int #{main}(int argc, char** argv);>
  end

  defp generate_main_function(callbacks) do
    main = Map.get(callbacks, :main, "unifex_cnode_main_function")

    ~g"""
    int main(int argc, char **argv) {
      return #{main}(argc, argv);
    }
    """
  end

  defp generate_implemented_function_declaration({name, args}) do
    args_declarations = ["UnifexEnv * env" | generate_args_declarations(args)] |> Enum.join(", ")

    ~g<UNIFEX_TERM #{name}(#{args_declarations})>
  end

  defp generate_result_function_declaration({name, specs}) do
    {_result, meta} = generate_function_spec_traverse_helper(specs)
    args = meta |> Keyword.get_values(:arg)

    args_declarations =
      ["UnifexEnv * env" | generate_args_declarations(args, :const)] |> Enum.join(", ")

    labels = meta |> Keyword.get_values(:label)
    fun_name = [name, "result" | labels] |> Enum.join("_")
    ~g<UNIFEX_TERM #{fun_name}(#{args_declarations})>
  end

  defp generate_result_function({name, specs}) do
    declaration = generate_result_function_declaration({name, specs})
    {result, _meta} = generate_function_spec_traverse_helper(specs)

    ~g"""
    #{declaration} {
      ei_x_buff * out_buff = (ei_x_buff *) malloc(sizeof(ei_x_buff));
      unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

      #{result}

      return out_buff;
    }
    """
  end

  defp generate_send_function_declaration(specs) do
    {_result, meta} = generate_function_spec_traverse_helper(specs)
    args = meta |> Keyword.get_values(:arg)

    args_declarations =
      [
        ~g<UnifexEnv * env>,
        ~g<UnifexPid pid>,
        ~g<int flags> | generate_args_declarations(args, :const)
      ]
      |> Enum.join(", ")

    labels = meta |> Keyword.get_values(:label)
    fun_name = ["send" | labels] |> Enum.join("_")
    ~g<int #{fun_name}(#{args_declarations})>
  end

  defp generate_send_function(specs) do
    declaration = generate_send_function_declaration(specs)

    {result, _meta} = generate_function_spec_traverse_helper(specs)

    ~g"""
    #{declaration} {
      UNIFEX_UNUSED(flags);
      ei_x_buff * out_buff = (ei_x_buff *) malloc(sizeof(ei_x_buff));
      ei_x_new_with_version(out_buff);

      #{result}

      unifex_cnode_send_and_free(env, &pid, out_buff);
      return 1;
    }
    """
  end

  defp generate_args_declarations(args, mode \\ :default) do
    Enum.flat_map(args, fn {name, type} ->
      BaseType.generate_declaration(type, name, mode, CNode)
    end)
  end

  defp generate_handle_message(functions) do
    if_statements =
      Enum.map(functions, fn
        {f_name, _args} ->
          ~g"""
          if (strcmp(fun_name, "#{f_name}") == 0) {
              return #{f_name}_caller(env, in_buff);
            }
          """
      end)

    last_statement = """
    {
      return unifex_cnode_undefined_function_error(env, fun_name);
    }
    """

    handling = Enum.concat(if_statements, [last_statement]) |> Enum.join(" else ")

    ~g"""
    UNIFEX_TERM unifex_cnode_handle_message(UnifexEnv *env, char* fun_name, UnifexCNodeInBuff *in_buff) {
      #{handling}
    }
    """
  end

  defp generate_caller_function({name, args}) do
    declaration = generate_caller_function_declaration({name, args})

    args_declaration =
      args |> generate_args_declarations() |> Enum.map(&~g<#{&1};>) |> Enum.join("\n")

    args_initialization =
      args
      |> Enum.map(fn {name, type} -> BaseType.generate_initialization(type, name, CNode) end)
      |> Enum.join("\n")

    args_parsing =
      args
      |> Enum.map(fn {name, type} -> BaseType.generate_arg_parse(type, name, "in_buff", CNode) end)
      |> Enum.join("\n")

    implemented_fun_args =
      [
        "env"
        | Enum.map(args, fn {name, type} -> BaseType.generate_arg_name(type, name, CNode) end)
      ]
      |> Enum.join(", ")

    args_destruction =
      args
      |> Enum.map(fn {name, type} -> BaseType.generate_destruction(type, name, CNode) end)
      |> Enum.reject(&("" == &1))
      |> Enum.join("\n")

    ~g"""
    #{declaration} {
      #{if Enum.empty?(args), do: "UNIFEX_UNUSED(in_buff);", else: ""}
      #{args_declaration}
      #{args_initialization}
      #{args_parsing}
      UNIFEX_TERM result = #{name}(#{implemented_fun_args});
      #{args_destruction}
      return result;
    }
    """
  end

  defp generate_caller_function_declaration({name, _args}) do
    ~g"UNIFEX_TERM #{name}_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff)"
  end

  def generate_state_related_declarations(%Specs{state_type: nil}) do
    ~g<>
  end

  def generate_state_related_declarations(%Specs{state_type: state_type}) do
    ~g"""
    typedef #{state_type} UnifexState;

    UnifexState *unifex_alloc_state(UnifexEnv *env);
    void unifex_release_state(UnifexEnv *env, UnifexState *state);
    void handle_destroy_state(UnifexEnv *env, UnifexState *state);
    """
  end

  def generate_state_related_functions(%Specs{state_type: nil}) do
    ~g"""
    void unifex_cnode_destroy_state(UnifexEnv *env, void *state) {}
    """
  end

  def generate_state_related_functions(%Specs{}) do
    ~g"""
    UnifexState *unifex_alloc_state(UnifexEnv *_env) {
      UNIFEX_UNUSED(_env);
      return (UnifexState *)malloc(sizeof(UnifexState));
    }

    void unifex_release_state(UnifexEnv *env, UnifexState *state) {
      unifex_cnode_add_to_released_states(env, state);
    }

    void unifex_cnode_destroy_state(UnifexEnv *env, void *state) {
      handle_destroy_state(env, (UnifexState*)state);
      free(state);
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

  defp generate_tuple_maker(content) do
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
end
