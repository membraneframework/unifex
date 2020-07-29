defmodule UnifiedTest do
  use ExUnit.Case

  test "nif" do
    assert {:ok, 10} = Example.foo()
  end

  test "cnode" do
    require Unifex.CNode
    assert {:ok, cnode} = Unifex.CNode.start_link(:example)
    assert {:ok, 10} = Unifex.CNode.call(cnode, :foo, [])
  end
end
