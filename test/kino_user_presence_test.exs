defmodule KinoUserPresenceTest do
  use ExUnit.Case
  doctest KinoUserPresence

  test "greets the world" do
    assert KinoUserPresence.hello() == :world
  end
end
