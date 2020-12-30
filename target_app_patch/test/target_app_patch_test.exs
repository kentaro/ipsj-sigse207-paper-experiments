defmodule TargetAppPatchTest do
  use ExUnit.Case
  doctest TargetAppPatch

  test "greets the world" do
    assert TargetAppPatch.hello() == :world
  end
end
