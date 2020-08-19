module Example

interface CNode

callback :main

state_type "MyState"

spec init() :: {:ok :: label, state}

spec test_atom(in_atom :: atom) :: {:ok :: label, out_atom :: atom}

spec test_uint(in_uint :: unsigned) :: {:ok :: label, out_uint :: unsigned}

spec test_string(in_string :: string) :: {:ok :: label, out_string :: string}

spec test_list(in_list :: [int]) :: {:ok :: label, out_list :: [int]}

spec test_list_of_strings(in_strings :: [string]) :: {:ok :: label, out_strings :: [string]}

spec test_list_of_uints(in_uints :: [unsigned]) :: {:ok :: label, out_uints :: [unsigned]}

spec test_payload(in_payload :: payload) :: {:ok :: label, out_payload :: payload}

spec test_pid(in_pid :: pid) :: {:ok :: label, out_pid :: pid}

spec test_example_message() :: {:ok :: label} | {:error :: label, reason :: atom}

sends {:example_msg :: label, num :: int}
