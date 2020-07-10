module Example

callback :main

state_type "MyState"

spec init() :: {:ok :: label, state}

spec foo(target :: pid, in_payload :: payload, state) ::
       {:ok :: label, answer :: int, out_payload :: payload} | {:error :: label, reason :: atom}

sends {:example_msg :: label, num :: int}
