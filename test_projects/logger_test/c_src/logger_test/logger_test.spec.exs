module LoggerTest

interface [NIF, CNode]

# Function to test basic logging
spec log_debug(message :: string) :: {:ok :: label}
spec log_info(message :: string) :: {:ok :: label}
spec log_warning(message :: string) :: {:ok :: label}
spec log_error(message :: string) :: {:ok :: label}

# Function to test logging with tags
spec log_with_tags(message :: string, tags :: [string]) :: {:ok :: label}

# Function to test timestamp handling
spec log_with_timestamp(message :: string, timestamp :: uint64) :: {:ok :: label}

# Function to test that causes queue overflow (for testing overflow handling)
spec log_many_messages(count :: int) :: {:ok :: label}

# Function to test queue overflow by sending more messages than the queue can hold
spec test_queue_overflow() :: {:ok :: label}