defmodule Anotao.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Anotao.Repo,
      {Phoenix.PubSub, name: Anotao.PubSub},
      # Start a worker by calling: Anotao.Worker.start_link(arg)
      # {Anotao.Worker, arg},
      # Start to serve requests, typically the last entry
      AnotaoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Anotao.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AnotaoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
