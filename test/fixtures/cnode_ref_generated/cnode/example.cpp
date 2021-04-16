#include "example.h"
#include <stdio.h>

UnifexState *unifex_alloc_state(UnifexEnv *_env) {
  UNIFEX_UNUSED(_env);
  return (UnifexState *)malloc(sizeof(UnifexState));
}

void unifex_release_state(UnifexEnv *env, UnifexState *state) {
  unifex_cnode_add_to_released_states(env, state);
}

void unifex_cnode_destroy_state(UnifexEnv *env, void *state) {
  handle_destroy_state(env, (UnifexState *)state);
  free(state);
}

UNIFEX_TERM init_result_ok(UnifexEnv *env, UnifexState *state) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_atom(out_buff, "ok");
  {
    UnifexState *unifex_state = state;
    env->state = unifex_state;
  };

  return out_buff;
}

UNIFEX_TERM test_atom_result_ok(UnifexEnv *env, const char *out_atom) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ei_x_encode_atom(out_buff, out_atom);

  return out_buff;
}

UNIFEX_TERM test_bool_result_ok(UnifexEnv *env, int out_bool) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ei_x_encode_atom(out_buff, out_bool ? "true" : "false");

  return out_buff;
}

UNIFEX_TERM test_float_result_ok(UnifexEnv *env, double out_float) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ei_x_encode_double(out_buff, out_float);

  return out_buff;
}

UNIFEX_TERM test_uint_result_ok(UnifexEnv *env, unsigned int out_uint) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    unsigned int tmp_uint = out_uint;
    ei_x_encode_ulonglong(out_buff, (unsigned long long)tmp_uint);
  });

  return out_buff;
}

UNIFEX_TERM test_string_result_ok(UnifexEnv *env, char const *out_string) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ei_x_encode_binary(out_buff, out_string, strlen(out_string));

  return out_buff;
}

UNIFEX_TERM test_list_result_ok(UnifexEnv *env, int const *out_list,
                                unsigned int out_list_length) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    ei_x_encode_list_header(out_buff, out_list_length);
    for (unsigned int i = 0; i < out_list_length; i++) {
      ({
        int tmp_int = out_list[i];
        ei_x_encode_longlong(out_buff, (long long)tmp_int);
      });
    }
    ei_x_encode_empty_list(out_buff);
  });

  return out_buff;
}

UNIFEX_TERM test_list_of_strings_result_ok(UnifexEnv *env,
                                           char const *const *out_strings,
                                           unsigned int out_strings_length) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    ei_x_encode_list_header(out_buff, out_strings_length);
    for (unsigned int i = 0; i < out_strings_length; i++) {
      ei_x_encode_binary(out_buff, out_strings[i], strlen(out_strings[i]));
    }
    ei_x_encode_empty_list(out_buff);
  });

  return out_buff;
}

UNIFEX_TERM test_list_of_uints_result_ok(UnifexEnv *env,
                                         unsigned int const *out_uints,
                                         unsigned int out_uints_length) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    ei_x_encode_list_header(out_buff, out_uints_length);
    for (unsigned int i = 0; i < out_uints_length; i++) {
      ({
        unsigned int tmp_uint = out_uints[i];
        ei_x_encode_ulonglong(out_buff, (unsigned long long)tmp_uint);
      });
    }
    ei_x_encode_empty_list(out_buff);
  });

  return out_buff;
}

UNIFEX_TERM test_list_with_other_args_result_ok(UnifexEnv *env,
                                                int const *out_list,
                                                unsigned int out_list_length,
                                                const char *other_param) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 3);
  ei_x_encode_atom(out_buff, "ok");
  ({
    ei_x_encode_list_header(out_buff, out_list_length);
    for (unsigned int i = 0; i < out_list_length; i++) {
      ({
        int tmp_int = out_list[i];
        ei_x_encode_longlong(out_buff, (long long)tmp_int);
      });
    }
    ei_x_encode_empty_list(out_buff);
  });

  ei_x_encode_atom(out_buff, other_param);

  return out_buff;
}

UNIFEX_TERM test_payload_result_ok(UnifexEnv *env, UnifexPayload *out_payload) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  unifex_payload_encode(env, out_buff, out_payload);

  return out_buff;
}

UNIFEX_TERM test_pid_result_ok(UnifexEnv *env, UnifexPid out_pid) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ei_x_encode_pid(out_buff, &out_pid);

  return out_buff;
}

UNIFEX_TERM test_example_message_result_ok(UnifexEnv *env) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 1);
  ei_x_encode_atom(out_buff, "ok");

  return out_buff;
}

UNIFEX_TERM test_example_message_result_error(UnifexEnv *env,
                                              const char *reason) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "error");
  ei_x_encode_atom(out_buff, reason);

  return out_buff;
}

