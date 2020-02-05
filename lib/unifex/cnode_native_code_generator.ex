defmodule Unifex.CNodeNativeCodeGenerator do
  alias Unifex.{BaseType, InterfaceIO}
  use Bunch

  defmacro __using__(_args) do
    quote do
      import unquote(__MODULE__), only: [gen: 2, sigil_g: 2]
    end
  end

  @type code_t() :: String.t()

  @doc """
  Sigil used for indentation of generated code.

  By itself it does nothing, but has very useful flags:
  * `r` trims trailing whitespaces of each line and removes subsequent empty
    lines
  * `t` trims the string
  * `i` indents all but the first line. Helpful when used
    inside string interpolation that already has been indented
  * `I` indents every line of string
  """
  @spec sigil_g(String.t(), charlist()) :: String.t()
  def sigil_g(content, 'r' ++ flags) do
    content =
      content
      |> String.split("\n")
      |> Enum.map(&String.trim_trailing/1)
      |> Enum.reduce([], fn
        "", ["" | _] = acc -> acc
        v, acc -> [v | acc]
      end)
      |> Enum.reverse()
      |> Enum.join("\n")

    sigil_g(content, flags)
  end

  def sigil_g(content, 't' ++ flags) do
    content = content |> String.trim()
    sigil_g(content, flags)
  end

  def sigil_g(content, 'i' ++ flags) do
    [first | rest] = content |> String.split("\n")
    content = [first | rest |> Enum.map(&indent/1)] |> Enum.join("\n")
    sigil_g(content, flags)
  end

  def sigil_g(content, 'I' ++ flags) do
    lines = content |> String.split("\n")
    content = lines |> Enum.map(&indent/1) |> Enum.join("\n")
    sigil_g(content, flags)
  end

  def sigil_g(content, []) do
    content
  end

  @doc """
  Helper for generating code. Uses `sigil_g/2` underneath.

  It supports all the flags supported by `sigil_g/2` and the following ones:
  * `j(joiner)` - joins list of strings using `joiner`
  * n - alias for `j(\\n)`

  If passed a list and flags supported by `sigil_g/2`, each flag will be executed
  on each element of the list, until the list is joined by using `j` or `n` flag.
  """
  @spec gen(String.Chars.t() | [String.Chars.t()], charlist()) :: String.t() | [String.t()]
  def gen(content, 'j(' ++ flags) when is_list(content) do
    {joiner, ')' ++ flags} = flags |> Enum.split_while(&([&1] != ')'))
    content = content |> Enum.join("#{joiner}")
    gen(content, flags)
  end

  def gen(content, 'n' ++ flags) when is_list(content) do
    gen(content, 'j(\n)' ++ flags)
  end

  def gen(content, flags) when is_list(content) do
    content |> Enum.map(&gen(&1, flags))
  end

  def gen(content, flags) do
    sigil_g(content, flags)
  end

  @spec generate_code(name :: String.t(), specs :: Unifex.SpecsParser.parsed_specs_t()) ::
          {code_t(), code_t()}
  def generate_code(name, specs) do
    IO.puts("\n\n\n generating cnode \n\n\n")

    module = specs |> Keyword.get(:module)
    fun_specs = specs |> Keyword.get_values(:fun_specs)
    dirty_funs = specs |> Keyword.get_values(:dirty) |> List.flatten() |> Map.new()
    sends = specs |> Keyword.get_values(:sends)
    callbacks = specs |> Keyword.get_values(:callbacks)

    {functions, results} =
      fun_specs
      |> Enum.map(fn {name, args, results} -> {{name, args}, {name, results}} end)
      |> Enum.unzip()

    results = results |> Enum.flat_map(fn {name, specs} -> specs |> Enum.map(&{name, &1}) end)
    header = generate_header(name, module, functions, results, sends, callbacks)
    source = generate_source(name, module, functions, results, dirty_funs, sends, callbacks)

    {header, source}
  end

  defp generate_function_spec_traverse_helper(node) do
    node
    |> case do
      {:__aliases__, [alias: als], atoms} ->
        generate_function_spec_traverse_helper(als || Module.concat(atoms))

      atom when is_atom(atom) ->
        {BaseType.generate_arg_serialize({:"\"#{atom}\"", :atom}), []}

      {:"::", _, [name, {:label, _, _}]} when is_atom(name) ->
        {BaseType.generate_arg_serialize({:"\"#{name}\"", :atom}), label: name}

      {:"::", _, [{name, _, _}, {type, _, _}]} ->
        {BaseType.generate_arg_serialize({name, type}), arg: {name, type}}

      {:"::", meta, [name_var, [{type, type_meta, type_ctx}]]} ->
        generate_function_spec_traverse_helper(
          {:"::", meta, [name_var, {{:list, type}, type_meta, type_ctx}]}
        )

      {a, b} ->
        generate_function_spec_traverse_helper({:{}, [], [a, b]})

      {:{}, _, content} ->
        {results, meta} =
          content
          |> Enum.map(&generate_function_spec_traverse_helper/1)
          |> Enum.unzip()

        {generate_tuple_maker(results), meta}

      [{_name, _, _} = name_var] ->
        generate_function_spec_traverse_helper({:"::", [], [name_var, [name_var]]})

      {_name, _, _} = name_var ->
        generate_function_spec_traverse_helper({:"::", [], [name_var, name_var]})
    end
    ~> ({result, meta} -> {result, meta |> List.flatten()})
  end

  defp generate_tuple_maker(_content) do
    # IO.inspect(content)
    # IO.inspect ~g<({
    #   const ERL_NIF_TERM terms[] = {
    #     #{content |> gen('j(,\n    )iit')}
    #   };
    #   enif_make_tuple_from_array(env, terms, #{length(content)});
    # })>

    ""
  end

  defp generate_implemented_function_declaration({name, args}) do
    args_declarations =
      ["const cnode_context * ctx" | args |> Enum.flat_map(&BaseType.generate_declaration/1)]
      |> Enum.join(", ")

    ~g<UNIFEX_TERM #{name}(#{args_declarations})>
  end

  defp generate_functions(results, generator) do
    results
    |> Enum.map(generator)
    |> Enum.join("\n")
  end

  defp generate_functions_declarations(results, generator) do
    results
    |> Enum.map(generator)
    |> Enum.map(&(&1 <> ";"))
    |> Enum.join("\n")
  end

  defp generate_args_decoding(args) do
    args
    |> Enum.map(fn
      {name, :atom} ->
        ~g<char #{name}[2048];
                ei_decode_atom(in_buff, index, #{name}));>

      {name, :int} ->
        ~g<long long #{name};
                ei_decode_longlong(in_buff, index, #{name});>

      {name, :string} ->
        ~g<char #{name}[2048];
                long #{name}_len;
                ei_decode_binary(in_buff, index, (void *) #{name}, &#{name}_len);
                #{name}[#{name}_len] = 0;>
    end)
    |> Enum.join("\n")
  end

  defp generate_result_encoding({var, :label}) do
    generate_result_encoding({var, :atom})
  end

  defp generate_result_encoding({var_name, :int}) do
    ~g<long long casted_#{var_name} = (long long) var_name;
        ei_x_encode_longlong(out_buff, casted_#{var_name});>
  end

  defp generate_result_encoding({var_name, :string}) do
    ~g<long #{var_name}_len = (long) strlen(#{var_name});
        ei_x_encode_binary(out_buff, #{var_name}, #{var_name}_len);>
  end

  defp generate_result_encoding({var_name, :atom}) do
    ~g<ei_x_encode_atom(out_buff, #{var_name});>
  end

  defp generate_label_encoding(label_name) do
    var_name = ~g<label_#{label_name}>
    encoding = generate_result_encoding({var_name, :atom})
    ~g<char #{var_name}[] = "#{label_name}";
        #{encoding}>
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

  def generate_result_function({name, specs}) do
    declaration = generate_result_function_declaration({name, specs})

    {_result, meta} = generate_function_spec_traverse_helper(specs)
    encodings = generate_encoding_block(meta)

    ~g[#{declaration} {
        ei_x_buff * out_buff = (ei_x_buff *) malloc(sizeof(ei_x_buff));
        prepare_ei_x_buff(out_buff, ctx->node_name);

        ei_x_encode_tuple_header(out_buff, #{length(encodings)});

        #{encodings |> Enum.join("\n    ")}

        return out_buff;
    }]
  end

  def generate_result_function_declaration({name, specs}) do
    fun_name_prefix = [name, :result] |> Enum.join("_")
    function_declaration_template("UNIFEX_TERM", fun_name_prefix, specs)
  end

  def generate_send_function_declaration(specs) do
    function_declaration_template("void", "send", specs)
  end

  def generate_send_function(specs) do
    declaration = generate_send_function_declaration(specs)

    {_result, meta} = generate_function_spec_traverse_helper(specs)
    encodings = generate_encoding_block(meta)

    ~g[#{declaration} {
      ei_x_buff * out_buff = (ei_x_buff *) malloc(sizeof(ei_x_buff));
      prepare_ei_x_buff(out_buff, ctx->node_name);
      
      ei_x_encode_tuple_header(out_buff, #{length(encodings)});

      #{encodings |> Enum.join("\n    ")}

      send_and_free(ctx, out_buff);
    }]
  end

  defp function_declaration_template(return_type, fun_name_prefix, specs) do
    {_result, meta} = generate_function_spec_traverse_helper(specs)
    args = meta |> Keyword.get_values(:arg)
    labels = meta |> Keyword.get_values(:label)

    args_declarations =
      ["const cnode_context * ctx" | args |> Enum.flat_map(&BaseType.generate_declaration/1)]
      |> Enum.join(", ")

    fun_name = [fun_name_prefix | labels] |> Enum.join("_")

    ~g<#{return_type} #{fun_name}(#{args_declarations})>
  end

  def generate_handle_message_declaration() do
    "int handle_message(int ei_fd, const char *node_name, erlang_msg emsg,
            ei_x_buff *in_buff)"
  end

  def generate_handle_message(functions) do
    if_statements =
      functions
      |> Enum.map(fn
        {f_name, _args} ->
          ~g"""
          if (strcmp(fun_name, "#{f_name}") == 0) {
              #{f_name}_caller(in_buff->buff, &index, &ctx);
          }
          """r
      end)

    last_statement = """
    {
        char err_msg[4000];
        strcpy(err_msg, "function ");
        strcat(err_msg, fun_name);
        strcat(err_msg, " not available");
        send_error(&ctx, err_msg);
        fflush(stderr);
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
            .e_pid = &emsg.from
        };

        #{handling}
    }
    """r
  end

  def generate_cnode_generic_utilities() do
    ~g"""


    int receive(int ei_fd, const char *node_name) {
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
              handle_message(ei_fd, node_name, emsg, &in_buf)) {
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

      int res = 0;
      int cont = 1;
      while (cont) {
        switch (receive(ei_fd, node_name)) {
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

  def generate_caller_function({name, args}) do
    declaration = generate_caller_function_declaration(name)
    args_decoding = generate_args_decoding(args)

    implemented_fun_args =
      ["ctx" | args |> Enum.map(fn {name, _type} -> to_string(name) end)]
      |> Enum.join(", ")

    implemented_fun_call = ~g<#{name}(#{implemented_fun_args});>

    ~g"""
        #{declaration} {
            #{args_decoding}
            UNIFEX_TERM result = #{implemented_fun_call}
            if (result != NULL) {
              send_and_free(ctx, result);
            }
        }
    """
  end

  def generate_caller_function_declaration({name, _args}) do
    generate_caller_function_declaration(name)
  end

  def generate_caller_function_declaration(name) do
    ~g"void #{name}_caller(const char * in_buff, int * index, const cnode_context * ctx)"
  end

  def generate_header(name, _module, functions, results, sends, _callbacks) do
    ~g"""
    #pragma once

    #include <stdio.h>
    #include <stdint.h>

    #ifndef _REENTRANT
    #define _REENTRANT // For some reason __erl_errno is undefined unless _REENTRANT
                      // is defined
    #endif
    #include <ei_connect.h>
    #include <erl_interface.h>

    #include "#{InterfaceIO.user_header_path(name)}"

    #ifdef __cplusplus
    extern "C" {
    #endif

    typedef ei_x_buff * UNIFEX_TERM;

    typedef struct cnode_context {
        const char * node_name;
        int ei_fd; 
        erlang_pid * e_pid;
    } cnode_context;

    typedef const cnode_context UnifexEnv;

    #{generate_functions_declarations(functions, &generate_implemented_function_declaration/1)}
    #{generate_functions_declarations(results, &generate_result_function_declaration/1)}
    #{generate_functions_declarations(functions, &generate_caller_function_declaration/1)}
    #{generate_functions_declarations(sends, &generate_send_function_declaration/1)}

    #ifdef __cplusplus
    }
    #endif
    """r
  end

  defp generate_source(name, _module, functions, results, _dirty_funs, sends, _callbacks) do
    ~g"""
    #include "#{name}.h"

    static void prepare_ei_x_buff(ei_x_buff *buff, const char *node_name) {
        ei_x_new_with_version(buff);
        ei_x_encode_tuple_header(buff, 2);
        ei_x_encode_atom(buff, node_name);
    }

    static void send_and_free(const cnode_context * ctx, ei_x_buff * out_buff) {
      ei_send(ctx->ei_fd, ctx->e_pid, out_buff->buff, out_buff->index);
      ei_x_free(out_buff);
    }

    static void send_error(const cnode_context * ctx, const char * msg) {
      ei_x_buff buff;
      ei_x_buff * out_buff = &buff;
      prepare_ei_x_buff(out_buff, ctx->node_name);
      
      ei_x_encode_tuple_header(out_buff, 2);
      #{generate_label_encoding("error")}
      #{generate_result_encoding({"msg", :string})}

      send_and_free(ctx, out_buff);
    }

    #{generate_functions(results, &generate_result_function/1)}
    #{generate_functions(functions, &generate_caller_function/1)}
    #{generate_functions(sends, &generate_send_function/1)}

    #{generate_handle_message(functions)}
    #{generate_cnode_generic_utilities()}
    """r
  end

  defp indent(line) do
    "  #{line}"
  end
end
