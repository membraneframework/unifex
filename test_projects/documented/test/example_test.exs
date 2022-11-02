defmodule UnifiedTest do
  use ExUnit.Case

  alias ElixirSense.Core.Introspection

  setup do
    %{}
  end

  test "nif functions are documented" do
    check_doc(:begin_file_documented_function)
    check_doc(:inside_file_documented_function)
    check_doc(:invalid_double_documented_function)
    check_doc_false(:inside_file_undocumented_function)
    check_doc(:after_undocumented_documented_function)
    check_doc_false(:undocumented_false_function)
    check_doc(:end_file_documented_function)
  end

  defp check_doc(fun_atom) do
    assert get_doc(Example, fun_atom) == "Test #{fun_atom} documentation"
  end

  defp check_doc_false(fun_atom) do
    assert get_doc(Example, fun_atom) == ""
  end

  defp get_doc(mod, func_atom) do
    %{docs: docs} =
      Introspection.get_all_docs(
        {mod, func_atom},
        :_
      )

    [_function_name | docs] = String.split(docs, "\n")
    Enum.join(docs, "")
  end
end
