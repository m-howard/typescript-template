# PRD Breakdown Patterns

## What Makes a Good PRD Issue

PRDs describe **user-facing behavior**. Issues derived from PRDs should always trace back to a user need.

## Extraction Map

| PRD Section | What to Extract | Issue Type |
|---|---|---|
| Goals / OKRs | Measurable outcomes → acceptance criteria | Epic-level success metrics |
| User Stories | Direct → Story issues | Stories |
| Non-goals | Explicit exclusions → add as "Out of scope" notes | Notes on related Epics |
| Functional Requirements | Each numbered req → 1 Story or Task | Stories / Tasks |
| Non-Functional Requirements | Performance, security, scale → Technical Tasks | Tasks |
| Open Questions | Each unresolved question → Spike | Spikes |
| Success Metrics | Tracking/analytics requirements → Tasks | Tasks |
| Milestones | Sprint boundaries | Sprint assignment |

## PRD Anti-Patterns to Catch

**Vague requirements** → Ask yourself: "Can a developer know when this is done?"
- BAD: "The UI should be responsive"
- GOOD TASK: "Implement responsive breakpoints at 768px and 1024px per design spec"

**Missing auth requirements** → Always check: does this feature need to know who the user is?
If yes, add a dependency on an auth task even if not stated in the PRD.

**Missing error states** → Every user-facing feature needs:
- [ ] Happy path (Task)
- [ ] Error states (Sub-task)
- [ ] Empty states (Sub-task)
- [ ] Loading states (Sub-task — if async)

## Story Point Anchors for PRD Work

```
1pt  → Copy change, label update, minor layout tweak
2pt  → New UI component (no logic), simple CRUD endpoint
3pt  → Feature with form validation, single integration
5pt  → Feature with multiple states, multiple API calls, complex logic
8pt  → Full feature with auth, permissions, multiple integrations, complex UX
```

## PRD-Specific Dependency Rules

1. **Analytics always depends on the feature it tracks** (analytics task blocked by feature task)
2. **Error monitoring setup blocks** all other tasks (can't validate features without observability)
3. **Permissions/roles always block** any feature with access control
4. **Data migrations always block** any feature reading that data

## Example: Extracting from a PRD Requirement

**PRD Text:**
> Users should be able to upload a profile photo. Photos should be resized to 200x200px. Users can remove their photo at any time.

**Extracted Issues:**

```
STORY: Profile Photo Management
  As a user, I want to upload and manage my profile photo
  so that my account feels personalized.
  
  AC:
  - [ ] User can upload JPG, PNG, GIF up to 5MB
  - [ ] Photo is automatically resized/cropped to 200x200px
  - [ ] User can remove their photo (reverts to default avatar)
  - [ ] Upload progress indicator shown
  - [ ] Error shown if file too large or wrong format
  
  Story Points: 5

  TASK: Photo Upload API endpoint (POST /users/:id/photo)
    - Accepts multipart form data
    - Validates file type and size
    - Returns signed URL or processed photo URL
    Story Points: 3
    BLOCKED BY: [Storage infrastructure task]
  
  TASK: Image Processing Service
    - Resize to 200x200px with center crop
    - Support JPG, PNG, GIF input
    - Output WebP + JPG fallback
    Story Points: 3
    BLOCKS: [Photo Upload API task]
  
  TASK: Photo Upload UI Component
    - Drag-and-drop + click-to-upload
    - Progress indicator
    - Error states
    - Remove photo button
    Story Points: 3
    BLOCKED BY: [Photo Upload API task]
  
  TASK: Default avatar system
    - Generate initials-based avatar when no photo set
    - Consistent across all surfaces
    Story Points: 2
```

## Common PRD Epic Patterns

### Authentication Epic
Always break into:
1. Registration flow
2. Login flow  
3. Password reset
4. Session management
5. OAuth providers (if applicable)

### Notification Epic
Always break into:
1. Notification data model
2. Trigger logic (what sends notifications)
3. Delivery mechanism (email/push/in-app)
4. User preferences
5. Notification center UI

### Search Epic
Always break into:
1. Indexing pipeline
2. Search API
3. Search UI (input + results)
4. Filters
5. Relevance tuning (often a Spike first)

### Settings / Profile Epic
Always break into:
1. Settings data model
2. Settings API (GET/PATCH)
3. Settings UI
4. Validation
5. Change history / audit (if required)