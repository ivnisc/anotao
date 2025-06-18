defmodule Anotao.Repo do
  use Ecto.Repo,
    otp_app: :anotao,
    adapter: Ecto.Adapters.Postgres
end
