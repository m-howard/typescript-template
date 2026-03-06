# Documentation Types Reference

This reference defines the purpose, structure, and guidance for each documentation type supported by the doc-writer skill.

---

## 1. README

**Purpose**: The front door of the project. Answers "What is this and how do I get started?"

**When to use**: Every project needs one. Update it whenever major features are added or changed.

**Audience**: Any new visitor — developer, user, or evaluator.

**Required sections**:

1. **Project name + one-line description**
2. **Badges** (CI status, coverage, version — only if relevant)
3. **Overview** — What does it do? What problem does it solve? (2–4 sentences)
4. **Prerequisites** — What must already be installed/configured?
5. **Installation / Quick Start** — Fewest steps to get it running
6. **Usage** — Most common use cases with code examples
7. **Configuration** — Key environment variables or config options (link to full reference if long)
8. **Contributing** — How to contribute (link to CONTRIBUTING.md if it exists)
9. **License**

**Anti-patterns to avoid**:

- Wall-of-text introduction before any setup instructions
- Missing prerequisites (assumes reader has everything installed)
- Code examples that are out of date or don't work
- Listing every possible option in the README (use a separate reference for that)

---

## 2. Getting Started Guide

**Purpose**: Takes a new user from zero to their first successful outcome in the shortest path possible.

**When to use**: When the README Quick Start isn't enough; when onboarding is complex.

**Audience**: Brand new users who have never used the project before.

**Structure**:

1. **Prerequisites checklist** — Exact versions required
2. **Installation steps** — Numbered, sequential, each producing a verifiable result
3. **Configuration** — Minimum required config to get running
4. **First Run** — Exact command(s) to run and expected output
5. **Verify it works** — How to confirm the setup succeeded
6. **Next Steps** — Links to deeper guides

**Key rules**:

- Every step must produce a visible, verifiable result
- If a step can fail, explain what failure looks like and how to recover
- Use exact commands, not paraphrases ("Run `npm install`", not "install your dependencies")
- Total time to complete must be realistic — state it at the top ("~10 minutes")

---

## 3. User Guide / How-To

**Purpose**: Task-focused documentation that teaches users how to accomplish specific goals.

**When to use**: For any non-trivial workflow that users will need to perform regularly.

**Audience**: Users who have already completed setup and need to do something specific.

**Structure per guide**:

1. **Title** — Begin with a verb ("Deploy to Production", "Configure Authentication", "Set Up Monitoring")
2. **Overview** — What this guide accomplishes in 1–2 sentences
3. **Prerequisites** — What must be true/done before starting
4. **Steps** — Numbered, with expected output after key steps
5. **Verification** — How to confirm success
6. **Troubleshooting** — 2–3 most common failure modes for this task
7. **Related Guides** — Links to adjacent how-tos

**Key rules**:

- One guide = one goal. Do not combine "Configure Auth AND set up monitoring" into one guide.
- Prerequisites must link to where they can be completed
- Never end a guide without a verification step

---

## 4. Reference Documentation

**Purpose**: Comprehensive, exhaustive listing of all options, parameters, commands, or flags.

**When to use**: When users need to look something up — not learn how to do something.

**Audience**: Experienced users who know what they want but need the exact syntax/options.

**Structure**:

````
## [Command / Option / Config Key]

**Type**: string | number | boolean | enum
**Default**: `value`
**Required**: Yes / No
**Description**: What this does.
**Valid values / range**: ...
**Example**:

​```yaml
option: value
​```
````

**Key rules**:

- Alphabetical ordering within sections
- Every option must have a default value or "none" stated explicitly
- Do not explain when to use something — that belongs in the User Guide
- Tables are preferred for large option sets

---

## 5. API Reference

**Purpose**: Complete documentation of all public API endpoints, methods, or interfaces.

**When to use**: When the project exposes a programmatic interface for other developers.

**Audience**: Developers integrating with or extending the system.

**Structure per endpoint/method**:

````
## [METHOD] /path/to/endpoint  (or: ClassName.methodName())

**Description**: What this does.
**Authentication**: Required / optional / none
**Parameters / Arguments**:
  - `paramName` (type, required/optional): Description
**Request Body** (if applicable): Schema with field descriptions
**Response**:
  - `200 OK` / success: Schema with field descriptions
  - `4xx` / error cases: What triggers them
**Example**:

​```bash
curl -X POST https://api.example.com/v1/resource \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"key": "value"}'
​```

**Example Response**:

​```json
{
  "id": "abc123",
  "status": "created"
}
​```
````

---

## 6. Troubleshooting Guide

**Purpose**: Help users diagnose and fix problems without contacting support.

**When to use**: When users commonly encounter errors or unexpected behavior.

**Audience**: Users who have already attempted something and it failed.

**Structure**:

```
## [Error message or symptom]

**Cause**: Why this happens.
**Solution**:
1. Step one
2. Step two

**Still not working?** [Link to next escalation path]
```

**Key rules**:

- Index by the exact error message users see, not by internal cause
- Every problem must have at least one actionable solution step
- Include "Still not working?" with a path to further help (GitHub Issues, Discord, email)
- Order by frequency (most common problems first)

---

## 7. Technical Overview / Architecture Doc

**Purpose**: Explains how the system works internally, for developers extending or operating it.

**When to use**: For complex systems where understanding the architecture is necessary to operate or extend it effectively.

**Audience**: Developers, operators, or contributors — not end users.

**Structure**:

1. **System Summary** — What it does at a high level (1 paragraph)
2. **Architecture Diagram** — Mermaid or ASCII diagram showing major components
3. **Component Descriptions** — One section per major component explaining its role
4. **Data Flow** — How data moves through the system for key operations
5. **Key Design Decisions** — Why major decisions were made (not implementation details)
6. **Operational Notes** — Scaling, failure modes, monitoring hooks

---

## 8. Changelog

**Purpose**: Communicates what changed between versions, for users and developers.

**When to use**: Every time a version is released.

**Format** (Keep a Changelog standard):

```markdown
# Changelog

## [Unreleased]

## [1.2.0] - 2025-01-15

### Added

- New feature X that does Y

### Changed

- Behavior of Z now works differently: [before] → [after]

### Fixed

- Bug where A caused B under condition C

### Removed

- Deprecated option `--old-flag` removed (use `--new-flag` instead)

### Security

- Patched CVE-XXXX-YYYY in dependency foo
```

**Key rules**:

- Every entry should describe the user-visible impact, not the code change
- Security fixes always get their own section
- Deprecated features must state the replacement
- Link to relevant PRs or issues where helpful
