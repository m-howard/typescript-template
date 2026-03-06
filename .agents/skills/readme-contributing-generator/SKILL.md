---
name: readme-contributing-generator
description: >
    Generates excellent, project-specific README.md and CONTRIBUTING.md documentation for
    repositories being converted from a template. Use this skill whenever the user wants to:
    write or improve a README, create a CONTRIBUTING guide, document their project for open
    source or team use, replace placeholder template content with real project documentation,
    or set up contributor-facing documentation. Trigger on phrases like "write my README",
    "create a contributing guide", "document my project", "update the README", "help me
    write docs for my repo", "convert this template", "I need a contributing doc", or any
    request to produce repository-level documentation. Also trigger when the user shares a
    project description or codebase and asks how to present it to other developers.
---

# README & Contributing Docs Generator

You are an expert technical writer and developer advocate. Your goal is to produce a
**polished, accurate, project-specific README.md and CONTRIBUTING.md** that replace
template placeholders with real content a developer would be proud to publish.

---

## Phase 1: Gather Context (ALWAYS DO THIS FIRST)

Before writing any documentation, collect the information you need. Do this by:

1. **Examining the repository** — read `package.json`, `pyproject.toml`, `Cargo.toml`, or
   equivalent; explore the directory structure; read existing source files to understand
   what the project does.
2. **Reading any existing docs** — check the current `README.md`, `CONTRIBUTING.md`,
   `docs/`, and any `AGENTS.md` or `copilot-instructions.md` for context already captured.
3. **Asking the user for gaps** — if critical information can't be inferred from the
   codebase, ask targeted questions. Combine into a single message:

   - What does this project do? (1–2 sentence elevator pitch)
   - Who is the intended audience? (end users, internal team, open-source community)
   - What are the top 3–5 features or capabilities?
   - Are there any special prerequisites beyond the standard tech stack?
   - What is the deployment or usage workflow? (local dev, Docker, cloud, etc.)
   - Is this open source, inner source, or a private project?
   - Is there a license? (if not stated, do not invent one)
   - Are there contribution guidelines, a code of conduct, or governance rules?

Do **not** invent facts about the project. If you cannot determine something, mark it with
`[TODO: fill in]` so the developer knows what to complete.

---

## Phase 2: Generate README.md

Produce a README using this structure. Adapt sections to the project — remove sections
that don't apply, add project-specific ones where needed.

### README Structure

```markdown
# [Project Name]

[1–2 sentence description — what it does and why it matters]

[Badges — build status, coverage, version, license, etc. — only include badges that
actually exist or can be inferred from CI/CD config. Use real badge URLs.]

## ✨ Features

[Bullet list of 3–7 key capabilities. Be specific — not "easy to use" but what it
actually does. Use the project's own language and terminology.]

## 📋 Prerequisites

[List runtime/environment requirements: language version, platform, tools, accounts.
Only include what is actually required, not nice-to-haves.]

## 🚀 Quick Start

[Step-by-step: install, configure, and run the project in under 5 minutes.
Use actual commands from package.json scripts, Makefile, or equivalent.]

​```bash
# Example commands — use the project's real commands
npm install
npm run dev
​```

## 💻 Usage

[Practical examples of the most common use cases. Show real code/commands.
Include expected output where helpful. Favor working examples over prose.]

## ⚙️ Configuration

[Describe configuration options: env variables, config files, flags.
Use a table where there are multiple options:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| ... | ... | ... | ... |

Only document options that actually exist in the codebase.]

## 🏗️ Architecture

[Optional — include if the system has meaningful architectural complexity.
Describe major components, how they relate, and why the structure is what it is.
A simple Mermaid diagram or ASCII structure is preferred over long prose.]

## 📁 Project Structure

[Directory tree with brief descriptions. Show real structure — don't invent directories.]

​```text
src/
├── ...
​```

## 🧪 Testing

[How to run tests. Include unit, integration, and e2e test commands if they exist.
Mention coverage targets if defined.]

## 📖 Documentation

[Link to extended docs if they exist. If not, skip this section.]

## 🤝 Contributing

[1–2 sentences + link to CONTRIBUTING.md. Keep it short here.]

## 📄 License

[State the license. If UNLICENSED, state that explicitly.]
```

### README Quality Rules

- **No marketing speak**: avoid "powerful", "robust", "seamless", "cutting-edge"
- **Real commands only**: every code block must contain commands that actually work
- **Specific over vague**: "deploys to AWS ECS using Pulumi" beats "supports cloud deployment"
- **Current badges only**: only link badges for CI/tools that are configured in the repo
- **Scannable**: use headers, bullets, and tables — avoid dense paragraphs
- **Mobile-aware**: keep badge rows short; prefer stacked layout for many badges

---

## Phase 3: Generate CONTRIBUTING.md

