# Vision & Problem Document Breakdown Patterns

## Vision Docs → Jira Issues

Vision and problem documents are **upstream of PRDs**. They describe the problem space, not the solution. Breaking these down requires a discovery-first approach.

## Key Difference from PRDs

| PRD | Vision / Problem Doc |
|-----|---------------------|
| Solution is defined | Solution is TBD |
| Tasks are implementation | Tasks are research and validation |
| Acceptance criteria are functional | Acceptance criteria are learning goals |
| Estimates are in story points | Estimates are in time-boxes |

## Extraction Map

| Vision Section | What to Extract | Issue Type |
|---|---|---|
| Problem statement | Core problem → Discovery Epic | Epic |
| User pain points | Each pain → User research task or Spike | Spike / Task |
| Opportunity hypothesis | Each hypothesis → Validation Spike | Spike |
| Success metrics / KPIs | Each metric → Instrumentation task (later sprint) | Task |
| Proposed solutions (if any) | Solution concepts → Design/POC Spikes | Spikes |
| Out of scope | Explicit exclusions → notes in Epic description | N/A |
| Open questions | Each question → Research Spike | Spike |

## Discovery Epic Pattern

```
EPIC: Discover & Validate {Problem Area}

  SPIKE: User research — {problem domain}
    Goal: Interview 5-8 target users, validate pain points
    Time-box: 3 days
    Output: Research synthesis doc with top insights
    BLOCKS: Solution design work

  SPIKE: Competitive analysis
    Goal: Understand how competitors address this problem
    Time-box: 2 days
    Output: Competitive landscape doc
    BLOCKS: Solution design work

  SPIKE: Technical feasibility assessment
    Goal: Is the proposed solution technically viable with current stack?
    Time-box: 2 days
    Output: Feasibility memo with go/no-go recommendation
    BLOCKS: Any implementation work

  TASK: Define success metrics & measurement plan
    - Identify leading and lagging indicators
    - Define data collection plan
    - Instrument analytics before feature launch
    BLOCKED BY: User research spike
    BLOCKS: Any feature implementation (can't build without knowing what to measure)

  TASK: Solution design workshop
    - Facilitated session with product + design + eng
    - Output: 2-3 solution concepts for evaluation
    BLOCKED BY: User research spike, competitive analysis spike
    BLOCKS: Prototype tasks

  SPIKE: Prototype & user test solution concept
    Time-box: 5 days
    Output: User-tested prototype + recommendation
    BLOCKED BY: Solution design workshop
    BLOCKS: PRD writeup
```

## Hypothesis-Driven Pattern

When a vision doc contains a hypothesis ("We believe that X will result in Y"), create:

```
SPIKE: Validate hypothesis — {hypothesis summary}
  Goal: Test whether {X} is true for our users
  Method: {A/B test / user interviews / data analysis / prototype test}
  Time-box: {appropriate duration}
  Success criteria: {what data/signal would confirm or deny the hypothesis}
  Output: Hypothesis verdict doc + recommendation
  
  IF CONFIRMED → triggers {next set of tasks}
  IF DENIED → triggers {pivot or abandon decision}
```

## Vision to PRD Bridge

Vision docs often need to produce a PRD before engineering tickets make sense. Include:

```
TASK: Write PRD for {feature/initiative}
  Input: Research synthesis, competitive analysis, prototype feedback
  Output: PRD reviewed and approved by stakeholders
  BLOCKED BY: Discovery spikes
  BLOCKS: All engineering Epics
```

## OKR/Metric Instrumentation Tasks

For each success metric in the vision doc:

```
TASK: Instrument {metric name} tracking
  - Define event schema for {metric}
  - Add tracking call at point of user action
  - Verify data flowing to analytics platform
  - Create initial dashboard/report
  Story Points: 2-3
  Note: Should be done BEFORE or WITH feature launch, never after
```

## Common Vision Doc Epic Patterns

### "0 to 1" New Product / Major Feature
```
EPIC 1: Discovery & Validation
  (Spikes: user research, competitive analysis, feasibility)

EPIC 2: Foundation (after discovery)
  (Spikes converted to tasks once solution is chosen)
  (Infrastructure, data model, core APIs)

EPIC 3: MVP Feature Set (after foundation)
  (Minimum set of stories to validate with real users)

EPIC 4: Iteration (after MVP validation)
  (Improvements based on real usage data)
```

### Platform Improvement / Problem Fix
```
EPIC 1: Understand Current State
  (Data analysis, user research, root cause investigation)

EPIC 2: Design Solution
  (Solution design, technical spike)

EPIC 3: Implement Fix
  (Engineering tasks)

EPIC 4: Validate Impact
  (Measurement, A/B test, rollout)
```

## Story Point Guidance for Discovery Work

Discovery work uses **time-boxes** not story points. But for backlog visibility, use:
```
1-day spike  → 3 points
2-day spike  → 5 points
3-day spike  → 8 points
5-day spike  → 13 points (max; split if larger)
```