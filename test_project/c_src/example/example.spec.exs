module Example

callback :load

spec init() :: {:ok :: label, was_handle_load_called :: int, state}

spec foo(target :: pid, state) ::
       {:ok :: label, answer :: int} | {:error :: label, reason :: atom}

sends {:example_msg :: label, num :: int}
