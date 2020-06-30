#include "unifex.h"

#ifdef __cplusplus
extern "C" {
#endif

void unifex_cnode_prepare_ei_x_buff(UnifexEnv *env, ei_x_buff *buff,
                                    const char *msg_type);
void unifex_cnode_send_and_free(UnifexEnv *env, erlang_pid *pid,
                                ei_x_buff *out_buff);
void unifex_cnode_send_to_server_and_free(UnifexEnv *env, ei_x_buff *out_buff);
UNIFEX_TERM unifex_cnode_undefined_function_error(UnifexEnv *env,
                                                  const char *fun_name);

void unifex_cnode_add_to_released_states(UnifexEnv *env, void *state);

UNIFEX_TERM unifex_cnode_handle_message(UnifexEnv *env, char *fun_name,
                                        int *index, ei_x_buff *in_buff);

void unifex_cnode_destroy_state(UnifexEnv *env, void *state);

int unifex_cnode_main_function(int argc, char **argv);

#ifdef __cplusplus
}
#endif