defmodule TokenService.Router do
  use Plug.Router

  alias TokenService.OpenApi.ApiSpec
  alias TokenService.TokenValidator

  plug(Plug.Telemetry, event_prefix: [:http, :request])
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(OpenApiSpex.Plug.PutApiSpec, module: ApiSpec)
  plug(:dispatch)

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

  get "/health" do
    send_resp(conn, 200, "Healthy")
  end

  get "/metrics" do
    metrics = TelemetryMetricsPrometheus.Core.scrape()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end

  get "/openapi" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(ApiSpec.spec()))
  end

  get "/swagger" do
    html = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Token Service API - Swagger UI</title>
      <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
    </head>
    <body>
      <div id="swagger-ui"></div>
      <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
      <script>
        SwaggerUIBundle({
          url: '/openapi',
          dom_id: '#swagger-ui',
        });
      </script>
    </body>
    </html>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  get "/" do
    conn
    |> put_resp_header("location", "/swagger")
    |> send_resp(302, "")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
