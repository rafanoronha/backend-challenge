defmodule TokenService.Integration.MetricsEndpointTest do
  use ExUnit.Case
  import Plug.Test
  import Plug.Conn

  alias TokenService.Router

  @opts Router.init([])

  setup_all do
    # Start Telemetry supervisor once for all tests in this module
    {:ok, _pid} = start_supervised(TokenService.Telemetry)

    # Wait for Prometheus metrics server to be ready
    wait_for_metrics_server()

    # Trigger VM measurements to ensure some metrics are available
    TokenService.Telemetry.vm_measurements()
    Process.sleep(50)

    :ok
  end

  defp wait_for_metrics_server(retries \\ 10) do
    case GenServer.whereis(:prometheus_metrics) do
      nil ->
        if retries > 0 do
          Process.sleep(50)
          wait_for_metrics_server(retries - 1)
        else
          raise "Prometheus metrics server did not start"
        end

      _pid ->
        # Server is ready, give it a moment to fully initialize
        Process.sleep(100)
        :ok
    end
  end

  describe "GET /metrics" do
    @tag :integration
    test "returns 200 with Prometheus metrics format" do
      conn =
        conn(:get, "/metrics")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body =~ "# TYPE"
      assert conn.resp_body =~ "# HELP"
    end

    @tag :integration
    test "includes custom token validation metrics" do
      # Make validation requests to generate metrics
      valid_token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNzg0MSIsIk5hbWUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05sIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"

      invalid_token = "invalid"

      # Valid validation
      conn(:post, "/validate", Jason.encode!(%{token: valid_token}))
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

      # Invalid validation
      conn(:post, "/validate", Jason.encode!(%{token: invalid_token}))
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

      # Check metrics include all custom validation metrics
      conn =
        conn(:get, "/metrics")
        |> Router.call(@opts)

      metrics_body = conn.resp_body

      # Custom validation metrics
      assert metrics_body =~ "token_service_validation_count"
      assert metrics_body =~ "result=\"success\""
      assert metrics_body =~ "result=\"failed\""
      assert metrics_body =~ "token_service_validation_failure_reasons"
    end

    @tag :integration
    test "metrics endpoint is accessible and returns valid Prometheus format" do
      # Make some HTTP requests
      conn(:get, "/health") |> Router.call(@opts)
      conn(:get, "/metrics") |> Router.call(@opts)

      conn =
        conn(:get, "/metrics")
        |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body =~ "# TYPE"
      assert conn.resp_body =~ "# HELP"
    end

    @tag :integration
    test "includes VM metrics" do
      # Trigger VM measurements manually to ensure they're available
      TokenService.Telemetry.vm_measurements()
      Process.sleep(50)

      conn =
        conn(:get, "/metrics")
        |> Router.call(@opts)

      metrics_body = conn.resp_body

      # VM metrics should be present (check for metric names in output)
      assert metrics_body =~ "vm_memory"
      assert metrics_body =~ "vm_system_counts"
      assert metrics_body =~ "vm_total_run_queue"
    end
  end
end
