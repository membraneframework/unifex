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

UNIFEX_TERM test_atom_result_ok(UnifexEnv *env, const char *out_atom) {
  return ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "ok"),
                                  enif_make_atom(env, out_atom)};
    enif_make_tuple_from_array(env, terms, 2);
  });
}

UNIFEX_TERM test_float_result_ok(UnifexEnv *env, double out_float) {
  return ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "ok"),
                                  enif_make_double(env, out_float)};
    enif_make_tuple_from_array(env, terms, 2);
  });
}

UNIFEX_TERM test_int_result_ok(UnifexEnv *env, int out_int) {
  return ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "ok"),
                                  enif_make_int(env, out_int)};
    enif_make_tuple_from_array(env, terms, 2);
  });
}

UNIFEX_TERM test_list_result_ok(UnifexEnv *env, int const *out_list,
                                unsigned int out_list_length) {
  return ({
    const ERL_NIF_TERM terms[] = {
        enif_make_atom(env, "ok"), ({
          ERL_NIF_TERM list = enif_make_list(env, 0);
          for (int i = out_list_length - 1; i >= 0; i--) {
            list =
                enif_make_list_cell(env, enif_make_int(env, out_list[i]), list);
          }
          list;
        })

    };
    enif_make_tuple_from_array(env, terms, 2);
  });
}

UNIFEX_TERM test_pid_result_ok(UnifexEnv *env, UnifexPid out_pid) {
  return ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "ok"),
                                  enif_make_pid(env, &out_pid)};
    enif_make_tuple_from_array(env, terms, 2);
  });
}

UNIFEX_TERM test_state_result_ok(UnifexEnv *env, UnifexState *state) {
  return ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "ok"),
                                  unifex_make_resource(env, state)};
    enif_make_tuple_from_array(env, terms, 2);
  });
}

UNIFEX_TERM test_example_message_result_ok(UnifexEnv *env) {
  return ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "ok")};
    enif_make_tuple_from_array(env, terms, 1);
  });
}

UNIFEX_TERM test_example_message_result_error(UnifexEnv *env,
                                              const char *reason) {
  return ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "error"),
                                  enif_make_atom(env, reason)};
    enif_make_tuple_from_array(env, terms, 2);
  });
}

UNIFEX_TERM test_my_struct_result_ok(UnifexEnv *env, my_struct out_struct) {
  return ({
    const ERL_NIF_TERM terms[] = {
        enif_make_atom(env, "ok"), ({
          ERL_NIF_TERM keys[4];
          ERL_NIF_TERM values[4];

          keys[0] = enif_make_atom(env, "id");
          values[0] = enif_make_int(env, out_struct.id);

          keys[1] = enif_make_atom(env, "data");
          values[1] = ({
            ERL_NIF_TERM list = enif_make_list(env, 0);
            for (int i = out_struct.data_length - 1; i >= 0; i--) {
              list = enif_make_list_cell(
                  env, enif_make_int(env, out_struct.data[i]), list);
            }
            list;
          });

          keys[2] = enif_make_atom(env, "name");
          values[2] = unifex_string_to_term(env, out_struct.name);

          keys[3] = enif_make_atom(env, "__struct__");
          values[3] = enif_make_atom(env, "Elixir.My.Struct");

          ERL_NIF_TERM result;
          enif_make_map_from_arrays(env, keys, values, 4, &result);
          result;
        })

    };
    enif_make_tuple_from_array(env, terms, 2);
  });
}