UNIFEX_TERM test_my_struct_result_ok(UnifexEnv *env, my_struct out_struct) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    ei_x_encode_map_header(out_buff, 4);
    ei_x_encode_atom(out_buff, "id");
    ({
      int tmp_int = out_struct.id;
      ei_x_encode_longlong(out_buff, (long long)tmp_int);
    });
    ;

    ei_x_encode_atom(out_buff, "data");
    ({
      ei_x_encode_list_header(out_buff, out_struct.data_length);
      for (unsigned int i = 0; i < out_struct.data_length; i++) {
        ({
          int tmp_int = out_struct.data[i];
          ei_x_encode_longlong(out_buff, (long long)tmp_int);
        });
      }
      ei_x_encode_empty_list(out_buff);
    });
    ;

    ei_x_encode_atom(out_buff, "name");
    ei_x_encode_binary(out_buff, out_struct.name, strlen(out_struct.name));
    ;

    ei_x_encode_atom(out_buff, "__struct__");
    ei_x_encode_atom(out_buff, "Elixir.My.Struct");
  });

  return out_buff;
}

UNIFEX_TERM test_nested_struct_result_ok(UnifexEnv *env,
                                         nested_struct out_struct) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    ei_x_encode_map_header(out_buff, 3);
    ei_x_encode_atom(out_buff, "inner_struct");
    ({
      ei_x_encode_map_header(out_buff, 4);
      ei_x_encode_atom(out_buff, "id");
      ({
        int tmp_int = out_struct.inner_struct.id;
        ei_x_encode_longlong(out_buff, (long long)tmp_int);
      });
      ;

      ei_x_encode_atom(out_buff, "data");
      ({
        ei_x_encode_list_header(out_buff, out_struct.inner_struct.data_length);
        for (unsigned int i = 0; i < out_struct.inner_struct.data_length; i++) {
          ({
            int tmp_int = out_struct.inner_struct.data[i];
            ei_x_encode_longlong(out_buff, (long long)tmp_int);
          });
        }
        ei_x_encode_empty_list(out_buff);
      });
      ;

      ei_x_encode_atom(out_buff, "name");
      ei_x_encode_binary(out_buff, out_struct.inner_struct.name,
                         strlen(out_struct.inner_struct.name));
      ;

      ei_x_encode_atom(out_buff, "__struct__");
      ei_x_encode_atom(out_buff, "Elixir.My.Struct");
    });
    ;

    ei_x_encode_atom(out_buff, "id");
    ({
      int tmp_int = out_struct.id;
      ei_x_encode_longlong(out_buff, (long long)tmp_int);
    });
    ;

    ei_x_encode_atom(out_buff, "__struct__");
    ei_x_encode_atom(out_buff, "Elixir.Nested.Struct");
  });

  return out_buff;
}

UNIFEX_TERM test_my_enum_result_ok(UnifexEnv *env, MyEnum out_enum) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    if (out_enum == OPTION_ONE) {
      char *enum_as_string = "option_one";
      ei_x_encode_atom(out_buff, enum_as_string);
    } else if (out_enum == OPTION_TWO) {
      char *enum_as_string = "option_two";
      ei_x_encode_atom(out_buff, enum_as_string);
    } else if (out_enum == OPTION_THREE) {
      char *enum_as_string = "option_three";
      ei_x_encode_atom(out_buff, enum_as_string);
    } else if (out_enum == OPTION_FOUR) {
      char *enum_as_string = "option_four";
      ei_x_encode_atom(out_buff, enum_as_string);
    } else {
      char *enum_as_string = "option_five";
      ei_x_encode_atom(out_buff, enum_as_string);
    }
  });

  return out_buff;
}

UNIFEX_TERM init_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;

  result = init(env);
  goto exit_init_caller;
exit_init_caller:

  return result;
}

UNIFEX_TERM test_atom_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  char *in_atom;
  in_atom = NULL;
  if (({
        in_atom = (char *)unifex_alloc(MAXATOMLEN);
        ei_decode_atom(in_buff->buff, in_buff->index, in_atom);
      })) {
    result = unifex_raise(
        env, "Unifex CNode: cannot parse argument 'in_atom' of type ':atom'");
    goto exit_test_atom_caller;
  }

  result = test_atom(env, in_atom);
  goto exit_test_atom_caller;
exit_test_atom_caller:
  if (in_atom != NULL)
    unifex_free(in_atom);
  return result;
}

UNIFEX_TERM test_bool_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  int in_bool;

  if (({
        int res = -1;
        char boolean_str[6];
        ei_decode_atom(in_buff->buff, in_buff->index, boolean_str);

        if (strcmp(boolean_str, "true") == 0) {
          in_bool = 1;
          res = 0;
        } else if (strcmp(boolean_str, "false") == 0) {
          in_bool = 0;
          res = 0;
        }
        res;
      })) {
    result = unifex_raise(
        env, "Unifex CNode: cannot parse argument 'in_bool' of type ':bool'");
    goto exit_test_bool_caller;
  }

  result = test_bool(env, in_bool);
  goto exit_test_bool_caller;
