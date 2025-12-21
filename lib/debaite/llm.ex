defmodule Debaite.LLM do
  @moduledoc """
  Wrapper module for LLM interactions using req_llm.
  """

  require Logger

  @doc """
  Generates text using the specified model and prompt.

  ## Parameters
    - provider: The LLM provider (e.g., "anthropic", "openai")
    - model: The model name (e.g., "claude-4-5-sonnet-20241022", "gpt-4")
    - messages: List of message maps with role and content
    - opts: Additional options (optional)

  ## Returns
    - {:ok, response_text} on success
    - {:error, reason} on failure
  """
  def generate_text(provider, model, messages, opts \\ []) do
    model_spec = "#{provider}:#{model}"

    try do
      case ReqLLM.generate_text(model_spec, messages, opts) do
        {:ok, response} ->
          # Extract the text content from the response message
          # response.message.content is a list of ContentPart structs
          text =
            response.message.content
            |> Enum.map(fn part -> part.text end)
            |> Enum.join("")
          {:ok, text}

        {:error, reason} = error ->
          Logger.error("LLM generation failed: #{inspect(reason)}")
          error
      end
    rescue
      e ->
        Logger.error("LLM generation exception: #{inspect(e)}")
        {:error, Exception.message(e)}
    end
  end

  @doc """
  Generates text with a simple string prompt (converts to message format).
  """
  def generate_text_simple(provider, model, prompt, opts \\ []) do
    messages = [%{role: "user", content: prompt}]
    generate_text(provider, model, messages, opts)
  end

  @doc """
  Generates text with a system prompt and user prompt.
  """
  def generate_with_system(provider, model, system_prompt, user_prompt, opts \\ []) do
    messages = [
      %{role: "system", content: system_prompt},
      %{role: "user", content: user_prompt}
    ]

    generate_text(provider, model, messages, opts)
  end

  @doc """
  Generates text for an agent in a chatroom context.

  Takes the agent's system prompt and full message history.
  """
  def generate_agent_response(agent, message_history) do
    # Build messages array with system prompt and history
    messages = [
      %{role: "system", content: agent.system_prompt}
      | Enum.map(message_history, fn msg ->
          # Format each historical message
          role = if msg.sender_type == "user", do: "user", else: "assistant"

          content =
            if msg.sender_type == "agent" do
              # For agent messages, prefix with agent name for context
              agent_name = get_agent_name(msg.sender_id)
              "[#{agent_name}]: #{msg.content}"
            else
              msg.content
            end

          %{role: role, content: content}
        end)
    ]

    # Add a final user message to prompt the agent to respond
    messages =
      messages ++
        [%{role: "user", content: "Please provide your response to continue the debate. IMPORTANT: Do not prefix your message with your name or [Your Name]: - the UI already shows who you are. Just write your message content directly."}]

    generate_text(agent.provider, agent.model, messages)
  end

  # Helper to get agent name from ID (could be cached or passed in)
  defp get_agent_name(agent_id) do
    case Debaite.Chatrooms.get_agent!(agent_id) do
      nil -> "Unknown Agent"
      agent -> agent.name
    end
  rescue
    _ -> "Agent #{agent_id}"
  end

  @doc """
  Returns a list of commonly used models for suggestions.
  """
  def default_models do
    [
      %{
        provider: "anthropic",
        model: "claude-sonnet-4-5-20250929",
        display_name: "Claude 4.5 Sonnet"
      },
      %{
        provider: "anthropic",
        model: "claude-haiku-4-5-20251001",
        display_name: "Claude 4.5 Haiku"
      },
      %{provider: "openai", model: "gpt-4o", display_name: "GPT-4o"},
      %{provider: "openai", model: "gpt-4o-mini", display_name: "GPT-4o Mini"},
      %{provider: "openai", model: "gpt-4-turbo", display_name: "GPT-4 Turbo"}
    ]
  end
end
