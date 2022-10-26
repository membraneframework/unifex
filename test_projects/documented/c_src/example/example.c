#include "example.h"

UNIFEX_TERM begin_file_documented_function(UnifexEnv* env, int num) {
  return begin_file_documented_function_result_ok(env, num);
}

UNIFEX_TERM inside_file_documented_function(UnifexEnv* env, int num) {
  return begin_file_documented_function_result_ok(env, num);
}

UNIFEX_TERM invalid_double_documented_function(UnifexEnv* env, int num) {
  return invalid_double_documented_function_result_ok(env, num);
}

UNIFEX_TERM inside_file_undocumented_function(UnifexEnv* env, int num) {
  return inside_file_undocumented_function_result_ok(env, num);
}

UNIFEX_TERM undocumented_false_function(UnifexEnv* env, int num) {
  return undocumented_false_function_result_ok(env, num);
}

UNIFEX_TERM after_undocumented_documented_function(UnifexEnv* env, int num) {
  return after_undocumented_documented_function_result_ok(env, num);
}

UNIFEX_TERM end_file_documented_function(UnifexEnv* env, int num) {
  return end_file_documented_function_result_ok(env, num);
}
