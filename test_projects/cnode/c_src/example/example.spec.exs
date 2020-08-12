module Example

interface CNode

callback :main

state_type "MyState"

spec init() :: {:ok :: label, state}

spec foo(target :: pid, in_payload :: payload, in_list :: [int], state) ::
       {:ok :: label, answer :: int, out_payload :: payload, out_list :: [int]} | {:error :: label, reason :: atom}

spec test_list(in_list :: [int]) :: {:ok :: label, out_list :: [int]}

spec test_string(in_string :: string) :: {:ok :: label, out_string :: string}

spec test_strings_list(in_strings :: [string]) :: {:ok :: label, out_strings :: [string]}

sends {:example_msg :: label, num :: int}
