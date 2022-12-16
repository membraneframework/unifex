# clang-format is required to format the generated code
# it won't match the reference files otherwise
if Unifex.Utils.clang_format_installed?() do
  ExUnit.start()
else
  raise "clang-format has to be installed on the system to run Unifex tests."
end
