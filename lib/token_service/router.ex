defmodule TokenService.Router do
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  get "/health" do
    send_resp(conn, 200, "Healthy")
  end

  post "/validate" do
    send_resp(conn, 200, ~s({"valid": false}))
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
