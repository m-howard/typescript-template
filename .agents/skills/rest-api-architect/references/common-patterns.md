# Common REST API Patterns

## Pagination Envelopes

### Cursor-Based (recommended for feeds and large datasets)
```json
{
  "data": [ ...items ],
  "meta": {
    "next_cursor": "eyJpZCI6MTAwfQ==",
    "has_more": true,
    "limit": 20
  }
}
```
Request: `GET /v1/posts?cursor=eyJpZCI6MTAwfQ==&limit=20`
- Cursor is opaque to client (base64-encoded internal state)
- Stable under concurrent inserts
- Cannot jump to arbitrary page

### Offset-Based (acceptable for admin UIs and bounded datasets)
```json
{
  "data": [ ...items ],
  "meta": {
    "total": 482,
    "page": 3,
    "page_size": 20,
    "total_pages": 25
  }
}
```
Request: `GET /v1/users?page=3&page_size=20&sort=created_at:desc`

---

## Auth Flows

### JWT Bearer (recommended)
- Login: `POST /v1/auth/sessions` → returns `{ access_token, refresh_token, expires_in }`
- Refresh: `POST /v1/auth/sessions/refresh` → returns new `access_token`
- Logout: `DELETE /v1/auth/sessions` (invalidates refresh token)
- All protected routes: `Authorization: Bearer <access_token>`

### Scope Model (for multi-role APIs)
Define scopes as `resource:action`:
- `users:read` — read any user profile
- `users:write` — create/update users
- `admin:*` — full access
Tokens carry a `scopes` claim; endpoints declare required scopes.

---

## Upsert vs Create

### Create (POST) — generates new resource
```
POST /v1/likes
Body: { "post_id": "uuid" }
Response: 201 Created | 409 Conflict (already exists)
```

### Upsert (PUT) — idempotent toggle or set
```
PUT /v1/posts/{postId}/like
Body: { "value": true }  // or just empty body for toggle
Response: 200 OK (with current state)
Idempotency: safe to call multiple times
```
Use upsert for: likes, follows, bookmarks, votes, feature flags.

---

## Soft Delete Pattern
```
DELETE /v1/posts/{id}
Response: 204 No Content

# Record gains: deleted_at: ISO8601, is_deleted: true
# Not returned in normal list queries
# Accessible to admins via ?include_deleted=true
```

---

## File Upload Pattern
Two-step upload (recommended over multipart for large files):

**Step 1** — Request upload URL:
```
POST /v1/uploads
Body: { "filename": "avatar.jpg", "content_type": "image/jpeg", "size_bytes": 204800 }
Response 200: { "upload_id": "uuid", "upload_url": "https://storage.../presigned", "expires_at": "..." }
```

**Step 2** — Client PUTs directly to `upload_url`, then notifies API:
```
POST /v1/uploads/{uploadId}/complete
Response 200: { "url": "https://cdn.example.com/avatars/uuid.jpg" }
```

---

## Bulk Operations
For batch reads or writes:
```
POST /v1/users/batch
Body: { "ids": ["uuid1", "uuid2", "uuid3"] }
Response 200: { "data": [...users], "not_found": ["uuid3"] }
```
- Max batch size should be documented (e.g., 100 items)
- Partial success: return what was found, report missing IDs

---

## Versioning Strategy

### URL Versioning (recommended)
`/v1/`, `/v2/` — simple, explicit, cacheable

### Breaking vs Non-Breaking Changes
**Non-breaking** (no version bump needed):
- Adding optional request fields
- Adding response fields
- Adding new endpoints

**Breaking** (requires new version):
- Removing or renaming fields
- Changing field types
- Changing status codes
- Removing endpoints

---

## ETag / Optimistic Concurrency

### Server sends:
```
GET /v1/documents/123
Response Headers:
  ETag: "a3f8b2"
  Cache-Control: no-cache
```

### Client updates with version check:
```
PUT /v1/documents/123
Request Headers:
  If-Match: "a3f8b2"
Body: { ...updated fields }

Success: 200 OK, new ETag: "b4c9d1"
Stale:   412 Precondition Failed
```

Use ETags for: documents, profile settings, any resource with concurrent editors.