module Example

interface NIF

callback :load

state_type "MyState"

spec init() :: {:ok :: label, was_handle_load_called :: int, state}

spec test_atom(in_atom :: atom) :: {:ok :: label, out_atom :: atom}

spec test_float(in_float :: float) :: {:ok :: label, out_float :: float}

spec test_int(in_int :: int) :: {:ok :: label, out_int :: int}

spec test_list(in_list :: [int]) :: {:ok :: label, out_list :: [int]}

spec test_pid(in_pid :: pid) :: {:ok :: label, out_pid :: pid}

spec test_state(state) :: {:ok :: label, state}

spec test_example_message(pid :: pid) :: {:ok :: label} | {:error :: label, reason :: atom}

sends {:example_msg :: label, num :: int}
