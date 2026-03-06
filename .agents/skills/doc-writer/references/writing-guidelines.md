# Technical Writing Guidelines

Style and quality rules for all documentation produced by the doc-writer skill.

---

## Core Principles

### 1. Accuracy Over Completeness

A short, accurate document is better than a long, speculative one. Never invent behavior, flags, or options that are not confirmed in the codebase. When in doubt, flag with `[NEEDS VERIFICATION]` rather than guessing.

### 2. Task Orientation

Users come to documentation with a goal. Every section should answer a specific question or help complete a specific task. If a section doesn't answer a question a user would ask, remove it.

### 3. Progressive Disclosure

Lead with what most users need. Put advanced, edge-case, and optional information at the end of a section or in a separate document. Never bury "how to get started" behind pages of background context.

---

## Voice and Tone

### Use Second Person

| ✅ Write this          | ❌ Not this                  |
| ---------------------- | ---------------------------- |
| "You can configure..." | "The user can configure..."  |
| "Run the command"      | "One should run the command" |
| "Your project"         | "The project"                |

### Use Active Voice

| ✅ Write this                        | ❌ Not this                                   |
| ------------------------------------ | --------------------------------------------- |
| "The CLI deploys the stack."         | "The stack is deployed by the CLI."           |
| "Run `npm install` to install deps." | "Dependencies should be installed by running" |

### Use Imperative Mood for Instructions

Instructions must be direct commands, not suggestions.

| ✅ Write this                    | ❌ Not this                                 |
| -------------------------------- | ------------------------------------------- |
| "Set the `AWS_REGION` variable." | "You should set the `AWS_REGION` variable." |
| "Create a new stack."            | "A new stack needs to be created."          |

---

## Banned Words and Phrases

Never use these in technical documentation:

| Banned                    | Why                                          | Alternative                             |
| ------------------------- | -------------------------------------------- | --------------------------------------- |
| "Simply"                  | Implies the reader is wrong if they fail     | Just delete it; the action stands alone |
| "Just"                    | Same as above                                | Delete it                               |
| "Easy" / "Easily"         | Subjective; condescending when it's not      | Show the steps; let them judge          |
| "Obviously"               | Alienates readers who didn't find it obvious | Delete it                               |
| "Straightforward"         | Same as "easy"                               | Delete it                               |
| "Powerful"                | Marketing language, not documentation        | Describe what it actually does          |
| "Robust" / "Seamless"     | Vague marketing                              | Describe the concrete behavior          |
| "Note that..." (overused) | Filler                                       | Use a callout block or rephrase         |
| "It is worth mentioning"  | Filler                                       | Just say the thing                      |
| "Please note"             | Weak; sounds apologetic                      | Use a `> **Note:**` callout             |

---

## Formatting Rules

### Headers

- Use `##` for top-level sections within a document (not `#` — that's the document title)
- Use `###` for subsections, `####` for sub-subsections
- Do not skip levels (never go from `##` directly to `####`)
- Headers must be sentence case, not Title Case: "Getting started" not "Getting Started"
- Exception: proper nouns always capitalize: "Deploying to AWS"

### Lists

Use **numbered lists** when:

- Steps must be performed in order
- Sequence matters to the outcome

Use **bullet lists** when:

- Items are non-sequential options, features, or notes
- Order does not matter

Never mix sequential and non-sequential items in one list.

### Code Blocks

Every code block must:

- Have a language identifier on the opening fence: ` ```bash `, ` ```typescript `, ` ```yaml `
- Be preceded by a sentence explaining what the block does or shows
- Show realistic, working examples (no placeholder lorem ipsum)

```bash
# Install project dependencies
npm install

# Run the test suite
npm test
```

For inline code, use backticks for: commands, file paths, option names, environment variables, and any literal value the user would type or see.

Examples:

- Run `npm run build` to compile.
- Set the `AWS_REGION` environment variable.
- Edit `configs/dev.json` to configure the dev environment.

### Callouts / Admonitions

Use Markdown blockquotes with bold labels for important notices:

```markdown
> **Note:** This only applies when deploying to production.

> **Warning:** This action cannot be undone.

> **Tip:** You can speed this up by caching the Pulumi state locally.
```

Do not overuse callouts — if everything is a warning, nothing is.

### Tables

Use tables for:

- Option/parameter reference listings
- Comparison of choices (e.g., environment variables)
- Error codes and their meanings

Always include a header row. Keep cell content concise — if a cell needs more than 2 sentences, use a separate section instead.

---

## Structure Patterns

### Opening a Section

Every section should begin with a clear statement of what the section covers. Do not start with background context.

❌ **Wrong:**

> "AWS provides multiple ways to manage infrastructure. Infrastructure as code has grown in popularity. Pulumi is one such tool. In this section..."

✅ **Right:**

> "This section explains how to deploy the networking stack to your AWS account."

### Step-Based Instructions

For any multi-step process:

1. Number every step
2. Each step = one action
3. Show expected output for steps that produce visible results
4. If a step can fail, show what failure looks like

````markdown
## Deploy the Stack

1. Authenticate with AWS:

    ```bash
    aws configure
    ```
````

2. Preview the changes before applying:

    ```bash
    npm run preview:dev
    ```

    Expected output:

    ```
    Previewing update (dev):
    + 3 resources to create
    ```

3. Deploy:

    ```bash
    npm run deploy:dev
    ```

````

### Prerequisites

Always list prerequisites as a checklist at the start of any guide that requires them:

```markdown
## Prerequisites

Before starting, ensure you have:

- [ ] Node.js 22+ installed (`node --version`)
- [ ] AWS CLI configured with appropriate credentials (`aws sts get-caller-identity`)
- [ ] Pulumi CLI installed (`pulumi version`)
- [ ] An S3 bucket for Pulumi state storage
````

---

## Handling Missing Information

When you cannot confirm information from the codebase or user input, use inline flags:

```
Run the following command to deploy: [NEEDS VERIFICATION: confirm exact command from package.json]
```

Collect all flags and surface them at the end of the document:

```markdown
## Open Questions

1. **Line 23** — What is the exact command to deploy to production?
2. **Prerequisites** — What minimum Node.js version is required?
```

Never invent details. A flagged gap is always better than confident misinformation.

---

## File and Document Conventions

### File Naming

- All documentation files: `kebab-case.md`
- README must be: `README.md` (uppercase, root of relevant directory)
- Place documentation in `docs/` unless the project has an established docs location

### Document Header

Every documentation file should begin with:

```markdown
# [Title]

> [One sentence: what this document covers and who it is for]
```

### Last Updated / Version

For reference documentation (configuration, API, CLI), include a version note at the bottom:

```markdown
---

_Applies to version 1.2.x and above. For older versions, see the [v1.1 docs](link)._
```
