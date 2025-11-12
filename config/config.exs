import Config

# Base configuration for all environments
config :logger,
  level: :debug

# Import environment specific config
import_config "#{config_env()}.exs"