Produce a CONTRIBUTING.md using this structure. Tailor every section to the actual
project toolchain and workflow.

### CONTRIBUTING.md Structure

```markdown
# Contributing to [Project Name]

[1–2 sentences welcoming contributors and framing the contribution philosophy.
Match tone to the project — formal for enterprise, friendly for open source.]

## Table of Contents

[Link to each major section for easy navigation]

## Getting Started

### Prerequisites

[What must be installed to contribute. Match to the actual dev toolchain.]

### Development Setup

[Step-by-step to get a working local development environment.
Use real commands. Include any environment variable setup.]

​```bash
# Clone and install
git clone <repo-url>
cd <project>
npm install   # or equivalent

# Set up environment
cp .env.example .env
# Edit .env with your values

# Verify setup
npm test
​```

## Development Workflow

### Branching Strategy

[Describe the actual branching model. Examples:
- Feature branches: `feature/<short-description>`
- Bug fixes: `fix/<issue-number>-short-description`
- Base branch: `main` or `develop`]

### Making Changes

[Step-by-step workflow: create branch → make changes → test → commit → PR]

### Commit Messages

[Specify the convention. If Conventional Commits are used, explain the format:

​```
<type>(<scope>): <short description>

Types: feat, fix, docs, refactor, test, chore, perf, ci
​```

If no convention is enforced, still recommend clear, imperative commit messages.]

## Code Standards

### Linting & Formatting

[List the tools and how to run them. Include auto-fix commands.
Explain what the pre-commit hooks do, if any.]

​```bash
npm run lint      # ESLint
npm run format    # Prettier
​```

### TypeScript / Language Guidelines

[Key conventions specific to this project. Pull from existing AGENTS.md or
coding standards docs if available. Keep it concise — link to fuller docs if they exist.]

### Testing Requirements

[What tests are required for a PR to be accepted:
- Unit tests for new functions/classes
- Integration tests for new API endpoints
- Coverage thresholds, if enforced]

​```bash
npm test           # Run all tests
npm run test:cov   # Run with coverage report
​```

## Pull Request Process

### Before Opening a PR

[Checklist of things to verify before submitting:]

- [ ] Tests pass locally (`npm test`)
- [ ] Linting passes (`npm run lint:check`)
- [ ] Formatting is correct (`npm run format:check`)
- [ ] New code has tests
- [ ] Documentation updated if needed

### PR Description

[Explain what a good PR description looks like: what changed, why, how to test it.
If there's a PR template, reference it.]

### Review Process

[Describe the review process: who reviews, how long it typically takes, what to expect.]

## Reporting Issues

### Bug Reports

[What to include in a bug report: steps to reproduce, expected vs. actual behavior,
environment info, logs or screenshots.]

### Feature Requests

[How to propose new features: use GitHub Issues, describe the use case and value,
wait for feedback before implementing.]

## Code of Conduct

[If a Code of Conduct exists, link to it. If not, include a brief statement about
expected behavior (respectful, constructive, inclusive).]

## Questions?

[How to get help: GitHub Discussions, issues, Slack, email — whatever applies.]
```

### CONTRIBUTING.md Quality Rules

- **Actionable steps only**: every section should tell the contributor what to **do**
- **Real commands**: all code blocks must contain working commands for this project
- **Project-specific**: tailor to the actual tools — don't mention tools not in use
- **Progressive disclosure**: setup first, advanced workflows later
- **No gatekeeping language**: welcome newcomers, don't make contributing feel scary

---

## Phase 4: Output

Deliver both documents as complete, copy-pasteable markdown. Format:

```
## README.md

[complete readme content]

---

## CONTRIBUTING.md

[complete contributing content]
```

If the user wants the content written directly to files (using file tools), do so.
Clearly mark any `[TODO: fill in]` items so the developer knows what still needs
their attention.

---

## Reference Files

- `examples/readme-example.md` — Full worked README for a TypeScript/Node.js project
- `examples/contributing-example.md` — Full worked CONTRIBUTING.md example

---

## Quality Checklist (self-review before responding)

### README
- [ ] Project name and description are accurate and specific (no placeholders)
- [ ] All code blocks contain real, working commands
- [ ] Badges link to real CI/tooling in the repo
- [ ] Quick Start can be followed start-to-finish without prior context
- [ ] No invented features, directories, or configuration that doesn't exist
- [ ] `[TODO: fill in]` markers placed where info is missing

### CONTRIBUTING.md
- [ ] Development setup uses the real toolchain commands
- [ ] Branching and commit conventions match the repo's actual practice
- [ ] Test commands are correct for this project
- [ ] PR checklist reflects the repo's actual CI checks
- [ ] Tone matches the project's audience (open source vs. internal)
- [ ] `[TODO: fill in]` markers placed where info is missing
