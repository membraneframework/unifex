#pragma once

#include <erl_nif.h>

#define UNIFEX_UTIL_UNUSED(x) (void)(x)

// varargs parse helpers
#define UNIFEX_UTIL_PARSE_ARG(position, var_name, var_def, getter_func, ...) \
  var_def; \
  if(!getter_func(env, argv[position], __VA_ARGS__)) { \
    return unifex_util_args_error_result(env, #var_name, #getter_func); \
  }

#define UNIFEX_UTIL_PARSE_UINT_ARG(position, var_name) \
  UNIFEX_UTIL_PARSE_ARG(position, var_name, unsigned int var_name, enif_get_uint, &var_name)

#define UNIFEX_UTIL_PARSE_INT_ARG(position, var_name) \
  UNIFEX_UTIL_PARSE_ARG(position, var_name, int var_name, enif_get_int, &var_name)

#define UNIFEX_UTIL_PARSE_ATOM_ARG(position, var_name, max_size) \
  UNIFEX_UTIL_PARSE_ARG(position, var_name, char var_name[max_size], enif_get_atom, (char *) var_name, max_size, ERL_NIF_LATIN1)

#define UNIFEX_UTIL_PARSE_STRING_ARG(position, var_name, max_size) \
  UNIFEX_UTIL_PARSE_ARG(position, var_name, char var_name[max_size], enif_get_string, (char *) var_name, max_size, ERL_NIF_LATIN1)

#define UNIFEX_UTIL_PARSE_BINARY_ARG(position, var_name) \
  UNIFEX_UTIL_PARSE_ARG(position, var_name, ErlNifBinary var_name, enif_inspect_binary, &var_name)

#define UNIFEX_UTIL_PARSE_RESOURCE_ARG(position, var_name, var_type, res_type) \
  var_type * var_name; \
  if(!enif_get_resource(env, argv[position], res_type, (void **) & var_name)) { \
    return unifex_util_args_error_result(env, #var_name, "enif_get_resource"); \
  }

#define UNIFEX_UTIL_PARSE_PID_ARG(position, var_name) \
  UNIFEX_UTIL_PARSE_ARG(position, var_name, ErlNifPid var_name, enif_get_local_pid, &var_name)


// common result functions
ERL_NIF_TERM unifex_util_args_error_result(ErlNifEnv* env, const char* field, const char *description);

// term manipulation helpers
ERL_NIF_TERM unifex_util_make_and_release_resource(ErlNifEnv* env, void* resource);
