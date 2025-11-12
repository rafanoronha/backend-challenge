defmodule TokenService.Integration.NotFoundTest do
  use ExUnit.Case
  import Plug.Test

  alias TokenService.Router

  @opts Router.init([])

  describe "unknown routes" do
    @tag :integration
    test "returns 404 for unknown POST route" do
      conn =
        conn(:post, "/unknown")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 404
      assert conn.resp_body == "Not Found"
    end

    @tag :integration
    test "returns 404 for unknown GET route" do
      conn =
        conn(:get, "/unknown")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 404
      assert conn.resp_body == "Not Found"
    end
  end
end
