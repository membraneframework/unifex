# clang-format is required to format the generated code
# it won't match the reference files otherwise
case System.cmd("clang-format", ~w(--version)) do
  {_result, 0} -> ExUnit.start()
  {_result, 1} -> raise "clang-format not found"
end
