#include "unifex.h"
#include "cnode.h"

UNIFEX_TERM unifex_raise(UnifexEnv *env, const char *message) {
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "raise");
  ei_x_encode_binary(out_buff, message, strlen(message));
  return out_buff;
}

// Helper function to send a term for CNode
// The socket fd is shared with the main receive loop (and possibly a
// background logger thread), so every send is serialized via socket_mutex.
int unifex_send(UnifexEnv *env, UnifexPid *pid, UNIFEX_TERM term, int flags) {
  UNIFEX_UNUSED(flags);
  if (!env || !pid || !term) {
    return 0;
  }

  pthread_mutex_lock(&env->socket_mutex);
  int result = ei_send(env->ei_socket_fd, pid, term->buff, term->index);
  pthread_mutex_unlock(&env->socket_mutex);

  return result >= 0 ? 1 : 0;
}