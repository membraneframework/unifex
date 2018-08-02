#include "util.h"

ERL_NIF_TERM unifex_util_args_error_result(ErlNifEnv* env, const char* field, const char *description) {
  ERL_NIF_TERM reason = enif_make_tuple2(
    env,
    enif_make_atom(env, "args"),
    enif_make_tuple2(env, enif_make_atom(env, field), enif_make_string(env, description, ERL_NIF_LATIN1))
  );
  return enif_make_tuple2(env, enif_make_atom(env, "error"), reason);
}

ERL_NIF_TERM unifex_util_make_and_release_resource(ErlNifEnv* env, void* resource) {
  ERL_NIF_TERM resource_term = enif_make_resource(env, resource);
  enif_release_resource(resource);
  return resource_term;
}

int unifex_util_inspect_binary(ErlNifEnv* env, ERL_NIF_TERM binary_term, UnifexPayload* payload) {
  ErlNifBinary erl_binary;
  int res = enif_inspect_binary(env, binary_term, &erl_binary);
  if(res) {
    payload->data = erl_binary.data;
    payload->size = erl_binary.size;
    payload->term = binary_term;
  }
  return res;
}
