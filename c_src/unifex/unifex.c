#include "unifex.h"

UnifexPayload * unifex_payload_alloc(UnifexEnv* env, UnifexPayloadType type, unsigned int size) {
  UnifexPayload * payload = enif_alloc(sizeof (UnifexPayload));
  payload->size = size;
  payload->type = type;
  payload->owned = 1;
  ShmPayload * p_struct;

  switch (type) {
  case UNIFEX_PAYLOAD_BINARY:
    enif_alloc_binary(size, &payload->payload_struct.binary);
    payload->data = payload->payload_struct.binary.data;
    break;
  case UNIFEX_PAYLOAD_SHM:
    p_struct = &payload->payload_struct.shm;
    static const int membrane_prefix_len = 10;
    static const int uuid_length = 37;
    char shm_name[membrane_prefix_len + uuid_length];
    strcpy(shm_name, "/membrane-");
    uuid_t uuid;
    uuid_generate(uuid);
    uuid_unparse(uuid, shm_name + membrane_prefix_len);
    shm_payload_init(env, p_struct, shm_name, size);
    shm_payload_allocate(p_struct);
    shm_payload_open_and_mmap(p_struct);
    p_struct->size = payload->size;
    payload->data = p_struct->mapped_memory;
    break;
  }

  return payload;
}

void unifex_payload_realloc(UnifexPayload * payload, unsigned int size) {
  payload->size = size;

  switch (payload->type) {
  case UNIFEX_PAYLOAD_BINARY:
    payload->owned = 1;
    enif_realloc_binary(&payload->payload_struct.binary, size);
    break;
  case UNIFEX_PAYLOAD_SHM:
    shm_payload_set_capacity(&payload->payload_struct.shm, size);
    payload->payload_struct.shm.size = payload->size;
    break;
  }
}

void unifex_payload_free(UnifexPayload * payload) {
  switch (payload->type) {
  case UNIFEX_PAYLOAD_BINARY:
    if (payload->owned) {
      enif_release_binary(&payload->payload_struct.binary);
    }
    break;
  case UNIFEX_PAYLOAD_SHM:
    shm_payload_free(&payload->payload_struct.shm);
    break;
  }
}

void unifex_payload_free_ptr(UnifexPayload ** payload) {
  if (*payload == NULL) {
    return;
  }

  unifex_payload_free(*payload);
  enif_free(*payload);
  *payload = NULL;
}