exit_test_bool_caller:

  return result;
}

UNIFEX_TERM test_float_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  double in_float;

  if (ei_decode_double(in_buff->buff, in_buff->index, &in_float)) {
    result = unifex_raise(
        env, "Unifex CNode: cannot parse argument 'in_float' of type ':float'");
    goto exit_test_float_caller;
  }

  result = test_float(env, in_float);
  goto exit_test_float_caller;
exit_test_float_caller:

  return result;
}

UNIFEX_TERM test_uint_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  unsigned int in_uint;

  if (({
        unsigned long long tmp_ulonglong;
        int result =
            ei_decode_ulonglong(in_buff->buff, in_buff->index, &tmp_ulonglong);
        in_uint = (unsigned int)tmp_ulonglong;
        result;
      })) {
    result = unifex_raise(
        env,
        "Unifex CNode: cannot parse argument 'in_uint' of type ':unsigned'");
    goto exit_test_uint_caller;
  }

  result = test_uint(env, in_uint);
  goto exit_test_uint_caller;
exit_test_uint_caller:

  return result;
}

UNIFEX_TERM test_string_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  char *in_string;
  in_string = NULL;
  if (({
        int type;
        int size;
        long len;
        ei_get_type(in_buff->buff, in_buff->index, &type, &size);
        size = size + 1; // for NULL byte
        in_string = (char *)malloc(sizeof(char) * size);
        memset(in_string, 0, size);
        ei_decode_binary(in_buff->buff, in_buff->index, in_string, &len);
      })) {
    result = unifex_raise(
        env,
        "Unifex CNode: cannot parse argument 'in_string' of type ':string'");
    goto exit_test_string_caller;
  }

  result = test_string(env, in_string);
  goto exit_test_string_caller;
exit_test_string_caller:
  unifex_free(in_string);
  return result;
}

UNIFEX_TERM test_list_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  int *in_list;
  unsigned int in_list_length;
  in_list = NULL;
  if (({
        int type;
        int size;

        ei_get_type(in_buff->buff, in_buff->index, &type, &size);
        in_list_length = (unsigned int)size;

        int index = 0;
        UnifexCNodeInBuff unifex_buff;
        UnifexCNodeInBuff *unifex_buff_ptr = &unifex_buff;
        if (type == ERL_STRING_EXT) {
          ei_x_buff buff = unifex_cnode_string_to_list(in_buff, in_list_length);
          unifex_buff.buff = buff.buff;
          unifex_buff.index = &index;
        } else {
          unifex_buff.buff = in_buff->buff;
          unifex_buff.index = in_buff->index;
        }
        int header_res = ei_decode_list_header(unifex_buff_ptr->buff,
                                               unifex_buff_ptr->index, &size);
        in_list_length = (unsigned int)size;
        in_list = (int *)malloc(sizeof(int) * in_list_length);

        for (unsigned int i = 0; i < in_list_length; i++) {
        }

        for (unsigned int i = 0; i < in_list_length; i++) {
          if (({
                long long tmp_longlong;
                int result =
                    ei_decode_longlong(unifex_buff_ptr->buff,
                                       unifex_buff_ptr->index, &tmp_longlong);
                in_list[i] = (int)tmp_longlong;
                result;
              })) {
            result = unifex_raise(env, "Unifex CNode: cannot parse argument "
                                       "'in_list' of type '{:list, :int}'");
            goto exit_test_list_caller;
          }
        }
        if (in_list_length) {
          header_res = ei_decode_list_header(unifex_buff_ptr->buff,
                                             unifex_buff_ptr->index, &size);
        }
        header_res;
      })) {
    result = unifex_raise(env, "Unifex CNode: cannot parse argument 'in_list' "
                               "of type '{:list, :int}'");
    goto exit_test_list_caller;
  }

  result = test_list(env, in_list, in_list_length);
  goto exit_test_list_caller;
exit_test_list_caller:
  if (in_list != NULL) {
    for (unsigned int i = 0; i < in_list_length; i++) {
    }
    unifex_free(in_list);
  }

  return result;
}

