# Debaite - Project TODO

**Status**: 🟢 Phase 1 Complete | **Last Updated**: 2025-12-21

---

## 📊 Project Status

### Quick Stats
- **Phase**: 1 of 3+ completed
- **Files Created**: 20+
- **Core Features**: 10/10 implemented
- **Tests**: 0/20+ (needs implementation)
- **Documentation**: 4/4 complete

### Current State
✅ Core application architecture complete
✅ Database schema implemented
✅ LLM integration functional
✅ Real-time debate orchestration working
⚠️ Needs end-to-end testing with real API keys
⚠️ UI/UX polish needed
❌ No automated tests yet

---

## ✅ Completed Features

### Phase 1 - Core Implementation (Dec 21, 2025)

#### Database & Schema
- [x] Create chatrooms, agents, messages tables
- [x] Add proper indexes for performance
- [x] Implement Ecto schemas with changesets
- [x] Create Chatrooms context module
- [x] Add associations (chatroom has_many agents/messages)

#### LLM Integration
- [x] Create LLM wrapper module around req_llm
- [x] Support for multiple providers (Anthropic, OpenAI)
- [x] Generate text with system prompts
- [x] Generate agent responses with message history
- [x] Default model registry

#### Agent Suggestion System
- [x] LLM-powered agent suggestion based on topic
- [x] JSON parsing and validation
- [x] Structured output (name, perspective, system prompt, provider, model)
- [x] Configurable suggester model

#### Chatroom Orchestration
- [x] ChatroomServer GenServer for debate coordination
- [x] Round-robin turn management
- [x] Pause/Resume/Stop functionality
- [x] Timer-based agent responses (2s interval)
- [x] DynamicSupervisor for multiple chatrooms
- [x] Registry for process lookup

#### User Interface
- [x] ChatroomSetupLive - topic input & agent editing
- [x] ChatroomLive - real-time debate viewing
- [x] User message input and participation
- [x] Status controls (pause/resume/stop)
- [x] Auto-scrolling messages
- [x] Participant list display

#### Infrastructure
- [x] PubSub integration for real-time updates
- [x] Routes configuration
- [x] Application supervision tree
- [x] Runtime configuration for API keys
- [x] JavaScript hooks for auto-scroll

#### Documentation
- [x] README.md with project overview
- [x] CLAUDE.md with AI development guide
- [x] GETTING_STARTED.md with setup instructions
- [x] .env.example for API keys
- [x] TODO.md (this file)

---

## 🚧 Current Work

### Immediate Testing Needed
- [ ] Test agent suggestion with real API key
- [ ] Test chatroom creation flow end-to-end
- [ ] Test agent debate with actual LLM responses
- [ ] Test pause/resume/stop functionality
- [ ] Test user message participation
- [ ] Verify PubSub broadcasts work correctly

### Known Issues to Investigate
- [ ] Verify agent response message history formatting
- [ ] Check for race conditions in ChatroomServer
- [ ] Test behavior with 0 or 1 agent (edge cases)
- [ ] Validate JSON parsing handles malformed LLM responses
- [ ] Test database cleanup when chatroom is stopped

---

## 📋 Next Phase (Phase 2)

### High Priority

#### Error Handling & Resilience
- [ ] Add comprehensive error handling in LLM module
- [ ] Handle API rate limits and timeouts gracefully
- [ ] Retry logic for failed LLM calls
- [ ] User-friendly error messages in UI
- [ ] Fallback behavior when agent fails to respond

#### UI/UX Improvements
- [ ] Add loading states for agent suggestions
- [ ] Show typing indicators when agent is responding
- [ ] Improve message styling and readability
- [ ] Add timestamps to all messages
- [ ] Mobile-responsive design
- [ ] Add animations and transitions
- [ ] Better empty states

#### Testing
- [ ] Unit tests for Chatrooms context
- [ ] Unit tests for LLM module
- [ ] Unit tests for AgentSuggester
- [ ] Integration tests for ChatroomServer
- [ ] LiveView tests for ChatroomSetupLive
- [ ] LiveView tests for ChatroomLive
- [ ] End-to-end test suite

### Medium Priority

#### Feature Enhancements
- [ ] Multiple chatroom listing page (browse active debates)
- [ ] Save/load historical debates
- [ ] Export debates to markdown/PDF
- [ ] Search through debate history
- [ ] Agent performance metrics
- [ ] Debate analytics (message counts, response times)

#### Agent Management
- [ ] Agent templates library (pre-made personas)
- [ ] Save custom agents for reuse
- [ ] Clone agents from other debates
- [ ] Agent personality presets

#### Turn Logic Improvements
- [ ] Implement natural turn flow (vs round-robin)
- [ ] Agent can choose to pass/skip turn
- [ ] Dynamic turn selection based on relevance
- [ ] User can request specific agent response
- [ ] Configurable turn timing

---

## 🔮 Future Enhancements (Phase 3+)

### Advanced Features
- [ ] **Streaming LLM responses** - Token-by-token display
- [ ] **Context window management** - Summarize long debates
- [ ] **Multi-debate support** - Run multiple debates simultaneously
- [ ] **Agent memory** - Persistent agent knowledge across debates
- [ ] **Voting system** - Users vote on best arguments
- [ ] **Moderation tools** - Filter inappropriate content

