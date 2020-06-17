defmodule Unifex.IntegrationTest do
  use ExUnit.Case, async: true

  test "test project" do
    # clang-format is required to format the generated code
    # it won't match the reference files otherwise
    assert {_output, 0} = System.cmd("clang-format", ~w(--version))
    assert {_output, 0} = System.cmd("bash", ["-c", "mix test 1>&2"], cd: "test_project")

    files =
      Enum.map(~w(example.h example.c example.cpp), &{&1, &1}) ++
        [{".gitignore", "ref_gitignore"}]

    Enum.each(files, fn {f, ref} ->
      assert File.read!(Path.join("test_project/c_src/example/_generated", f)) ==
               File.read!(Path.join("test_fixtures/ref_generated", ref))
    end)
  end
end
