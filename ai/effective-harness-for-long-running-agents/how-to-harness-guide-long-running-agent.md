# Long-Running AI Agent Harness: Implementation Guide

> Source: [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

## What This Document Is

This is a self-contained implementation guide for building a harness that enables an AI coding agent to work effectively across many sessions on a single project. Follow this guide directly — no external references are required.

---

## Core Constraint You're Solving

An AI agent operates within a fixed-size context window. When that window fills up, the session ends and a new one begins with **no memory** of prior sessions. Without a structured approach, this causes:

- The agent attempts to build everything in one session, runs out of context mid-task, and leaves broken, undocumented code.
- The agent sees partially completed work from a prior session, misinterprets the project as finished, and stops working.
- The agent spends most of its context budget just figuring out what happened before.

The solution is to give the agent **external memory** through files and git history, and to enforce a **disciplined per-session workflow**.

---

## Architecture: Two Prompt Modes, One Agent

You use the same underlying model and tools for both modes. The only difference is the prompt.

### Mode 1: Initializer Prompt (first session only)

**Goal**: Create every file and structure that future sessions will depend on. Do NOT write application code yet.

The initializer must produce the following artifacts:

#### 1. Feature List (`feature_list.json`)

Decompose the user's high-level goal into granular, testable features. Use JSON, not Markdown — the model is less likely to accidentally restructure or delete entries in JSON.

Each feature entry should contain:

```json
{
  "id": 1,
  "category": "functional",
  "description": "User can open a new chat and receive an AI response",
  "verification_steps": [
    "Navigate to the main page",
    "Click 'New Chat'",
    "Type a message and press Enter",
    "Verify an AI response appears"
  ],
  "passes": false
}
```

Rules for this file:
- Every feature starts as `"passes": false`.
- Future agents may ONLY change the `passes` field. They must never delete, reword, or reorder entries.
- Include this instruction explicitly in the coding agent prompt: "It is unacceptable to remove or edit feature definitions. You may only change the passes field from false to true."

#### 2. Startup Script (`init.sh`)

A shell script that:
- Installs dependencies if needed
- Starts the development server
- Runs a basic smoke test (e.g., curl the health endpoint, or launch a browser and verify the main page loads)

This eliminates the time future agents would spend figuring out how to run the project.

#### 3. Progress Log (`claude-progress.txt`)

An empty or minimally seeded text file. Each future session will append a summary here. Format:

```
## Session 3 — 2025-11-26
- Implemented feature #12: User can delete a conversation
- Fixed bug: sidebar not updating after deletion
- All existing features still pass smoke test
- Next priority: feature #13 (conversation search)
```

#### 4. Git Repository

Initialize a git repo and make an initial commit containing all scaffolding files. This gives future agents a clean starting point and a full history of changes.

```bash
git init
git add .
git commit -m "Initialize project scaffolding: feature list, init script, progress log"
```

---

### Mode 2: Coding Prompt (every session after the first)

**Goal**: Make incremental progress on exactly one feature, leave the codebase clean, and document what happened.

Every coding session must follow this exact sequence:

#### Step 1: Orient

```
1. Run `pwd` to confirm your working directory.
2. Read `claude-progress.txt` to learn what previous sessions accomplished.
3. Run `git log --oneline -20` to see recent commits.
4. Read `feature_list.json` to see overall progress.
```

#### Step 2: Verify Existing Functionality

```
1. Run `init.sh` to start the development server.
2. Perform a basic end-to-end test of core functionality.
   - For a web app: open the browser, perform a core user flow, verify it works.
   - For a backend API: hit the main endpoints and verify responses.
3. If anything is broken, FIX IT FIRST before starting new work.
```

**Why this matters**: If the previous session left a bug, building a new feature on top of broken code compounds the problem. Always stabilize before advancing.

#### Step 3: Select One Feature

```
1. Scan `feature_list.json` for the highest-priority feature where `passes` is `false`.
2. Work on ONLY this one feature. Do not start a second feature in the same session.
```

**Why only one**: Attempting multiple features risks running out of context mid-implementation, leaving behind half-finished code with no documentation — the exact problem this harness exists to prevent.

#### Step 4: Implement

Write the code for the selected feature. Standard development practices apply.

#### Step 5: Test End-to-End

```
1. Do NOT rely solely on unit tests or manual curl commands.
2. Test the feature the way a real user would:
   - For web apps: use browser automation (e.g., Puppeteer) to click through the UI.
   - For APIs: send realistic request sequences and verify full response chains.
3. Only mark the feature as `"passes": true` in `feature_list.json` AFTER it passes this test.
```

**Common failure mode**: The agent writes code, runs a unit test, sees it pass, and marks the feature as done — but the feature doesn't actually work end-to-end. Explicit prompting to test as a real user resolves this.

#### Step 6: Commit and Document

```
1. Stage and commit all changes with a descriptive message:
   git add .
   git commit -m "Implement feature #12: conversation deletion with sidebar sync"

2. Append a session summary to `claude-progress.txt`:
   - What feature was implemented
   - Any bugs found and fixed
   - Current state of the application
   - Suggested next feature to work on

3. Update `feature_list.json`: set `passes` to `true` for completed features.
```

#### Step 7: Leave the Codebase Merge-Ready

Before ending the session, verify:
- [ ] No major bugs in existing functionality
- [ ] Code is readable and reasonably documented
- [ ] No half-implemented features left in the codebase
- [ ] A new developer (or agent) could start the next feature immediately without cleanup

---

## Prompt Templates

### Initializer Prompt (Session 1)

```
You are setting up a project workspace for a long-running development effort.
Your goal is NOT to write application code yet. Instead, create the scaffolding
that will allow future coding sessions to work effectively.

The user wants to build: [USER'S HIGH-LEVEL DESCRIPTION]

You must create:
1. feature_list.json — Decompose the above into 50-200+ granular, testable features.
   Each entry must have: id, category, description, verification_steps, passes (set to false).
   Use JSON format. Do not use Markdown.

2. init.sh — A script that installs dependencies, starts the dev server, and runs a
   basic smoke test.

3. claude-progress.txt — An empty progress log with a header explaining its purpose.

4. Initialize a git repository and commit all files.

Do not write any application code. Your only job is to set up this environment.
```

### Coding Prompt (Session 2+)

```
You are a coding agent continuing work on an existing project.

MANDATORY STARTUP SEQUENCE:
1. Run `pwd`
2. Read `claude-progress.txt`
3. Run `git log --oneline -20`
4. Read `feature_list.json`
5. Run `init.sh` to start the dev server
6. Test core functionality end-to-end. If anything is broken, fix it first.

THEN:
7. Choose the highest-priority feature in feature_list.json where passes is false.
8. Implement ONLY that one feature.
9. Test it end-to-end as a real user would (use browser automation for web apps).
10. Only set passes to true after the feature genuinely works.

MANDATORY SHUTDOWN SEQUENCE:
11. git add and commit with a descriptive message.
12. Append a session summary to claude-progress.txt.
13. Verify the codebase is clean and merge-ready.

RULES:
- Work on exactly ONE feature per session.
- Never remove or edit feature definitions in feature_list.json. You may only change
  the passes field.
- Never declare the project complete unless every feature in feature_list.json
  has passes set to true.
- If you find a bug in existing functionality, fix it before starting new work.
- Always test end-to-end, not just with unit tests.
```

---

## Common Pitfalls and Mitigations

| Pitfall | Mitigation |
|---|---|
| Agent tries to build everything at once | Constrain to one feature per session in the prompt |
| Agent declares the project done prematurely | Feature list with explicit `passes: false` flags forces the agent to check completion status |
| Agent leaves broken code at session end | Mandatory git commit + progress log + merge-ready checklist |
| Agent marks features done without real testing | Require end-to-end testing with browser automation or realistic API calls |
| Agent spends time figuring out how to run the app | `init.sh` script eliminates this overhead |
| Agent modifies or deletes the feature list | Use JSON (harder to accidentally restructure) + strong prompt guardrails |
| Agent starts new features on top of broken code | Mandatory "verify existing functionality" step before any new work |

---

## Adapting to Different Project Types

This guide uses web app development as the primary example, but the pattern generalizes:

**Backend API development (Spring Boot, etc.)**
- `init.sh` starts the application server and runs health checks
- End-to-end testing = realistic HTTP request sequences against running endpoints
- Feature list entries describe API behaviors: "POST /orders creates an order and returns 201"

**Data pipeline / batch processing**
- `init.sh` sets up test data and runs a minimal pipeline
- End-to-end testing = verify input → processing → output chain
- Feature list entries describe transformations: "Pipeline correctly handles null values in column X"

**Infrastructure / DevOps**
- `init.sh` validates tool versions and cloud credentials
- End-to-end testing = deploy to a staging environment and verify
- Feature list entries describe infrastructure states: "Auto-scaling triggers at 80% CPU"

---

## Summary

The entire approach rests on one insight: **treat each agent session like a shift change between engineers.** Good engineers leave clean code, descriptive commit messages, progress notes, and a working build. This harness encodes those habits into a repeatable structure that an AI agent can follow across arbitrarily many sessions.
