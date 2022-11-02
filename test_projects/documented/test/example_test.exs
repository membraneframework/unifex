defmodule UnifiedTest do
  use ExUnit.Case

  alias ElixirSense.Core.Introspection

  setup do
    %{}
  end

  test "nif functions are documented" do
    docs = get_docs(Example)

    check_doc(docs, :begin_file_documented_function)
    check_doc(docs, :inside_file_documented_function)
    check_doc(docs, :invalid_double_documented_function)
    check_doc_false(docs, :inside_file_undocumented_function)
    check_doc(docs, :after_undocumented_documented_function)
    check_doc_false(docs, :undocumented_false_function)
    check_doc(docs, :end_file_documented_function)
  end

  defp check_doc(docs, fun_atom) do
    assert Map.get(docs, fun_atom) == "Test #{fun_atom} documentation\n"
  end

  defp check_doc_false(docs, fun_atom) do
    assert Map.get(docs, fun_atom) == :none
  end

  defp get_docs(mod) do
    {_, _, _, _, _, _, docs} = Code.fetch_docs(mod)

    docs
    |> Enum.map(fn
      {{:function, atom_name, 1}, 2, _name, doc, %{}} ->
        case doc do
          %{"en" => doc} -> {atom_name, doc}
          :none -> {atom_name, :none}
        end
    end)
    |> Map.new()
  end
end
