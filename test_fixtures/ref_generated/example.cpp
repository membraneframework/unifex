#include "example.h"

ErlNifResourceType *UNIFEX_PAYLOAD_GUARD_RESOURCE_TYPE;

UNIFEX_TERM init_result_ok(UnifexEnv* env, int was_handle_load_called, UnifexNifState* state) {
  return ({
        const ERL_NIF_TERM terms[] = {
          enif_make_atom(env, "ok"),
      enif_make_int(env, was_handle_load_called),
      unifex_make_resource(env, state)
        };
        enif_make_tuple_from_array(env, terms, 3);
      });
}

UNIFEX_TERM foo_result_ok(UnifexEnv* env, int answer) {
  return ({
        const ERL_NIF_TERM terms[] = {
          enif_make_atom(env, "ok"),
      enif_make_int(env, answer)
        };
        enif_make_tuple_from_array(env, terms, 2);
      });
}

UNIFEX_TERM foo_result_error(UnifexEnv* env, char* reason) {
  return ({
        const ERL_NIF_TERM terms[] = {
          enif_make_atom(env, "error"),
      enif_make_atom(env, reason)
        };
        enif_make_tuple_from_array(env, terms, 2);
      });
}

int send_example_msg(UnifexEnv* env, UnifexPid pid, int flags, int num) {
  ERL_NIF_TERM term = ({
        const ERL_NIF_TERM terms[] = {
          enif_make_atom(env, "example_msg"),
      enif_make_int(env, num)
        };
        enif_make_tuple_from_array(env, terms, 2);
      });
  return unifex_send(env, &pid, term, flags);
}

ErlNifResourceType *STATE_RESOURCE_TYPE;

UnifexNifState* unifex_alloc_state(UnifexEnv* env) {
  UNIFEX_UNUSED(env);
  return (UnifexNifState*) enif_alloc_resource(STATE_RESOURCE_TYPE, sizeof(UnifexNifState));
}

void unifex_release_state(UnifexEnv * env, UnifexNifState* state) {
  UNIFEX_UNUSED(env);
  enif_release_resource(state);
}

void unifex_keep_state(UnifexEnv * env, UnifexNifState* state) {
  UNIFEX_UNUSED(env);
  enif_keep_resource(state);
}

static void destroy_state(ErlNifEnv* env, void* value) {
  UnifexNifState* state = (UnifexNifState*) value;
  UnifexEnv *unifex_env = env;
  handle_destroy_state(unifex_env, state);
}

static int unifex_load_nif(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
  UNIFEX_UNUSED(load_info);
  UNIFEX_UNUSED(priv_data);

  ErlNifResourceFlags flags = (ErlNifResourceFlags) (ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER);
  STATE_RESOURCE_TYPE =
    enif_open_resource_type(env, NULL, "UnifexNifState", (ErlNifResourceDtor*) destroy_state, flags, NULL);

  UNIFEX_PAYLOAD_GUARD_RESOURCE_TYPE =
    enif_open_resource_type(env, NULL, "UnifexPayloadGuard", (ErlNifResourceDtor*) unifex_payload_guard_destructor, flags, NULL);

  return handle_load(env, priv_data);
}

static ERL_NIF_TERM export_init(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]){
  UNIFEX_UNUSED(argc);
  ERL_NIF_TERM result;
  UNIFEX_UNUSED(argv);
  UnifexEnv *unifex_env = env;

  result = init(unifex_env);
  goto exit_export_init;
exit_export_init:

  return result;
}

static ERL_NIF_TERM export_foo(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]){
  UNIFEX_UNUSED(argc);
  ERL_NIF_TERM result;

  UnifexEnv *unifex_env = env;
  UnifexPid target;
  UnifexNifState* state;

  if(!enif_get_local_pid(env, argv[0], &target)) {
    result = unifex_raise_args_error(env, "target", "enif_get_local_pid(env, argv[0], &target)");
    goto exit_export_foo;
  }
  if(!enif_get_resource(env, argv[1], STATE_RESOURCE_TYPE, (void **)&state)) {
    result = unifex_raise_args_error(env, "state", "enif_get_resource(env, argv[1], STATE_RESOURCE_TYPE, (void **)&state)");
    goto exit_export_foo;
  }

  result = foo(unifex_env, target, state);
  goto exit_export_foo;
exit_export_foo:

  return result;
}

static ErlNifFunc nif_funcs[] =
{
  {"unifex_init", 0, export_init, 0},
  {"unifex_foo", 2, export_foo, 0}
};

ERL_NIF_INIT(Elixir.Example.Nif, nif_funcs, unifex_load_nif, NULL, NULL, NULL)
