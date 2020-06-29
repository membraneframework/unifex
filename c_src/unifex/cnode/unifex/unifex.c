#include "unifex.h"
#include <arpa/inet.h>
#include <unistd.h>

void prepare_ei_x_buff(UnifexEnv *env, ei_x_buff *buff, const char *msg_type) {
  ei_x_new_with_version(buff);
  ei_x_encode_tuple_header(buff, 2);
  ei_x_encode_atom(buff, env->node_name);
  ei_x_encode_tuple_header(buff, 2);
  ei_x_encode_atom(buff, msg_type);
}

void send_and_free(UnifexEnv *ctx, erlang_pid *pid, ei_x_buff *out_buff) {
  ei_send(ctx->ei_fd, pid, out_buff->buff, out_buff->index);
  ei_x_free(out_buff);
}

void send_to_server_and_free(UnifexEnv *ctx, ei_x_buff *out_buff) {
  send_and_free(ctx, ctx->e_pid, out_buff);
}

void sending_error(UnifexEnv *ctx, const char *msg) {
  ei_x_buff buff;
  ei_x_buff *out_buff = &buff;
  prepare_ei_x_buff(ctx, out_buff, "error");

  long msg_len = (long)strlen(msg);
  ei_x_encode_binary(out_buff, msg, msg_len);

  send_to_server_and_free(ctx, out_buff);
}

void add_item(UnifexEnv *env, void *state) {
  UnifexStateNode *node = malloc(sizeof(UnifexStateNode));
  node->state = state;
  node->next = env->released_states;
  env->released_states = node;
}

void free_states(UnifexEnv *env) {
  while (env->released_states) {
    if (env->released_states->state != env->state) {
      unifex_destroy_state(env, env->released_states->state);
    }
    UnifexStateNode *next = env->released_states->next;
    free(env->released_states);
    env->released_states = next;
  }
}

int receive(UnifexEnv *env) {
  ei_x_buff in_buff;
  ei_x_new(&in_buff);
  erlang_msg emsg;
  int res = 0;
  switch (ei_xreceive_msg_tmo(env->ei_fd, &emsg, &in_buff, 100)) {
  case ERL_TICK:
    break;
  case ERL_ERROR:
    res = erl_errno != ETIMEDOUT;
    break;
  default:
    if (emsg.msgtype == ERL_REG_SEND) {
      env->e_pid = &emsg.from;
      int index = 0;
      int version;
      ei_decode_version(in_buff.buff, &index, &version);

      int arity;
      ei_decode_tuple_header(in_buff.buff, &index, &arity);

      char fun_name[2048];
      ei_decode_atom(in_buff.buff, &index, fun_name);

      handle_message(env, fun_name, &index, &in_buff);
      free_states(env);
      break;
    }
  }
  ei_x_free(&in_buff);
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

int main_function(int argc, char **argv) {
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

  UnifexEnv env = {.node_name = node_name,
                   .ei_fd = ei_fd,
                   .e_pid = NULL,
                   .state = NULL,
                   .released_states = NULL};

  while (!receive(&env))
    ;
  close(listen_fd);
  close(ei_fd);
  return 0;
}