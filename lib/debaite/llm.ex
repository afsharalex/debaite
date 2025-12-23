defmodule Debaite.LLM do
  @moduledoc """
  Wrapper module for LLM interactions using req_llm.
  """

  require Logger

  # Hardcoded formatting instructions that are always appended to agent system prompts
  # These are not user-editable and ensure consistent chat-style responses
  @formatting_instructions """

  FORMATTING REQUIREMENTS (DO NOT IGNORE):
  You are participating in a real-time chat debate. Your messages MUST follow these rules:
  - Keep responses conversational and concise (2-4 short paragraphs maximum)
  - Avoid heavy markdown formatting (no headers like ##, minimal bullet points)
  - Write naturally as if speaking in a live discussion, not writing an essay
  - Engage directly with other participants' points
  - Sound like you're chatting, not writing a formal document
  - NEVER prefix your messages with your own name (e.g., "[Name]:" or "Name:") - the UI already shows who is speaking
  - Do not use formal salutations or sign-offs
  """

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
  The formatting instructions are automatically appended to ensure consistent chat-style responses.
  """
  def generate_agent_response(agent, message_history) do
    # Combine the agent's custom system prompt with hardcoded formatting instructions
    full_system_prompt = agent.system_prompt <> @formatting_instructions

    # Build messages array with system prompt and history
    messages = [
      %{role: "system", content: full_system_prompt}
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
        [%{role: "user", content: "Please provide your response to continue the debate."}]

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
