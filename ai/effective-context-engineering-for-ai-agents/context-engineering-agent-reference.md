# Context Engineering for AI Agents — Operational Knowledge Base

> This document is a self-contained reference. No additional reading is required.
> Reference: [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

---

## 1. Core Definitions

**Context**: The complete set of tokens present during a single LLM inference call. This includes system prompts, tool definitions, few-shot examples, message history, retrieved documents, MCP data, and any other information the model can see.

**Context Engineering**: The discipline of curating and managing which information enters the model's context window at each step of an agent's operation. It is the successor to prompt engineering — broader in scope because it addresses everything in the context, not just how prompts are worded.

**Attention Budget**: LLMs have a finite capacity to attend to information. Every token added to the context consumes part of this budget. Adding more tokens does not linearly add more value — it can actively degrade performance.

**Context Rot**: A well-documented phenomenon where model accuracy for information retrieval and reasoning decreases as context length increases. This is architectural — the transformer's n² pairwise attention mechanism stretches thin over longer sequences. It is not a bug to be fixed; it is a fundamental constraint to be managed.

---

## 2. The Guiding Principle

**Find the smallest possible set of high-signal tokens that maximizes the likelihood of the desired outcome.**

This is not about being brief for brevity's sake. "Minimal" means every token earns its place. A 5,000-token system prompt can be minimal if every line drives correct behavior. A 500-token prompt can be bloated if half of it is redundant.

---

## 3. Context Components and How to Optimize Each

### 3.1 System Prompts

**The "Right Altitude" Rule**: System prompts fail in two ways:

| Failure Mode | What It Looks Like | Why It Fails |
|---|---|---|
| Too rigid (low altitude) | Hardcoded if-else chains, exhaustive rule lists for every edge case | Brittle, high maintenance cost, breaks on novel inputs |
| Too vague (high altitude) | "Be helpful and accurate", generic goals without concrete signals | Model lacks actionable guidance, assumes wrong defaults |

**The sweet spot**: Specific enough to constrain behavior on critical paths, flexible enough to let the model generalize on novel situations. Use heuristics, not hardcoded logic.

**Structural best practices**:
- Organize into labeled sections (XML tags like `<instructions>`, `<tool_guidance>` or Markdown headers)
- Start with a minimal prompt on the best available model
- Add instructions only to address observed failure modes, not hypothetical ones

### 3.2 Tools

Tools define the contract between the agent and its environment. They are how the agent acts and retrieves new information.

**Design principles**:
- Each tool should be self-contained with a single clear purpose (like a well-designed function)
- Tool descriptions must be unambiguous — if a human engineer can't tell which tool to use in a scenario, the agent can't either
- Return token-efficient responses: strip unnecessary metadata, verbose formatting, or redundant fields
- Minimize the total number of tools — bloated tool sets create decision ambiguity and waste context on unused tool definitions

**Common anti-pattern**: Overlapping tools where multiple tools could handle the same request. This forces the model to spend attention choosing between them instead of executing.

### 3.3 Examples (Few-Shot)

- Curate a small, diverse set of canonical examples that demonstrate expected behavior
- Do NOT enumerate every edge case as a rule — examples teach patterns more effectively than rules
- Each example should illustrate a different dimension of desired behavior

### 3.4 Message History

- Older turns accumulate noise (redundant tool results, superseded decisions, exploratory dead-ends)
- Without active management, message history becomes the dominant consumer of the attention budget
- Strategy: actively prune or summarize older turns (see Compaction in Section 5)

---

## 4. Context Retrieval — How Agents Get Information

There are three paradigms for bringing external information into context:

### 4.1 Pre-Computed Retrieval (Traditional RAG)

Embed documents at index time, retrieve top-k relevant chunks before inference.

- **Pro**: Fast, predictable latency
- **Con**: Stale indexes, can miss context that only becomes relevant mid-task, retrieval quality depends on embedding similarity which may not match task relevance

### 4.2 Just-in-Time Retrieval (Agentic Search)

The agent holds lightweight references (file paths, saved queries, URLs) and pulls data into context dynamically using tools during execution.

- **Pro**: Always fresh, agent can follow chains of relevance, metadata (file names, folder structure, timestamps) provides free navigational signals
- **Con**: Slower, requires well-designed exploration tools, risk of wasting context on dead-ends without proper guidance

**Example**: Claude Code writes targeted SQL queries, uses `head`/`tail` to inspect large files, and navigates codebases with `grep`/`glob` — never loading entire files into context.

**Progressive Disclosure**: Each retrieval step informs the next. File sizes hint at complexity, naming conventions suggest purpose, timestamps indicate freshness. The agent assembles understanding incrementally.

### 4.3 Hybrid (Recommended Default)

Pre-load essential context for speed (e.g., project configuration, key reference docs), then let the agent explore autonomously for task-specific details.

- **Example**: Claude Code drops `CLAUDE.md` into context upfront, then uses `grep`/`glob` to find specific files just-in-time
- Best advice: **"Do the simplest thing that works."** Start simple, add complexity only when needed.

---

## 5. Long-Horizon Task Strategies

When a task generates more tokens than the context window can hold (spanning tens of minutes to hours), use one or more of these techniques:

### 5.1 Compaction

**What**: Summarize the current conversation and restart the context window with the summary.

**How to implement**:
1. Pass the full message history to the model with a summarization prompt
2. Preserve: architectural decisions, unresolved issues, key implementation details, current objectives
3. Discard: redundant tool outputs, superseded messages, exploratory dead-ends
4. Reinitialize context with the summary + most recently accessed files (e.g., 5 files)

**Tuning approach**: Start by maximizing recall (capture everything), then iterate to improve precision (remove noise). Test on complex, real agent traces.

**Lightest-touch variant**: Tool result clearing — remove raw tool call results from older messages while keeping the agent's conclusions. This is the safest form of compaction because tool results are almost never re-read.

**Best for**: Tasks with extensive back-and-forth conversation flow.

### 5.2 Structured Note-Taking (Agentic Memory)

**What**: The agent writes persistent notes to external storage (a file, database, or memory tool) during execution, and reads them back after context resets.

**How it works**:
- Agent maintains a scratchpad file (e.g., `NOTES.md`, a to-do list, or a structured state file)
- Writes progress updates, decisions made, dependencies discovered, and next steps
- After compaction or context reset, the agent reads its own notes to restore working state

**Real-world example**: An AI agent playing Pokémon tracked objectives ("trained Pikachu 8 of 10 target levels on Route 1 over 1,234 steps"), maintained maps of explored regions, and recorded combat strategy notes — all without being prompted about memory structure. After context resets, it read its notes and continued multi-hour strategies seamlessly.

**Best for**: Iterative tasks with clear milestones and measurable progress.

### 5.3 Sub-Agent Architecture

**What**: Delegate focused sub-tasks to specialized child agents, each operating with a clean context window. The lead agent coordinates at a high level and synthesizes results.

**How it works**:
1. Lead agent creates a high-level plan
2. Sub-agents receive focused instructions and execute with full context budget available for their sub-task
3. Each sub-agent may consume tens of thousands of tokens exploring, but returns only a condensed summary (typically 1,000–2,000 tokens)
4. Lead agent synthesizes sub-agent outputs without being polluted by their detailed search context

**Key benefit**: Separation of concerns. Detailed exploration stays isolated in sub-agents. The lead agent's context stays clean for synthesis and decision-making.

**Best for**: Complex research, analysis, or any task where parallel exploration of multiple avenues adds value.

### 5.4 Selection Guide

| Task Characteristic | Recommended Technique |
|---|---|
| Long conversational flow with many turns | Compaction |
| Step-by-step development with clear checkpoints | Structured Note-Taking |
| Multi-faceted research or analysis | Sub-Agent Architecture |
| Very long tasks (hours) | Combine all three |

---

## 6. Decision Framework — Quick Reference

When building or configuring an agent, use this checklist:

1. **Is every token in the system prompt earning its place?** Remove anything that doesn't directly drive correct behavior.
2. **Can a human instantly tell which tool to use for any given task?** If not, consolidate or clarify tool boundaries.
3. **Are tool responses token-efficient?** Strip verbose metadata, redundant formatting, and unnecessary fields.
4. **Is old message history actively managed?** Implement at least tool result clearing for long conversations.
5. **Is retrieval pre-computed, just-in-time, or hybrid?** Default to hybrid. Pre-load essentials, explore the rest.
6. **For long tasks: which persistence strategy fits?** Compaction for flow, notes for milestones, sub-agents for parallel work.
7. **Are you over-engineering?** Start simple. Add complexity only to address observed failures.

---

## 7. Key Principles to Remember

- **Context is finite and has diminishing returns.** More tokens ≠ better performance.
- **Curate ruthlessly.** The best context is the smallest context that gets the job done.
- **Tools are part of context.** Bloated tool definitions waste attention budget even when unused.
- **Let capable models be capable.** As models improve, prescribe less and enable more autonomy.
- **Even larger context windows won't eliminate these concerns.** Context rot and attention degradation are architectural, not just a matter of capacity.
- **"Do the simplest thing that works"** is the best default strategy in a fast-moving field.
