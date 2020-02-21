#include "cnode_utils.h"

void prepare_ei_x_buff(ei_x_buff *buff, const char *node_name,
                       const char *msg_type) {
  ei_x_new_with_version(buff);
  ei_x_encode_tuple_header(buff, 2);
  ei_x_encode_atom(buff, node_name);
  ei_x_encode_tuple_header(buff, 2);
  ei_x_encode_atom(buff, msg_type);
}

void prepare_result_buff(ei_x_buff *buff, const char *node_name) {
  prepare_ei_x_buff(buff, node_name, "result");
}

void prepare_send_buff(ei_x_buff *buff) {
  ei_x_new_with_version(buff);
  ei_x_encode_tuple_header(buff, 1);
}

void prepare_error_buff(ei_x_buff *buff, const char *node_name) {
  prepare_ei_x_buff(buff, node_name, "error");
}

void sending_and_freeing(cnode_context *ctx, ei_x_buff *out_buff) {
  ei_send(ctx->ei_fd, ctx->e_pid, out_buff->buff, out_buff->index);
  ei_x_free(out_buff);
}

void sending_error(cnode_context *ctx, const char *msg) {
  ei_x_buff buff;
  ei_x_buff *out_buff = &buff;
  prepare_error_buff(out_buff, ctx->node_name);

  long msg_len = (long)strlen(msg);
  ei_x_encode_binary(out_buff, msg, msg_len);

  sending_and_freeing(ctx, out_buff);
}

void add_item(state_linked_list *list, UnifexStateWrapper *item) {
  state_node *node = (state_node *)malloc(sizeof(state_node));
  node->item = item;
  node->next = list->head;
  list->head = node;
}

void rec_free_node(state_node *n) {
  if (n == NULL)
    return;

  rec_free_node(n->next);
  free(n->item);
  free(n);
}

void free_states(UnifexEnv *env, state_linked_list *list,
                 UnifexStateWrapper *main_state) {
  for (state_node *curr = list->head; curr != NULL; curr = curr->next) {
    if (wrappers_cmp(curr->item, main_state)) {
      handle_destroy_state_wrapper(env, curr->item);
      free_state(curr->item);
    }
  }
  rec_free_node(list->head);
  free(list);
}

state_linked_list *new_state_linked_list() {
  state_linked_list *res =
      (state_linked_list *)malloc(sizeof(state_linked_list));
  res->head = NULL;
  return res;
}

int receive(int ei_fd, const char *node_name, UnifexStateWrapper *state) {
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
        handle_message(ei_fd, node_name, emsg, &in_buf, state)) {
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

  UnifexStateWrapper *state =
      (UnifexStateWrapper *)malloc(unifex_state_wrapper_sizeof());
  memset(state, 0, unifex_state_wrapper_sizeof());

  int res = 0;
  int cont = 1;
  while (cont) {
    switch (receive(ei_fd, node_name, state)) {
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