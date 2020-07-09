defmodule ExampleTest do
  use ExUnit.Case

  test "init" do
    require Unifex.UnifexCNode
    assert {:ok, cnode} = Unifex.UnifexCNode.start_link(:example)
    assert :ok = Unifex.UnifexCNode.call(cnode, :init)
    assert {:ok, 42, <<2, 2, 3>>} = Unifex.UnifexCNode.call(cnode, :foo, [self(), <<1, 2, 3>>])
    assert_receive {:example_msg, 42}

    assert_raise RuntimeError, ~r/undefined.*function.*abc/i, fn ->
      Unifex.UnifexCNode.call(cnode, :abc)
    end
  end
end
