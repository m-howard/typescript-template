# User Guide Template

> Use this template when writing a task-oriented user guide or how-to document. Each guide covers one goal. Copy and fill in the sections below based on actual project behavior. Remove sections that do not apply.

---

````markdown
# [Task Title — Start with a Verb]

> [One sentence: what this guide helps you accomplish, and any prerequisites at a glance]

**Time to complete**: [~X minutes]

## Overview

[1–2 sentences explaining what this guide covers and what the end result looks like. Do not repeat the title verbatim.]

## Prerequisites

Before starting, confirm:

- [ ] [Prerequisite 1] — [link to where this can be completed if it's a prior guide]
- [ ] [Prerequisite 2]
- [ ] [Prerequisite 3]

## Steps

### Step 1: [Action Verb + Brief Description]

[One sentence explaining what this step accomplishes and why it's needed.]

```bash
[Exact command]
```
````

**Expected output**:

```
[What the user should see when this step succeeds]
```

---

### Step 2: [Action Verb + Brief Description]

[One sentence explaining what this step accomplishes.]

[If configuration is needed, show a minimal working example:]

```yaml
# [filename.yaml or .env or relevant config file]
KEY: value
ANOTHER_KEY: other-value
```

---

### Step 3: [Action Verb + Brief Description]

[Continue for each step. Each step = one action. Do not bundle multiple actions into one step.]

---

## Verify

[Explain how the user confirms the task was completed successfully. This must be concrete and observable — not "it should work".]

```bash
[Verification command]
```

**Expected result**: [What they should see]

## Troubleshooting

### [Error message or symptom users commonly see]

**Cause**: [Why this happens]

**Fix**:

1. [Step to resolve]
2. [Step to resolve]

---

### [Another common error]

**Cause**: [Why this happens]

**Fix**: [What to do]

---

## Next Steps

- [Link to related guide 1] — [Brief description of when to use it]
- [Link to related guide 2] — [Brief description of when to use it]
- [Link to reference docs] — [For users who want full option details]

```

---

## Authoring Notes

### One Guide, One Goal

This template is for a single, focused task. If you find yourself writing "and also" or "while you're here", those belong in a separate guide.

### Step Granularity

Split steps when:
- A step requires the user to make a decision
- A step can fail independently
- A step produces output the user needs to verify before continuing

Combine steps when:
- They are always done together with no possible failure between them
- They take less than 5 seconds total

### Verification Matters

Every guide must end with a verification step. "It should be working now" is not verification. Show a command and its expected output.

### Prerequisites vs. Steps

Prerequisites are things that must already be true before the user starts. Steps are actions the user takes within this guide. Do not put setup instructions in prerequisites — link to the guide that covers them.

## Checklist Before Publishing

- [ ] Title starts with a verb
- [ ] All commands verified against current codebase
- [ ] Every numbered step is a single action
- [ ] Verification section shows expected output
- [ ] Troubleshooting covers the 2–3 most common failure modes
- [ ] All prerequisite links resolve correctly
- [ ] No placeholder text remaining
```
