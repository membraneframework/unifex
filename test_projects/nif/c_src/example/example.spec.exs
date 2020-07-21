module Example

interface :nif

callback :load

state_type "MyState"

spec init() :: {:ok :: label, was_handle_load_called :: int, state}

spec foo(target :: pid, list_in :: [int], state) ::
       {:ok :: label, list_out :: [int], answer :: int} | {:error :: label, reason :: atom}

sends {:example_msg :: label, num :: int}
