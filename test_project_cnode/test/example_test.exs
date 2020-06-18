defmodule ExampleTest do
  use ExUnit.Case

  test "init" do
    require Unifex.UnifexCNode
    assert {:ok, cnode} = Unifex.UnifexCNode.start_link(:example)
    assert {:ok} = Unifex.UnifexCNode.call(cnode, :init)
  end
end
