#include "util.h"

ERL_NIF_TERM unifex_util_raise_args_error(ErlNifEnv* env, const char* field, const char *description) {
  ERL_NIF_TERM exception_content = enif_make_tuple2(
    env,
    enif_make_atom(env, "unifex_parse_arg"),
    enif_make_tuple2(env, enif_make_atom(env, field), enif_make_string(env, description, ERL_NIF_LATIN1))
  );
  return enif_raise_exception(env, exception_content);
}

ERL_NIF_TERM unifex_util_make_and_release_resource(ErlNifEnv* env, void* resource) {
  ERL_NIF_TERM resource_term = enif_make_resource(env, resource);
  enif_release_resource(resource);
  return resource_term;
}

int unifex_util_payload_from_term(ErlNifEnv * env, ERL_NIF_TERM term, UnifexPayload* payload) {
  int res = enif_inspect_binary(env, term, &payload->payload_struct.binary);
  if (res) {
    payload->data = payload->payload_struct.binary.data;
    payload->size = payload->payload_struct.binary.size;
    payload->type = UNIFEX_PAYLOAD_BINARY;
    payload->owned = 0;
    return res;
  }

  res = shm_payload_get_from_term(env, term, &payload->payload_struct.shm);
  if (res) {
    shm_payload_open_and_mmap(&payload->payload_struct.shm);
    payload->data = payload->payload_struct.shm.mapped_memory;
    payload->size = payload->payload_struct.shm.capacity;
    payload->type = UNIFEX_PAYLOAD_SHM;
    payload->owned = 1;
  }
  return res;
}

ERL_NIF_TERM unifex_payload_to_term(ErlNifEnv * env, UnifexPayload * payload) {
  switch (payload->type) {
  case UNIFEX_PAYLOAD_BINARY:
    payload->owned = 0;
    return enif_make_binary(env, &payload->payload_struct.binary);
  case UNIFEX_PAYLOAD_SHM:
    return shm_payload_make_term(env, &payload->payload_struct.shm);
  }
  // Switch should be exhaustive, this is added just to silence the warning
  return enif_raise_exception(env, enif_make_atom(env, "unifex_payload_to_term"));
}
