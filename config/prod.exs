import Config

# Production: JSON-structured logs for observability platforms
config :logger, :default_handler, formatter: {LoggerJSON.Formatters.Basic, metadata: :all}

config :logger,
  level: :debug
