defmodule CompilersTest do
  use ExUnit.Case
  doctest Compilers

  test "greets the world" do
    assert Compilers.hello() == :world
  end
end
