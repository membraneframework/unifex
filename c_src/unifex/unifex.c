#include "unifex.h"

UnifexPayload unifex_payload_alloc(UnifexEnv* env, unsigned int size) {
  UnifexPayload payload;
  payload.data = enif_make_new_binary(env->nif_env, size, &payload.term);
  payload.size = size;
  return payload;
}
