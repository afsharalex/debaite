defmodule Debaite.Chatrooms do
  @moduledoc """
  The Chatrooms context.
  """

  import Ecto.Query, warn: false
  alias Debaite.Repo

  alias Debaite.Chatrooms.{Chatroom, Agent, Message}

  @doc """
  Creates a chatroom.
  """
  def create_chatroom(attrs \\ %{}) do
    %Chatroom{}
    |> Chatroom.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single chatroom.
  """
  def get_chatroom!(id), do: Repo.get!(Chatroom, id)

  @doc """
  Gets a chatroom with preloaded associations.
  """
  def get_chatroom_with_agents!(id) do
    Chatroom
    |> Repo.get!(id)
    |> Repo.preload(agents: from(a in Agent, order_by: a.position))
  end

  @doc """
  Updates a chatroom.
  """
  def update_chatroom(%Chatroom{} = chatroom, attrs) do
    chatroom
    |> Chatroom.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the chatroom status.
  """
  def update_status(%Chatroom{} = chatroom, status) do
    update_chatroom(chatroom, %{status: status})
  end

  @doc """
  Updates the turn index.
  """
  def update_turn_index(%Chatroom{} = chatroom, turn_index) do
    update_chatroom(chatroom, %{turn_index: turn_index})
  end

  @doc """
  Creates an agent.
  """
  def create_agent(attrs \\ %{}) do
    %Agent{}
    |> Agent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an agent.
  """
  def update_agent(%Agent{} = agent, attrs) do
    agent
    |> Agent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an agent.
  """
  def delete_agent(%Agent{} = agent) do
    Repo.delete(agent)
  end

  @doc """
  Lists all agents for a chatroom, ordered by position.
  """
  def list_agents_by_chatroom(chatroom_id) do
    Agent
    |> where([a], a.chatroom_id == ^chatroom_id)
    |> order_by([a], a.position)
    |> Repo.all()
  end

  @doc """
  Gets a specific agent.
  """
  def get_agent!(id), do: Repo.get!(Agent, id)

  @doc """
  Creates a message.
  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists all messages for a chatroom, ordered by insertion time.
  """
  def list_messages_by_chatroom(chatroom_id) do
    Message
    |> where([m], m.chatroom_id == ^chatroom_id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end

  @doc """
  Subscribes to chatroom updates via PubSub.
  """
  def subscribe_to_chatroom(chatroom_id) do
    Phoenix.PubSub.subscribe(Debaite.PubSub, "chatroom:#{chatroom_id}")
  end

  @doc """
  Broadcasts a message to all subscribers of a chatroom.
  """
  def broadcast_message(chatroom_id, message) do
    Phoenix.PubSub.broadcast(
      Debaite.PubSub,
      "chatroom:#{chatroom_id}",
      {:new_message, message}
    )
  end

  @doc """
  Broadcasts a status change to all subscribers of a chatroom.
  """
  def broadcast_status_change(chatroom_id, status) do
    Phoenix.PubSub.broadcast(
      Debaite.PubSub,
      "chatroom:#{chatroom_id}",
      {:status_change, status}
    )
  end
end
