defmodule TokenService.Integration.ValidateEndpointTest do
  use ExUnit.Case
  import Plug.Test
  import Plug.Conn

  alias TokenService.Router

  @opts Router.init([])

  setup_all do
    # Start Telemetry supervisor once for all tests in this module
    {:ok, _pid} = start_supervised(TokenService.Telemetry)
    # Give the Prometheus metrics server time to initialize
    Process.sleep(200)
    :ok
  end

  describe "POST /validate" do
    @tag :integration
    test "returns valid: true for challenge case 1 - valid token" do
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNzg0MSIsIk5hbWUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05sIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"

      conn =
        conn(:post, "/validate", Jason.encode!(%{token: token}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200

      response = Jason.decode!(conn.resp_body)
      assert response["valid"] == true
    end

    @tag :integration
    test "returns valid: false for challenge case 2 - malformed JWT" do
      token =
        "eyJhbGciOiJzI1NiJ9.dfsdfsfryJSr2xrIjoiQWRtaW4iLCJTZrkIjoiNzg0MSIsIk5hbrUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05fsdfsIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"

      conn =
        conn(:post, "/validate", Jason.encode!(%{token: token}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200

      response = Jason.decode!(conn.resp_body)
      assert response["valid"] == false
    end

    @tag :integration
    test "returns valid: false for challenge case 3 - Name with numbers" do
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiRXh0ZXJuYWwiLCJTZWVkIjoiODgwMzciLCJOYW1lIjoiTTRyaWEgT2xpdmlhIn0.6YD73XWZYQSSMDf6H0i3-kylz1-TY_Yt6h1cV2Ku-Qs"

      conn =
        conn(:post, "/validate", Jason.encode!(%{token: token}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200

      response = Jason.decode!(conn.resp_body)
      assert response["valid"] == false
    end

    @tag :integration
    test "returns valid: false for challenge case 4 - more than 3 claims" do
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiTWVtYmVyIiwiT3JnIjoiQlIiLCJTZWVkIjoiMTQ2MjciLCJOYW1lIjoiVmFsZGlyIEFyYW5oYSJ9.cmrXV_Flm5mfdpfNUVopY_I2zeJUy4EZ4i3Fea98zvY"

      conn =
        conn(:post, "/validate", Jason.encode!(%{token: token}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200

      response = Jason.decode!(conn.resp_body)
      assert response["valid"] == false
    end

    @tag :integration
    test "returns valid: false when token field is missing" do
      conn =
        conn(:post, "/validate", Jason.encode!(%{other: "value"}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200

      response = Jason.decode!(conn.resp_body)
      assert response["valid"] == false
    end

    @tag :integration
    test "returns valid: false when body is empty" do
      conn =
        conn(:post, "/validate", Jason.encode!(%{}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200

      response = Jason.decode!(conn.resp_body)
      assert response["valid"] == false
    end
  end

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

  describe "GET /metrics" do
    @tag :integration
    test "returns 200 with Prometheus metrics" do
      conn =
        conn(:get, "/metrics")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body =~ "# TYPE"
      assert conn.resp_body =~ "# HELP"
    end

    @tag :integration
    test "includes token validation metrics after validation" do
      # First, make a validation request
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNzg0MSIsIk5hbWUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05sIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"

      conn(:post, "/validate", Jason.encode!(%{token: token}))
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

      # Then check metrics include validation counters
      conn =
        conn(:get, "/metrics")
        |> Router.call(@opts)

      assert conn.resp_body =~ "token_service_validation_count"
    end
  end

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
