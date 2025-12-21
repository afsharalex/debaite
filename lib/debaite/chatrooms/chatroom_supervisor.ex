defmodule Debaite.Chatrooms.ChatroomSupervisor do
  @moduledoc """
  DynamicSupervisor for managing ChatroomServer processes.
  """

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a ChatroomServer for the given chatroom_id.
  """
  def start_chatroom(chatroom_id) do
    spec = {Debaite.Chatrooms.ChatroomServer, chatroom_id}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc """
  Stops a ChatroomServer for the given chatroom_id.
  """
  def stop_chatroom(chatroom_id) do
    case Registry.lookup(Debaite.ChatroomRegistry, chatroom_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Checks if a chatroom server is running.
  """
  def chatroom_running?(chatroom_id) do
    case Registry.lookup(Debaite.ChatroomRegistry, chatroom_id) do
      [{_pid, _}] -> true
      [] -> false
    end
  end
end
