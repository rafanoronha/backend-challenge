defmodule TokenService.Router do
  use Plug.Router

  alias TokenService.TokenValidator

  plug(Plug.Telemetry, event_prefix: [:http, :request])
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  get "/health" do
    send_resp(conn, 200, "Healthy")
  end

  get "/metrics" do
    metrics = TelemetryMetricsPrometheus.Core.scrape()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end

  post "/validate" do
    with %{"token" => token} <- conn.body_params,
         valid <- TokenValidator.validate(token),
         response <- Jason.encode!(%{valid: valid}) do
      send_resp(conn, 200, response)
    else
      _ ->
        response = Jason.encode!(%{valid: false})
        send_resp(conn, 200, response)
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
