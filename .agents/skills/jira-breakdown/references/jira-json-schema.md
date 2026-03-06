# Jira JSON Schema for API Import

## Overview

Use this format when producing JSON output for programmatic Jira import via the REST API or for tooling integration.

## Top-Level Structure

```json
{
  "project": "PROJ",
  "issues": [
    { ... issue object ... }
  ],
  "links": [
    { ... link object ... }
  ],
  "metadata": {
    "generated_by": "jira-breakdown-skill",
    "source_document": "...",
    "generated_at": "ISO8601 timestamp",
    "total_story_points": 0,
    "sprint_count": 0
  }
}
```

## Issue Object Schema

```json
{
  "tempId": "EPIC-1",
  "type": "Epic | Story | Task | Sub-task | Spike",
  "summary": "Short title (max 255 chars)",
  "description": "Full markdown description",
  "acceptanceCriteria": [
    "Criterion 1",
    "Criterion 2"
  ],
  "priority": "Highest | High | Medium | Low | Lowest",
  "storyPoints": 3,
  "labels": ["backend", "api", "auth"],
  "epicLink": "EPIC-1",
  "epicName": "Only for Epic type",
  "sprint": "Sprint 1 - Foundation",
  "suggestedRole": "Backend Engineer | Frontend Engineer | Full-stack | DevOps | Design | PM",
  "parentTempId": "STORY-1",
  "timebox": "2 days",
  "spikeOutput": "Decision document"
}
```

## Link Object Schema

```json
{
  "from": "TASK-4",
  "to": "TASK-7",
  "type": "blocks | is blocked by | relates to | duplicates | clones"
}
```

Note: In Jira's model, `blocks` and `is blocked by` are inverses of the same link. You only need to define one direction:
- Use `"type": "blocks"` — the `from` issue blocks the `to` issue.

## Complete Example

```json
{
  "project": "AUTH",
  "issues": [
    {
      "tempId": "EPIC-1",
      "type": "Epic",
      "summary": "User Authentication System",
      "description": "Complete authentication, session management, and authorization system supporting email/password and OAuth providers.",
      "priority": "High",
      "labels": ["auth", "security", "foundation"],
      "epicName": "User Authentication System",
      "sprint": "Sprint 1 - Foundation",
      "suggestedRole": "Backend Engineer"
    },
    {
      "tempId": "SPIKE-1",
      "type": "Spike",
      "summary": "Evaluate OAuth provider options (Auth0 vs Cognito vs custom)",
      "description": "Research and evaluate OAuth/OIDC provider options. Assess: cost, compliance features, SDK quality, lock-in risk.",
      "priority": "High",
      "labels": ["auth", "spike", "research"],
      "epicLink": "EPIC-1",
      "sprint": "Sprint 1 - Foundation",
      "timebox": "2 days",
      "spikeOutput": "Decision document with recommendation and cost breakdown"
    },
    {
      "tempId": "TASK-1",
      "type": "Task",
      "summary": "Auth service infrastructure provisioning",
      "description": "Provision auth service infrastructure: container resources, environment secrets (JWT_SECRET, OAUTH_CLIENT_ID/SECRET), networking, and service discovery config.",
      "acceptanceCriteria": [
        "Service deployable to dev/staging/prod environments",
        "Secrets managed via secrets manager (not env files)",
        "Health check endpoint responds 200",
        "Logs flowing to centralized log aggregator"
      ],
      "priority": "High",
      "storyPoints": 3,
      "labels": ["auth", "infrastructure", "devops"],
      "epicLink": "EPIC-1",
      "sprint": "Sprint 1 - Foundation",
      "suggestedRole": "DevOps"
    },
    {
      "tempId": "TASK-2",
      "type": "Task",
      "summary": "User schema and auth database migrations",
      "description": "Design and implement database schema for users, sessions, refresh tokens, and OAuth provider links.",
      "acceptanceCriteria": [
        "Users table with: id, email (unique), password_hash, email_verified_at, created_at, updated_at",
        "Sessions table with: id, user_id, refresh_token_hash, expires_at, ip, user_agent",
        "OAuth providers table with: id, user_id, provider, provider_user_id",
        "Migration scripts are idempotent and reversible",
        "Indexes on email, provider+provider_user_id"
      ],
      "priority": "High",
      "storyPoints": 3,
      "labels": ["auth", "database", "backend"],
      "epicLink": "EPIC-1",
      "sprint": "Sprint 1 - Foundation",
      "suggestedRole": "Backend Engineer"
    },
    {
      "tempId": "STORY-1",
      "type": "Story",
      "summary": "User Registration Flow",
      "description": "As a new user, I want to register for an account so that I can access the platform.",
      "acceptanceCriteria": [
        "User can register with email and password",
        "Password must be 8+ chars with at least 1 uppercase, 1 number",
        "Email uniqueness enforced with clear error message",
        "Verification email sent after registration",
        "User cannot log in until email is verified",
        "Registration form has accessible labels and error messages"
      ],
      "priority": "High",
      "storyPoints": 5,
      "labels": ["auth", "registration", "backend", "frontend"],
      "epicLink": "EPIC-1",
      "sprint": "Sprint 2 - Auth Core",
      "suggestedRole": "Full-stack"
    }
  ],
  "links": [
    { "from": "SPIKE-1", "to": "TASK-1", "type": "blocks" },
    { "from": "TASK-1", "to": "TASK-2", "type": "blocks" },
    { "from": "TASK-2", "to": "STORY-1", "type": "blocks" }
  ],
  "metadata": {
    "generated_by": "jira-breakdown-skill",
    "source_document": "Auth System PRD v2.1",
    "generated_at": "2024-01-15T10:00:00Z",
    "total_story_points": 38,
    "sprint_count": 3,
    "critical_path": ["SPIKE-1", "TASK-1", "TASK-2", "STORY-1"]
  }
}
```

## Jira REST API Import Reference

```bash
# Create an Epic
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JIRA_TOKEN" \
  -d '{
    "fields": {
      "project": { "key": "PROJ" },
      "summary": "Epic title",
      "issuetype": { "name": "Epic" },
      "customfield_10014": "Epic Name Here"
    }
  }' \
  "https://your-org.atlassian.net/rest/api/3/issue"

# Add a link (after issues are created)
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JIRA_TOKEN" \
  -d '{
    "type": { "name": "Blocks" },
    "inwardIssue": { "key": "PROJ-5" },
    "outwardIssue": { "key": "PROJ-8" }
  }' \
  "https://your-org.atlassian.net/rest/api/3/issueLink"
```