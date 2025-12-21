defmodule Debaite.Repo do
  use Ecto.Repo,
    otp_app: :debaite,
    adapter: Ecto.Adapters.Postgres
end
