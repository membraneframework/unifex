defmodule BundlexExsTest do
  use ExUnit.Case

  test "nif" do
    assert {:ok, 10} = Example.foo(10)
  end

  test "cnode" do
    require Unifex.CNode
    assert {:ok, cnode} = Unifex.CNode.start_link(:example)
    assert {:ok, 10} = Unifex.CNode.call(cnode, :foo, [10])
  end
end
