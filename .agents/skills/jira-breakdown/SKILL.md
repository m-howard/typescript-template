---
name: jira-breakdown
description: >
    Analyzes product documents (PRDs, vision docs, technical architectures, RFCs, problem statements, design specs)
    and breaks them down into well-structured Jira issues with proper hierarchy, story points, acceptance criteria,
    and explicit dependency mapping. Use this skill whenever a user wants to: convert a document into tickets,
    break down a feature into tasks, create a sprint backlog from a spec, generate Jira issues from a PRD,
    map out work items with dependencies, or plan engineering work from any written artifact. Also trigger when
    the user uploads or pastes a technical document and asks "what are the tickets?", "break this down", "make
    issues from this", "plan the work", or similar. Even if the user just says "turn this into Jira issues" or
    "I need to create tickets from this doc", always use this skill.
---

# Jira Issue Breakdown Skill

Transforms product and technical documents into a complete, dependency-mapped Jira backlog.

## Overview

This skill produces a **full Jira issue hierarchy** from any input document:

```
Epic
 └── Story
      ├── Task / Sub-task
      └── Task / Sub-task (blocked by: ...)
```

Issues include: title, type, description, acceptance criteria, story points, labels, suggested assignee role, and dependency links.

---

## Step 1 — Document Intake & Classification

First, identify what kind of document you're working with:

| Type                       | Signals                                        | Output Focus                       |
| -------------------------- | ---------------------------------------------- | ---------------------------------- |
| **PRD**                    | User stories, goals, non-goals, metrics        | Feature epics + stories            |
| **Technical Architecture** | System diagrams, components, APIs, data models | Infrastructure + integration tasks |
| **Vision / Problem Doc**   | "Why we're building", user pain, opportunity   | Discovery epics + research spikes  |
| **RFC**                    | Proposed changes, migration plans, rollout     | Migration tasks + validation tasks |
| **Design Spec**            | Wireframes, UX flows, component specs          | UI tasks + design review tasks     |
| **Combined / Mixed**       | Multiple sections                              | Layered hierarchy across types     |

Read the references for your doc type:

- PRD → `references/prd-patterns.md`
- Architecture → `references/architecture-patterns.md`
- Vision/Problem → `references/vision-patterns.md`

---

## Step 2 — Extract Work Units

Scan the document for these **work signals**:

**Functional signals** (become Stories or Tasks):

- User-facing features described ("Users can...", "The system will...")
- Acceptance criteria or success metrics
- API endpoints or integrations mentioned
- Data models or schema changes

**Infrastructure signals** (become Technical Tasks):

- New services, queues, databases mentioned
- Deployment or infrastructure changes
- Security/auth requirements
- Performance targets that require specific implementation

**Discovery signals** (become Spikes):

- Unknown technical areas ("investigate...", "evaluate options for...")
- Proof-of-concept needs
- Unknowns in the architecture

**Cross-cutting signals** (become sub-tasks on multiple issues):

- Testing requirements
- Documentation needs
- Monitoring/alerting setup
- Feature flags

---

## Step 3 — Build Issue Hierarchy

### Issue Types and When to Use Them

```
EPIC        → A major feature or capability (2–8 weeks of work)
  STORY     → A user-facing behavior or capability (3–8 days)
    TASK    → A concrete engineering unit (1–3 days)
    SUBTASK → A step within a task (< 1 day)
  SPIKE     → Time-boxed research/investigation (1–2 days, fixed)
  BUG       → Only if analyzing existing system issues
```

### Story Point Scale (Fibonacci)

```
1  → Trivial, well-understood, < 2 hours
2  → Small, clear scope, half-day
3  → Moderate, some unknowns, ~1 day
5  → Complex, multi-part, 2–3 days
8  → Large, many unknowns or integrations, near-full sprint
13 → Too big — split it further
```

---

## Step 4 — Map Dependencies

For every issue, determine:

1. **Blocks** — this issue must be done BEFORE others can start
2. **Blocked by** — this issue CANNOT start until another completes
3. **Related to** — parallel work, no hard dependency but related context

### Dependency Rules

- Database schema issues **always block** API issues
- API issues **always block** frontend issues
- Auth/security issues **always block** any issue exposing user data
- Infrastructure provisioning **always blocks** service deployment
- Design/UX issues **block** frontend implementation
- Spikes **block** the tasks they're investigating

### Dependency Notation in Output

```
BLOCKED BY: [EPIC-3], [EPIC-7]
BLOCKS: [EPIC-12], [EPIC-15]
```

---

## Step 5 — Output Format