UNIFEX_TERM test_my_enum_result_ok(UnifexEnv *env, MyEnum out_enum) {
  return ({
    const ERL_NIF_TERM terms[] = {enif_make_atom(env, "ok"), ({
                                    ERL_NIF_TERM res;
                                    if (out_enum == OPTION_ONE) {
                                      char *enum_as_string = "option_one";
                                      res = enif_make_atom(env, enum_as_string);
                                    } else if (out_enum == OPTION_TWO) {
                                      char *enum_as_string = "option_two";
                                      res = enif_make_atom(env, enum_as_string);
                                    } else if (out_enum == OPTION_THREE) {
                                      char *enum_as_string = "option_three";
                                      res = enif_make_atom(env, enum_as_string);
                                    } else if (out_enum == OPTION_FOUR) {
                                      char *enum_as_string = "option_four";
                                      res = enif_make_atom(env, enum_as_string);
                                    } else {
                                      char *enum_as_string = "option_five";
                                      res = enif_make_atom(env, enum_as_string);
                                    }

                                    res;
                                  })

    };
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
  UNIFEX_MAYBE_UNUSED(argc);
  UNIFEX_MAYBE_UNUSED(argv);
  ERL_NIF_TERM result;
  UnifexEnv *unifex_env = env;

  result = init(unifex_env);
  goto exit_export_init;
exit_export_init:

  return result;
}

static ERL_NIF_TERM export_test_atom(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]) {
  UNIFEX_MAYBE_UNUSED(argc);
  UNIFEX_MAYBE_UNUSED(argv);
  ERL_NIF_TERM result;
  UnifexEnv *unifex_env = env;
  char *in_atom;

  in_atom = NULL;

  if (!unifex_alloc_and_get_atom(env, argv[0], &in_atom)) {
    result = unifex_raise_args_error(env, "in_atom", ":atom");
    goto exit_export_test_atom;
  }

  result = test_atom(unifex_env, in_atom);
  goto exit_export_test_atom;
exit_export_test_atom:
  if (in_atom != NULL)
    unifex_free(in_atom);
  return result;
}

static ERL_NIF_TERM export_test_float(ErlNifEnv *env, int argc,
                                      const ERL_NIF_TERM argv[]) {
  UNIFEX_MAYBE_UNUSED(argc);
  UNIFEX_MAYBE_UNUSED(argv);
  ERL_NIF_TERM result;
  UnifexEnv *unifex_env = env;
  double in_float;

  if (!enif_get_double(env, argv[0], &in_float)) {
    result = unifex_raise_args_error(env, "in_float", ":float");
    goto exit_export_test_float;
  }

  result = test_float(unifex_env, in_float);
  goto exit_export_test_float;
exit_export_test_float:

  return result;
}

static ERL_NIF_TERM export_test_int(ErlNifEnv *env, int argc,
                                    const ERL_NIF_TERM argv[]) {
  UNIFEX_MAYBE_UNUSED(argc);
  UNIFEX_MAYBE_UNUSED(argv);
  ERL_NIF_TERM result;
  UnifexEnv *unifex_env = env;
  int in_int;

  if (!enif_get_int(env, argv[0], &in_int)) {
    result = unifex_raise_args_error(env, "in_int", ":int");
    goto exit_export_test_int;
  }

  result = test_int(unifex_env, in_int);
  goto exit_export_test_int;
exit_export_test_int:

  return result;
}

static ERL_NIF_TERM export_test_list(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[]) {
  UNIFEX_MAYBE_UNUSED(argc);
  UNIFEX_MAYBE_UNUSED(argv);
  ERL_NIF_TERM result;
  UnifexEnv *unifex_env = env;
  int *in_list;
  unsigned int in_list_length;

  in_list = NULL;

  if (!({
        int get_list_length_result =
            enif_get_list_length(env, argv[0], &in_list_length);
        if (get_list_length_result) {
          in_list = (int *)enif_alloc(sizeof(int) * in_list_length);

          for (unsigned int i = 0; i < in_list_length; i++) {
          }

          ERL_NIF_TERM list = argv[0];
          for (unsigned int i = 0; i < in_list_length; i++) {
            ERL_NIF_TERM elem;
            enif_get_list_cell(env, list, &elem, &list);
            if (!enif_get_int(env, elem, &in_list[i])) {
              result = unifex_raise_args_error(env, "in_list", "{:list, :int}");
              goto exit_export_test_list;
            }
          }
        }
        get_list_length_result;
      })) {
    result = unifex_raise_args_error(env, "in_list", "{:list, :int}");
    goto exit_export_test_list;
  }

  result = test_list(unifex_env, in_list, in_list_length);
  goto exit_export_test_list;
exit_export_test_list:
  if (in_list != NULL) {
    for (unsigned int i = 0; i < in_list_length; i++) {
    }
    unifex_free(in_list);
  }

  return result;
}

static ERL_NIF_TERM export_test_pid(ErlNifEnv *env, int argc,
                                    const ERL_NIF_TERM argv[]) {
  UNIFEX_MAYBE_UNUSED(argc);
  UNIFEX_MAYBE_UNUSED(argv);
  ERL_NIF_TERM result;
  UnifexEnv *unifex_env = env;
  UnifexPid in_pid;

  if (!enif_get_local_pid(env, argv[0], &in_pid)) {
    result = unifex_raise_args_error(env, "in_pid", ":pid");
    goto exit_export_test_pid;
  }

  result = test_pid(unifex_env, in_pid);
  goto exit_export_test_pid;
exit_export_test_pid:

  return result;
}

static ERL_NIF_TERM export_test_state(ErlNifEnv *env, int argc,
                                      const ERL_NIF_TERM argv[]) {
  UNIFEX_MAYBE_UNUSED(argc);
  UNIFEX_MAYBE_UNUSED(argv);
  ERL_NIF_TERM result;
  UnifexEnv *unifex_env = env;
  UnifexState *state;

  if (!enif_get_resource(env, argv[0], STATE_RESOURCE_TYPE, (void **)&state)) {
    result = unifex_raise_args_error(env, "state", ":state");
    goto exit_export_test_state;
  }

  result = test_state(unifex_env, state);
  goto exit_export_test_state;
exit_export_test_state:

  return result;
}

static ERL_NIF_TERM export_test_example_message(ErlNifEnv *env, int argc,
                                                const ERL_NIF_TERM argv[]) {
  UNIFEX_MAYBE_UNUSED(argc);
  UNIFEX_MAYBE_UNUSED(argv);
  ERL_NIF_TERM result;
  UnifexEnv *unifex_env = env;
  UnifexPid pid;

  if (!enif_get_local_pid(env, argv[0], &pid)) {
    result = unifex_raise_args_error(env, "pid", ":pid");
    goto exit_export_test_example_message;
  }

  result = test_example_message(unifex_env, pid);
  goto exit_export_test_example_message;
exit_export_test_example_message:

  return result;
}

static ERL_NIF_TERM export_test_my_struct(ErlNifEnv *env, int argc,
                                          const ERL_NIF_TERM argv[]) {
  UNIFEX_MAYBE_UNUSED(argc);
  UNIFEX_MAYBE_UNUSED(argv);
  ERL_NIF_TERM result;
  UnifexEnv *unifex_env = env;
  my_struct in_struct;

  in_struct.data = NULL;
  in_struct.name = NULL;

  if (!({
        ERL_NIF_TERM key;
        ERL_NIF_TERM value;

        key = enif_make_atom(env, "id");
        int get_id_result = enif_get_map_value(env, argv[0], key, &value);
        if (get_id_result) {
          if (!enif_get_int(env, value, &in_struct.id)) {
            result = unifex_raise_args_error(env, "in_struct", ":my_struct");
            goto exit_export_test_my_struct;
          }
        }

        key = enif_make_atom(env, "data");
        int get_data_result = enif_get_map_value(env, argv[0], key, &value);
        if (get_data_result) {
          if (!({
                int get_list_length_result =
                    enif_get_list_length(env, value, &in_struct.data_length);
                if (get_list_length_result) {
                  in_struct.data =
                      (int *)enif_alloc(sizeof(int) * in_struct.data_length);

                  for (unsigned int i = 0; i < in_struct.data_length; i++) {
                  }

                  ERL_NIF_TERM list = value;
                  for (unsigned int i = 0; i < in_struct.data_length; i++) {
                    ERL_NIF_TERM elem;
                    enif_get_list_cell(env, list, &elem, &list);
                    if (!enif_get_int(env, elem, &in_struct.data[i])) {
                      result = unifex_raise_args_error(env, "in_struct",
                                                       ":my_struct");
                      goto exit_export_test_my_struct;
                    }
                  }
                }
                get_list_length_result;
              })) {
            result = unifex_raise_args_error(env, "in_struct", ":my_struct");
            goto exit_export_test_my_struct;
          }
        }

        key = enif_make_atom(env, "name");
        int get_name_result = enif_get_map_value(env, argv[0], key, &value);
        if (get_name_result) {
          if (!unifex_string_from_term(env, value, &in_struct.name)) {
            result = unifex_raise_args_error(env, "in_struct", ":my_struct");
            goto exit_export_test_my_struct;
          }
        }

        get_id_result &&get_data_result &&get_name_result;
      })) {
    result = unifex_raise_args_error(env, "in_struct", ":my_struct");
    goto exit_export_test_my_struct;
  }

  result = test_my_struct(unifex_env, in_struct);
  goto exit_export_test_my_struct;
exit_export_test_my_struct:
  if (in_struct.data != NULL) {
    for (unsigned int i = 0; i < in_struct.data_length; i++) {
    }
    unifex_free(in_struct.data);
  }

  unifex_free(in_struct.name);
  return result;
}

static ERL_NIF_TERM export_test_my_enum(ErlNifEnv *env, int argc,
                                        const ERL_NIF_TERM argv[]) {
  UNIFEX_MAYBE_UNUSED(argc);
  UNIFEX_MAYBE_UNUSED(argv);
  ERL_NIF_TERM result;
  UnifexEnv *unifex_env = env;
  MyEnum in_enum;

  if (!({
        char *enum_as_string;
        int res = 0;

        if (!unifex_alloc_and_get_atom(env, argv[0], &enum_as_string)) {
          result = unifex_raise_args_error(env, "in_enum", ":my_enum");
          goto exit_export_test_my_enum;
        };

        if (strcmp(enum_as_string, "option_one") == 0) {
          in_enum = OPTION_ONE;
          res = 1;
        } else if (strcmp(enum_as_string, "option_two") == 0) {
          in_enum = OPTION_TWO;
          res = 1;
        } else if (strcmp(enum_as_string, "option_three") == 0) {
          in_enum = OPTION_THREE;
          res = 1;
        } else if (strcmp(enum_as_string, "option_four") == 0) {
          in_enum = OPTION_FOUR;
          res = 1;
        } else if (strcmp(enum_as_string, "option_five") == 0) {
          in_enum = OPTION_FIVE;
          res = 1;
        }

        res;
      })) {
    result = unifex_raise_args_error(env, "in_enum", ":my_enum");
    goto exit_export_test_my_enum;
  }

  result = test_my_enum(unifex_env, in_enum);
  goto exit_export_test_my_enum;
exit_export_test_my_enum:

  return result;
}

static ErlNifFunc nif_funcs[] = {
    {"unifex_init", 0, export_init, 0},
    {"unifex_test_atom", 1, export_test_atom, 0},
    {"unifex_test_float", 1, export_test_float, 0},
    {"unifex_test_int", 1, export_test_int, 0},
    {"unifex_test_list", 1, export_test_list, 0},
    {"unifex_test_pid", 1, export_test_pid, 0},
    {"unifex_test_state", 1, export_test_state, 0},
    {"unifex_test_example_message", 1, export_test_example_message, 0},
    {"unifex_test_my_struct", 1, export_test_my_struct, 0},
    {"unifex_test_my_enum", 1, export_test_my_enum, 0}};

ERL_NIF_INIT(Elixir.Example.Nif, nif_funcs, unifex_load_nif, NULL, NULL, NULL)
