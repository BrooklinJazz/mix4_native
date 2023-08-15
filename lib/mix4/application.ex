defmodule Mix4.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      Mix4Web.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Mix4.PubSub},
      {Mix4Web.Presence, name: Mix4Web.Presence},
      # Start the Endpoint (http/https)
      Mix4Web.Endpoint,
      # Start a worker by calling: Mix4.Worker.start_link(arg)
      # {Mix4.Worker, arg}
      {DynamicSupervisor, name: Mix4.GameSupervisor},
      {Mix4.GamesServer, []},
      {Registry, [keys: :unique, name: Mix4.GameRegistry]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mix4.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Mix4Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
