# Context: Anthropic's Multi-Agent Harness for Long-Running Autonomous Coding

> Source: Anthropic Engineering Blog, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)

---

## What This Article Is About

This article describes how an engineer at Anthropic Labs designed and iterated on a multi-agent harness (orchestration system) that enables Claude to autonomously build complete, polished full-stack applications over multi-hour coding sessions. The work covers two domains: frontend UI design and full-stack application development.

---

## Background and Motivation

The author had previously worked on two related projects: a "frontend design skill" (a prompt/instruction set that improves Claude's UI output quality) and a long-running coding agent harness (an orchestration system that lets Claude build apps over extended sessions). Both achieved gains over baseline through prompt engineering and harness design, but both eventually hit performance ceilings.

To break through, the author drew inspiration from GANs (Generative Adversarial Networks) and designed a system where separate agents generate and evaluate output, creating a feedback loop that drives quality upward.

---

## Two Failure Modes the Harness Addresses

### 1. Context Degradation

As tasks get longer and the context window fills, models lose coherence. Some models also exhibit "context anxiety" — they start wrapping up work prematurely because they sense they're approaching their context limit.

**Solution: Context resets.** Rather than summarizing earlier conversation in place (compaction), the harness clears the context entirely and starts a fresh agent with a structured handoff artifact carrying the previous agent's state and next steps. This gives the agent a clean slate. In testing, Claude Sonnet 4.5 exhibited context anxiety strongly enough that compaction alone was insufficient, making context resets essential.

Note: With Opus 4.5 and later Opus 4.6, context anxiety largely disappeared, so context resets became less necessary.

### 2. Self-Evaluation Bias

When asked to evaluate their own output, agents consistently over-praise their work — even when quality is obviously mediocre to a human. This is especially problematic for subjective tasks (design), but also appears in objective tasks (functional correctness).

**Solution: Separate the generator from the evaluator.** A standalone evaluator agent judges the generator's output. Tuning an independent evaluator to be skeptical is far more tractable than making a generator self-critical. The evaluator provides concrete feedback that the generator can iterate against.

---

## Part 1: Frontend Design Experiment

### Problem

Without intervention, Claude gravitates toward safe, generic layouts — technically functional but visually unremarkable.

### Approach

The author created four grading criteria given to both the generator and evaluator agents:

1. **Design Quality** — Does the design feel like a coherent whole with a distinct mood/identity? (Colors, typography, layout, imagery working together.)
2. **Originality** — Evidence of deliberate creative choices vs. template defaults and AI-generated patterns. Penalizes "AI slop" like purple gradients over white cards.
3. **Craft** — Technical execution: typography hierarchy, spacing consistency, color harmony, contrast ratios. A competence check. Claude already scores well here by default.
4. **Functionality** — Usability independent of aesthetics. Can users understand the interface, find actions, complete tasks?

Design quality and originality were weighted more heavily because Claude already performed well on craft and functionality.

### Feedback Loop Mechanics

- Built on the Claude Agent SDK.
- Generator creates HTML/CSS/JS frontend from a user prompt.
- Evaluator uses Playwright MCP to navigate and interact with the live page (not static screenshots), then scores each criterion and writes a detailed critique.
- Feedback flows back to the generator for the next iteration.
- 5–15 iterations per generation. Full runs took up to 4 hours.
- Generator was instructed to make a strategic choice after each evaluation: refine the current direction if scores trended well, or pivot to an entirely different aesthetic if the approach wasn't working.

### Key Findings

- Scores generally improved over iterations before plateauing, but not always linearly. The author sometimes preferred a middle iteration over the final one.
- Implementation complexity increased across rounds as the generator reached for more ambitious solutions.
- Even the first iteration was better than a zero-prompting baseline, suggesting the criteria language itself steered the model away from generic defaults before any evaluator feedback.
- The wording of criteria shaped output character in unexpected ways — e.g., "the best designs are museum quality" pushed designs toward a specific visual convergence.
- Notable example: A Dutch art museum website prompt. Through 9 iterations, the generator produced polished dark-themed landing pages. On iteration 10, it scrapped everything and built a 3D spatial experience — a CSS perspective-rendered room with a checkered floor, artwork on walls, and doorway-based navigation between gallery rooms. This kind of creative leap was unprecedented from single-pass generation.

---

## Part 2: Full-Stack Application Development

### Architecture (V1 — Three-Agent System with Sprints)

**Planner Agent:**
- Takes a 1–4 sentence user prompt and expands it into a full product spec.
- Prompted to be ambitious about scope.
- Focuses on product context and high-level technical design, NOT granular implementation details (to avoid cascading spec errors).
- Instructed to find opportunities to weave AI features (Claude-powered) into the product.

**Generator Agent:**
- Works in sprints, implementing one feature at a time from the spec.
- Tech stack: React, Vite, FastAPI, SQLite (later PostgreSQL).
- Self-evaluates at the end of each sprint before handing off to QA.
- Uses git for version control.

**Evaluator (QA) Agent:**
- Uses Playwright MCP to click through the running application like a real user.
- Tests UI features, API endpoints, and database states.
- Grades each sprint against criteria covering: product depth, functionality, visual design, code quality.
- Each criterion has a hard pass/fail threshold. If any fails, the sprint goes back to the generator with detailed feedback.

**Sprint Contract:**
- Before each sprint, generator and evaluator negotiate what "done" looks like.
- Generator proposes what it will build and how success will be verified.
- Evaluator reviews the proposal to ensure correctness.
- They iterate until they agree.
- Communication happens via files (one agent writes, another reads and responds).

### V1 Test: Retro Game Maker

**Prompt:** "Create a 2D retro game maker with features including a level editor, sprite editor, entity behaviors, and a playable test mode."

| Approach | Duration | Cost |
|----------|----------|------|
| Single agent (no harness) | 20 min | $9 |
| Full 3-agent harness | 6 hours | $200 |

**Single agent result:**
- App looked reasonable at first glance.
- Layout wasted space (fixed-height panels, mostly empty viewport).
- Rigid workflow with no guidance on required sequence (create sprites → entities → populate level).
- **Game was fundamentally broken:** entities appeared on screen but nothing responded to input. The wiring between entity definitions and game runtime was disconnected.

**Full harness result:**
- Planner expanded the prompt into a 16-feature spec across 10 sprints, adding: sprite animation, behavior templates, sound effects/music, AI-assisted sprite generator and level designer, game export with shareable links.
- App used full viewport, had consistent visual identity, sensible panel sizing.
- **The game actually worked** — character could move and play the level.
- Physics had rough edges (character overlapping with platforms) and some AI-generated level design issues (impassable walls), but core functionality was intact.
- Built-in Claude integration allowed generating game components via prompting.

**Examples of bugs the evaluator caught:**

| Contract Criterion | Finding |
|---|---|
| Rectangle fill tool should fill area via click-drag | FAIL — Only placed tiles at drag start/end points. `fillRectangle` function exists but isn't triggered on mouseUp. |
| User can select and delete entity spawn points | FAIL — Delete handler requires both `selection` and `selectedEntityId`, but clicking only sets `selectedEntityId`. |
| User can reorder animation frames via API | FAIL — `PUT /frames/reorder` defined after `/{frame_id}` routes. FastAPI matches "reorder" as an integer frame_id → 422 error. |

**Evaluator tuning challenges:**
- Out of the box, Claude was a poor QA agent.
- It would find real issues, then talk itself into deciding they weren't important and approve anyway.
- It tested superficially, missing edge cases.
- Required multiple rounds of: read evaluator logs → find judgment divergences from human assessment → update prompt → repeat.

---

## Part 3: Simplifying the Harness (V2)

### Motivation

The V1 harness was effective but bulky, slow, and expensive. Every harness component encodes an assumption about what the model can't do alone — those assumptions should be stress-tested because they may be wrong or go stale as models improve.

The guiding principle: "Find the simplest solution possible, and only increase complexity when needed."

### Opus 4.6 Capabilities That Enabled Simplification

Opus 4.6 (released during this work) offered: more careful planning, longer sustained agentic tasks, more reliable operation in larger codebases, better code review and debugging, and substantially improved long-context retrieval. These were all capabilities the harness had been built to supplement.

### Key Change: Removing the Sprint Structure

- Opus 4.6 could work coherently for 2+ hours without sprint decomposition.
- Agents ran as one continuous session with automatic compaction handling context growth.
- Evaluator moved to a single pass at the end of the run (instead of per-sprint).
- Planner and evaluator were kept because they still added clear value.

### When the Evaluator Matters

The evaluator's value is relative to model capability:
- On Sonnet 4.5: builds were at the edge of what the generator could do well solo → evaluator caught meaningful issues consistently.
- On Opus 4.6: model's raw capability increased, boundary moved outward → tasks that previously needed the evaluator were now handled well solo. But for tasks still at the edge of the generator's capabilities, the evaluator continued to provide real lift.

**Takeaway:** The evaluator is not a fixed yes/no decision. It's worth the cost when the task exceeds what the current model does reliably on its own.

### V2 Test: Browser-Based DAW (Digital Audio Workstation)

**Prompt:** "Build a fully featured DAW in the browser using the Web Audio API."

| Phase | Duration | Cost |
|-------|----------|------|
| Planner | 4.7 min | $0.46 |
| Build (Round 1) | 2 hr 7 min | $71.08 |
| QA (Round 1) | 8.8 min | $3.24 |
| Build (Round 2) | 1 hr 2 min | $36.89 |
| QA (Round 2) | 6.8 min | $3.09 |
| Build (Round 3) | 10.9 min | $5.88 |
| QA (Round 3) | 9.6 min | $4.06 |
| **Total** | **3 hr 50 min** | **$124.70** |

**QA findings (Round 1):** Strong app with good design and AI integration, but several core DAW features were display-only without interactive depth — clips couldn't be dragged on timeline, no instrument UI panels (synth knobs, drum pads), no visual effect editors (EQ curves, compressor meters).

**QA findings (Round 2):** Audio recording still stub-only, clip resize/split not implemented, effect visualizations are numeric sliders not graphical.

**Final result:**
- Working arrangement view, mixer, and transport in the browser.
- Author composed a short song snippet entirely through prompting — the AI agent set tempo/key, laid down a melody, built a drum track, adjusted mixer levels, added reverb.
- Not a professional DAW, and Claude can't hear (limiting QA effectiveness for musical taste), but all core primitives for song composition were present and the agent could drive them autonomously.

---

## Lessons and Takeaways

1. **Separate generation from evaluation.** Tuning an independent evaluator to be skeptical is far easier than making a generator self-critical.

2. **Subjective quality can be made gradable.** "Is this beautiful?" is hard to answer consistently, but "does this follow concrete design principles?" gives models something actionable to score against.

3. **Every harness component is an assumption about model limitations.** Stress-test these regularly — they go stale as models improve.

4. **When a new model arrives, re-examine the harness.** Strip away parts that are no longer load-bearing. Add new parts to achieve capabilities that weren't possible before.

5. **The space of interesting harness designs doesn't shrink as models improve — it moves.** The work for AI engineers is to keep finding the next novel combination.

6. **Invest in reading agent traces.** The evaluator tuning loop (read logs → find judgment gaps → update prompts) was essential and could not be shortcut.

7. **Planner agents add value even with capable models.** Without the planner, the generator under-scoped and produced less feature-rich applications.

---

## Technical Details Referenced

- **Frameworks/Tools used:** Claude Agent SDK, Playwright MCP, Git
- **Tech stacks generated:** React + Vite + FastAPI + SQLite/PostgreSQL
- **Models discussed:** Claude Sonnet 4.5, Claude Opus 4.5, Claude Opus 4.6
- **Related Anthropic publications:** "Building Effective Agents," "Effective context engineering for AI agents," "Effective harnesses for long-running agents"
