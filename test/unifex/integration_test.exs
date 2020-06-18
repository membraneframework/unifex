defmodule Unifex.IntegrationTest do
  use ExUnit.Case, async: true

  test "test test project" do
    test_project("test_project")
  end

  test "test cnode test project" do
    test_project("test_project_cnode")
  end

  defp test_project(project) do
    assert {_output, 0} = System.cmd("bash", ["-c", "mix test 1>&2"], cd: project)

    # clang-format is required to format the generated code
    # it won't match the reference files otherwise
    assert {_output, 0} = System.cmd("clang-format", ~w(--version))

    "test_fixtures/#{project}_ref_generated"
    |> File.ls!()
    |> Enum.each(fn ref ->
      f = if ref == "ref_gitignore", do: ".gitignore", else: ref

      assert File.read!("#{project}/c_src/example/_generated/#{f}") ==
               File.read!("test_fixtures/#{project}_ref_generated/#{ref}")
    end)
  end
end