UNIFEX_TERM test_list_of_strings_caller(UnifexEnv *env,
                                        UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  char **in_strings;
  unsigned int in_strings_length;
  in_strings = NULL;
  if (({
        int type;
        int size;

        ei_get_type(in_buff->buff, in_buff->index, &type, &size);
        in_strings_length = (unsigned int)size;

        int index = 0;
        UnifexCNodeInBuff unifex_buff;
        UnifexCNodeInBuff *unifex_buff_ptr = &unifex_buff;
        if (type == ERL_STRING_EXT) {
          ei_x_buff buff =
              unifex_cnode_string_to_list(in_buff, in_strings_length);
          unifex_buff.buff = buff.buff;
          unifex_buff.index = &index;
        } else {
          unifex_buff.buff = in_buff->buff;
          unifex_buff.index = in_buff->index;
        }
        int header_res = ei_decode_list_header(unifex_buff_ptr->buff,
                                               unifex_buff_ptr->index, &size);
        in_strings_length = (unsigned int)size;
        in_strings = (char **)malloc(sizeof(char *) * in_strings_length);

        for (unsigned int i = 0; i < in_strings_length; i++) {
          in_strings[i] = NULL;
        }

        for (unsigned int i = 0; i < in_strings_length; i++) {
          if (({
                int type;
                int size;
                long len;
                ei_get_type(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                            &type, &size);
                size = size + 1; // for NULL byte
                in_strings[i] = (char *)malloc(sizeof(char) * size);
                memset(in_strings[i], 0, size);
                ei_decode_binary(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                                 in_strings[i], &len);
              })) {
            result =
                unifex_raise(env, "Unifex CNode: cannot parse argument "
                                  "'in_strings' of type '{:list, :string}'");
            goto exit_test_list_of_strings_caller;
          }
        }
        if (in_strings_length) {
          header_res = ei_decode_list_header(unifex_buff_ptr->buff,
                                             unifex_buff_ptr->index, &size);
        }
        header_res;
      })) {
    result = unifex_raise(env, "Unifex CNode: cannot parse argument "
                               "'in_strings' of type '{:list, :string}'");
    goto exit_test_list_of_strings_caller;
  }

  result = test_list_of_strings(env, in_strings, in_strings_length);
  goto exit_test_list_of_strings_caller;
exit_test_list_of_strings_caller:
  if (in_strings != NULL) {
    for (unsigned int i = 0; i < in_strings_length; i++) {
      unifex_free(in_strings[i]);
    }
    unifex_free(in_strings);
  }

  return result;
}

UNIFEX_TERM test_list_of_uints_caller(UnifexEnv *env,
                                      UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  unsigned int *in_uints;
  unsigned int in_uints_length;
  in_uints = NULL;
  if (({
        int type;
        int size;

        ei_get_type(in_buff->buff, in_buff->index, &type, &size);
        in_uints_length = (unsigned int)size;

        int index = 0;
        UnifexCNodeInBuff unifex_buff;
        UnifexCNodeInBuff *unifex_buff_ptr = &unifex_buff;
        if (type == ERL_STRING_EXT) {
          ei_x_buff buff =
              unifex_cnode_string_to_list(in_buff, in_uints_length);
          unifex_buff.buff = buff.buff;
          unifex_buff.index = &index;
        } else {
          unifex_buff.buff = in_buff->buff;
          unifex_buff.index = in_buff->index;
        }
        int header_res = ei_decode_list_header(unifex_buff_ptr->buff,
                                               unifex_buff_ptr->index, &size);
        in_uints_length = (unsigned int)size;
        in_uints =
            (unsigned int *)malloc(sizeof(unsigned int) * in_uints_length);

        for (unsigned int i = 0; i < in_uints_length; i++) {
        }

        for (unsigned int i = 0; i < in_uints_length; i++) {
          if (({
                unsigned long long tmp_ulonglong;
                int result =
                    ei_decode_ulonglong(unifex_buff_ptr->buff,
                                        unifex_buff_ptr->index, &tmp_ulonglong);
                in_uints[i] = (unsigned int)tmp_ulonglong;
                result;
              })) {
            result =
                unifex_raise(env, "Unifex CNode: cannot parse argument "
                                  "'in_uints' of type '{:list, :unsigned}'");
            goto exit_test_list_of_uints_caller;
          }
        }
        if (in_uints_length) {
          header_res = ei_decode_list_header(unifex_buff_ptr->buff,
                                             unifex_buff_ptr->index, &size);
        }
        header_res;
      })) {
    result = unifex_raise(env, "Unifex CNode: cannot parse argument 'in_uints' "
                               "of type '{:list, :unsigned}'");
    goto exit_test_list_of_uints_caller;
  }

  result = test_list_of_uints(env, in_uints, in_uints_length);
  goto exit_test_list_of_uints_caller;
exit_test_list_of_uints_caller:
  if (in_uints != NULL) {
    for (unsigned int i = 0; i < in_uints_length; i++) {
    }
    unifex_free(in_uints);
  }

  return result;
}

