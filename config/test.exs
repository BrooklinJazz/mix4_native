import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mix4, Mix4Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Iy3/+MlD8NItSkcW5ItLAyDUk6VRHnZ2D7MkCJLdvs3jkgVfNk5j8wSf4TcVfbbC",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
