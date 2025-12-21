# Getting Started with Debaite

Phase 1 implementation is complete! Here's how to get started with your AI debate platform.

## What's Been Implemented

### Core Features
- **Database Schema**: Chatrooms, agents, and messages tables with proper relationships
- **LLM Integration**: Wrapper around req_llm supporting multiple providers (Anthropic, OpenAI, etc.)
- **Agent Suggestion System**: LLM-powered agent generation based on debate topics
- **Chatroom Orchestration**: GenServer-based debate coordinator with round-robin turn management
- **Real-time UI**: Phoenix LiveView interfaces for setup and live debates
- **Pause/Resume/Stop Controls**: Full debate flow control

### Project Structure
```
lib/debaite/
├── chatrooms/
│   ├── chatroom.ex          # Chatroom schema
│   ├── agent.ex             # Agent schema
│   ├── message.ex           # Message schema
│   ├── chatroom_server.ex   # GenServer for debate orchestration
│   └── chatroom_supervisor.ex # DynamicSupervisor for chatrooms
├── chatrooms.ex             # Chatrooms context (API)
├── llm.ex                   # LLM integration wrapper
└── agent_suggester.ex       # LLM-powered agent suggestions

lib/debaite_web/live/
├── chatroom_setup_live.ex   # UI for creating chatrooms
└── chatroom_live.ex         # UI for watching/participating in debates
```

## Setup Instructions

### 1. Install Dependencies
```bash
mix deps.get
```

### 2. Configure Environment Variables

Copy the example environment file:
```bash
cp .env.example .env
```

Edit `.env` and add your API keys:
```bash
# At minimum, add one of these:
ANTHROPIC_API_KEY=your_key_here
# or
OPENAI_API_KEY=your_key_here
```

Load the environment variables:
```bash
source .env
# or use a tool like direnv
```

### 3. Setup Database

The database and migrations have already been created. If you need to reset:
```bash
mix ecto.reset
```

### 4. Install Assets
```bash
cd assets && npm install && cd ..
```

### 5. Start the Server
```bash
mix phx.server
```

Visit http://localhost:4000

## How to Use

### Creating a Debate Chatroom

1. **Enter a Topic**: On the home page, enter a debate topic (e.g., "Should AI be regulated?")

2. **Review Suggested Agents**: The system will use an LLM to suggest 2-5 agents with different perspectives

3. **Customize Agents**:
   - Edit agent names, system prompts, providers, and models
   - Delete agents you don't want
   - Add new agents with custom configurations

4. **Create Chatroom**: Click "Create Chatroom & Start Debate"

### Participating in a Debate

Once created, you'll see:
- **Live Messages**: Agents debating in real-time (messages appear every 2 seconds)
- **Participant List**: All agents with their model configurations
- **User Input**: Type and send your own messages to join the debate
- **Controls**: Pause, Resume, or Stop the debate at any time

## Architecture Highlights

### Round-Robin Turn Management
Agents take turns in order based on their position. The ChatroomServer GenServer coordinates this flow.

### Real-time Updates
Phoenix PubSub broadcasts new messages to all connected clients instantly.

### Process Supervision
Each active chatroom runs in its own supervised GenServer process, managed by a DynamicSupervisor.

### LLM Context
All agents receive the complete message history, allowing them to respond contextually to the entire debate.

## Configuration

### Default Suggester Model
Configure in runtime.exs or via environment variables:
```bash
SUGGESTER_PROVIDER=anthropic
SUGGESTER_MODEL=claude-3-5-sonnet-20241022
```

### Agent Response Interval
Currently set to 2 seconds between agent turns. To change, edit `@tick_interval` in `chatroom_server.ex:13`.

## Next Steps (Future Enhancements)

Based on the plan, these features are designed for but not yet implemented:

1. **Streaming Responses**: Add support for token-by-token streaming from LLMs
2. **Natural Turn Flow**: Replace round-robin with more dynamic turn logic
3. **Context Window Management**: Handle long debates by summarizing history
4. **Multiple Chatrooms**: UI for browsing and managing multiple debates
5. **Persistence**: Save and load historical debates

## Troubleshooting

### Database Connection Errors
Make sure PostgreSQL is running:
```bash
# macOS with Homebrew
brew services start postgresql
```

### Missing API Keys
Ensure environment variables are loaded:
```bash
echo $ANTHROPIC_API_KEY
```

### Compilation Errors
Clean and recompile:
```bash
mix clean
mix compile
```

## Development Tips

### Interactive Console
```bash
iex -S mix phx.server
```

### Testing Agent Suggestions Manually
```elixir
iex> Debaite.AgentSuggester.suggest_agents("Should we colonize Mars?")
```

### Inspecting Running Chatrooms
```elixir
iex> Registry.lookup(Debaite.ChatroomRegistry, chatroom_id)
```

## Support

Refer to:
- [README.md](README.md) for project overview
- [CLAUDE.md](CLAUDE.md) for AI assistant development guide
- [Phoenix Framework Docs](https://hexdocs.pm/phoenix)
- [req_llm Documentation](https://hexdocs.pm/req_llm)
