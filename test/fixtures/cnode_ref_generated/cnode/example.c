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

UNIFEX_TERM test_string_result_ok(UnifexEnv *env, const char *out_string) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ei_x_encode_string(out_buff, out_string);

  return out_buff;
}

UNIFEX_TERM test_list_result_ok(UnifexEnv *env, const int *out_list,
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
                                           const char **out_strings,
                                           unsigned int out_strings_length) {
  UNIFEX_TERM out_buff = (ei_x_buff *)malloc(sizeof(ei_x_buff));
  unifex_cnode_prepare_ei_x_buff(env, out_buff, "result");

  ei_x_encode_tuple_header(out_buff, 2);
  ei_x_encode_atom(out_buff, "ok");
  ({
    ei_x_encode_list_header(out_buff, out_strings_length);
    for (unsigned int i = 0; i < out_strings_length; i++) {
      ei_x_encode_string(out_buff, out_strings[i]);
    }
    ei_x_encode_empty_list(out_buff);
  });

  return out_buff;
}

UNIFEX_TERM test_list_of_uints_result_ok(UnifexEnv *env,
                                         const unsigned int *out_uints,
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
                                                const int *out_list,
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

UNIFEX_TERM init_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_TERM result;
  UNIFEX_UNUSED(in_buff);

  result = init(env);
  goto exit_init_caller;
exit_init_caller:

  return result;
}

UNIFEX_TERM test_atom_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
  UNIFEX_TERM result;

  char *in_atom;
  in_atom = NULL;
  if (({
        in_atom = unifex_alloc(MAXATOMLEN);
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

UNIFEX_TERM test_uint_caller(UnifexEnv *env, UnifexCNodeInBuff *in_buff) {
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
  UNIFEX_TERM result;

  char *in_string;
  in_string = NULL;
  if (({
        int type;
        int size;
        ei_get_type(in_buff->buff, in_buff->index, &type, &size);
        size = size + 1; // for NULL byte
        in_string = malloc(sizeof(char) * size);
        ei_decode_string(in_buff->buff, in_buff->index, in_string);
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
  UNIFEX_TERM result;

  int *in_list;
  unsigned int in_list_length;
  in_list = NULL;
  if (({
        __label__ empty_list;
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
        if (in_list_length == 0) {
          goto empty_list;
        }
        ei_decode_list_header(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                              &size);
        in_list_length = (unsigned int)size;
        in_list = malloc(sizeof(int) * in_list_length);

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
      empty_list:
        ei_decode_list_header(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                              &size);
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
  UNIFEX_TERM result;

  char **in_strings;
  unsigned int in_strings_length;
  in_strings = NULL;
  if (({
        __label__ empty_list;
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
        if (in_strings_length == 0) {
          goto empty_list;
        }
        ei_decode_list_header(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                              &size);
        in_strings_length = (unsigned int)size;
        in_strings = malloc(sizeof(char *) * in_strings_length);

        for (unsigned int i = 0; i < in_strings_length; i++) {
          in_strings[i] = NULL;
        }

        for (unsigned int i = 0; i < in_strings_length; i++) {
          if (({
                int type;
                int size;
                ei_get_type(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                            &type, &size);
                size = size + 1; // for NULL byte
                in_strings[i] = malloc(sizeof(char) * size);
                ei_decode_string(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                                 in_strings[i]);
              })) {
            result =
                unifex_raise(env, "Unifex CNode: cannot parse argument "
                                  "'in_strings' of type '{:list, :string}'");
            goto exit_test_list_of_strings_caller;
          }
        }
      empty_list:
        ei_decode_list_header(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                              &size);
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
  UNIFEX_TERM result;

  unsigned int *in_uints;
  unsigned int in_uints_length;
  in_uints = NULL;
  if (({
        __label__ empty_list;
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
        if (in_uints_length == 0) {
          goto empty_list;
        }
        ei_decode_list_header(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                              &size);
        in_uints_length = (unsigned int)size;
        in_uints = malloc(sizeof(unsigned int) * in_uints_length);

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
      empty_list:
        ei_decode_list_header(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                              &size);
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
  UNIFEX_TERM result;

  int *in_list;
  unsigned int in_list_length;
  char *other_param;
  in_list = NULL;
  other_param = NULL;
  if (({
        __label__ empty_list;
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
        if (in_list_length == 0) {
          goto empty_list;
        }
        ei_decode_list_header(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                              &size);
        in_list_length = (unsigned int)size;
        in_list = malloc(sizeof(int) * in_list_length);

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
      empty_list:
        ei_decode_list_header(unifex_buff_ptr->buff, unifex_buff_ptr->index,
                              &size);
      })) {
    result = unifex_raise(env, "Unifex CNode: cannot parse argument 'in_list' "
                               "of type '{:list, :int}'");
    goto exit_test_list_with_other_args_caller;
  }

  if (({
        other_param = unifex_alloc(MAXATOMLEN);
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
  UNIFEX_TERM result;
  UNIFEX_UNUSED(in_buff);

  result = test_example_message(env);
  goto exit_test_example_message_caller;
exit_test_example_message_caller:

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
  } else {
    return unifex_cnode_undefined_function_error(env, fun_name);
  }
}

int main(int argc, char **argv) { return handle_main(argc, argv); }
