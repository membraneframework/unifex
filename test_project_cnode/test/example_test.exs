defmodule ExampleTest do
  use ExUnit.Case

  test "init" do
    require Unifex.CNode
    assert {:ok, cnode} = Unifex.CNode.start_link(:example)
    assert :ok = Unifex.CNode.call(cnode, :init)
    assert {:ok, 42, <<2, 2, 3>>} = Unifex.CNode.call(cnode, :foo, [self(), <<1, 2, 3>>])
    assert_receive {:example_msg, 42}

    assert_raise RuntimeError, ~r/undefined.*function.*abc/i, fn ->
      Unifex.CNode.call(cnode, :abc)
    end
  end
end
