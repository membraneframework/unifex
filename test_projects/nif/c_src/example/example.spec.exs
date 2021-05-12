module Example

interface NIF

callback :load

state_type "MyState"

spec init() :: {:ok :: label, was_handle_load_called :: int, state}

spec test_atom(in_atom :: atom) :: {:ok :: label, out_atom :: atom}

spec test_float(in_float :: float) :: {:ok :: label, out_float :: float}

spec test_int(in_int :: int) :: {:ok :: label, out_int :: int}

spec test_string(in_string :: string) :: {:ok :: label, out_string :: string}

spec test_list(in_list :: [int]) :: {:ok :: label, out_list :: [int]}

spec test_list_of_strings(in_strings :: [string]) :: {:ok :: label, out_strings :: [string]}

spec test_pid(in_pid :: pid) :: {:ok :: label, out_pid :: pid}

spec test_state(state) :: {:ok :: label, state}

spec test_example_message(pid :: pid) :: {:ok :: label} | {:error :: label, reason :: atom}

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