UNIFEX_TERM test_list_with_other_args_caller(UnifexEnv *env,
                                             UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  int *in_list;
  unsigned int in_list_length;
  char *other_param;
  in_list = NULL;
  other_param = NULL;
  if (({
        int type;
        int size;

        ei_get_type(in_buff->buff, in_buff->index, &type, &size);
        in_list_length = (unsigned int)size;

        int index = 0;
        UnifexCNodeInBuff unifex_buff;
        UnifexCNodeInBuff *unifex_buff_ptr = &unifex_buff;
        if (type == ERL_STRING_EXT) {
          ei_x_buff buff = unifex_cnode_string_to_list(in_buff, in_list_length);
          unifex_buff.buff = buff.buff;
          unifex_buff.index = &index;
        } else {
          unifex_buff.buff = in_buff->buff;
          unifex_buff.index = in_buff->index;
        }
        int header_res = ei_decode_list_header(unifex_buff_ptr->buff,
                                               unifex_buff_ptr->index, &size);
        in_list_length = (unsigned int)size;
        in_list = (int *)malloc(sizeof(int) * in_list_length);

        for (unsigned int i = 0; i < in_list_length; i++) {
        }

        for (unsigned int i = 0; i < in_list_length; i++) {
          if (({
                long long tmp_longlong;
                int result =
                    ei_decode_longlong(unifex_buff_ptr->buff,
                                       unifex_buff_ptr->index, &tmp_longlong);
                in_list[i] = (int)tmp_longlong;
                result;
              })) {
            result = unifex_raise(env, "Unifex CNode: cannot parse argument "
                                       "'in_list' of type '{:list, :int}'");
            goto exit_test_list_with_other_args_caller;
          }
        }
        if (in_list_length) {
          header_res = ei_decode_list_header(unifex_buff_ptr->buff,
                                             unifex_buff_ptr->index, &size);
        }
        header_res;
      })) {
    result = unifex_raise(env, "Unifex CNode: cannot parse argument 'in_list' "
                               "of type '{:list, :int}'");
    goto exit_test_list_with_other_args_caller;
  }

  if (({
        other_param = (char *)unifex_alloc(MAXATOMLEN);
        ei_decode_atom(in_buff->buff, in_buff->index, other_param);
      })) {
    result = unifex_raise(
        env,
        "Unifex CNode: cannot parse argument 'other_param' of type ':atom'");
    goto exit_test_list_with_other_args_caller;
  }

  result = test_list_with_other_args(env, in_list, in_list_length, other_param);
  goto exit_test_list_with_other_args_caller;
exit_test_list_with_other_args_caller:
  if (in_list != NULL) {
    for (unsigned int i = 0; i < in_list_length; i++) {
    }
    unifex_free(in_list);
  }

  if (other_param != NULL)
    unifex_free(other_param);
  return result;
}

UNIFEX_TERM test_payload_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  UnifexPayload *in_payload;
  in_payload = NULL;
  if (unifex_payload_decode(env, in_buff, &in_payload)) {
    result = unifex_raise(
        env,
        "Unifex CNode: cannot parse argument 'in_payload' of type ':payload'");
    goto exit_test_payload_caller;
  }

  result = test_payload(env, in_payload);
  goto exit_test_payload_caller;
exit_test_payload_caller:
  if (in_payload && !in_payload->owned) {
    unifex_payload_release(in_payload);
  }

  return result;
}

UNIFEX_TERM test_pid_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  UnifexPid in_pid;

  if (ei_decode_pid(in_buff->buff, in_buff->index, &in_pid)) {
    result = unifex_raise(
        env, "Unifex CNode: cannot parse argument 'in_pid' of type ':pid'");
    goto exit_test_pid_caller;
  }

  result = test_pid(env, in_pid);
  goto exit_test_pid_caller;
exit_test_pid_caller:

  return result;
}

UNIFEX_TERM test_example_message_caller(UnifexEnv *env,
                                        UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;

  result = test_example_message(env);
  goto exit_test_example_message_caller;
exit_test_example_message_caller:

  return result;
}

