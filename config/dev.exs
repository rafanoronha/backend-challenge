import Config

# Development: human-readable console logs
config :logger, :default_handler,
  formatter:
    Logger.Formatter.new(
      format: "\n$time $metadata[$level] $message\n",
      metadata: [:request_id]
    )
