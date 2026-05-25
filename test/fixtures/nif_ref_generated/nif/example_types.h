#pragma once

#include <erl_nif.h>
#include <stdint.h>
#include <stdio.h>
#include <unifex/payload.h>
#include <unifex/unifex.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
enum MyEnum {
  MY_ENUM_OPTION_ONE,
  MY_ENUM_OPTION_TWO,
  MY_ENUM_OPTION_THREE,
  MY_ENUM_OPTION_FOUR,
  MY_ENUM_OPTION_FIVE
};
#else
enum MyEnum_t {
  MY_ENUM_OPTION_ONE,
  MY_ENUM_OPTION_TWO,
  MY_ENUM_OPTION_THREE,
  MY_ENUM_OPTION_FOUR,
  MY_ENUM_OPTION_FIVE
};
typedef enum MyEnum_t MyEnum;
#endif

#ifdef __cplusplus
enum MyExplicitEnum {
  MY_EXPLICIT_ENUM_A = 1,
  MY_EXPLICIT_ENUM_B,
  MY_EXPLICIT_ENUM_C = 4,
  MY_EXPLICIT_ENUM_D = 8
};
#else
enum MyExplicitEnum_t {
  MY_EXPLICIT_ENUM_A = 1,
  MY_EXPLICIT_ENUM_B,
  MY_EXPLICIT_ENUM_C = 4,
  MY_EXPLICIT_ENUM_D = 8
};
typedef enum MyExplicitEnum_t MyExplicitEnum;
#endif

#ifdef __cplusplus
struct my_struct {
  int id;
  int *data;
  unsigned int data_length;
  char *name;
};
#else
struct my_struct_t {
  int id;
  int *data;
  unsigned int data_length;
  char *name;
};
typedef struct my_struct_t my_struct;
#endif

#ifdef __cplusplus
struct simple_struct {
  int id;
  char *name;
};
#else
struct simple_struct_t {
  int id;
  char *name;
};
typedef struct simple_struct_t simple_struct;
#endif

#ifdef __cplusplus
struct nested_struct {
  my_struct inner_struct;
  int id;
};
#else
struct nested_struct_t {
  my_struct inner_struct;
  int id;
};
typedef struct nested_struct_t nested_struct;
#endif

#ifdef __cplusplus
struct nested_struct_list {
  my_struct *struct_list;
  unsigned int struct_list_length;
  int id;
};
#else
struct nested_struct_list_t {
  my_struct *struct_list;
  unsigned int struct_list_length;
  int id;
};
typedef struct nested_struct_list_t nested_struct_list;
#endif

#ifdef __cplusplus
}
#endif
