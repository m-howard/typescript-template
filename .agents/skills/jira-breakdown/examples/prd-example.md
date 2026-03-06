# Example: PRD → Jira Breakdown

## Input Document: Notification Center PRD

> **Product Requirement Document: In-App Notification Center**
> Version: 1.2 | Author: Jane Smith | Status: Approved
>
> **Goal:** Give users a centralized place to view all platform notifications so they stop missing important updates and reduce reliance on email.
>
> **Non-goals:** Push notifications (mobile), SMS notifications, notification scheduling
>
> **User Story:** As a platform user, I want to see all my notifications in one place and mark them as read, so I don't miss anything important.
>
> **Functional Requirements:**
> 1. Bell icon in header shows unread notification count (badge)
> 2. Clicking bell opens notification panel with list of notifications
> 3. Notifications have: icon (by type), title, short description, timestamp, read/unread state
> 4. Users can mark individual notifications as read
> 5. Users can mark all notifications as read
> 6. Clicking a notification navigates to relevant content
> 7. Notifications auto-refresh every 30 seconds when panel is open
> 8. Notification types: Comment, Mention, Assignment, System Alert
>
> **Non-functional Requirements:**
> - Panel should open in <200ms
> - Unread count must be accurate within 30 seconds
> - Notifications must be stored for 90 days
>
> **Success Metrics:**
> - 70% of users open notification panel within 7 days of launch
> - Reduce notification-related support tickets by 40%
> - Avg time to first notification open < 30s after delivery
>
> **Open Questions:**
> - Real-time delivery via WebSocket or polling? (Engineering decision)
> - How many notifications to show in panel? Paginate or limit?

---

## Output: Complete Jira Breakdown

---

## 🗂️ EPIC: [EPIC-1] Notification Center
**Goal:** Give users a centralized, real-time view of all platform activity relevant to them, reducing missed updates.
**Labels:** notifications, engagement, q1-2024
**Estimated Size:** L (3 sprints)
**Dependencies:** None — this Epic is foundational

---

### 🔬 SPIKE: [SPIKE-1] Real-time delivery architecture decision
**Type:** Spike
**Parent Epic:** [EPIC-1]
**Goal:** Determine whether to use WebSockets, SSE, or polling for notification delivery. Evaluate: implementation complexity, infrastructure cost, browser compatibility, and reliability guarantees.
**Time-box:** 2 days
**Output:** Architecture decision record (ADR) with recommended approach and fallback strategy
**Story Points:** 5
**BLOCKS:** [TASK-1], [TASK-5] — delivery mechanism affects API and frontend design

---

### 🔬 SPIKE: [SPIKE-2] Pagination vs. windowed list for notification panel
**Type:** Spike
**Parent Epic:** [EPIC-1]
**Goal:** Define the right UX approach for displaying large notification volumes. Load more? Infinite scroll? Fixed 50-item list?
**Time-box:** 1 day
**Output:** UX recommendation with rationale; design mockup updated
**Story Points:** 3
**BLOCKS:** [STORY-3] — affects UI implementation

---

### 📖 STORY: [STORY-1] Notification Data Model & Storage
**Type:** Story
**Epic:** [EPIC-1]
**As a** backend system, **I want** a reliable notifications data model, **so that** all notification types can be stored, retrieved, and expired consistently.

**Acceptance Criteria:**
- [ ] Notifications table stores: id, user_id, type (enum), title, description, link_url, read_at (nullable), created_at
- [ ] Notification types enum: COMMENT, MENTION, ASSIGNMENT, SYSTEM_ALERT
- [ ] Index on (user_id, read_at) for unread count queries
- [ ] Index on (user_id, created_at DESC) for panel list queries
- [ ] Auto-deletion job removes notifications older than 90 days
- [ ] Migration scripts are reversible

**Story Points:** 5
**Suggested Role:** Backend Engineer
**Labels:** notifications, database, backend
**BLOCKED BY:** None (can start immediately)
**BLOCKS:** [STORY-2], [STORY-3], [STORY-4]

#### ✅ TASK: [TASK-1] Database schema + migrations for notifications
**Type:** Task
**Parent Story:** [STORY-1]
**Description:** Write and test database migration creating the notifications table, enums, and indexes. Include seed data for local development.

**Acceptance Criteria:**
- [ ] Migration creates notifications table with all fields
- [ ] Enum type created for notification_type
- [ ] Both indexes created
- [ ] Migration is reversible (down migration works)
- [ ] Seed script creates 1 notification of each type for dev user

