#include "payload.h"

int unifex_payload_from_term(ErlNifEnv * env, ERL_NIF_TERM term, UnifexPayload* payload) {
  int res = enif_inspect_binary(env, term, &payload->payload_struct.binary);
  if (res) {
    payload->data = payload->payload_struct.binary.data;
    payload->size = payload->payload_struct.binary.size;
    payload->type = UNIFEX_PAYLOAD_BINARY;
    payload->owned = 0;
    return res;
  }

  res = shmex_get_from_term(env, term, &payload->payload_struct.shm);
  if (res) {
    shmex_open_and_mmap(&payload->payload_struct.shm);
    payload->data = payload->payload_struct.shm.mapped_memory;
    payload->size = payload->payload_struct.shm.capacity;
    payload->type = UNIFEX_PAYLOAD_SHM;
    payload->owned = 1;
  }
  return res;
}

UNIFEX_TERM unifex_payload_to_term(ErlNifEnv * env, UnifexPayload * payload) {
  switch (payload->type) {
  case UNIFEX_PAYLOAD_BINARY:
    payload->owned = 0;
    return enif_make_binary(env, &payload->payload_struct.binary);
  case UNIFEX_PAYLOAD_SHM:
    return shmex_make_term(env, &payload->payload_struct.shm);
  }
  // Switch should be exhaustive, this is added just to silence the warning
  return enif_raise_exception(env, enif_make_atom(env, "unifex_payload_to_term"));
}

UnifexPayload * unifex_payload_alloc(UnifexEnv* env, UnifexPayloadType type, unsigned int size) {
  UnifexPayload * payload = enif_alloc(sizeof (UnifexPayload));
  payload->size = size;
  payload->type = type;
  payload->owned = 1;
  Shmex * p_struct;

  switch (type) {
  case UNIFEX_PAYLOAD_BINARY:
    enif_alloc_binary(size, &payload->payload_struct.binary);
    payload->data = payload->payload_struct.binary.data;
    break;
  case UNIFEX_PAYLOAD_SHM:
    p_struct = &payload->payload_struct.shm;
    shmex_init(env, p_struct, size);
    shmex_add_guard(env, UNIFEX_PAYLOAD_GUARD_RESOURCE_TYPE, p_struct);
    shmex_allocate(p_struct);
    shmex_open_and_mmap(p_struct);
    p_struct->size = payload->size;
    payload->data = p_struct->mapped_memory;
    break;
  }

  return payload;
}

void unifex_payload_guard_destructor(UnifexEnv* env, void * resource) {
  shmex_guard_destructor(env, resource);
}

void unifex_payload_realloc(UnifexPayload * payload, unsigned int size) {
  payload->size = size;

  switch (payload->type) {
  case UNIFEX_PAYLOAD_BINARY:
    payload->owned = 1;
    enif_realloc_binary(&payload->payload_struct.binary, size);
    break;
  case UNIFEX_PAYLOAD_SHM:
    shmex_set_capacity(&payload->payload_struct.shm, size);
    payload->payload_struct.shm.size = payload->size;
    break;
  }
}

void unifex_payload_release(UnifexPayload * payload) {
  switch (payload->type) {
  case UNIFEX_PAYLOAD_BINARY:
    if (payload->owned) {
      enif_release_binary(&payload->payload_struct.binary);
    }
    break;
  case UNIFEX_PAYLOAD_SHM:
    shmex_release(&payload->payload_struct.shm);
    break;
  }
}

void unifex_payload_release_ptr(UnifexPayload ** payload) {
  if (*payload == NULL) {
    return;
  }

  unifex_payload_release(*payload);
  enif_free(*payload);
  *payload = NULL;
}
