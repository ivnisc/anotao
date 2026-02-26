import Config

# Optimizaciones de memoria y CPU
config :phoenix, :json_library, Jason

# Logger optimizado para bajos recursos
config :logger,
  level: :warning,
  # Reduce buffers
  handle_otp_reports: true,
  handle_sasl_reports: false