**Story Points:** 3
**Suggested Role:** Backend Engineer
**BLOCKED BY:** None
**BLOCKS:** [TASK-2], [TASK-3]

---

#### ✅ TASK: [TASK-2] Notification cleanup job (90-day TTL)
**Type:** Task
**Parent Story:** [STORY-1]
**Description:** Scheduled job (cron) that deletes notifications older than 90 days. Should run nightly, be idempotent, log deletion counts.

**Acceptance Criteria:**
- [ ] Job runs on configurable schedule (default: nightly 2am)
- [ ] Deletes notifications where created_at < NOW() - 90 days
- [ ] Logs: how many deleted, duration, any errors
- [ ] Job is idempotent (safe to run multiple times)
- [ ] Unit tested with time-travel mock

**Story Points:** 2
**Suggested Role:** Backend Engineer
**BLOCKED BY:** [TASK-1]
**BLOCKS:** None

---

### 📖 STORY: [STORY-2] Notification Creation API
**Type:** Story
**Epic:** [EPIC-1]
**As a** platform service, **I want** to create notifications via an internal API, **so that** any part of the system can trigger notifications consistently.

**Acceptance Criteria:**
- [ ] Internal API endpoint: POST /internal/notifications
- [ ] Accepts: user_id, type, title, description, link_url
- [ ] Returns: notification_id, created_at
- [ ] Validates all required fields with meaningful error messages
- [ ] Idempotent: duplicate check prevents double-delivery within 5 minutes
- [ ] Emits `notification.created` event for real-time delivery layer

**Story Points:** 5
**Suggested Role:** Backend Engineer
**Labels:** notifications, api, backend
**BLOCKED BY:** [TASK-1]
**BLOCKS:** [STORY-3]

#### ✅ TASK: [TASK-3] POST /internal/notifications endpoint
**Type:** Task
**Parent Story:** [STORY-2]
**Description:** Internal (not user-facing) API endpoint for creating notifications. Other services call this to notify users of events.

**Acceptance Criteria:**
- [ ] Endpoint requires internal API key (not user JWT)
- [ ] Input validation with typed errors
- [ ] Idempotency key support (prevent duplicate notifications)
- [ ] Emits event to notification delivery queue after successful write
- [ ] Integration tested

**Story Points:** 3
**Suggested Role:** Backend Engineer
**BLOCKED BY:** [TASK-1]
**BLOCKS:** [TASK-4], [TASK-5]

#### ✅ TASK: [TASK-4] Wire notification triggers from existing services
**Type:** Task
**Parent Story:** [STORY-2]
**Description:** Add calls to POST /internal/notifications from the existing Comment, Mention, Assignment, and Alert services when relevant events occur.

**Acceptance Criteria:**
- [ ] Comment service calls notifications API when a comment is posted on user's content
- [ ] Mention service calls when user is @mentioned
- [ ] Assignment service calls when task/issue assigned to user
- [ ] System alert service calls for platform-level alerts
- [ ] Each call includes correct type, title, description, link_url

**Story Points:** 5
**Suggested Role:** Backend Engineer
**BLOCKED BY:** [TASK-3]
**BLOCKS:** None (parallel to frontend work)

---

### 📖 STORY: [STORY-3] Notification Panel UI
**Type:** Story
**Epic:** [EPIC-1]
**As a** user, **I want** to see my notifications in a panel when I click the bell icon, **so that** I can stay up to date without leaving the current page.

**Acceptance Criteria:**
- [ ] Bell icon in header with unread count badge (hidden when 0)
- [ ] Clicking bell opens panel (< 200ms, uses cached data)
- [ ] Panel shows notifications: icon by type, title, description, relative timestamp
- [ ] Unread notifications visually distinct from read ones
- [ ] Clicking notification marks it read and navigates to linked content
- [ ] "Mark all as read" button clears all unread state
- [ ] Panel closes on outside click or Escape key
- [ ] Empty state shown when no notifications
- [ ] Accessible (keyboard navigable, screen reader compatible)

**Story Points:** 8
**Suggested Role:** Frontend Engineer
**Labels:** notifications, frontend, ui
**BLOCKED BY:** [STORY-2], [SPIKE-1], [SPIKE-2]
**BLOCKS:** [STORY-4]

#### ✅ TASK: [TASK-5] Notification bell + badge component
**Type:** Task
**Parent Story:** [STORY-3]
**Description:** Header bell icon that shows unread notification count. Updates every 30 seconds (or on WebSocket push per SPIKE-1 outcome).

