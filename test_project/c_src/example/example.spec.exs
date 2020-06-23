module Example

callback :load

use_state(true)

spec init() :: {:ok :: label, was_handle_load_called :: int, state}

spec foo(target :: pid, ls :: [int], state) ::
       {:ok :: label, ols :: [int], answer :: int} | {:error :: label, reason :: atom}

sends {:example_msg :: label, num :: int}
