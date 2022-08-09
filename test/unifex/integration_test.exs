defmodule Unifex.IntegrationTest do
  use ExUnit.Case, async: true

  test "NIF test project" do
    generate_cpp_code("nif")

    test_project("nif", :nif, :c)
    test_project("nif", :nif, :cpp)

    delete_cpp_code("nif")
  end

  test "CNode test project" do
    generate_cpp_code("cnode")

    test_project("cnode", :cnode, :c)
    test_project("cnode", :cnode, :cpp)

    delete_cpp_code("cnode")
  end

  test "unified (NIF) test project" do
    generate_cpp_code("unified")

    test_project("unified", :nif, :c)
    test_project("unified", :nif, :cpp)

    delete_cpp_code("unified")
  end

  test "unified (CNode) test project" do
    generate_cpp_code("unified")

    test_project("unified", :cnode, :c)
    test_project("unified", :cnode, :cpp)

    delete_cpp_code("unified")
  end

  test "bundlex.exs specified interface (NIF) test project" do
    generate_cpp_code("bundlex_exs")

    test_project("bundlex_exs", :nif, :c)
    test_project("bundlex_exs", :nif, :cpp)

    delete_cpp_code("bundlex_exs")
  end

  test "bundlex.exs specified interface (CNode) test project" do
    generate_cpp_code("bundlex_exs")

    test_project("bundlex_exs", :cnode, :c)
    test_project("bundlex_exs", :cnode, :cpp)

    delete_cpp_code("bundlex_exs")
  end

  defp test_project(project, interface, language) do
    assert {_output, 0} =
             System.cmd("bash", ["-c", "mix test 1>&2"],
               cd: "test_projects/#{project}",
               env: [{"UNIFEX_TEST_LANG", "#{language}"}]
             )

    # clang-format is required to format the generated code
    # it won't match the reference files otherwise
    assert {_output, 0} = System.cmd("clang-format", ~w(--version))

    test_common(project)
    test_particular(project, interface)
  end

  defp test_common(project) do
    "test/fixtures/common_ref_generated"
    |> File.ls!()
    |> Enum.each(fn ref ->
      f = if ref == "ref_gitignore", do: ".gitignore", else: ref

      assert File.read!("test_projects/#{project}/c_src/example/_generated/#{f}") ==
               File.read!("test/fixtures/common_ref_generated/#{ref}")
    end)
  end

  defp test_particular(project, interface) do
    test_tie_header(project)
    test_main_files(project, interface)
  end

  defp test_tie_header(project) do
    assert File.read!("test_projects/#{project}/c_src/example/_generated/example.h") ==
             File.read!("test/fixtures/#{project}_ref_generated/example.h")
  end

  defp test_main_files(project, interface) do
    "test/fixtures/#{project}_ref_generated/#{interface}"
    |> File.ls!()
    |> Enum.each(fn ref ->
      assert File.read!("test_projects/#{project}/c_src/example/_generated/#{interface}/#{ref}") ==
               File.read!("test/fixtures/#{project}_ref_generated/#{interface}/#{ref}")
    end)
  end

  defp generate_cpp_code(project) do
    System.cmd("cp", ["example.c", "example.cpp"], cd: "test_projects/#{project}/c_src/example")
  end

  defp delete_cpp_code(project) do
    System.cmd("rm", ["example.cpp"], cd: "test_projects/#{project}/c_src/example")
  end
end
