# RFC 9457 Problem+JSON Reference

## Media Type
`Content-Type: application/problem+json`

## Required Fields
| Field | Type | Description |
|---|---|---|
| `type` | URI | A URI reference that identifies the problem type. Use a stable, human-readable URL. |
| `title` | string | Short, human-readable summary. Should not change between occurrences. |
| `status` | integer | HTTP status code. Must match the actual response status. |

## Optional Fields
| Field | Type | Description |
|---|---|---|
| `detail` | string | Human-readable explanation specific to this occurrence. |
| `instance` | URI | A URI reference identifying the specific occurrence (e.g., the request path). |

## Extensions
Add custom fields at the top level. Common extensions:

```json
{
  "type": "https://api.example.com/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "One or more fields failed validation.",
  "instance": "/v1/registrations",
  "errors": [
    {
      "field": "email",
      "code": "already_taken",
      "message": "This email is already registered."
    },
    {
      "field": "password",
      "code": "too_short",
      "message": "Password must be at least 8 characters."
    }
  ]
}
```

## Standard Problem Types

### 401 Unauthorized
```json
{
  "type": "https://api.example.com/errors/unauthorized",
  "title": "Unauthorized",
  "status": 401,
  "detail": "A valid Bearer token is required."
}
```

### 403 Forbidden
```json
{
  "type": "https://api.example.com/errors/forbidden",
  "title": "Forbidden",
  "status": 403,
  "detail": "You do not have permission to perform this action."
}
```

### 404 Not Found
```json
{
  "type": "https://api.example.com/errors/not-found",
  "title": "Not Found",
  "status": 404,
  "detail": "The requested resource does not exist.",
  "instance": "/v1/users/abc-123"
}
```

### 409 Conflict
```json
{
  "type": "https://api.example.com/errors/conflict",
  "title": "Conflict",
  "status": 409,
  "detail": "A user with this email already exists."
}
```

### 429 Rate Limited
```json
{
  "type": "https://api.example.com/errors/rate-limited",
  "title": "Too Many Requests",
  "status": 429,
  "detail": "Rate limit exceeded. Try again in 30 seconds."
}
```

## Rules
- `type` URIs should be stable and resolvable (ideally link to human-readable docs)
- Never use `"about:blank"` as type in production APIs — use specific error types
- The `errors` array extension is not part of the spec but is universally accepted for validation errors
- Always set `Content-Type: application/problem+json` — not `application/json`