module Example

interface CNode

callback :main

state_type "MyState"

spec init() :: {:ok :: label, state}

spec test_atom(in_atom :: atom) :: {:ok :: label, out_atom :: atom}

spec test_bool(in_bool :: bool) :: {:ok :: label, out_bool :: bool}

spec test_float(in_float :: float) :: {:ok :: label, out_float :: float}

spec test_uint(in_uint :: unsigned) :: {:ok :: label, out_uint :: unsigned}

spec test_string(in_string :: string) :: {:ok :: label, out_string :: string}

spec test_list(in_list :: [int]) :: {:ok :: label, out_list :: [int]}

spec test_list_of_strings(in_strings :: [string]) :: {:ok :: label, out_strings :: [string]}

spec test_list_of_uints(in_uints :: [unsigned]) :: {:ok :: label, out_uints :: [unsigned]}

spec test_list_with_other_args(in_list :: [int], other_param :: atom) ::
       {:ok :: label, out_list :: [int], other_param :: atom}

spec test_payload(in_payload :: payload) :: {:ok :: label, out_payload :: payload}

spec test_pid(in_pid :: pid) :: {:ok :: label, out_pid :: pid}

spec test_example_message() :: {:ok :: label} | {:error :: label, reason :: atom}

sends {:example_msg :: label, num :: int}

type my_struct :: %My.Struct{
  id: int,
  data: [int],
  name: string
}

spec test_my_struct(in_struct :: my_struct) :: {:ok :: label, out_struct :: my_struct}

type nested_struct :: %Nested.Struct{
  inner_struct: my_struct,
  id: int
}

spec test_nested_struct(in_struct :: nested_struct) :: {:ok :: label, out_struct :: nested_struct}

type my_enum :: :option_one | :option_two | :option_three | :option_four | :option_five

spec test_my_enum(in_enum :: my_enum) :: {:ok :: label, out_enum :: my_enum}
