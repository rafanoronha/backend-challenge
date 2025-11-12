defmodule TokenServiceTest do
  use ExUnit.Case
  doctest TokenService

  test "greets the world" do
    assert TokenService.hello() == :world
  end
end