**Acceptance Criteria:**
- [ ] Bell icon in header, matches design system
- [ ] Red badge shows unread count (hidden when 0, shows "99+" when >99)
- [ ] Fetches unread count on mount and refreshes per SPIKE-1 recommendation
- [ ] Accessible: aria-label "X unread notifications"

**Story Points:** 3
**Suggested Role:** Frontend Engineer
**BLOCKED BY:** [SPIKE-1], [TASK-3]
**BLOCKS:** [TASK-6]

#### ✅ TASK: [TASK-6] Notification panel list + mark-as-read
**Type:** Task
**Parent Story:** [STORY-3]
**Description:** The dropdown panel showing the notification list with read/unread state management.

**Acceptance Criteria:**
- [ ] Panel opens below bell icon
- [ ] Lists notifications per pagination decision from SPIKE-2
- [ ] Each notification: type icon, title, description (truncated at 100 chars), relative time
- [ ] Unread: white background. Read: grey background
- [ ] Click row: PATCH /notifications/:id/read, then navigate to link_url
- [ ] "Mark all read" button: PATCH /notifications/read-all
- [ ] Loading skeleton shown while fetching
- [ ] Error state if fetch fails

**Story Points:** 5
**Suggested Role:** Frontend Engineer
**BLOCKED BY:** [TASK-5], [SPIKE-2]
**BLOCKS:** None

---

### 📖 STORY: [STORY-4] Notification Read API
**Type:** Story
**Epic:** [EPIC-1]
**As a** user, **I want** to mark notifications as read, **so that** my unread count stays accurate.

**Acceptance Criteria:**
- [ ] PATCH /notifications/:id/read — marks single notification as read
- [ ] PATCH /notifications/read-all — marks all user's notifications as read
- [ ] GET /notifications — returns paginated list (50 per page) for current user
- [ ] GET /notifications/unread-count — returns count for badge

**Story Points:** 3
**Suggested Role:** Backend Engineer
**Labels:** notifications, api, backend
**BLOCKED BY:** [TASK-1]
**BLOCKS:** [TASK-6]

---

### 📖 STORY: [STORY-5] Analytics & Observability
**Type:** Story
**Epic:** [EPIC-1]
**As a** product team, **I want** to track notification engagement metrics, **so that** we can validate success metrics and iterate.

**Acceptance Criteria:**
- [ ] Track: notification_panel_opened (user_id, session_id)
- [ ] Track: notification_clicked (user_id, notification_id, notification_type)
- [ ] Track: mark_all_read_clicked (user_id)
- [ ] Dashboard: % users opening panel, CTR by notification type, unread count distribution
- [ ] Alert: if notification delivery latency > 60s P95

**Story Points:** 3
**Suggested Role:** Full-stack / Data
**Labels:** notifications, analytics, observability
**BLOCKED BY:** [STORY-3] — must launch feature first
**BLOCKS:** None

---

## 🔗 Dependency Graph

```
SPIKE-1 (Real-time arch) ──┐
                            ├──blocks──► TASK-5 (Bell component)
TASK-1 (DB schema) ─────────┤            └──blocks──► TASK-6 (Panel UI)
  └──blocks──► TASK-3 (API) ┘
                └──blocks──► TASK-4 (Wire triggers)
                └──blocks──► STORY-4 (Read API) ──blocks──► TASK-6

SPIKE-2 (Pagination UX) ──────────────────blocks──► TASK-6

STORY-3 (Panel complete) ──blocks──► STORY-5 (Analytics)

Critical Path: TASK-1 → TASK-3 → TASK-5 → TASK-6
Parallel track: SPIKE-1 (must resolve before TASK-5)
Estimated Minimum Duration (critical path only): ~8 days
```

---

## 📅 Suggested Sprint Breakdown

### Sprint 1 — Foundation (start immediately)
- [SPIKE-1] Real-time delivery architecture decision (2 days)
- [SPIKE-2] Pagination UX decision (1 day)
- [TASK-1] Database schema + migrations (3 pts)
- [TASK-2] Notification cleanup job (2 pts)

### Sprint 2 — API Layer (after Sprint 1)
- [TASK-3] POST /internal/notifications endpoint (3 pts)
- [STORY-4] Read/list notification APIs (3 pts)
- [TASK-4] Wire notification triggers from existing services (5 pts)

### Sprint 3 — UI + Launch (after Sprint 2)
- [TASK-5] Bell + badge component (3 pts)
- [TASK-6] Notification panel + mark-as-read (5 pts)
- [STORY-5] Analytics tracking (3 pts)

**Total Story Points:** 38
**Estimated Velocity Needed:** ~13 pts/sprint (3 sprints)