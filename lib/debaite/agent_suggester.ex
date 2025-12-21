defmodule Debaite.AgentSuggester do
  @moduledoc """
  Generates agent suggestions for debate topics using LLMs.
  """

  alias Debaite.LLM
  require Logger

  @system_prompt """
  You are an AI assistant that helps create interesting debates by suggesting AI agents with different perspectives.

  Given a debate topic, suggest 2-5 AI agents (you decide the optimal number based on the topic) that would provide diverse, interesting perspectives on the issue. Each agent should have:
  1. A name that reflects their perspective
  2. A clear perspective/stance on the topic
  3. A detailed system prompt that defines their character, expertise, and debate style
  4. A recommended LLM provider and model

  Return your response as valid JSON with the following structure:
  {
    "agents": [
      {
        "name": "Agent Name",
        "perspective": "Brief description of their stance",
        "system_prompt": "Detailed system prompt for the agent...",
        "provider": "anthropic|openai",
        "model": "model-name"
      }
    ]
  }

  Guidelines:
  - Ensure perspectives are genuinely different and interesting
  - Make system prompts detailed and personality-rich
  - Consider expertise, debate style, and argumentative approach
  - Recommend appropriate models (use claude-sonnet-4-5-20250929 for complex reasoning, gpt-4o for balanced performance, claude-haiku-4-5-20251001 for faster responses)
  - Ensure the debate will be substantive and educational

  IMPORTANT: Each agent's system prompt MUST include instructions that they are participating in a REAL-TIME CHAT DEBATE, not writing essays. Agents should:
  - Keep responses conversational and concise (2-4 short paragraphs maximum)
  - Avoid heavy markdown formatting (no headers like ##, minimal bullet points)
  - Write naturally as if speaking in a live discussion
  - Engage directly with other participants' points
  - Sound like they're chatting, not writing a formal document
  - NEVER prefix their messages with their own name (e.g., "[Name]:" or "Name:") - the UI already shows who is speaking

  Example phrase to include in system prompts: "You are participating in a real-time chat debate. Keep your messages conversational, concise, and chat-appropriate - imagine you're speaking in a live discussion, not writing an essay. Do not prefix your messages with your name - just write your message content directly."
  """

  @doc """
  Suggests agents for a given debate topic.

  Returns {:ok, agents} or {:error, reason}
  """
  def suggest_agents(topic) do
    config = Application.get_env(:debaite, :default_suggester_model)
    provider = config[:provider]
    model = config[:model]

    user_prompt = """
    Debate topic: #{topic}

    Please suggest AI agents for this debate. Remember to return valid JSON only.
    """

    case LLM.generate_with_system(provider, model, @system_prompt, user_prompt) do
      {:ok, response} ->
        parse_agent_suggestions(response)

      {:error, reason} = error ->
        Logger.error("Failed to generate agent suggestions: #{inspect(reason)}")
        error
    end
  end

  defp parse_agent_suggestions(json_string) do
    # Strip markdown code fences if present
    cleaned_json =
      json_string
      |> String.trim()
      |> String.replace(~r/^```json\n/, "")
      |> String.replace(~r/\n```$/, "")
      |> String.trim()

    case Jason.decode(cleaned_json) do
      {:ok, %{"agents" => agents}} when is_list(agents) ->
        parsed_agents =
          agents
          |> Enum.with_index()
          |> Enum.map(fn {agent, index} ->
            %{
              name: agent["name"],
              perspective: agent["perspective"],
              system_prompt: agent["system_prompt"],
              provider: agent["provider"],
              model: agent["model"],
              position: index
            }
          end)

        {:ok, parsed_agents}

      {:ok, _other} ->
        {:error, "Invalid response format from LLM"}

      {:error, reason} ->
        Logger.error("Failed to parse agent suggestions JSON: #{inspect(reason)}")
        {:error, "Failed to parse LLM response: #{inspect(reason)}"}
    end
  end

  @doc """
  Validates an agent suggestion has all required fields.
  """
  def validate_agent(agent) do
    required_fields = [:name, :system_prompt, :provider, :model, :position]

    missing_fields =
      Enum.filter(required_fields, fn field ->
        is_nil(Map.get(agent, field)) or Map.get(agent, field) == ""
      end)

    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, "Missing required fields: #{inspect(missing_fields)}"}
    end
  end
end