UNIFEX_TERM test_my_struct_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  my_struct in_struct;
  in_struct.data = NULL;
  in_struct.name = NULL;
  if (({
        int arity = 0;
        int decode_map_header_result =
            ei_decode_map_header(in_buff->buff, in_buff->index, &arity);
        if (decode_map_header_result == 0) {
          for (int i = 0; i < arity; ++i) {
            char key[MAXATOMLEN + 1];
            int decode_key_result =
                ei_decode_atom(in_buff->buff, in_buff->index, key);
            if (decode_key_result == 0) {
              if (strcmp(key, "id") == 0) {
                if (({
                      long long tmp_longlong;
                      int result = ei_decode_longlong(
                          in_buff->buff, in_buff->index, &tmp_longlong);
                      in_struct.id = (int)tmp_longlong;
                      result;
                    })) {
                  result =
                      unifex_raise(env, "Unifex CNode: cannot parse argument "
                                        "'in_struct' of type ':my_struct'");
                  goto exit_test_my_struct_caller;
                }

              } else if (strcmp(key, "data") == 0) {
                if (({
                      int type;
                      int size;

                      ei_get_type(in_buff->buff, in_buff->index, &type, &size);
                      in_struct.data_length = (unsigned int)size;

                      int index = 0;
                      UnifexCNodeInBuff unifex_buff;
                      UnifexCNodeInBuff *unifex_buff_ptr = &unifex_buff;
                      if (type == ERL_STRING_EXT) {
                        ei_x_buff buff = unifex_cnode_string_to_list(
                            in_buff, in_struct.data_length);
                        unifex_buff.buff = buff.buff;
                        unifex_buff.index = &index;
                      } else {
                        unifex_buff.buff = in_buff->buff;
                        unifex_buff.index = in_buff->index;
                      }
                      int header_res = ei_decode_list_header(
                          unifex_buff_ptr->buff, unifex_buff_ptr->index, &size);
                      in_struct.data_length = (unsigned int)size;
                      in_struct.data =
                          (int *)malloc(sizeof(int) * in_struct.data_length);

                      for (unsigned int i = 0; i < in_struct.data_length; i++) {
                      }

                      for (unsigned int i = 0; i < in_struct.data_length; i++) {
                        if (({
                              long long tmp_longlong;
                              int result = ei_decode_longlong(
                                  unifex_buff_ptr->buff, unifex_buff_ptr->index,
                                  &tmp_longlong);
                              in_struct.data[i] = (int)tmp_longlong;
                              result;
                            })) {
                          result = unifex_raise(
                              env, "Unifex CNode: cannot parse argument "
                                   "'in_struct' of type ':my_struct'");
                          goto exit_test_my_struct_caller;
                        }
                      }
                      if (in_struct.data_length) {
                        header_res = ei_decode_list_header(
                            unifex_buff_ptr->buff, unifex_buff_ptr->index,
                            &size);
                      }
                      header_res;
                    })) {
                  result =
                      unifex_raise(env, "Unifex CNode: cannot parse argument "
                                        "'in_struct' of type ':my_struct'");
                  goto exit_test_my_struct_caller;
                }

              } else if (strcmp(key, "name") == 0) {
                if (({
                      int type;
                      int size;
                      long len;
                      ei_get_type(in_buff->buff, in_buff->index, &type, &size);
                      size = size + 1; // for NULL byte
                      in_struct.name = (char *)malloc(sizeof(char) * size);
                      memset(in_struct.name, 0, size);
                      ei_decode_binary(in_buff->buff, in_buff->index,
                                       in_struct.name, &len);
                    })) {
                  result =
                      unifex_raise(env, "Unifex CNode: cannot parse argument "
                                        "'in_struct' of type ':my_struct'");
                  goto exit_test_my_struct_caller;
                }

              } else if (strcmp(key, "__struct__") == 0) {
                char *elixir_module_name;
                if (({
                      elixir_module_name = (char *)unifex_alloc(MAXATOMLEN);
                      ei_decode_atom(in_buff->buff, in_buff->index,
                                     elixir_module_name);
                    })) {
                  result =
                      unifex_raise(env, "Unifex CNode: cannot parse argument "
                                        "'in_struct' of type ':my_struct'");
                  goto exit_test_my_struct_caller;
                }

                if (elixir_module_name != NULL)
                  unifex_free(elixir_module_name);
              }
            }
          }
        }

        decode_map_header_result;
      })) {
    result = unifex_raise(
        env,
        "Unifex CNode: cannot parse argument 'in_struct' of type ':my_struct'");
    goto exit_test_my_struct_caller;
  }

  result = test_my_struct(env, in_struct);
  goto exit_test_my_struct_caller;
exit_test_my_struct_caller:
  if (in_struct.data != NULL) {
    for (unsigned int i = 0; i < in_struct.data_length; i++) {
    }
    unifex_free(in_struct.data);
  }

  unifex_free(in_struct.name);
  return result;
}