### Integration Features
- [ ] Share debates publicly via link
- [ ] Embed debates in other websites
- [ ] API for programmatic access
- [ ] Webhooks for debate events
- [ ] Third-party LLM provider support (Google, Cohere, etc.)

### Advanced UI
- [ ] Debate visualization (argument tree)
- [ ] Real-time collaboration (multiple users)
- [ ] Dark mode
- [ ] Accessibility improvements (ARIA labels, keyboard nav)
- [ ] Internationalization (i18n)

### Performance
- [ ] Message pagination for long debates
- [ ] Caching layer for agent suggestions
- [ ] Database query optimization
- [ ] CDN for static assets

### DevOps
- [ ] Docker deployment setup
- [ ] CI/CD pipeline
- [ ] Monitoring and observability
- [ ] Rate limiting
- [ ] Production deployment guide

---

## 🐛 Known Issues & Bugs

### To Investigate
- **Agent name lookup in messages**: Currently queries DB for each message, could be optimized
- **Turn timing**: Fixed 2-second interval may be too fast/slow for some models
- **Error recovery**: If agent fails, next agent doesn't automatically continue
- **Memory**: Long-running debates may accumulate large message history

### Edge Cases to Handle
- [ ] What happens if all agents have errors?
- [ ] What happens if user stops debate with 0 messages?
- [ ] Handle empty agent suggestions from LLM
- [ ] Handle malformed JSON from suggestion API
- [ ] What if chatroom process crashes during debate?
- [ ] Handle concurrent user messages properly

### UI Issues
- [ ] Long agent names may overflow in participant list
- [ ] Very long messages need better formatting
- [ ] Status badge colors may not be accessible
- [ ] Form validation feedback could be clearer

---

## 🔧 Technical Debt

### Code Quality
- [ ] Add typespecs to all public functions
- [ ] Add @doc attributes to undocumented functions
- [ ] Extract magic numbers to module attributes/config
- [ ] Consistent error tuple returns across modules
- [ ] Add logging throughout the application

### Architecture
- [ ] Consider extracting LLM providers into behaviour
- [ ] Decouple ChatroomServer from specific turn logic
- [ ] Create dedicated module for message formatting
- [ ] Consider using Phoenix.Tracker for chatroom presence

### Documentation
- [ ] Add inline code examples to module docs
- [ ] Create architecture diagram
- [ ] Document database schema visually
- [ ] Add troubleshooting guide
- [ ] API documentation for contexts

---

## 📝 Development Notes

### Testing Locally
```bash
# Set up environment
cp .env.example .env
# Edit .env with your API keys
source .env

# Start server
mix phx.server

# Visit http://localhost:4000
```

### Running Tests (once written)
```bash
mix test
mix test --failed  # Re-run only failed tests
mix test test/debaite/chatrooms_test.exs  # Run specific file
```

### Debugging
```bash
# Interactive console
iex -S mix phx.server

# Test agent suggestions
iex> Debaite.AgentSuggester.suggest_agents("Should we colonize Mars?")

# Check running chatrooms
iex> Registry.lookup(Debaite.ChatroomRegistry, chatroom_id)
```

### Database Commands
```bash
mix ecto.create     # Create database
mix ecto.migrate    # Run migrations
mix ecto.rollback   # Rollback last migration
mix ecto.reset      # Drop, create, migrate
```

### Code Quality
```bash
mix format          # Format code
mix compile --warnings-as-errors  # Strict compilation
```

---

## 🎯 Milestones

### Milestone 1: Core MVP ✅
**Target**: Dec 21, 2025 | **Status**: Complete
Basic debate functionality with LLM integration

### Milestone 2: Production Ready
**Target**: TBD | **Status**: Not Started
- All tests passing
- Error handling complete
- UI polished
- Documentation complete
- Deployed to production

### Milestone 3: Advanced Features
**Target**: TBD | **Status**: Not Started
- Streaming responses
- Natural turn flow
- Multi-debate support
- Historical debates

---

## 📞 Questions & Decisions Needed

### Open Questions
- [ ] What should happen when an agent consistently fails?
- [ ] Should debates auto-stop after N messages or time limit?
- [ ] How to handle context window limits for long debates?
- [ ] Should we cache agent suggestions for popular topics?
- [ ] What's the best way to handle concurrent user messages?

### Configuration Decisions
- [ ] Default agent response interval (currently 2s)
- [ ] Maximum message history length
- [ ] Timeout for LLM API calls
- [ ] Maximum agents per chatroom
- [ ] Rate limiting strategy

---

## 🤝 Contributing

When working on this project:
1. Update this TODO.md as you complete tasks
2. Move items from "Next Phase" to "Current Work" when starting
3. Add new issues to "Known Issues" as discovered
4. Keep "Project Status" section updated
5. Document any architectural decisions

---

## 📚 References

- [README.md](README.md) - Project overview
- [GETTING_STARTED.md](GETTING_STARTED.md) - Setup instructions
- [req_llm docs](https://hexdocs.pm/req_llm) - LLM integration library
- [Phoenix docs](https://hexdocs.pm/phoenix) - Web framework
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view) - Real-time UI

---

**Note**: This is a living document. Update it frequently to track progress and maintain clarity on project state.
