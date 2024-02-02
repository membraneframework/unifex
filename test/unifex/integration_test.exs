defmodule Unifex.IntegrationTest do
  use ExUnit.Case, async: true

  test "NIF test project" do
    test_project("nif", :nif)
  end

  test "CNode test project" do
    test_project("cnode", :cnode)
  end

  test "unified (NIF) test project" do
    test_project("unified", :nif)
  end

  test "unified (CNode) test project" do
    test_project("unified", :cnode)
  end

  test "bundlex.exs specified interface (NIF) test project" do
    test_project("bundlex_exs", :nif)
  end

  test "bundlex.exs specified interface (CNode) test project" do
    test_project("bundlex_exs", :cnode)
  end

  defp test_project(project, interface) do
    generate_cpp_code(project)

    for language <- [:c, :cpp] do
      do_test_project(project, interface, language)
    end
  end

  defp run_projects_tests(project, language) do
    assert {_output, 0} =
             System.cmd("bash", ["-c", "mix test 1>&2"],
               cd: "test_projects/#{project}",
               env: [{"UNIFEX_TEST_LANG", "#{language}"}]
             )
  end

  defp do_test_project(project, interface, language) do
    run_projects_tests(project, language)

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
      IO.inspect("test_projects/#{project}/c_src/example/_generated/#{interface}/#{ref}", label: "GENERATED")
      IO.inspect("test/fixtures/#{project}_ref_generated/#{interface}/#{ref}", label: "FIXTURE")
      assert File.read!("test_projects/#{project}/c_src/example/_generated/#{interface}/#{ref}") ==
               File.read!("test/fixtures/#{project}_ref_generated/#{interface}/#{ref}")
    end)
  end

  defp generate_cpp_code(project) do
    path_prefix = "test_projects/#{project}/c_src/example"
    File.cp("#{path_prefix}/example.c", "#{path_prefix}/example.cpp")
    on_exit(fn -> File.rm!("#{path_prefix}/example.cpp") end)
  end
end
