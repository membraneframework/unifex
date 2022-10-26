module Example

interface [NIF]

@doc """
Test begin_file_documented_function documentation
"""
spec begin_file_documented_function(num :: int) :: {:ok :: label, answer :: int}

@doc """
Test inside_file_documented_function documentation
"""
spec inside_file_documented_function(num :: int) :: {:ok :: label, answer :: int}

@doc """
Invalid test invalid_double_documented_function documentation
"""
@doc """
Test invalid_double_documented_function documentation
"""
spec invalid_double_documented_function(num :: int) :: {:ok :: label, answer :: int}

spec inside_file_undocumented_function(num :: int) :: {:ok :: label, answer :: int}

@doc """
Test after_undocumented_documented_function documentation
"""
spec after_undocumented_documented_function(num :: int) :: {:ok :: label, answer :: int}

@doc false
spec undocumented_false_function(num :: int) :: {:ok :: label, answer :: int}

@doc """
Test end_file_documented_function documentation
"""
spec end_file_documented_function(num :: int) :: {:ok :: label, answer :: int}
