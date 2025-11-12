defmodule TokenService.Integration.HealthEndpointTest do
  use ExUnit.Case
  import Plug.Test

  alias TokenService.Router

  @opts Router.init([])

  describe "GET /health" do
    @tag :integration
    test "returns 200 with Healthy message" do
      conn =
        conn(:get, "/health")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "Healthy"
    end
  end
end
