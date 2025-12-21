defmodule Debaite.Repo.Migrations.CreateChatrooms do
  use Ecto.Migration

  def change do
    create table(:chatrooms) do
      add :topic, :string, null: false
      add :status, :string, null: false, default: "setup"
      add :turn_index, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:chatrooms, [:status])
  end
end
