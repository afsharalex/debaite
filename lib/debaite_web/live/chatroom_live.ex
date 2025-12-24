defmodule DebaiteWeb.ChatroomLive do
  use DebaiteWeb, :live_view

  alias Debaite.Chatrooms
  alias Debaite.Chatrooms.ChatroomServer

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    chatroom_id = String.to_integer(id)
    chatroom = Chatrooms.get_chatroom_with_agents!(chatroom_id)
    messages = Chatrooms.list_messages_by_chatroom(chatroom_id)

    # Subscribe to chatroom updates
    if connected?(socket) do
      Chatrooms.subscribe_to_chatroom(chatroom_id)
    end

    {:ok,
     socket
     |> assign(:chatroom, chatroom)
     |> assign(:messages, messages)
     |> assign(:message_input, "")
     |> assign(:typing_agent, nil)
     |> assign(:sending_message, false)
     |> assign(:agents_map, build_agents_map(chatroom.agents))}
  end

  @impl true
  def handle_event("pause", _params, socket) do
    ChatroomServer.pause(socket.assigns.chatroom.id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("resume", _params, socket) do
    ChatroomServer.resume(socket.assigns.chatroom.id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("stop", _params, socket) do
    ChatroomServer.stop_debate(socket.assigns.chatroom.id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => content}, socket) do
    if String.trim(content) != "" do
      ChatroomServer.add_user_message(socket.assigns.chatroom.id, content)
      {:noreply, socket |> assign(:message_input, "") |> assign(:sending_message, true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    new_socket = update(socket, :messages, fn messages -> messages ++ [message] end)

    # If this is a user message, clear the sending state
    new_socket = if message.sender_type == "user" do
      assign(new_socket, :sending_message, false)
    else
      new_socket
    end

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:status_change, new_status}, socket) do
    chatroom = %{socket.assigns.chatroom | status: new_status}
    {:noreply, assign(socket, :chatroom, chatroom)}
  end

  @impl true
  def handle_info({:typing, agent_name}, socket) do
    {:noreply, assign(socket, :typing_agent, agent_name)}
  end

  defp build_agents_map(agents) do
    Map.new(agents, fn agent -> {agent.id, agent} end)
  end

  defp get_sender_name(message, agents_map) do
    case message.sender_type do
      "user" -> "You"
      "agent" -> Map.get(agents_map, message.sender_id, %{name: "Unknown"}).name
      _ -> "Unknown"
    end
  end

  defp message_class(message) do
    case message.sender_type do
      "user" -> "bg-blue-100 border-blue-300"
      "agent" -> "bg-gray-100 border-gray-300"
      _ -> "bg-white border-gray-200"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4 py-8 h-screen flex flex-col">
      <div class="mb-4">
        <h1 class="text-3xl font-bold"><%= @chatroom.topic %></h1>
        <div class="flex items-center gap-4 mt-2">
          <span class={"px-3 py-1 rounded text-sm font-semibold " <> status_badge_class(@chatroom.status)}>
            <%= String.upcase(@chatroom.status) %>
          </span>
          <div class="flex gap-2">
            <%= if @chatroom.status == "active" do %>
              <button
                phx-click="pause"
                class="bg-yellow-500 hover:bg-yellow-600 text-white px-3 py-1 rounded text-sm"
              >
                Pause
              </button>
            <% end %>
            <%= if @chatroom.status == "paused" do %>
              <button
                phx-click="resume"
                class="bg-green-500 hover:bg-green-600 text-white px-3 py-1 rounded text-sm"
              >
                Resume
              </button>
            <% end %>
            <%= if @chatroom.status in ["active", "paused"] do %>
              <button
                phx-click="stop"
                class="bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded text-sm"
              >
                Stop
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <div class="bg-white shadow rounded-lg mb-4 p-4">
        <h2 class="text-lg font-semibold mb-2 text-black">Participants</h2>
        <div class="flex flex-wrap gap-2">
          <%= for agent <- @chatroom.agents do %>
            <span class="bg-purple-100 text-purple-800 px-3 py-1 rounded-full text-sm">
              <%= agent.name %> (<%= agent.provider %>:<%= agent.model %>)
            </span>
          <% end %>
        </div>
      </div>

      <div
        id="messages-container"
        class="flex-1 bg-white shadow rounded-lg p-4 overflow-y-auto mb-4"
        phx-hook="ScrollToBottom"
      >
        <%= if Enum.empty?(@messages) do %>
          <p class="text-gray-500 text-center py-8">
            No messages yet. The debate will begin shortly...
          </p>
        <% else %>
          <%= for message <- @messages do %>
            <div class={"border-l-4 p-4 mb-3 rounded " <> message_class(message)}>
              <div class="flex items-center gap-2 mb-1">
                <span class="font-bold text-sm text-gray-900">
                  <%= get_sender_name(message, @agents_map) %>
                </span>
                <span class="text-xs text-gray-500">
                  <%= Calendar.strftime(message.inserted_at, "%I:%M %p") %>
                </span>
              </div>
              <p class="text-gray-800 whitespace-pre-wrap"><%= message.content %></p>
            </div>
          <% end %>
        <% end %>
        <%= if @typing_agent do %>
          <div class="border-l-4 border-gray-300 bg-gray-50 p-4 mb-3 rounded animate-pulse">
            <div class="flex items-center gap-2">
              <span class="font-bold text-sm text-gray-700">
                <%= @typing_agent %>
              </span>
              <span class="text-sm text-gray-600">is writing...</span>
            </div>
          </div>
        <% end %>
      </div>

      <div class="bg-white shadow rounded-lg p-4">
        <form phx-submit="send_message" class="flex gap-2">
          <input
            type="text"
            name="message"
            value={@message_input}
            placeholder="Type your message..."
            class="flex-1 border rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
            autocomplete="off"
            disabled={@sending_message}
          />
          <button
            type="submit"
            disabled={@sending_message}
            class={"px-6 py-2 rounded font-semibold " <> if @sending_message do
              "bg-blue-300 text-white cursor-not-allowed"
            else
              "bg-blue-500 hover:bg-blue-600 text-white"
            end}
          >
            <%= if @sending_message, do: "Sending...", else: "Send" %>
          </button>
        </form>
      </div>
    </div>
    """
  end

  defp status_badge_class(status) do
    case status do
      "active" -> "bg-green-100 text-green-800"
      "paused" -> "bg-yellow-100 text-yellow-800"
      "stopped" -> "bg-red-100 text-red-800"
      "setup" -> "bg-gray-100 text-gray-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end