Produce the full breakdown in this format. See `examples/` for complete worked examples.

### Full Issue Output Template

```markdown
## 🗂️ EPIC: [EPIC-N] {Epic Title}

**Goal:** {One sentence describing the user/business outcome}
**Labels:** {epic, feature-area, team}
**Estimated Size:** {S / M / L / XL}
**Dependencies:** {None | BLOCKED BY: [...]}

---

### 📖 STORY: [STORY-N] {Story Title}

**Type:** Story
**Epic:** [EPIC-N]
**As a** {user type}, **I want** {action}, **so that** {benefit}.

**Acceptance Criteria:**

- [ ] {Criterion 1}
- [ ] {Criterion 2}
- [ ] {Criterion 3}

**Story Points:** {1|2|3|5|8}
**Suggested Role:** {Frontend / Backend / Full-stack / Platform / Design}
**Labels:** {story, feature-area}
**BLOCKED BY:** {None | [ISSUE-N], [ISSUE-N]}
**BLOCKS:** {None | [ISSUE-N], [ISSUE-N]}

---

#### ✅ TASK: [TASK-N] {Task Title}

**Type:** Task
**Parent Story:** [STORY-N]
**Description:** {What needs to be built/done, with technical specifics}

**Acceptance Criteria:**

- [ ] {Technical criterion 1}
- [ ] {Technical criterion 2}

**Story Points:** {1|2|3|5}
**Suggested Role:** {Backend / Frontend / DevOps / etc.}
**BLOCKED BY:** {None | [ISSUE-N]}
**BLOCKS:** {None | [ISSUE-N]}

---

#### 🔬 SPIKE: [SPIKE-N] {Investigation Title}

**Type:** Spike
**Parent Epic:** [EPIC-N]
**Goal:** {What question this spike answers}
**Time-box:** {1–2 days}
**Output:** {Document / POC / Decision / Recommendation}
**BLOCKS:** {[ISSUE-N] — cannot begin until spike concludes}
```

---

## Step 6 — Dependency Graph Summary

After all issues, produce a visual dependency summary:

```markdown
## 🔗 Dependency Graph

[EPIC-1: Auth] ──blocks──► [EPIC-3: User Profiles]
└──blocks──► [EPIC-5: Social Features]

[SPIKE-1: DB Eval] ──blocks──► [TASK-4: Schema Design]
└──blocks──► [TASK-7: API Layer]
└──blocks──► [TASK-12: Frontend Integration]

Critical Path: SPIKE-1 → TASK-4 → TASK-7 → TASK-12
Estimated Minimum Duration (sequential): ~11 days
```

---

## Step 7 — Sprint Planning Recommendation

After the dependency graph, add sprint recommendations:

```markdown
## 📅 Suggested Sprint Breakdown

### Sprint 1 — Foundation (can start immediately, no blockers)

- [SPIKE-1] Investigate database options
- [TASK-2] Set up CI/CD pipeline
- [TASK-3] Design system components

### Sprint 2 — Core Infrastructure (after Sprint 1)

- [TASK-4] Schema design and migrations
- [TASK-5] Auth service implementation

### Sprint 3+ — Features (after infrastructure complete)

- [STORY-3] User registration flow
- [STORY-4] Profile management
```

---

## Quality Checklist

Before finalizing output, verify:

- [ ] Every Epic has at least 2 Stories
- [ ] Every Story has explicit Acceptance Criteria
- [ ] Every issue has Story Points (no "TBD")
- [ ] All database/schema issues precede API issues in dependencies
- [ ] All Spikes have a defined time-box and output artifact
- [ ] No "orphan" tasks (every task belongs to a parent story)
- [ ] Critical path is identified
- [ ] No circular dependencies

---

## Output Formats

### Default: Markdown (inline in chat)

Full markdown breakdown as shown in Step 5.

### If user asks for file export:

- **CSV** — Use `references/jira-csv-format.md` to produce importable CSV
- **JSON** — Use `references/jira-json-schema.md` for API-ready JSON

---

## Reference Files

Read these as needed:

- `references/prd-patterns.md` — PRD-specific extraction patterns and examples
- `references/architecture-patterns.md` — Technical architecture breakdown patterns
- `references/vision-patterns.md` — Vision/problem doc to discovery epic patterns
- `references/jira-csv-format.md` — Jira CSV import format spec
- `references/jira-json-schema.md` — JSON schema for programmatic export
- `examples/prd-example.md` — Full worked PRD → Jira breakdown
- `examples/architecture-example.md` — Full worked architecture doc → Jira breakdown
