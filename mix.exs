defmodule TokenService.MixProject do
  use Mix.Project

  def project do
    [
      app: :token_service,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: [precommit: :test],
      config_path: "config/config.exs"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    extra_applications = [:logger]

    if Mix.env() == :test do
      [extra_applications: extra_applications]
    else
      [extra_applications: extra_applications, mod: {TokenService.Application, []}]
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:plug_cowboy, "~> 2.7"},
      {:joken, "~> 2.6"},
      {:jason, "~> 1.4"},
      {:ecto, "~> 3.12"},
      {:logger_json, "~> 6.2"}
    ]
  end

  defp aliases do
    [
      start: ["compile", "run --no-halt"],
      precommit: ["compile --warning-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