UNIFEX_TERM test_nested_struct_caller(UnifexEnv *env,
                                      UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  nested_struct in_struct;
  in_struct.inner_struct.data = NULL;
  in_struct.inner_struct.name = NULL;
  if (({
        int arity = 0;
        int decode_map_header_result =
            ei_decode_map_header(in_buff->buff, in_buff->index, &arity);
        if (decode_map_header_result == 0) {
          for (int i = 0; i < arity; ++i) {
            char key[MAXATOMLEN + 1];
            int decode_key_result =
                ei_decode_atom(in_buff->buff, in_buff->index, key);
            if (decode_key_result == 0) {
              if (strcmp(key, "inner_struct") == 0) {
                if (({
                      int arity = 0;
                      int decode_map_header_result = ei_decode_map_header(
                          in_buff->buff, in_buff->index, &arity);
                      if (decode_map_header_result == 0) {
                        for (int i = 0; i < arity; ++i) {
                          char key[MAXATOMLEN + 1];
                          int decode_key_result = ei_decode_atom(
                              in_buff->buff, in_buff->index, key);
                          if (decode_key_result == 0) {
                            if (strcmp(key, "id") == 0) {
                              if (({
                                    long long tmp_longlong;
                                    int result = ei_decode_longlong(
                                        in_buff->buff, in_buff->index,
                                        &tmp_longlong);
                                    in_struct.inner_struct.id =
                                        (int)tmp_longlong;
                                    result;
                                  })) {
                                result = unifex_raise(
                                    env,
                                    "Unifex CNode: cannot parse argument "
                                    "'in_struct' of type ':nested_struct'");
                                goto exit_test_nested_struct_caller;
                              }

                            } else if (strcmp(key, "data") == 0) {
                              if (({
                                    int type;
                                    int size;

                                    ei_get_type(in_buff->buff, in_buff->index,
                                                &type, &size);
                                    in_struct.inner_struct.data_length =
                                        (unsigned int)size;

                                    int index = 0;
                                    UnifexCNodeInBuff unifex_buff;
                                    UnifexCNodeInBuff *unifex_buff_ptr =
                                        &unifex_buff;
                                    if (type == ERL_STRING_EXT) {
                                      ei_x_buff buff =
                                          unifex_cnode_string_to_list(
                                              in_buff, in_struct.inner_struct
                                                           .data_length);
                                      unifex_buff.buff = buff.buff;
                                      unifex_buff.index = &index;
                                    } else {
                                      unifex_buff.buff = in_buff->buff;
                                      unifex_buff.index = in_buff->index;
                                    }
                                    int header_res = ei_decode_list_header(
                                        unifex_buff_ptr->buff,
                                        unifex_buff_ptr->index, &size);
                                    in_struct.inner_struct.data_length =
                                        (unsigned int)size;
                                    in_struct.inner_struct.data = (int *)malloc(
                                        sizeof(int) *
                                        in_struct.inner_struct.data_length);

                                    for (unsigned int i = 0;
                                         i < in_struct.inner_struct.data_length;
                                         i++) {
                                    }

                                    for (unsigned int i = 0;
                                         i < in_struct.inner_struct.data_length;
                                         i++) {
                                      if (({
                                            long long tmp_longlong;
                                            int result = ei_decode_longlong(
                                                unifex_buff_ptr->buff,
                                                unifex_buff_ptr->index,
                                                &tmp_longlong);
                                            in_struct.inner_struct.data[i] =
                                                (int)tmp_longlong;
                                            result;
                                          })) {
                                        result = unifex_raise(
                                            env, "Unifex CNode: cannot parse "
                                                 "argument 'in_struct' of type "
                                                 "':nested_struct'");
                                        goto exit_test_nested_struct_caller;
                                      }
                                    }
                                    if (in_struct.inner_struct.data_length) {
                                      header_res = ei_decode_list_header(
                                          unifex_buff_ptr->buff,
                                          unifex_buff_ptr->index, &size);
                                    }
                                    header_res;
                                  })) {
                                result = unifex_raise(
                                    env,
                                    "Unifex CNode: cannot parse argument "
                                    "'in_struct' of type ':nested_struct'");
                                goto exit_test_nested_struct_caller;
                              }

                            } else if (strcmp(key, "name") == 0) {
                              if (({
                                    int type;
                                    int size;
                                    long len;
                                    ei_get_type(in_buff->buff, in_buff->index,
                                                &type, &size);
                                    size = size + 1; // for NULL byte
                                    in_struct.inner_struct.name =
                                        (char *)malloc(sizeof(char) * size);
                                    memset(in_struct.inner_struct.name, 0,
                                           size);
                                    ei_decode_binary(
                                        in_buff->buff, in_buff->index,
                                        in_struct.inner_struct.name, &len);
                                  })) {
                                result = unifex_raise(
                                    env,
                                    "Unifex CNode: cannot parse argument "
                                    "'in_struct' of type ':nested_struct'");
                                goto exit_test_nested_struct_caller;
                              }

                            } else if (strcmp(key, "__struct__") == 0) {
                              char *elixir_module_name;
                              if (({
                                    elixir_module_name =
                                        (char *)unifex_alloc(MAXATOMLEN);
                                    ei_decode_atom(in_buff->buff,
                                                   in_buff->index,
                                                   elixir_module_name);
                                  })) {
                                result = unifex_raise(
                                    env,
                                    "Unifex CNode: cannot parse argument "
                                    "'in_struct' of type ':nested_struct'");
                                goto exit_test_nested_struct_caller;
                              }

                              if (elixir_module_name != NULL)
                                unifex_free(elixir_module_name);
                            }
                          }
                        }
                      }

                      decode_map_header_result;
                    })) {
                  result =
                      unifex_raise(env, "Unifex CNode: cannot parse argument "
                                        "'in_struct' of type ':nested_struct'");
                  goto exit_test_nested_struct_caller;
                }

              } else if (strcmp(key, "id") == 0) {
                if (({
                      long long tmp_longlong;
                      int result = ei_decode_longlong(
                          in_buff->buff, in_buff->index, &tmp_longlong);
                      in_struct.id = (int)tmp_longlong;
                      result;
                    })) {
                  result =
                      unifex_raise(env, "Unifex CNode: cannot parse argument "
                                        "'in_struct' of type ':nested_struct'");
                  goto exit_test_nested_struct_caller;
                }

              } else if (strcmp(key, "__struct__") == 0) {
                char *elixir_module_name;
                if (({
                      elixir_module_name = (char *)unifex_alloc(MAXATOMLEN);
                      ei_decode_atom(in_buff->buff, in_buff->index,
                                     elixir_module_name);
                    })) {
                  result =
                      unifex_raise(env, "Unifex CNode: cannot parse argument "
                                        "'in_struct' of type ':nested_struct'");
                  goto exit_test_nested_struct_caller;
                }

                if (elixir_module_name != NULL)
                  unifex_free(elixir_module_name);
              }
            }
          }
        }

        decode_map_header_result;
      })) {
    result = unifex_raise(env, "Unifex CNode: cannot parse argument "
                               "'in_struct' of type ':nested_struct'");
    goto exit_test_nested_struct_caller;
  }

  result = test_nested_struct(env, in_struct);
  goto exit_test_nested_struct_caller;
exit_test_nested_struct_caller:
  if (in_struct.inner_struct.data != NULL) {
    for (unsigned int i = 0; i < in_struct.inner_struct.data_length; i++) {
    }
    unifex_free(in_struct.inner_struct.data);
  }

  unifex_free(in_struct.inner_struct.name);
  return result;
}

