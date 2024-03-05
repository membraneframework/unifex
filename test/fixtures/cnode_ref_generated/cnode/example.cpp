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

UNIFEX_TERM test_uint64_result_ok(UnifexEnv *env, uint64_t out_uint) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    uint64_t tmp_int = out_uint;
    ei_x_encode_ulonglong(out_buff, (long long)tmp_int);
  });

  return out_buff;
}

UNIFEX_TERM test_int64_result_ok(UnifexEnv *env, int64_t out_uint) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    int64_t tmp_int = out_uint;
    ei_x_encode_longlong(out_buff, (long long)tmp_int);
  });

  return out_buff;
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

UNIFEX_TERM test_nil_result_nil(UnifexEnv *env) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_atom(out_buff, "nil");

  return out_buff;
}

UNIFEX_TERM test_atom_result_ok(UnifexEnv *env, char const *out_atom) {
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
    for (unsigned int i_9 = 0; i_9 < out_list_length; i_9++) {
      ({
        int tmp_int = out_list[i_9];
        ei_x_encode_longlong(out_buff, (long long)tmp_int);
      });
    }
    ei_x_encode_empty_list(out_buff);
  });

  return out_buff;
}

UNIFEX_TERM test_list_of_strings_result_ok(UnifexEnv *env, char **out_strings,
                                           unsigned int out_strings_length) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    ei_x_encode_list_header(out_buff, out_strings_length);
    for (unsigned int i_11 = 0; i_11 < out_strings_length; i_11++) {
      ei_x_encode_binary(out_buff, out_strings[i_11],
                         strlen(out_strings[i_11]));
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
    for (unsigned int i_13 = 0; i_13 < out_uints_length; i_13++) {
      ({
        unsigned int tmp_uint = out_uints[i_13];
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
                                                char const *other_param) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 3);
  ei_x_encode_atom(out_buff, "ok");
  ({
    ei_x_encode_list_header(out_buff, out_list_length);
    for (unsigned int i_15 = 0; i_15 < out_list_length; i_15++) {
      ({
        int tmp_int = out_list[i_15];
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
                                              char const *reason) {
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
      for (unsigned int i_17 = 0; i_17 < out_struct.data_length; i_17++) {
        ({
          int tmp_int = out_struct.data[i_17];
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
        for (unsigned int i_19 = 0; i_19 < out_struct.inner_struct.data_length;
             i_19++) {
          ({
            int tmp_int = out_struct.inner_struct.data[i_19];
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

UNIFEX_TERM test_nested_struct_list_result_ok(UnifexEnv *env,
                                              nested_struct_list out_struct) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    ei_x_encode_map_header(out_buff, 3);
    ei_x_encode_atom(out_buff, "struct_list");
    ({
      ei_x_encode_list_header(out_buff, out_struct.struct_list_length);
      for (unsigned int i_22 = 0; i_22 < out_struct.struct_list_length;
           i_22++) {
        ({
          ei_x_encode_map_header(out_buff, 4);
          ei_x_encode_atom(out_buff, "id");
          ({
            int tmp_int = out_struct.struct_list[i_22].id;
            ei_x_encode_longlong(out_buff, (long long)tmp_int);
          });
          ;

          ei_x_encode_atom(out_buff, "data");
          ({
            ei_x_encode_list_header(out_buff,
                                    out_struct.struct_list[i_22].data_length);
            for (unsigned int i_23 = 0;
                 i_23 < out_struct.struct_list[i_22].data_length; i_23++) {
              ({
                int tmp_int = out_struct.struct_list[i_22].data[i_23];
                ei_x_encode_longlong(out_buff, (long long)tmp_int);
              });
            }
            ei_x_encode_empty_list(out_buff);
          });
          ;

          ei_x_encode_atom(out_buff, "name");
          ei_x_encode_binary(out_buff, out_struct.struct_list[i_22].name,
                             strlen(out_struct.struct_list[i_22].name));
          ;

          ei_x_encode_atom(out_buff, "__struct__");
          ei_x_encode_atom(out_buff, "Elixir.My.Struct");
        });
      }
      ei_x_encode_empty_list(out_buff);
    });
    ;

    ei_x_encode_atom(out_buff, "id");
    ({
      int tmp_int = out_struct.id;
      ei_x_encode_longlong(out_buff, (long long)tmp_int);
    });
    ;

    ei_x_encode_atom(out_buff, "__struct__");
    ei_x_encode_atom(out_buff, "Elixir.Nested.StructList");
  });

  return out_buff;
}

UNIFEX_TERM test_my_enum_result_ok(UnifexEnv *env, MyEnum out_enum) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    if (out_enum == MY_ENUM_OPTION_ONE) {
      const char *enum_as_string = "option_one";
      ei_x_encode_atom(out_buff, enum_as_string);

    } else if (out_enum == MY_ENUM_OPTION_TWO) {
      const char *enum_as_string = "option_two";
      ei_x_encode_atom(out_buff, enum_as_string);

    } else if (out_enum == MY_ENUM_OPTION_THREE) {
      const char *enum_as_string = "option_three";
      ei_x_encode_atom(out_buff, enum_as_string);

    } else if (out_enum == MY_ENUM_OPTION_FOUR) {
      const char *enum_as_string = "option_four";
      ei_x_encode_atom(out_buff, enum_as_string);

    } else {
      const char *enum_as_string = "option_five";
      ei_x_encode_atom(out_buff, enum_as_string);
    }
  });

  return out_buff;
}

UNIFEX_TERM test_uint64_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  uint64_t in_uint;

  if (({
        unsigned long long tmp_ulonglong;
        int result =
            ei_decode_ulonglong(in_buff->buff, in_buff->index, &tmp_ulonglong);
        in_uint = (uint64_t)tmp_ulonglong;
        result;
      })) {
    result = unifex_raise(
        env, "Unifex CNode: cannot parse argument 'in_uint' of type ':uint64'");
    goto exit_test_uint64_caller;
  }

  result = test_uint64(env, in_uint);
  goto exit_test_uint64_caller;
exit_test_uint64_caller:

  return result;
}

UNIFEX_TERM test_int64_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  int64_t in_uint;

  if (({
        long long tmp_longlong;
        int result =
            ei_decode_longlong(in_buff->buff, in_buff->index, &tmp_longlong);
        in_uint = (int64_t)tmp_longlong;
        result;
      })) {
    result = unifex_raise(
        env, "Unifex CNode: cannot parse argument 'in_uint' of type ':int64'");
    goto exit_test_int64_caller;
  }

  result = test_int64(env, in_uint);
  goto exit_test_int64_caller;
exit_test_int64_caller:

  return result;
}

UNIFEX_TERM init_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;

  result = init(env);
  goto exit_init_caller;
exit_init_caller:

  return result;
}

UNIFEX_TERM test_nil_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;

  result = test_nil(env);
  goto exit_test_nil_caller;
exit_test_nil_caller:

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
        UnifexCNodeInBuff unifex_buff_24;
        UnifexCNodeInBuff *unifex_buff_ptr_24 = &unifex_buff_24;
        if (type == ERL_STRING_EXT) {
          ei_x_buff buff = unifex_cnode_string_to_list(in_buff, in_list_length);
          unifex_buff_24.buff = buff.buff;
          unifex_buff_24.index = &index;
        } else {
          unifex_buff_24.buff = in_buff->buff;
          unifex_buff_24.index = in_buff->index;
        }
        int header_res = ei_decode_list_header(
            unifex_buff_ptr_24->buff, unifex_buff_ptr_24->index, &size);
        in_list_length = (unsigned int)size;
        in_list = (int *)malloc(sizeof(int) * in_list_length);

        for (unsigned int i_24 = 0; i_24 < in_list_length; i_24++) {
        }

        for (unsigned int i_24 = 0; i_24 < in_list_length; i_24++) {
          if (({
                long long tmp_longlong;
                int result = ei_decode_longlong(unifex_buff_ptr_24->buff,
                                                unifex_buff_ptr_24->index,
                                                &tmp_longlong);
                in_list[i_24] = (int)tmp_longlong;
                result;
              })) {
            result = unifex_raise(env, "Unifex CNode: cannot parse argument "
                                       "'in_list' of type '{:list, :int}'");
            goto exit_test_list_caller;
          }
        }
        if (in_list_length) {
          header_res = ei_decode_list_header(unifex_buff_ptr_24->buff,
                                             unifex_buff_ptr_24->index, &size);
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
    for (unsigned int i_25 = 0; i_25 < in_list_length; i_25++) {
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
        UnifexCNodeInBuff unifex_buff_26;
        UnifexCNodeInBuff *unifex_buff_ptr_26 = &unifex_buff_26;
        if (type == ERL_STRING_EXT) {
          ei_x_buff buff =
              unifex_cnode_string_to_list(in_buff, in_strings_length);
          unifex_buff_26.buff = buff.buff;
          unifex_buff_26.index = &index;
        } else {
          unifex_buff_26.buff = in_buff->buff;
          unifex_buff_26.index = in_buff->index;
        }
        int header_res = ei_decode_list_header(
            unifex_buff_ptr_26->buff, unifex_buff_ptr_26->index, &size);
        in_strings_length = (unsigned int)size;
        in_strings = (char **)malloc(sizeof(char *) * in_strings_length);

        for (unsigned int i_26 = 0; i_26 < in_strings_length; i_26++) {
          in_strings[i_26] = NULL;
        }

        for (unsigned int i_26 = 0; i_26 < in_strings_length; i_26++) {
          if (({
                int type;
                int size;
                long len;
                ei_get_type(unifex_buff_ptr_26->buff, unifex_buff_ptr_26->index,
                            &type, &size);
                size = size + 1; // for NULL byte
                in_strings[i_26] = (char *)malloc(sizeof(char) * size);
                memset(in_strings[i_26], 0, size);
                ei_decode_binary(unifex_buff_ptr_26->buff,
                                 unifex_buff_ptr_26->index, in_strings[i_26],
                                 &len);
              })) {
            result =
                unifex_raise(env, "Unifex CNode: cannot parse argument "
                                  "'in_strings' of type '{:list, :string}'");
            goto exit_test_list_of_strings_caller;
          }
        }
        if (in_strings_length) {
          header_res = ei_decode_list_header(unifex_buff_ptr_26->buff,
                                             unifex_buff_ptr_26->index, &size);
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
    for (unsigned int i_27 = 0; i_27 < in_strings_length; i_27++) {
      unifex_free(in_strings[i_27]);
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
        UnifexCNodeInBuff unifex_buff_28;
        UnifexCNodeInBuff *unifex_buff_ptr_28 = &unifex_buff_28;
        if (type == ERL_STRING_EXT) {
          ei_x_buff buff =
              unifex_cnode_string_to_list(in_buff, in_uints_length);
          unifex_buff_28.buff = buff.buff;
          unifex_buff_28.index = &index;
        } else {
          unifex_buff_28.buff = in_buff->buff;
          unifex_buff_28.index = in_buff->index;
        }
        int header_res = ei_decode_list_header(
            unifex_buff_ptr_28->buff, unifex_buff_ptr_28->index, &size);
        in_uints_length = (unsigned int)size;
        in_uints =
            (unsigned int *)malloc(sizeof(unsigned int) * in_uints_length);

        for (unsigned int i_28 = 0; i_28 < in_uints_length; i_28++) {
        }

        for (unsigned int i_28 = 0; i_28 < in_uints_length; i_28++) {
          if (({
                unsigned long long tmp_ulonglong;
                int result = ei_decode_ulonglong(unifex_buff_ptr_28->buff,
                                                 unifex_buff_ptr_28->index,
                                                 &tmp_ulonglong);
                in_uints[i_28] = (unsigned int)tmp_ulonglong;
                result;
              })) {
            result =
                unifex_raise(env, "Unifex CNode: cannot parse argument "
                                  "'in_uints' of type '{:list, :unsigned}'");
            goto exit_test_list_of_uints_caller;
          }
        }
        if (in_uints_length) {
          header_res = ei_decode_list_header(unifex_buff_ptr_28->buff,
                                             unifex_buff_ptr_28->index, &size);
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
    for (unsigned int i_29 = 0; i_29 < in_uints_length; i_29++) {
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
        UnifexCNodeInBuff unifex_buff_30;
        UnifexCNodeInBuff *unifex_buff_ptr_30 = &unifex_buff_30;
        if (type == ERL_STRING_EXT) {
          ei_x_buff buff = unifex_cnode_string_to_list(in_buff, in_list_length);
          unifex_buff_30.buff = buff.buff;
          unifex_buff_30.index = &index;
        } else {
          unifex_buff_30.buff = in_buff->buff;
          unifex_buff_30.index = in_buff->index;
        }
        int header_res = ei_decode_list_header(
            unifex_buff_ptr_30->buff, unifex_buff_ptr_30->index, &size);
        in_list_length = (unsigned int)size;
        in_list = (int *)malloc(sizeof(int) * in_list_length);

        for (unsigned int i_30 = 0; i_30 < in_list_length; i_30++) {
        }

        for (unsigned int i_30 = 0; i_30 < in_list_length; i_30++) {
          if (({
                long long tmp_longlong;
                int result = ei_decode_longlong(unifex_buff_ptr_30->buff,
                                                unifex_buff_ptr_30->index,
                                                &tmp_longlong);
                in_list[i_30] = (int)tmp_longlong;
                result;
              })) {
            result = unifex_raise(env, "Unifex CNode: cannot parse argument "
                                       "'in_list' of type '{:list, :int}'");
            goto exit_test_list_with_other_args_caller;
          }
        }
        if (in_list_length) {
          header_res = ei_decode_list_header(unifex_buff_ptr_30->buff,
                                             unifex_buff_ptr_30->index, &size);
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
    for (unsigned int i_31 = 0; i_31 < in_list_length; i_31++) {
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
  unifex_free(in_payload);

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
                      UnifexCNodeInBuff unifex_buff_32;
                      UnifexCNodeInBuff *unifex_buff_ptr_32 = &unifex_buff_32;
                      if (type == ERL_STRING_EXT) {
                        ei_x_buff buff = unifex_cnode_string_to_list(
                            in_buff, in_struct.data_length);
                        unifex_buff_32.buff = buff.buff;
                        unifex_buff_32.index = &index;
                      } else {
                        unifex_buff_32.buff = in_buff->buff;
                        unifex_buff_32.index = in_buff->index;
                      }
                      int header_res = ei_decode_list_header(
                          unifex_buff_ptr_32->buff, unifex_buff_ptr_32->index,
                          &size);
                      in_struct.data_length = (unsigned int)size;
                      in_struct.data =
                          (int *)malloc(sizeof(int) * in_struct.data_length);

                      for (unsigned int i_32 = 0; i_32 < in_struct.data_length;
                           i_32++) {
                      }

                      for (unsigned int i_32 = 0; i_32 < in_struct.data_length;
                           i_32++) {
                        if (({
                              long long tmp_longlong;
                              int result = ei_decode_longlong(
                                  unifex_buff_ptr_32->buff,
                                  unifex_buff_ptr_32->index, &tmp_longlong);
                              in_struct.data[i_32] = (int)tmp_longlong;
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
                            unifex_buff_ptr_32->buff, unifex_buff_ptr_32->index,
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
    for (unsigned int i_33 = 0; i_33 < in_struct.data_length; i_33++) {
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
                                    UnifexCNodeInBuff unifex_buff_34;
                                    UnifexCNodeInBuff *unifex_buff_ptr_34 =
                                        &unifex_buff_34;
                                    if (type == ERL_STRING_EXT) {
                                      ei_x_buff buff =
                                          unifex_cnode_string_to_list(
                                              in_buff, in_struct.inner_struct
                                                           .data_length);
                                      unifex_buff_34.buff = buff.buff;
                                      unifex_buff_34.index = &index;
                                    } else {
                                      unifex_buff_34.buff = in_buff->buff;
                                      unifex_buff_34.index = in_buff->index;
                                    }
                                    int header_res = ei_decode_list_header(
                                        unifex_buff_ptr_34->buff,
                                        unifex_buff_ptr_34->index, &size);
                                    in_struct.inner_struct.data_length =
                                        (unsigned int)size;
                                    in_struct.inner_struct.data = (int *)malloc(
                                        sizeof(int) *
                                        in_struct.inner_struct.data_length);

                                    for (unsigned int i_34 = 0;
                                         i_34 <
                                         in_struct.inner_struct.data_length;
                                         i_34++) {
                                    }

                                    for (unsigned int i_34 = 0;
                                         i_34 <
                                         in_struct.inner_struct.data_length;
                                         i_34++) {
                                      if (({
                                            long long tmp_longlong;
                                            int result = ei_decode_longlong(
                                                unifex_buff_ptr_34->buff,
                                                unifex_buff_ptr_34->index,
                                                &tmp_longlong);
                                            in_struct.inner_struct.data[i_34] =
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
                                          unifex_buff_ptr_34->buff,
                                          unifex_buff_ptr_34->index, &size);
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
    for (unsigned int i_35 = 0; i_35 < in_struct.inner_struct.data_length;
         i_35++) {
    }
    unifex_free(in_struct.inner_struct.data);
  }

  unifex_free(in_struct.inner_struct.name);
  return result;
}

UNIFEX_TERM test_nested_struct_list_caller(UnifexEnv *env,
                                           UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  nested_struct_list in_struct;
  in_struct.struct_list = NULL;
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
              if (strcmp(key, "struct_list") == 0) {
                if (({
                      int type;
                      int size;

                      ei_get_type(in_buff->buff, in_buff->index, &type, &size);
                      in_struct.struct_list_length = (unsigned int)size;

                      int index = 0;
                      UnifexCNodeInBuff unifex_buff_36;
                      UnifexCNodeInBuff *unifex_buff_ptr_36 = &unifex_buff_36;
                      if (type == ERL_STRING_EXT) {
                        ei_x_buff buff = unifex_cnode_string_to_list(
                            in_buff, in_struct.struct_list_length);
                        unifex_buff_36.buff = buff.buff;
                        unifex_buff_36.index = &index;
                      } else {
                        unifex_buff_36.buff = in_buff->buff;
                        unifex_buff_36.index = in_buff->index;
                      }
                      int header_res = ei_decode_list_header(
                          unifex_buff_ptr_36->buff, unifex_buff_ptr_36->index,
                          &size);
                      in_struct.struct_list_length = (unsigned int)size;
                      in_struct.struct_list = (my_struct *)malloc(
                          sizeof(my_struct) * in_struct.struct_list_length);

                      for (unsigned int i_36 = 0;
                           i_36 < in_struct.struct_list_length; i_36++) {
                        in_struct.struct_list[i_36].data = NULL;
                        in_struct.struct_list[i_36].name = NULL;
                      }

                      for (unsigned int i_36 = 0;
                           i_36 < in_struct.struct_list_length; i_36++) {
                        if (({
                              int arity = 0;
                              int decode_map_header_result =
                                  ei_decode_map_header(
                                      unifex_buff_ptr_36->buff,
                                      unifex_buff_ptr_36->index, &arity);
                              if (decode_map_header_result == 0) {
                                for (int i = 0; i < arity; ++i) {
                                  char key[MAXATOMLEN + 1];
                                  int decode_key_result = ei_decode_atom(
                                      unifex_buff_ptr_36->buff,
                                      unifex_buff_ptr_36->index, key);
                                  if (decode_key_result == 0) {
                                    if (strcmp(key, "id") == 0) {
                                      if (({
                                            long long tmp_longlong;
                                            int result = ei_decode_longlong(
                                                unifex_buff_ptr_36->buff,
                                                unifex_buff_ptr_36->index,
                                                &tmp_longlong);
                                            in_struct.struct_list[i_36].id =
                                                (int)tmp_longlong;
                                            result;
                                          })) {
                                        result = unifex_raise(
                                            env, "Unifex CNode: cannot parse "
                                                 "argument 'in_struct' of type "
                                                 "':nested_struct_list'");
                                        goto exit_test_nested_struct_list_caller;
                                      }

                                    } else if (strcmp(key, "data") == 0) {
                                      if (({
                                            int type;
                                            int size;

                                            ei_get_type(
                                                unifex_buff_ptr_36->buff,
                                                unifex_buff_ptr_36->index,
                                                &type, &size);
                                            in_struct.struct_list[i_36]
                                                .data_length =
                                                (unsigned int)size;

                                            int index = 0;
                                            UnifexCNodeInBuff unifex_buff_37;
                                            UnifexCNodeInBuff
                                                *unifex_buff_ptr_37 =
                                                    &unifex_buff_37;
                                            if (type == ERL_STRING_EXT) {
                                              ei_x_buff buff =
                                                  unifex_cnode_string_to_list(
                                                      unifex_buff_ptr_36,
                                                      in_struct
                                                          .struct_list[i_36]
                                                          .data_length);
                                              unifex_buff_37.buff = buff.buff;
                                              unifex_buff_37.index = &index;
                                            } else {
                                              unifex_buff_37.buff =
                                                  unifex_buff_ptr_36->buff;
                                              unifex_buff_37.index =
                                                  unifex_buff_ptr_36->index;
                                            }
                                            int header_res =
                                                ei_decode_list_header(
                                                    unifex_buff_ptr_37->buff,
                                                    unifex_buff_ptr_37->index,
                                                    &size);
                                            in_struct.struct_list[i_36]
                                                .data_length =
                                                (unsigned int)size;
                                            in_struct.struct_list[i_36].data =
                                                (int *)malloc(
                                                    sizeof(int) *
                                                    in_struct.struct_list[i_36]
                                                        .data_length);

                                            for (unsigned int i_37 = 0;
                                                 i_37 <
                                                 in_struct.struct_list[i_36]
                                                     .data_length;
                                                 i_37++) {
                                            }

                                            for (unsigned int i_37 = 0;
                                                 i_37 <
                                                 in_struct.struct_list[i_36]
                                                     .data_length;
                                                 i_37++) {
                                              if (({
                                                    long long tmp_longlong;
                                                    int result =
                                                        ei_decode_longlong(
                                                            unifex_buff_ptr_37
                                                                ->buff,
                                                            unifex_buff_ptr_37
                                                                ->index,
                                                            &tmp_longlong);
                                                    in_struct.struct_list[i_36]
                                                        .data[i_37] =
                                                        (int)tmp_longlong;
                                                    result;
                                                  })) {
                                                result = unifex_raise(
                                                    env,
                                                    "Unifex CNode: cannot "
                                                    "parse argument "
                                                    "'in_struct' of type "
                                                    "':nested_struct_list'");
                                                goto exit_test_nested_struct_list_caller;
                                              }
                                            }
                                            if (in_struct.struct_list[i_36]
                                                    .data_length) {
                                              header_res =
                                                  ei_decode_list_header(
                                                      unifex_buff_ptr_37->buff,
                                                      unifex_buff_ptr_37->index,
                                                      &size);
                                            }
                                            header_res;
                                          })) {
                                        result = unifex_raise(
                                            env, "Unifex CNode: cannot parse "
                                                 "argument 'in_struct' of type "
                                                 "':nested_struct_list'");
                                        goto exit_test_nested_struct_list_caller;
                                      }

                                    } else if (strcmp(key, "name") == 0) {
                                      if (({
                                            int type;
                                            int size;
                                            long len;
                                            ei_get_type(
                                                unifex_buff_ptr_36->buff,
                                                unifex_buff_ptr_36->index,
                                                &type, &size);
                                            size = size + 1; // for NULL byte
                                            in_struct.struct_list[i_36].name =
                                                (char *)malloc(sizeof(char) *
                                                               size);
                                            memset(in_struct.struct_list[i_36]
                                                       .name,
                                                   0, size);
                                            ei_decode_binary(
                                                unifex_buff_ptr_36->buff,
                                                unifex_buff_ptr_36->index,
                                                in_struct.struct_list[i_36]
                                                    .name,
                                                &len);
                                          })) {
                                        result = unifex_raise(
                                            env, "Unifex CNode: cannot parse "
                                                 "argument 'in_struct' of type "
                                                 "':nested_struct_list'");
                                        goto exit_test_nested_struct_list_caller;
                                      }

                                    } else if (strcmp(key, "__struct__") == 0) {
                                      char *elixir_module_name;
                                      if (({
                                            elixir_module_name =
                                                (char *)unifex_alloc(
                                                    MAXATOMLEN);
                                            ei_decode_atom(
                                                unifex_buff_ptr_36->buff,
                                                unifex_buff_ptr_36->index,
                                                elixir_module_name);
                                          })) {
                                        result = unifex_raise(
                                            env, "Unifex CNode: cannot parse "
                                                 "argument 'in_struct' of type "
                                                 "':nested_struct_list'");
                                        goto exit_test_nested_struct_list_caller;
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
                              env, "Unifex CNode: cannot parse argument "
                                   "'in_struct' of type ':nested_struct_list'");
                          goto exit_test_nested_struct_list_caller;
                        }
                      }
                      if (in_struct.struct_list_length) {
                        header_res = ei_decode_list_header(
                            unifex_buff_ptr_36->buff, unifex_buff_ptr_36->index,
                            &size);
                      }
                      header_res;
                    })) {
                  result = unifex_raise(
                      env, "Unifex CNode: cannot parse argument 'in_struct' of "
                           "type ':nested_struct_list'");
                  goto exit_test_nested_struct_list_caller;
                }

              } else if (strcmp(key, "id") == 0) {
                if (({
                      long long tmp_longlong;
                      int result = ei_decode_longlong(
                          in_buff->buff, in_buff->index, &tmp_longlong);
                      in_struct.id = (int)tmp_longlong;
                      result;
                    })) {
                  result = unifex_raise(
                      env, "Unifex CNode: cannot parse argument 'in_struct' of "
                           "type ':nested_struct_list'");
                  goto exit_test_nested_struct_list_caller;
                }

              } else if (strcmp(key, "__struct__") == 0) {
                char *elixir_module_name;
                if (({
                      elixir_module_name = (char *)unifex_alloc(MAXATOMLEN);
                      ei_decode_atom(in_buff->buff, in_buff->index,
                                     elixir_module_name);
                    })) {
                  result = unifex_raise(
                      env, "Unifex CNode: cannot parse argument 'in_struct' of "
                           "type ':nested_struct_list'");
                  goto exit_test_nested_struct_list_caller;
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
                               "'in_struct' of type ':nested_struct_list'");
    goto exit_test_nested_struct_list_caller;
  }

  result = test_nested_struct_list(env, in_struct);
  goto exit_test_nested_struct_list_caller;
exit_test_nested_struct_list_caller:
  if (in_struct.struct_list != NULL) {
    for (unsigned int i_38 = 0; i_38 < in_struct.struct_list_length; i_38++) {
      if (in_struct.struct_list[i_38].data != NULL) {
        for (unsigned int i_39 = 0;
             i_39 < in_struct.struct_list[i_38].data_length; i_39++) {
        }
        unifex_free(in_struct.struct_list[i_38].data);
      }

      unifex_free(in_struct.struct_list[i_38].name);
    }
    unifex_free(in_struct.struct_list);
  }

  return result;
}

UNIFEX_TERM test_my_enum_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_MAYBE_UNUSED(in_buff);
  UNIFEX_TERM result;
  MyEnum in_enum;

  if (({
        int res = 1;
        char *enum_as_string = NULL;

        if (!({
              enum_as_string = (char *)unifex_alloc(MAXATOMLEN);
              ei_decode_atom(in_buff->buff, in_buff->index, enum_as_string);
            })) {
          if (strcmp(enum_as_string, "option_one") == 0) {
            in_enum = MY_ENUM_OPTION_ONE;
            res = 0;
          } else if (strcmp(enum_as_string, "option_two") == 0) {
            in_enum = MY_ENUM_OPTION_TWO;
            res = 0;
          } else if (strcmp(enum_as_string, "option_three") == 0) {
            in_enum = MY_ENUM_OPTION_THREE;
            res = 0;
          } else if (strcmp(enum_as_string, "option_four") == 0) {
            in_enum = MY_ENUM_OPTION_FOUR;
            res = 0;
          } else if (strcmp(enum_as_string, "option_five") == 0) {
            in_enum = MY_ENUM_OPTION_FIVE;
            res = 0;
          }

          if (enum_as_string != NULL) {
            unifex_free((void *)enum_as_string);
          }
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
  if (strcmp(fun_name, "test_uint64") == 0) {
    return test_uint64_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_int64") == 0) {
    return test_int64_caller(env, in_buff);
  } else if (strcmp(fun_name, "init") == 0) {
    return init_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_nil") == 0) {
    return test_nil_caller(env, in_buff);
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
  } else if (strcmp(fun_name, "test_nested_struct_list") == 0) {
    return test_nested_struct_list_caller(env, in_buff);
  } else if (strcmp(fun_name, "test_my_enum") == 0) {
    return test_my_enum_caller(env, in_buff);
  } else {
    return unifex_cnode_undefined_function_error(env, fun_name);
  }
}

int main(int argc, char **argv) { return handle_main(argc, argv); }
