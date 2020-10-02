#include "example.h"

UNIFEX_TERM foo_result_ok(UnifexEnv *env, int answer) {
  return ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "ok"),
                                  enif_make_int(env, answer)};
    enif_make_tuple_from_array(env, terms, 2);
  });
}

static int unifex_load_nif(ErlNifEnv *env, void **priv_data,
                           ERL_NIF_TERM load_info) {
  UNIFEX_UNUSED(load_info);
  UNIFEX_UNUSED(priv_data);

  ErlNifResourceFlags flags =
      (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER);

  UNIFEX_PAYLOAD_GUARD_RESOURCE_TYPE = enif_open_resource_type(
      env, NULL, "UnifexPayloadGuard",
      (ErlNifResourceDtor *)unifex_payload_guard_destructor, flags, NULL);

  return 0;
}

static ERL_NIF_TERM export_foo(ErlNifEnv *env, int argc,
                               const ERL_NIF_TERM argv[]) {
  UNIFEX_MAYBE_UNUSED(argc);
  UNIFEX_MAYBE_UNUSED(argv);
  ERL_NIF_TERM result;
  UnifexEnv *unifex_env = env;
  int num;

  if (!enif_get_int(env, argv[0], &num)) {
    result = unifex_raise_args_error(env, "num", ":int");
    goto exit_export_foo;
  }

  result = foo(unifex_env, num);
  goto exit_export_foo;
exit_export_foo:

  return result;
}

static ErlNifFunc nif_funcs[] = {{"unifex_foo", 1, export_foo, 0}};

ERL_NIF_INIT(Elixir.Example.Nif, nif_funcs, unifex_load_nif, NULL, NULL, NULL)
