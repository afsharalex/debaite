defmodule Debaite.Chatrooms.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    field :sender_type, :string
    field :sender_id, :integer

    belongs_to :chatroom, Debaite.Chatrooms.Chatroom

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :sender_type, :sender_id, :chatroom_id])
    |> validate_required([:content, :sender_type, :chatroom_id])
    |> validate_inclusion(:sender_type, ["user", "agent"])
  end
end
