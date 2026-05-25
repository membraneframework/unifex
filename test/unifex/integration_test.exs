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

  @tag :a
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
    tie_headers =
      File.ls!("test_projects/#{project}/c_src/example/_generated")
      |> Enum.filter(&String.ends_with?(&1, ".h"))

    assert Enum.count(tie_headers) == 2

    main_files =
      File.ls!("test_projects/#{project}/c_src/example/_generated/#{interface}")
      |> Enum.map(&Path.join("#{interface}", &1))

    (tie_headers ++ main_files)
    |> Enum.each(fn file ->
      ref_file_path = "test/fixtures/#{project}_ref_generated/#{file}"
      generated_file_path = "test_projects/#{project}/c_src/example/_generated/#{file}"

      assert File.exists?(ref_file_path)
      assert File.read!(generated_file_path) == File.read!(ref_file_path)
    end)
  end

  defp generate_cpp_code(project) do
    path_prefix = "test_projects/#{project}/c_src/example"
    File.cp("#{path_prefix}/example.c", "#{path_prefix}/example.cpp")
    on_exit(fn -> File.rm!("#{path_prefix}/example.cpp") end)
  end
end
