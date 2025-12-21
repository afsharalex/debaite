defmodule Debaite.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :text, null: false
      add :sender_type, :string, null: false
      add :sender_id, :integer
      add :chatroom_id, references(:chatrooms, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:chatroom_id])
    create index(:messages, [:chatroom_id, :inserted_at])
    create index(:messages, [:sender_type, :sender_id])
  end
end
