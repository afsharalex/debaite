# Debaite

An AI-powered debate platform where multiple AI agents argue different perspectives on any topic in real-time.

## Overview

Debaite allows users to create dynamic chatrooms where AI agents debate topics from different perspectives. Each chatroom features multiple AI agents, each with their own system prompts, viewpoints, and LLM configurations.

### Key Features

- Topic-based chatrooms for any debate subject
- LLM-powered agent suggestions with diverse perspectives
- Support for multiple LLM providers (Anthropic, OpenAI, and 40+ others)
- Fully customizable agent configurations
- Real-time debate viewing with Phoenix LiveView
- User participation during debates
- Pause, resume, and stop controls
- Shared message context across all agents

## Installation

### Prerequisites

- Elixir 1.15 or later
- PostgreSQL
- Node.js (for asset compilation)
- API key for at least one LLM provider (Anthropic or OpenAI recommended)

### Setup

1. Clone the repository and install dependencies:
```bash
git clone <repository-url>
cd debaite
mix deps.get
```

2. Configure your environment variables:
```bash
cp .env.example .env
```

Edit `.env` and add your API keys:
```bash
ANTHROPIC_API_KEY=your_anthropic_key_here
OPENAI_API_KEY=your_openai_key_here
```

3. Create and migrate the database:
```bash
mix ecto.setup
```

4. Install JavaScript dependencies:
```bash
cd assets && npm install && cd ..
```

5. Start the development server:
```bash
source .env
mix phx.server
```

Visit `http://localhost:4000` in your browser.

## Usage

### Creating a Debate

1. Enter a debate topic on the home page (e.g., "Should governments regulate artificial intelligence?")

2. Review the automatically generated agent suggestions. The system uses an LLM to create agents with diverse perspectives, each with:
   - A descriptive name
   - A unique perspective on the topic
   - A detailed system prompt defining their character and debate style
   - A recommended LLM provider and model

3. Customize the agents as needed:
   - Edit names, system prompts, providers, or models
   - Remove agents you don't want
   - Add additional agents with the "Add Agent" button

4. Click "Create Chatroom & Start Debate" to begin

### During a Debate

Once the debate starts:

- Agents respond in round-robin order with a 2-second interval between messages
- All messages appear in real-time using Phoenix LiveView
- Use the message input box to participate in the debate
- Control the debate flow with the available buttons:
  - Pause: Temporarily stop agent responses
  - Resume: Continue from where you paused
  - Stop: End the debate permanently

### Agent Configuration

Each agent can be configured with:

- **Name**: Identifier for the agent
- **System Prompt**: Instructions defining the agent's personality, expertise, and debate approach
- **Provider**: LLM provider (e.g., "anthropic", "openai")
- **Model**: Specific model identifier (e.g., "claude-3-5-sonnet-20241022", "gpt-4o")

Supported providers include Anthropic, OpenAI, Google, Groq, xAI, and many others via the req_llm library.

## Architecture

The application uses a process-based architecture for managing debates:

- Each active chatroom runs in a supervised GenServer process
- A DynamicSupervisor manages multiple concurrent chatrooms
- Phoenix PubSub broadcasts messages to all connected clients
- Messages and chatroom state persist in PostgreSQL

### Key Components

- `Debaite.Chatrooms.ChatroomServer` - Orchestrates debate flow and agent turns
- `Debaite.LLM` - Wrapper around req_llm for LLM API calls
- `Debaite.AgentSuggester` - Generates agent suggestions using LLMs
- `DebaiteWeb.ChatroomSetupLive` - LiveView for chatroom creation
- `DebaiteWeb.ChatroomLive` - LiveView for debate viewing and participation

## Configuration

### Environment Variables

Required:
- `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` - At least one LLM provider key

Optional:
- `SUGGESTER_PROVIDER` - LLM provider for agent suggestions (default: "anthropic")
- `SUGGESTER_MODEL` - Model for agent suggestions (default: "claude-3-5-sonnet-20241022")
- `DATABASE_URL` - PostgreSQL connection string (configured in dev.exs for development)
- `SECRET_KEY_BASE` - Phoenix secret key base (auto-generated for development)

### Database

The application uses PostgreSQL with the following schema:

- `chatrooms` - Stores debate topics and status
- `agents` - Stores agent configurations and associations
- `messages` - Stores all debate messages with sender information

## Development

### Running Tests

```bash
mix test
```

### Interactive Console

```bash
iex -S mix phx.server
```

### Code Quality

```bash
mix format
mix compile --warnings-as-errors
```

## Documentation

- [GETTING_STARTED.md](GETTING_STARTED.md) - Detailed setup and usage guide
- [TODO.md](TODO.md) - Current development status and roadmap

## Tech Stack

- Elixir 1.15+ - Functional programming language
- Phoenix 1.8 - Web framework
- Phoenix LiveView - Real-time UI updates
- PostgreSQL - Database
- req_llm - Multi-provider LLM integration
- Tailwind CSS - Styling

## License

Copyright (c) 2025
