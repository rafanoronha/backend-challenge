defmodule TokenService.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: TokenService.Router, options: [port: 4000]}
    ]

    Logger.info("Starting TokenService on port 4000")
    opts = [strategy: :one_for_one, name: TokenService.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
