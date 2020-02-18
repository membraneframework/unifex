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

  defp generate_implemented_function_declaration({name, args}) do
    args_declarations =
      ["cnode_context * ctx" | args |> Enum.flat_map(&BaseType.generate_declaration/1)]
      |> Enum.join(", ")

    ~g<UNIFEX_TERM #{name}(#{args_declarations})>
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
    *(ctx->state) = #{var_name};
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

    state_encodings_num = meta  
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
      prepare_send_buff(out_buff, ctx->node_name);
      
      ei_x_encode_tuple_header(out_buff, #{length(encodings)});

      #{encodings |> Enum.join("\n")}

      send_and_free(ctx, out_buff);
      free(out_buff);
    }
    """
  end
     
  defp function_declaration_template(return_type, fun_name_prefix, specs) do
    {_result, meta} = generate_function_spec_traverse_helper(specs)
    args = meta |> Keyword.get_values(:arg)

    args_declarations =
      ["cnode_context * ctx" | args |> Enum.flat_map(&BaseType.generate_declaration/1)]
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

    if :void in labels do
      ""
    else
      fun_name = [fun_name_prefix | labels] |> Enum.join("_")
      ~g<#{return_type} #{fun_name}(#{args_declarations})>
    end
  end

  defp generate_handle_message_declaration(mode) do
    opt_arg = optional_state_arg_def(mode)
    "int handle_message(int ei_fd, const char *node_name, erlang_msg emsg,
            ei_x_buff *in_buff#{opt_arg})"
  end

  defp generate_handle_message(functions, mode) do
    opt_arg = optional_state_arg(mode)

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
    #{generate_handle_message_declaration(mode)} {
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
        .e_pid = &emsg.from
        #{optional_state_in_ctx_init(mode)}
      };

      #{handling}
    }
    """r
  end

  defp generate_cnode_generic_utilities(mode) do
    opt_state_def = optional_state_def(mode)
    opt_state_arg_def = optional_state_ptr_arg_def(mode)
    opt_state_ref_arg = optional_state_arg_ref(mode)
    opt_state_arg = optional_state_arg(mode)

    ~g"""
    int receive(int ei_fd, const char *node_name#{opt_state_arg_def}) {
      ei_x_buff in_buf;
      ei_x_new(&in_buf);
      erlang_msg emsg;
      int res = 0;
      switch (ei_xreceive_msg_tmo(ei_fd, &emsg, &in_buf, 100)) {
      case ERL_TICK:
        break;
      case ERL_ERROR:
        res = erl_errno != ETIMEDOUT;
        break;
      default:
        if (emsg.msgtype == ERL_REG_SEND &&
            handle_message(ei_fd, node_name, emsg, &in_buf#{opt_state_arg})) {
          res = -1;
        }
        break;
      }
      
      ei_x_free(&in_buf);
      return res;
    }

    int validate_args(int argc, char **argv) {
      if (argc != 6) {
        return 1;
      }
      for (int i = 1; i < argc; i++) {
        if (strlen(argv[i]) > 255) {
          return 1;
        }
      }
      return 0;
    }

    #ifdef CNODE_DEBUG
    #define DEBUG(X, ...) fprintf(stderr, X "\r\n", ##__VA_ARGS__)
    #else
    #define DEBUG(...)
    #endif


    int listen_sock(int *listen_fd, int *port) {
      int fd = socket(AF_INET, SOCK_STREAM, 0);
      if (fd < 0) {
        return 1;
      }

      int opt_on = 1;
      if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt_on, sizeof(opt_on))) {
      return 1;
      }

      struct sockaddr_in addr;
      unsigned int addr_size = sizeof(addr);
      addr.sin_family = AF_INET;
      addr.sin_port = htons(0);
      addr.sin_addr.s_addr = htonl(INADDR_ANY);

      if (bind(fd, (struct sockaddr *)&addr, addr_size) < 0) {
        return 1;
      }

      if (getsockname(fd, (struct sockaddr *)&addr, &addr_size)) {
        return 1;
      }
      *port = (int)ntohs(addr.sin_port);

      const int queue_size = 5;
      if (listen(fd, queue_size)) {
        return 1;
      }

      *listen_fd = fd;
      return 0;
    }

    int main(int argc, char **argv) {
      if (validate_args(argc, argv)) {
        fprintf(stderr,
                "%s <host_name> <alive_name> <node_name> <cookie> <creation>\r\n",
                argv[0]);
        return 1;
      }

      char host_name[256];
      strcpy(host_name, argv[1]);
      char alive_name[256];
      strcpy(alive_name, argv[2]);
      char node_name[256];
      strcpy(node_name, argv[3]);
      char cookie[256];
      strcpy(cookie, argv[4]);
      short creation = (short)atoi(argv[5]);

      int listen_fd;
      int port;
      if (listen_sock(&listen_fd, &port)) {
        DEBUG("listen error");
        return 1;
      }
      DEBUG("listening at %d", port);

      ei_cnode ec;
      struct in_addr addr;
      addr.s_addr = inet_addr("127.0.0.1");
      if (ei_connect_xinit(&ec, host_name, alive_name, node_name, &addr, cookie,
                           creation) < 0) {
        DEBUG("init error: %d", erl_errno);
        return 1;
      }
      DEBUG("initialized %s (%s)", ei_thisnodename(&ec), inet_ntoa(addr));

      if (ei_publish(&ec, port) == -1) {
        DEBUG("publish error: %d", erl_errno);
        return 1;
      }
      DEBUG("published");
      printf("ready\r\n");
      fflush(stdout);

      ErlConnect conn;
      int ei_fd = ei_accept_tmo(&ec, listen_fd, &conn, 5000);
      if (ei_fd == ERL_ERROR) {
        DEBUG("accept error: %d", erl_errno);
        return 1;
      }
      DEBUG("accepted %s", conn.nodename);

      #{opt_state_def}

      int res = 0;
      int cont = 1;
      while (cont) {
        switch (receive(ei_fd, node_name#{opt_state_ref_arg})) {
        case 0:
          break;
        case 1:
          DEBUG("disconnected");
          cont = 0;
          break;
        default:
          DEBUG("error handling message, disconnecting");
          cont = 0;
          res = 1;
          break;
        }
      }
      close(listen_fd);
      close(ei_fd);
      return res;
    }
    """r
  end

  defp generate_caller_function({name, args}, mode) do
    declaration = generate_caller_function_declaration(name, mode)
    args_decoding = generate_args_decoding(args)

    implemented_fun_args =
      ["ctx" | args |> Enum.map(fn 
        {_name, :state} -> "*(ctx->state)"
        {name, _type} -> to_string(name) 
      end)]
      |> Enum.join(", ")

    implemented_fun_call = ~g<#{name}(#{implemented_fun_args});>

    ~g"""
    #{declaration} {
      #{args_decoding}
      #{optional_prepare_state_list(mode)}
      
      UNIFEX_TERM result = #{implemented_fun_call}
      if (result != EMPTY_UNIFEX_TERM) {
        send_and_free(ctx, result);
      }

      #{optional_state_cleanup(mode)}
    }
    """
  end

  defp generate_caller_function_declaration({name, _args}, mode) do
    generate_caller_function_declaration(name, mode)
  end

  defp generate_caller_function_declaration(name, mode) do
    opt_state = optional_state_arg_def(mode)
    ~g"void #{name}_caller(const char * in_buff, int * index, cnode_context * ctx)"
  end

  defp optional_state_in_ctx_init(%CodeGenerationMode{use_state: true} = _mode) do
    ", .state = state"
  end

  defp optional_state_in_ctx_init(_mode) do
    ""
  end

  def optional_state_arg_def(%CodeGenerationMode{use_state: true} = _mode) do
    ", #{BaseType.State.generate_native_type} state"
  end

  def optional_state_arg_def(_mode) do
    ~g<>
  end

  def optional_state_ptr_arg_def(%CodeGenerationMode{use_state: true} = _mode) do
    ", #{BaseType.State.generate_native_type}* state"
  end

  def optional_state_ptr_arg_def(_mode) do
    ~g<>
  end

  def optional_state_arg(%CodeGenerationMode{use_state: true} = _mode) do
    ", state"
  end

  def optional_state_arg(_mode) do
    ~g<>
  end

  def optional_state_arg_ref(%CodeGenerationMode{use_state: true} = _mode) do
    ", &state"
  end

  def optional_state_arg_ref(_mode) do
    ~g<>
  end

  def optional_state_related_fields(%CodeGenerationMode{use_state: true} = _mode) do
    state_type = BaseType.State.generate_native_type
    ~g"""
    #{state_type}* state;
    state_linked_list * released_states;
    """
  end

  def optional_state_related_fields(_mode) do
    ~g<>
  end

  def optional_prepare_state_list(%CodeGenerationMode{use_state: true} = _mode) do 
    ~g"""
    ctx->released_states = new_state_linked_list();
    """
  end

  def optional_prepare_state_list(_mode) do 
    ~g<>
  end

  def optional_state_cleanup(%CodeGenerationMode{use_state: true} = _mode) do 
    ~g"""
    free_states(ctx, ctx->released_states, *(ctx->state));
    """
  end

  def optional_state_cleanup(_mode) do 
    ~g<>
  end

  def state_aggregating_stuff(%CodeGenerationMode{use_state: true} = _mode) do
    state_type = BaseType.State.generate_native_type

    ~g"""
    typedef struct state_node {
      #{state_type} item;
    #ifdef __cplusplus
      state_node * next;
    #else
      struct state_node * next;
    #endif
    } state_node;

    typedef struct state_linked_list {
      state_node * head;
    } state_linked_list;
    """
  end

  def state_aggregating_stuff(_mode) do
    ~g<>
  end

  def state_related_functions_declarations(%CodeGenerationMode{use_state: true} = _mode) do
    state_type = BaseType.State.generate_native_type

    ~g"""
    void add_item(state_linked_list * list, #{state_type} item);
    void rec_free_node(state_node * n);
    void free_states(UnifexEnv * env, state_linked_list * list, #{state_type} main_state);
    state_linked_list * new_state_linked_list();

    void unifex_release_state(UnifexEnv* env, UnifexState* state);
    UnifexState * unifex_alloc_state(UnifexEnv * env);

    void handle_destroy_state(UnifexEnv * env, UnifexState * state);
    """
  end
  
  def state_related_functions_declarations(_mode) do
    ~g<>
  end

  def state_related_functions(%CodeGenerationMode{use_state: true} = _mode) do
    state_type = BaseType.State.generate_native_type

    ~g"""
    void add_item(state_linked_list * list, #{state_type} item) {
      state_node * node = (state_node *) malloc (sizeof(state_node));
      node->item = item;
      node->next = list->head;
      list->head = node;
    }

    void rec_free_node(state_node * n) {
      if (n == NULL) return;

      rec_free_node(n->next);
      free(n);
    }

    void free_states(UnifexEnv * env, state_linked_list * list, #{state_type} main_state) {
      for (state_node * curr = list->head; curr != NULL; curr = curr->next) {
        if (curr->item != main_state) {
          handle_destroy_state(env, curr->item);
          free(curr->item);
        }
      }
      rec_free_node(list->head);
      free(list);
    }

    state_linked_list * new_state_linked_list() {
      state_linked_list * res = (state_linked_list *) malloc (sizeof(state_linked_list));
      res->head = NULL;
      return res;
    }

    void unifex_release_state(UnifexEnv* env, UnifexState* state) {
      add_item(env->released_states, state);
    }

    UnifexState * unifex_alloc_state(UnifexEnv * env) {
      return (UnifexState *) malloc (sizeof(UnifexState));
    }
    """
  end

  def tate_related_functions(_mode) do
    ~g<>
  end

  def optional_state_def(%CodeGenerationMode{use_state: true} = _mode) do
    state_type = BaseType.State.generate_native_type
    ~g<#{state_type} state = NULL;>
  end

  def optional_state_def(_mode) do
    ~g<>
  end

  @impl CodeGenerator
  def generate_header(name, _module, functions, results, sends, _callbacks, mode) do
    ~g"""
    #pragma once

    #include <stdio.h>
    #include <stdint.h>

    #ifndef _REENTRANT
    #define _REENTRANT 
                      
    #endif
    #include <ei_connect.h>
    #include <erl_interface.h>

    #include "#{InterfaceIO.user_header_path(name)}"

    #ifdef __cplusplus
    extern "C" {
    #endif

    typedef ei_x_buff * UNIFEX_TERM;

    #define EMPTY_UNIFEX_TERM NULL
    #define UNIFEX_UNUSED(x) (void)(x)

    #{state_aggregating_stuff(mode)}

    typedef struct cnode_context {
      const char * node_name;
      int ei_fd; 
      erlang_pid * e_pid;
      #{optional_state_related_fields(mode)}
    } cnode_context;

    typedef cnode_context UnifexEnv;

    #{state_related_functions_declarations(mode)}

    #{
      CodeGeneratorUtils.generate_functions_declarations(
        functions,
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
        &generate_caller_function_declaration/2,
        mode
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

    static void prepare_ei_x_buff(ei_x_buff *buff, const char *node_name, const char * msg_type) {
      ei_x_new_with_version(buff);
      ei_x_encode_tuple_header(buff, 2);
      ei_x_encode_atom(buff, node_name);
      ei_x_encode_tuple_header(buff, 2);
      ei_x_encode_atom(buff, msg_type);
    }

    static void prepare_result_buff(ei_x_buff * buff, const char * node_name) {
      prepare_ei_x_buff(buff, node_name, "result");
    }

    static void prepare_send_buff(ei_x_buff * buff, const char * node_name) {
      prepare_ei_x_buff(buff, node_name, "send");
    }

    static void prepare_error_buff(ei_x_buff * buff, const char * node_name) {
      prepare_ei_x_buff(buff, node_name, "error");
    }

    static void send_and_free(cnode_context * ctx, ei_x_buff * out_buff) {
      ei_send(ctx->ei_fd, ctx->e_pid, out_buff->buff, out_buff->index);
     // ei_x_free(out_buff);
    }

    static void send_error(cnode_context * ctx, const char * msg) {
      ei_x_buff buff;
      ei_x_buff * out_buff = &buff;
      prepare_error_buff(out_buff, ctx->node_name);
      
      #{generate_result_encoding({"msg", :string})}

      send_and_free(ctx, out_buff);
    }

    #{state_related_functions(mode)}

    #{CodeGeneratorUtils.generate_functions(results, &generate_result_function/1)}
    #{CodeGeneratorUtils.generate_functions(functions, &generate_caller_function/2, mode)}
    #{CodeGeneratorUtils.generate_functions(sends, &generate_send_function/1)}

    #{generate_handle_message(functions, mode)}
    #{generate_cnode_generic_utilities(mode)}
    """r
  end
end
