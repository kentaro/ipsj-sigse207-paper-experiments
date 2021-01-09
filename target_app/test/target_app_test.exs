defmodule TargetAppTest do
  use ExUnit.Case
  doctest TargetApp

  test "greets the world" do
    assert TargetApp.hello() == :world
  end
end
