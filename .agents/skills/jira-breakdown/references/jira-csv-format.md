# Jira CSV Import Format

## Overview

Jira's CSV import requires specific column headers. This reference shows the exact format to produce an importable CSV.

## Required Columns

```csv
Issue Type,Summary,Description,Priority,Story Points,Labels,Epic Link,Epic Name,Sprint,Assignee,Reporter,Components,Fix Version,Affects Version,Custom field (Acceptance Criteria),Custom field (Blocked By),Custom field (Blocks)
```

## Column Definitions

| Column | Required | Values | Notes |
|--------|----------|--------|-------|
| `Issue Type` | Yes | Epic, Story, Task, Sub-task, Spike | Must match project issue types |
| `Summary` | Yes | Text (max 255 chars) | The ticket title |
| `Description` | No | Text (supports wiki markup) | Full description |
| `Priority` | No | Highest, High, Medium, Low, Lowest | Default: Medium |
| `Story Points` | No | Number | Maps to "Story Points" custom field |
| `Labels` | No | Comma-separated, no spaces | e.g., backend,api,auth |
| `Epic Link` | No | Epic issue key | For Stories/Tasks — links to parent Epic |
| `Epic Name` | No | Text | Only for Epic rows |
| `Sprint` | No | Sprint name | e.g., "Sprint 1 - Foundation" |
| `Assignee` | No | Username | Leave blank if unassigned |
| `Reporter` | No | Username | Defaults to importer |
| `Components` | No | Component name | Must exist in project |
| `Custom field (Acceptance Criteria)` | No | Text | May vary by Jira config |
| `Custom field (Blocked By)` | No | Issue key(s) | e.g., PROJ-1, PROJ-2 |
| `Custom field (Blocks)` | No | Issue key(s) | e.g., PROJ-5, PROJ-6 |

## Example CSV Output

```csv
Issue Type,Summary,Description,Priority,Story Points,Labels,Epic Link,Epic Name,Sprint
Epic,User Authentication System,"Complete authentication and session management system",High,,auth,,,
Story,User Registration Flow,"As a new user I want to register for an account so that I can access the platform. AC: Email validation, password requirements enforced, confirmation email sent",High,5,auth,USER-AUTH,,Sprint 1
Task,Registration API endpoint (POST /auth/register),"Implement registration endpoint with input validation and email verification trigger",High,3,backend api auth,USER-AUTH,,Sprint 1
Task,Email verification service,"Send verification email on registration, handle verification callback",Medium,2,backend email auth,USER-AUTH,,Sprint 1
Story,User Login Flow,"As a registered user I want to log in so that I can access my account",High,3,auth,USER-AUTH,,Sprint 2
Task,Login API endpoint (POST /auth/login),"JWT token generation, refresh token rotation, rate limiting",High,3,backend api auth,USER-AUTH,,Sprint 2
```

## Jira Wiki Markup for Descriptions

```
*bold*        → bold text
_italic_      → italic text  
-strikethrough-
{{monospace}}
h1. Heading 1
h2. Heading 2
* bullet item
# numbered item
|| header || header ||
| cell | cell |
{code}code block{code}
```

## Acceptance Criteria Format in CSV

Since CSV doesn't support checkboxes, format AC as:
```
AC: 1) User can upload JPG/PNG/GIF 2) File size limit of 5MB enforced 3) Error message shown on failure
```

## Dependency Notation

Jira CSV import handles "links" via a separate Links import or via the custom field approach. Two options:

**Option A — Custom fields (if configured):**
```csv
...,Custom field (Blocked By),Custom field (Blocks)
...,"PROJ-1, PROJ-2","PROJ-5, PROJ-6"
```

**Option B — Description-embedded (always works):**
Include in description:
```
*Dependencies:*
BLOCKED BY: PROJ-1 (Auth service), PROJ-2 (DB schema)  
BLOCKS: PROJ-5 (Frontend), PROJ-6 (Mobile)
```

## Import Instructions for Users

1. Go to your Jira project
2. Click **Project settings** → **Import issues** (or use Jira admin CSV import)
3. Upload the CSV file
4. Map columns to Jira fields in the wizard
5. Review and confirm import
6. After import, manually add "Link" relationships for dependencies if using Option B above