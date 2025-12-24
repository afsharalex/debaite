defmodule Debaite.ApiKeyChecker do
  @moduledoc """
  Checks which LLM provider API keys are configured and available.
  """

  @doc """
  Returns a list of provider names (strings) that have API keys configured.

  ## Examples

      iex> Debaite.ApiKeyChecker.available_providers()
      ["anthropic", "openai"]

      iex> Debaite.ApiKeyChecker.available_providers()
      ["anthropic"]  # Only Anthropic key is set
  """
  def available_providers do
    []
    |> maybe_add_provider("anthropic", "ANTHROPIC_API_KEY")
    |> maybe_add_provider("openai", "OPENAI_API_KEY")
  end

  @doc """
  Returns a list of provider options suitable for select dropdowns.
  Each option is a map with :value and :label.

  ## Examples

      iex> Debaite.ApiKeyChecker.provider_options()
      [
        %{value: "anthropic", label: "Anthropic (Claude)"},
        %{value: "openai", label: "OpenAI (GPT)"}
      ]
  """
  def provider_options do
    available_providers()
    |> Enum.map(&provider_to_option/1)
  end

  @doc """
  Checks if a specific provider has an API key configured.

  ## Examples

      iex> Debaite.ApiKeyChecker.has_api_key?("anthropic")
      true

      iex> Debaite.ApiKeyChecker.has_api_key?("openai")
      false
  """
  def has_api_key?(provider) when is_binary(provider) do
    provider in available_providers()
  end

  # Private Functions

  defp maybe_add_provider(providers, provider_name, env_var) do
    if has_env_key?(env_var) do
      [provider_name | providers]
    else
      providers
    end
  end

  defp has_env_key?(env_var) do
    case System.get_env(env_var) do
      nil -> false
      "" -> false
      _key -> true
    end
  end

  defp provider_to_option("anthropic"), do: %{value: "anthropic", label: "Anthropic (Claude)"}
  defp provider_to_option("openai"), do: %{value: "openai", label: "OpenAI (GPT)"}
  defp provider_to_option(other), do: %{value: other, label: String.capitalize(other)}
end
