defmodule Debaite.Chatrooms.ChatroomServer do
  @moduledoc """
  GenServer that manages the debate flow for a single chatroom.
  Handles round-robin agent turns and coordinates LLM responses.
  """

  use GenServer
  require Logger

  alias Debaite.Chatrooms
  alias Debaite.LLM

  @tick_interval 2000  # Time between agent responses (2 seconds)

  # Client API

  def start_link(chatroom_id) do
    GenServer.start_link(__MODULE__, chatroom_id, name: via_tuple(chatroom_id))
  end

  def pause(chatroom_id) do
    GenServer.call(via_tuple(chatroom_id), :pause)
  end

  def resume(chatroom_id) do
    GenServer.call(via_tuple(chatroom_id), :resume)
  end

  def stop_debate(chatroom_id) do
    GenServer.call(via_tuple(chatroom_id), :stop)
  end

  def add_user_message(chatroom_id, content) do
    GenServer.cast(via_tuple(chatroom_id), {:user_message, content})
  end

  defp via_tuple(chatroom_id) do
    {:via, Registry, {Debaite.ChatroomRegistry, chatroom_id}}
  end

  # Server Callbacks

  @impl true
  def init(chatroom_id) do
    chatroom = Chatrooms.get_chatroom_with_agents!(chatroom_id)

    state = %{
      chatroom_id: chatroom_id,
      chatroom: chatroom,
      agents: chatroom.agents,
      status: chatroom.status,
      turn_index: chatroom.turn_index,
      timer_ref: nil
    }

    # If chatroom is already active, start the debate loop
    if chatroom.status == "active" do
      {:ok, schedule_next_turn(state)}
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_call(:pause, _from, state) do
    new_state = %{state | status: "paused", timer_ref: cancel_timer(state.timer_ref)}

    # Update database
    Chatrooms.update_status(state.chatroom, "paused")
    Chatrooms.broadcast_status_change(state.chatroom_id, "paused")

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:resume, _from, state) do
    new_state = %{state | status: "active"}

    # Update database
    Chatrooms.update_status(state.chatroom, "active")
    Chatrooms.broadcast_status_change(state.chatroom_id, "active")

    {:reply, :ok, schedule_next_turn(new_state)}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    new_state = %{state | status: "stopped", timer_ref: cancel_timer(state.timer_ref)}

    # Update database
    Chatrooms.update_status(state.chatroom, "stopped")
    Chatrooms.broadcast_status_change(state.chatroom_id, "stopped")

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast({:user_message, content}, state) do
    # Create user message
    {:ok, message} =
      Chatrooms.create_message(%{
        content: content,
        sender_type: "user",
        chatroom_id: state.chatroom_id
      })

    # Broadcast the message
    Chatrooms.broadcast_message(state.chatroom_id, message)

    {:noreply, state}
  end

  @impl true
  def handle_info(:next_turn, state) do
    if state.status == "active" do
      new_state = execute_agent_turn(state)
      {:noreply, schedule_next_turn(new_state)}
    else
      {:noreply, state}
    end
  end

  # Private Functions

  defp schedule_next_turn(state) do
    if state.status == "active" do
      timer_ref = Process.send_after(self(), :next_turn, @tick_interval)
      %{state | timer_ref: timer_ref}
    else
      state
    end
  end

  defp cancel_timer(nil), do: nil
  defp cancel_timer(timer_ref) do
    Process.cancel_timer(timer_ref)
    nil
  end

  defp execute_agent_turn(state) do
    # Get current agent based on round-robin
    agent = Enum.at(state.agents, rem(state.turn_index, length(state.agents)))

    if agent do
      Logger.info("Agent #{agent.name} is taking their turn in chatroom #{state.chatroom_id}")

      # Broadcast typing indicator
      Chatrooms.broadcast_typing(state.chatroom_id, agent.name)

      # Get message history
      message_history = Chatrooms.list_messages_by_chatroom(state.chatroom_id)

      # Generate agent response
      case LLM.generate_agent_response(agent, message_history) do
        {:ok, response_text} ->
          # Create agent message
          {:ok, message} =
            Chatrooms.create_message(%{
              content: response_text,
              sender_type: "agent",
              sender_id: agent.id,
              chatroom_id: state.chatroom_id
            })

          # Clear typing indicator
          Chatrooms.broadcast_typing(state.chatroom_id, nil)

          # Broadcast the message
          Chatrooms.broadcast_message(state.chatroom_id, message)

          # Increment turn index
          new_turn_index = state.turn_index + 1
          Chatrooms.update_turn_index(state.chatroom, new_turn_index)

          %{state | turn_index: new_turn_index}

        {:error, reason} ->
          Logger.error("Failed to generate agent response: #{inspect(reason)}")
          # Clear typing indicator on error
          Chatrooms.broadcast_typing(state.chatroom_id, nil)
          state
      end
    else
      Logger.error("No agent found for turn #{state.turn_index}")
      state
    end
  end
end
