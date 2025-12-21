defmodule DebaiteWeb.ChatroomSetupLive do
  use DebaiteWeb, :live_view

  alias Debaite.{Chatrooms, AgentSuggester}
  alias Debaite.Chatrooms.ChatroomSupervisor

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:topic, "")
     |> assign(:suggested_agents, [])
     |> assign(:loading, false)
     |> assign(:error, nil)
     |> assign(:step, :topic_input)}
  end

  @impl true
  def handle_event("suggest_agents", %{"topic" => topic}, socket) do
    send(self(), {:generate_suggestions, topic})

    {:noreply,
     socket
     |> assign(:topic, topic)
     |> assign(:loading, true)
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("update_agent", %{"index" => index_str} = params, socket) do
    index = String.to_integer(index_str)
    agents = socket.assigns.suggested_agents

    updated_agent =
      Enum.at(agents, index)
      |> Map.put(:name, params["name"])
      |> Map.put(:system_prompt, params["system_prompt"])
      |> Map.put(:provider, params["provider"])
      |> Map.put(:model, params["model"])

    updated_agents = List.replace_at(agents, index, updated_agent)

    {:noreply, assign(socket, :suggested_agents, updated_agents)}
  end

  @impl true
  def handle_event("delete_agent", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    agents = socket.assigns.suggested_agents

    updated_agents =
      agents
      |> List.delete_at(index)
      |> Enum.with_index()
      |> Enum.map(fn {agent, new_index} -> %{agent | position: new_index} end)

    {:noreply, assign(socket, :suggested_agents, updated_agents)}
  end

  @impl true
  def handle_event("add_agent", _params, socket) do
    agents = socket.assigns.suggested_agents

    new_agent = %{
      name: "New Agent",
      perspective: "Custom perspective",
      system_prompt: "You are a debate participant...",
      provider: "anthropic",
      model: "claude-sonnet-4-5-20250929",
      position: length(agents)
    }

    {:noreply, assign(socket, :suggested_agents, agents ++ [new_agent])}
  end

  @impl true
  def handle_event("create_chatroom", _params, socket) do
    topic = socket.assigns.topic
    agents = socket.assigns.suggested_agents

    case Chatrooms.create_chatroom(%{topic: topic, status: "setup"}) do
      {:ok, chatroom} ->
        # Create agents
        Enum.each(agents, fn agent ->
          Chatrooms.create_agent(%{
            name: agent.name,
            system_prompt: agent.system_prompt,
            provider: agent.provider,
            model: agent.model,
            position: agent.position,
            chatroom_id: chatroom.id
          })
        end)

        # Update status to active BEFORE starting the server
        # so the server initializes with the correct status
        {:ok, chatroom} = Chatrooms.update_status(chatroom, "active")

        # Start the chatroom server
        {:ok, _pid} = ChatroomSupervisor.start_chatroom(chatroom.id)

        # Redirect to chatroom
        {:noreply, push_navigate(socket, to: ~p"/chatrooms/#{chatroom.id}")}

      {:error, _changeset} ->
        {:noreply, assign(socket, :error, "Failed to create chatroom")}
    end
  end

  @impl true
  def handle_info({:generate_suggestions, topic}, socket) do
    case AgentSuggester.suggest_agents(topic) do
      {:ok, agents} ->
        {:noreply,
         socket
         |> assign(:suggested_agents, agents)
         |> assign(:loading, false)
         |> assign(:step, :agent_editing)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:error, "Failed to generate suggestions: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4 py-8">
      <h1 class="text-4xl font-bold mb-8 text-center">Create a Debate Chatroom</h1>

      <%= if @error do %>
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {@error}
        </div>
      <% end %>

      <%= if @step == :topic_input do %>
        <div class="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
          <form phx-submit="suggest_agents">
            <div class="mb-4">
              <label class="block text-gray-700 text-sm font-bold mb-2" for="topic">
                Debate Topic
              </label>
              <textarea
                id="topic"
                name="topic"
                rows="3"
                class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                placeholder="Enter a topic for debate (e.g., 'Should artificial intelligence be regulated?')"
                required
              ><%= @topic %></textarea>
            </div>
            <div class="flex items-center justify-between">
              <button
                type="submit"
                class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
                disabled={@loading}
              >
                {if @loading, do: "Generating...", else: "Generate Agent Suggestions"}
              </button>
            </div>
          </form>
        </div>
      <% end %>

      <%= if @step == :agent_editing do %>
        <div class="mb-6">
          <h2 class="text-2xl font-bold mb-4">Suggested Agents</h2>
          <p class="text-gray-600 mb-4">
            Review and customize the suggested agents. You can edit, delete, or add new agents.
          </p>

          <%= for {agent, index} <- Enum.with_index(@suggested_agents) do %>
            <div class="bg-white shadow-md rounded px-6 py-4 mb-4">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-gray-700 text-sm font-bold mb-2">Name</label>
                  <input
                    type="text"
                    value={agent.name}
                    phx-blur="update_agent"
                    phx-value-index={index}
                    name="name"
                    class="shadow border rounded w-full py-2 px-3 text-gray-700"
                  />
                </div>
                <div>
                  <label class="block text-gray-700 text-sm font-bold mb-2">Perspective</label>
                  <p class="text-gray-600 text-sm">{agent[:perspective] || "No perspective"}</p>
                </div>
                <div class="md:col-span-2">
                  <label class="block text-gray-700 text-sm font-bold mb-2">System Prompt</label>
                  <textarea
                    rows="4"
                    phx-blur="update_agent"
                    phx-value-index={index}
                    name="system_prompt"
                    class="shadow border rounded w-full py-2 px-3 text-gray-700"
                  ><%= agent.system_prompt %></textarea>
                </div>
                <div>
                  <label class="block text-gray-700 text-sm font-bold mb-2">Provider</label>
                  <select
                    phx-change="update_agent"
                    phx-value-index={index}
                    name="provider"
                    class="shadow border rounded w-full py-2 px-3 text-gray-700"
                  >
                    <option value="anthropic" selected={agent.provider == "anthropic"}>
                      Anthropic
                    </option>
                    <option value="openai" selected={agent.provider == "openai"}>OpenAI</option>
                  </select>
                </div>
                <div>
                  <label class="block text-gray-700 text-sm font-bold mb-2">Model</label>
                  <input
                    type="text"
                    value={agent.model}
                    phx-blur="update_agent"
                    phx-value-index={index}
                    name="model"
                    class="shadow border rounded w-full py-2 px-3 text-gray-700"
                  />
                </div>
              </div>
              <div class="mt-4">
                <button
                  phx-click="delete_agent"
                  phx-value-index={index}
                  class="bg-red-500 hover:bg-red-700 text-white font-bold py-1 px-3 rounded text-sm"
                >
                  Delete Agent
                </button>
              </div>
            </div>
          <% end %>

          <div class="flex gap-4 mt-6">
            <button
              phx-click="add_agent"
              class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded"
            >
              Add Agent
            </button>
            <button
              phx-click="create_chatroom"
              class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
            >
              Create Chatroom & Start Debate
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
