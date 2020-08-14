#include "example.h"

UNIFEX_TERM init_result_ok(UnifexEnv *env, int was_handle_load_called,
                           UnifexState *state) {
  return ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "ok"),
                                  enif_make_int(env, was_handle_load_called),
                                  unifex_make_resource(env, state)};
    enif_make_tuple_from_array(env, terms, 3);
  });
}

UNIFEX_TERM foo_result_ok(UnifexEnv *env, const int *list_out,
                          unsigned int list_out_length, int answer) {
  return ({
    const ERL_NIF_TERM terms[] = {
        enif_make_atom(env, "ok"), ({
          ERL_NIF_TERM list = enif_make_list(env, 0);
          for (int i = list_out_length - 1; i >= 0; i--) {
            list =
                enif_make_list_cell(env, enif_make_int(env, list_out[i]), list);
          }
          list;
        }),
        enif_make_int(env, answer)};
    enif_make_tuple_from_array(env, terms, 3);
  });
}

UNIFEX_TERM foo_result_error(UnifexEnv *env, const char *reason) {
  return ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "error"),
                                  enif_make_atom(env, reason)};
    enif_make_tuple_from_array(env, terms, 2);
  });
}

int send_example_msg(UnifexEnv *env, UnifexPid pid, int flags, int num) {
  ERL_NIF_TERM term = ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "example_msg"),
                                  enif_make_int(env, num)};
    enif_make_tuple_from_array(env, terms, 2);
  });
  return unifex_send(env, &pid, term, flags);
}

ErlNifResourceType *STATE_RESOURCE_TYPE;

UnifexState *unifex_alloc_state(UnifexEnv *env) {
  UNIFEX_UNUSED(env);
  return (UnifexState *)enif_alloc_resource(STATE_RESOURCE_TYPE,
                                            sizeof(UnifexState));
}

void unifex_release_state(UnifexEnv *env, UnifexState *state) {
  UNIFEX_UNUSED(env);
  enif_release_resource(state);
}

void unifex_keep_state(UnifexEnv *env, UnifexState *state) {
  UNIFEX_UNUSED(env);
  enif_keep_resource(state);
}

static void destroy_state(ErlNifEnv *env, void *value) {
  UnifexState *state = (UnifexState *)value;
  UnifexEnv *unifex_env = env;
  handle_destroy_state(unifex_env, state);
}

static int unifex_load_nif(ErlNifEnv *env, void **priv_data,
                           ERL_NIF_TERM load_info) {
  UNIFEX_UNUSED(load_info);
  UNIFEX_UNUSED(priv_data);

  ErlNifResourceFlags flags =
      (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER);

  STATE_RESOURCE_TYPE =
      enif_open_resource_type(env, NULL, "UnifexState",
                              (ErlNifResourceDtor *)destroy_state, flags, NULL);

  UNIFEX_PAYLOAD_GUARD_RESOURCE_TYPE = enif_open_resource_type(
      env, NULL, "UnifexPayloadGuard",
      (ErlNifResourceDtor *)unifex_payload_guard_destructor, flags, NULL);

  return handle_load(env, priv_data);
}

static ERL_NIF_TERM export_init(ErlNifEnv *env, int argc,
                                const ERL_NIF_TERM argv[]) {
  UNIFEX_UNUSED(argc);
  ERL_NIF_TERM result;
  UNIFEX_UNUSED(argv);
  UnifexEnv *unifex_env = env;

  result = init(unifex_env);
  goto exit_export_init;
exit_export_init:

  return result;
}

static ERL_NIF_TERM export_foo(ErlNifEnv *env, int argc,
                               const ERL_NIF_TERM argv[]) {
  UNIFEX_UNUSED(argc);
  ERL_NIF_TERM result;

  UnifexEnv *unifex_env = env;
  UnifexPid target;
  int *list_in;
  unsigned int list_in_length;
  UnifexState *state;

  list_in = NULL;

  if (!enif_get_local_pid(env, argv[0], &target)) {
    result = unifex_raise_args_error(env, "target", ":pid");
    goto exit_export_foo;
  }

  if (!({
        int get_list_length_result =
            enif_get_list_length(env, argv[1], &list_in_length);
        if (get_list_length_result) {
          list_in = enif_alloc(sizeof(int) * list_in_length);

          for (unsigned int i = 0; i < list_in_length; i++) {
          }

          ERL_NIF_TERM list = argv[1];
          for (unsigned int i = 0; i < list_in_length; i++) {
            ERL_NIF_TERM elem;
            enif_get_list_cell(env, list, &elem, &list);
            if (!enif_get_int(env, elem, &list_in[i])) {
              result = unifex_raise_args_error(env, "list_in", "{:list, :int}");
              goto exit_export_foo;
            }
          }
        }
        get_list_length_result;
      })) {
    result = unifex_raise_args_error(env, "list_in", "{:list, :int}");
    goto exit_export_foo;
  }

  if (!enif_get_resource(env, argv[2], STATE_RESOURCE_TYPE, (void **)&state)) {
    result = unifex_raise_args_error(env, "state", ":state");
    goto exit_export_foo;
  }

  result = foo(unifex_env, target, list_in, list_in_length, state);
  goto exit_export_foo;
exit_export_foo:
  if (list_in != NULL) {
    for (unsigned int i = 0; i < list_in_length; i++) {
    }
    unifex_free(list_in);
  }

  return result;
}

static ErlNifFunc nif_funcs[] = {{"unifex_init", 0, export_init, 0},
                                 {"unifex_foo", 3, export_foo, 0}};

ERL_NIF_INIT(Elixir.Example.Nif, nif_funcs, unifex_load_nif, NULL, NULL, NULL)