UNIFEX_TERM test_my_enum_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  MyEnum in_enum;

  if (({
        int res = 1;
        char *enum_as_string;
        if (({
              enum_as_string = (char *)unifex_alloc(MAXATOMLEN);
              ei_decode_atom(in_buff->buff, in_buff->index, enum_as_string);
            })) {
          result = unifex_raise(env, "Unifex CNode: cannot parse argument "
                                     "'in_enum' of type ':my_enum'");
          goto exit_test_my_enum_caller;
        }

        if (strcmp(enum_as_string, "option_one") == 0) {
          in_enum = OPTION_ONE;
          res = 0;
        }
        if (strcmp(enum_as_string, "option_two") == 0) {
          in_enum = OPTION_TWO;
          res = 0;
        }
        if (strcmp(enum_as_string, "option_three") == 0) {
          in_enum = OPTION_THREE;
          res = 0;
        }
        if (strcmp(enum_as_string, "option_four") == 0) {
          in_enum = OPTION_FOUR;
          res = 0;
        }
        if (strcmp(enum_as_string, "option_five") == 0) {
          in_enum = OPTION_FIVE;
          res = 0;
        }

        res;
      })) {
    result = unifex_raise(
        env,
        "Unifex CNode: cannot parse argument 'in_enum' of type ':my_enum'");
    goto exit_test_my_enum_caller;
  }

  result = test_my_enum(env, in_enum);
  goto exit_test_my_enum_caller;
exit_test_my_enum_caller:

  return result;
}

int send_example_msg(UnifexEnv *env, UnifexPid pid, int flags, int num) {
  UNIFEX_UNUSED(flags);
  ei_x_buff *out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  ei_x_new_with_version(out_buff);

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "example_msg");
  ({
    int tmp_int = num;
    ei_x_encode_longlong(out_buff, (long long)tmp_int);
  });

  unifex_cnode_send_and_free(env, &pid, out_buff);
  return 1;
}

UNIFEX_TERM unifex_cnode_handle_message(UnifexEnv *env, char *fun_name,
                                        UnifexCNodeInBuff *in_buff) {
  if (strcmp(fun_name, "init") == 0) {
    return init_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_atom") == 0) {
    return test_atom_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_bool") == 0) {
    return test_bool_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_float") == 0) {
    return test_float_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_uint") == 0) {
    return test_uint_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_string") == 0) {
    return test_string_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_list") == 0) {
    return test_list_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_list_of_strings") == 0) {
    return test_list_of_strings_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_list_of_uints") == 0) {
    return test_list_of_uints_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_list_with_other_args") == 0) {
    return test_list_with_other_args_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_payload") == 0) {
    return test_payload_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_pid") == 0) {
    return test_pid_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_example_message") == 0) {
    return test_example_message_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_my_struct") == 0) {
    return test_my_struct_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_nested_struct") == 0) {
    return test_nested_struct_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_my_enum") == 0) {
    return test_my_enum_caller(env, in_buff);
  } else {
    return unifex_cnode_undefined_function_error(env, fun_name);
  }
}

int main(int argc, char **argv) { return handle_main(argc, argv); }
