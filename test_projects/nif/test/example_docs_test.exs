defmodule ExampleDocsTest do
  use ExUnit.Case

  setup_all do
    docs = get_docs(Example)
    %{docs: docs}
  end

  describe "nif documentation" do
    test "for first function", %{docs: docs} do
      check_doc(docs, :init)
    end

    test "for second function", %{docs: docs} do
      check_doc(docs, :test_atom)
    end

    test "false", %{docs: docs} do
      check_doc_false(docs, :test_float)
    end

    test "without documentation", %{docs: docs} do
      check_doc_false(docs, :test_int)
    end

    test "for function inside the file", %{docs: docs} do
      check_doc(docs, :test_string)
    end

    test "for last function", %{docs: docs} do
      check_doc(docs, :test_my_enum)
    end
  end

  defp check_doc(docs, fun_atom) do
    assert Map.get(docs, fun_atom) == "#{fun_atom} docs\n"
  end

  defp check_doc_false(docs, fun_atom) do
    assert Map.get(docs, fun_atom) == :none
  end

  defp get_docs(mod) do
    {_, _, _, _, _, _, docs} = Code.fetch_docs(mod)

    docs
    |> Enum.map(fn
      {{:function, atom_name, _}, _, _name, doc, %{}} ->
        case doc do
          %{"en" => doc} -> {atom_name, doc}
          :none -> {atom_name, :none}
        end
    end)
    |> Map.new()
  end
end
