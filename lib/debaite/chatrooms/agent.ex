defmodule Debaite.Chatrooms.Agent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "agents" do
    field :name, :string
    field :system_prompt, :string
    field :provider, :string
    field :model, :string
    field :position, :integer

    belongs_to :chatroom, Debaite.Chatrooms.Chatroom

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(agent, attrs) do
    agent
    |> cast(attrs, [:name, :system_prompt, :provider, :model, :position, :chatroom_id])
    |> validate_required([:name, :system_prompt, :provider, :model, :position, :chatroom_id])
  end
end
