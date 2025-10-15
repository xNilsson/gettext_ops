defmodule GettextOpsTest do
  use ExUnit.Case
  doctest GettextOps

  test "greets the world" do
    assert GettextOps.hello() == :world
  end
end
