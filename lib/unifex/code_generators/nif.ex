defmodule Unifex.CodeGenerators.NIF do
  @moduledoc """
  Module responsible for C code genearation based on Unifex specs
  """
  use Bunch
  import Unifex.CodeGenerator.Utils, only: [sigil_g: 2]
  alias Unifex.{CodeGenerationMode, CodeGenerator, InterfaceIO}
  alias Unifex.CodeGenerator.{BaseType, Utils}

  @behaviour CodeGenerator

  @type code_t() :: String.t()

  @impl CodeGenerator
  def generate_header(name, module, functions, results, sends, callbacks, mode) do
    ~g"""
    #pragma once

    #include <stdio.h>
    #include <stdint.h>
    #include <erl_nif.h>
    #include <unifex/unifex.h>
    #include <unifex/payload.h>
    #include "#{InterfaceIO.user_header_path(name)}"

    #ifdef __cplusplus
    extern "C" {
    #endif

    /*
     * Declaration of native functions for module #{module}.
     * The implementation have to be provided by the user.
     */

    #{
      CodeGenerator.Utils.generate_functions_declarations(
        functions,
        &generate_implemented_function_declaration/1
      )
    }

    /*
     * Functions that manage lib and state lifecycle
     * Functions with 'unifex_' prefix are generated automatically,
     * the user have to implement rest of them.
     * Available only and only if in #{InterfaceIO.user_header_path(name)}
     * exisis definition of UnifexNigState
     */

    #{generate_state_related_declarations(module, mode)}

    /*
     * Callbacks for nif lifecycle hooks.
     * Have to be implemented by user.
     */

    #{generate_nif_lifecycle_callbacks_declarations(callbacks)}

    /*
     * Functions that create the defined output from Nif.
     * They are automatically generated and don't need to be implemented.
     */

    #{
      CodeGenerator.Utils.generate_functions_declarations(
        results,
        &generate_result_function_declaration/1
      )
    }

    /*
     * Functions that send the defined messages from Nif.
     * They are automatically generated and don't need to be implemented.
     */

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
  def generate_source(name, module, functions, results, dirty_funs, sends, callbacks, mode) do
    ~g"""
    #include "#{name}.h"

    #{CodeGenerator.Utils.generate_functions(results, &generate_result_function/1)}
    #{CodeGenerator.Utils.generate_functions(sends, &generate_send_function/1)}
    #{generate_state_related_stuff(module, mode)}
    #{generate_nif_lifecycle_callbacks(module, callbacks, mode)}
    #{CodeGenerator.Utils.generate_functions(functions, &generate_export_function/1)}
    #{generate_erlang_boilerplate(module, functions, dirty_funs, callbacks)}
    """
  end

  defp generate_implemented_function_declaration({name, args}) do
    args_declarations =
      [
        ~g<UnifexEnv* env>
        | Enum.flat_map(args, fn {name, type} ->
            BaseType.generate_declaration(type, name, NIF)
          end)
      ]
      |> Enum.join(", ")

    ~g<UNIFEX_TERM #{name}(#{args_declarations})>
  end

  defp generate_result_function({name, specs}) do
    declaration = generate_result_function_declaration({name, specs})
    {result, _meta} = generate_function_spec_traverse_helper(specs)

    ~g"""
    #{declaration} {
      return #{result};
    }
    """
  end

  defp generate_result_function_declaration({name, specs}) do
    {_result, meta} = generate_function_spec_traverse_helper(specs)
    args = meta |> Keyword.get_values(:arg)
    labels = meta |> Keyword.get_values(:label)

    args_declarations =
      [
        ~g<UnifexEnv* env>
        | args
          |> Enum.flat_map(fn {name, type} ->
            BaseType.generate_declaration(type, name, :const, NIF)
          end)
      ]
      |> Enum.join(", ")

    ~g<UNIFEX_TERM #{[name, :result | labels] |> Enum.join("_")}(#{args_declarations})>
  end

  defp generate_send_function(specs) do
    declaration = generate_send_function_declaration(specs)
    {result, _meta} = generate_function_spec_traverse_helper(specs)

    ~g"""
    #{declaration} {
      ERL_NIF_TERM term = #{result};
      return unifex_send(env, &pid, term, flags);
    }
    """
  end

  defp generate_send_function_declaration(specs) do
    {_result, meta} = generate_function_spec_traverse_helper(specs)
    args = meta |> Keyword.get_values(:arg)
    labels = meta |> Keyword.get_values(:label)

    args_declarations =
      [
        ~g<UnifexEnv* env>,
        ~g<UnifexPid pid>,
        ~g<int flags>
        | Enum.flat_map(args, fn {name, type} ->
            BaseType.generate_declaration(type, name, :const, NIF)
          end)
      ]
      |> Enum.join(", ")

    ~g<int #{[:send | labels] |> Enum.join("_")}(#{args_declarations})>
  end

  defp generate_export_function({name, args}) do
    result_var = "result"
    exit_label = "exit_export_#{name}"

    args_declaration =
      args
      |> Enum.flat_map(fn {name, type} -> BaseType.generate_declaration(type, name, NIF) end)
      |> Enum.map(&~g<#{&1};>)
      |> Enum.join("\n")

    args_initialization =
      args
      |> Enum.map(fn {name, type} -> BaseType.generate_initialization(type, name, NIF) end)
      |> Enum.join("\n")

    args_parsing =
      args
      |> Enum.with_index()
      |> Enum.map(fn {{name, type}, i} ->
        postproc_fun = fn arg_getter ->
          ~g"""
          if(!#{arg_getter}) {
            #{result_var} = unifex_raise_args_error(env, "#{name}", "#{inspect(type)}");
            goto #{exit_label};
          }
          """
        end

        BaseType.generate_arg_parse(type, name, "argv[#{i}]", postproc_fun, NIF)
      end)
      |> Enum.join("\n")

    args_destruction =
      args
      |> Enum.map(fn {name, type} -> BaseType.generate_destruction(type, name, NIF) end)
      |> Enum.reject(&("" == &1))
      |> Enum.join("\n")

    args_names =
      args |> Enum.flat_map(fn {name, type} -> BaseType.generate_arg_name(type, name, NIF) end)

    ~g"""
    static ERL_NIF_TERM export_#{name}(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]){
      UNIFEX_UNUSED(argc);
      ERL_NIF_TERM #{result_var};
      #{if args |> Enum.empty?(), do: ~g<UNIFEX_UNUSED(argv);>, else: ""}
      #{generate_unifex_env()}
      #{args_declaration}

      #{args_initialization}

      #{args_parsing}

      #{result_var} = #{name}(#{[:unifex_env | args_names] |> Enum.join(", ")});
      goto #{exit_label};
    #{exit_label}:
      #{args_destruction}
      return result;
    }
    """
  end

  defp generate_state_related_declarations(
         module,
         %CodeGenerationMode{use_state: true} = _mode
       ) do
    state_type = BaseType.generate_native_type(:state, NIF)

    ~g"""
    #define UNIFEX_MODULE "#{module}"

    /**
     * Allocates the state struct. Have to be paired with 'unifex_release_state' call
     */
    #{state_type} unifex_alloc_state(UnifexEnv* env);

    /**
     * Removes a reference to the state object.
     * The state is destructed when the last reference is removed.
     * Each call to 'unifex_release_state' must correspond to a previous
     * call to 'unifex_alloc_state' or 'unifex_keep_state'.
     */
    void unifex_release_state(UnifexEnv* env, #{state_type} state);

    /**
     * Increases reference count of state object.
     * Each call has to be balanced by 'unifex_release_state' call
     */
    void unifex_keep_state(UnifexEnv* env, #{state_type} state);

    /**
     * Callback called when the state struct is destroyed. It should
     * be responsible for releasing any resources kept inside state.
     */
    void handle_destroy_state(UnifexEnv* env, #{state_type} state);
    """
  end

  defp generate_state_related_declarations(nil, _mode) do
    ~g<>
  end

  defp generate_state_related_declarations(_module, _mode) do
    ~g<>
  end

  defp generate_state_related_stuff(nil, _mode) do
    ~g<>
  end

  defp generate_state_related_stuff(_module, %CodeGenerationMode{use_state: true} = _mode) do
    state_type = BaseType.generate_native_type(:state, NIF)

    ~g"""
    ErlNifResourceType *STATE_RESOURCE_TYPE;

    #{state_type} unifex_alloc_state(UnifexEnv* env) {
      UNIFEX_UNUSED(env);
      return (#{state_type}) enif_alloc_resource(STATE_RESOURCE_TYPE, sizeof(UnifexState));
    }

    void unifex_release_state(UnifexEnv * env, #{state_type} state) {
      UNIFEX_UNUSED(env);
      enif_release_resource(state);
    }

    void unifex_keep_state(UnifexEnv * env, #{state_type} state) {
      UNIFEX_UNUSED(env);
      enif_keep_resource(state);
    }

    static void destroy_state(ErlNifEnv* env, void* value) {
      #{state_type} state = (#{state_type}) value;
      #{generate_unifex_env()}
      handle_destroy_state(unifex_env, state);
    }
    """
  end

  defp generate_state_related_stuff(_module, _mode) do
    ~g<>
  end

  defp generate_nif_lifecycle_callbacks_declarations(callbacks) do
    callbacks
    |> Enum.map_join("\n", fn
      {:load, fun_name} ->
        ~g"int #{fun_name}(UnifexEnv * env, void ** priv_data);"

      {:upgrade, fun_name} ->
        ~g"int #{fun_name}(UnifexEnv * env, void ** priv_data, void **old_priv_data);"

      {:unload, fun_name} ->
        ~g"void #{fun_name}(UnifexEnv * env, void * priv_data);"
    end)
  end

  defp state_resource_type_initialization(%CodeGenerationMode{use_state: true} = _mode) do
    ~g"""
      STATE_RESOURCE_TYPE =
        enif_open_resource_type(env, NULL, "UnifexState", (ErlNifResourceDtor*) destroy_state, flags, NULL);
    """
  end

  defp state_resource_type_initialization(_mode) do
    ~g<>
  end

  defp generate_nif_lifecycle_callbacks(nil, _callbacks, _mode) do
    ~g<>
  end

  defp generate_nif_lifecycle_callbacks(_module, callbacks, mode) do
    load_result =
      case callbacks[:load] do
        nil -> "0"
        name -> ~g"#{name}(env, priv_data)"
      end

    load = ~g"""
    static int unifex_load_nif(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
      UNIFEX_UNUSED(load_info);
      UNIFEX_UNUSED(priv_data);

      ErlNifResourceFlags flags = (ErlNifResourceFlags) (ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER);

      #{state_resource_type_initialization(mode)}

      UNIFEX_PAYLOAD_GUARD_RESOURCE_TYPE =
        enif_open_resource_type(env, NULL, "UnifexPayloadGuard", (ErlNifResourceDtor*) unifex_payload_guard_destructor, flags, NULL);

      return #{load_result};
    }
    """

    upgrade =
      case callbacks[:upgrade] do
        nil ->
          ~g""

        name ->
          ~g"""
          static int unifex_upgrade_nif(ErlNifEnv * env, void ** priv_data, void **old_priv_data, ERL_NIF_TERM load_info) {
            UNIFEX_UNUSED(load_info);
            return #{name}(env, priv_data, old_priv_data);
          }
          """
      end

    unload =
      case callbacks[:unload] do
        nil ->
          ~g""

        name ->
          ~g"""
          static void unifex_unload_nif(ErlNifEnv* env, void* priv_data) {
            #{name}(env, priv_data);
          }
          """
      end

    [load, upgrade, unload]
    |> Enum.join("\n")
  end

  defp generate_erlang_boilerplate(nil, _functions, _dirty_funs, _callbacks) do
    ~g<>
  end

  defp generate_erlang_boilerplate(module, functions, dirty_funs, callbacks) do
    printed_funcs =
      functions
      |> Enum.map(fn {name, args} ->
        arity = length(args)

        flags =
          case dirty_funs[{name, arity}] do
            :cpu -> ~g<ERL_NIF_DIRTY_JOB_CPU_BOUND>
            :io -> ~g<ERL_NIF_DIRTY_JOB_IO_BOUND>
            nil -> ~g<0>
          end

        ~g<{"unifex_#{name}", #{arity}, export_#{name}, #{flags}}>
      end)
      |> Enum.join(",\n")

    # Erlang used to have reload callback. It is unsupported from OTP 20
    # Its entry in ERL_NIF_INIT parameters is always NULL
    callback_pointers =
      [:deprecated_reload, :upgrade, :unload]
      |> Enum.map_join(", ", fn hook ->
        case callbacks[hook] do
          nil -> "NULL"
          _ -> "unifex_#{hook}_nif"
        end
      end)

    ~g"""
    static ErlNifFunc nif_funcs[] =
    {
      #{printed_funcs}
    };

    ERL_NIF_INIT(#{module}.Nif, nif_funcs, unifex_load_nif, #{callback_pointers})
    """
  end

  def generate_tuple_maker(content) do
    ~g<({
      const ERL_NIF_TERM terms[] = {
        #{content |> Enum.join(",\n")}
      };
      enif_make_tuple_from_array(env, terms, #{length(content)});
    })>
  end

  defp generate_unifex_env() do
    ~g<UnifexEnv *unifex_env = env;>
  end

  defp generate_function_spec_traverse_helper(specs) do
    Utils.generate_function_spec_traverse_helper(specs, %{
      arg_serializer: fn type, name -> BaseType.generate_arg_serialize(type, name, NIF) end,
      tuple_serializer: &generate_tuple_maker/1
    })
  end
end