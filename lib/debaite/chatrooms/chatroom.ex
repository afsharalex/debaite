defmodule Debaite.Chatrooms.Chatroom do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chatrooms" do
    field :topic, :string
    field :status, :string, default: "setup"
    field :turn_index, :integer, default: 0

    has_many :agents, Debaite.Chatrooms.Agent
    has_many :messages, Debaite.Chatrooms.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chatroom, attrs) do
    chatroom
    |> cast(attrs, [:topic, :status, :turn_index])
    |> validate_required([:topic])
    |> validate_inclusion(:status, ["setup", "active", "paused", "stopped"])
  end
end
