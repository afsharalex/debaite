defmodule Debaite.Repo.Migrations.CreateAgents do
  use Ecto.Migration

  def change do
    create table(:agents) do
      add :name, :string, null: false
      add :system_prompt, :text, null: false
      add :provider, :string, null: false
      add :model, :string, null: false
      add :position, :integer, null: false
      add :chatroom_id, references(:chatrooms, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:agents, [:chatroom_id])
    create index(:agents, [:chatroom_id, :position])
  end
end
