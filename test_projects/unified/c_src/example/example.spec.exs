module Example

interface [NIF, CNode]

spec foo(num :: int) :: {:ok :: label, answer :: int}
