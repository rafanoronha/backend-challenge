import Config

# Test: allow debug logs for testing, but minimal console output
config :logger,
  level: :debug

config :logger, :default_handler, level: :warning
