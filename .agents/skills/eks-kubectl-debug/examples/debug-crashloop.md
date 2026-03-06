# Worked Example: Debugging a CrashLoopBackOff

This example walks through the full debugging workflow for a pod stuck in `CrashLoopBackOff`
on an EKS cluster.

---

## Scenario

**User report:** "My `api-server` deployment in the `production` namespace is stuck in
`CrashLoopBackOff`. It was working fine until we deployed a new version 30 minutes ago."

---

## Phase 1: Gather Context

- **Cluster:** `my-cluster` / `us-east-1` / Kubernetes 1.30
- **Workload:** `Deployment/api-server` in `production`
- **Symptom:** CrashLoopBackOff on all 3 replicas after a new image deployment
- **Recent changes:** New Docker image `my-ecr.dkr.ecr.us-east-1.amazonaws.com/api-server:v2.1.0`
- **Already tried:** Nothing yet

---

## Phase 2: Identify Issue Category

Symptom is `CrashLoopBackOff` → **Category: Container Startup (Phase 3-B)**

---

## Phase 3: Run Targeted Diagnostics

### Step 1 — Check pod status

```bash
kubectl get pods -n production -l app=api-server
```

Output:

```
NAME                          READY   STATUS             RESTARTS   AGE
api-server-6d9f8b7c4-kp2xw   0/1     CrashLoopBackOff   7          18m
api-server-6d9f8b7c4-m4nqr   0/1     CrashLoopBackOff   7          18m
api-server-6d9f8b7c4-t7vpl   0/1     CrashLoopBackOff   6          18m
```

All 3 replicas crashing — likely an application or config issue, not a node-specific problem.

### Step 2 — Describe one pod

```bash
kubectl describe pod api-server-6d9f8b7c4-kp2xw -n production
```

Relevant output in the `Events` section:

```
Events:
  Warning  BackOff    2m    kubelet  Back-off restarting failed container api-server
  Normal   Pulled     3m    kubelet  Successfully pulled image "api-server:v2.1.0"
  Normal   Started    3m    kubelet  Started container api-server
  Warning  Failed     3m    kubelet  Error: failed to start container
```

The image pulled successfully — so it's not an `ImagePullBackOff`. The container starts but
immediately crashes.

Also note the `Last State` in `Container Statuses`:

```
Last State:     Terminated
  Reason:       Error
  Exit Code:    1
  Started:      Thu, 06 Mar 2026 04:30:00 +0000
  Finished:     Thu, 06 Mar 2026 04:30:02 +0000
```

Exit code `1` = application error (not OOMKilled which would be `137`).

### Step 3 — Get logs from previous container

```bash
kubectl logs api-server-6d9f8b7c4-kp2xw -n production --previous --tail=50
```

Output:

```
2026-03-06T04:30:00Z INFO  Starting api-server v2.1.0
2026-03-06T04:30:00Z INFO  Loading configuration from environment
2026-03-06T04:30:01Z ERROR Configuration error: required environment variable DB_CONNECTION_STRING is not set
2026-03-06T04:30:02Z FATAL Exiting: cannot start without database connection
```

**Root cause identified:** The new image version `v2.1.0` requires a new environment variable
`DB_CONNECTION_STRING` that was not present in the existing deployment configuration.

### Step 4 — Verify existing environment variables

```bash
kubectl get deployment api-server -n production \
  -o jsonpath='{.spec.template.spec.containers[0].env}' | jq .
```

Output:

```json
[
    { "name": "APP_PORT", "value": "8080" },
    { "name": "LOG_LEVEL", "value": "info" },
    { "name": "DB_HOST", "value": "prod-db.cluster-abc.us-east-1.rds.amazonaws.com" }
]
```

Confirmed: `DB_CONNECTION_STRING` is missing. The `v2.1.0` app switched from individual
`DB_*` variables to a single connection string variable.

---

## Phase 4: Diagnosis Summary

```
### Diagnosis Summary

Root Cause: The api-server v2.1.0 image requires a new environment variable
  `DB_CONNECTION_STRING` that replaces the previous `DB_HOST` variable.
  The deployment was not updated before rolling out the new image.

Evidence:
  - Container logs show: "required environment variable DB_CONNECTION_STRING is not set"
  - Exit code 1 (clean application exit, not OOMKilled)
  - All 3 replicas crash within 2 seconds of starting
  - Image pull succeeded; crash is purely at application startup

Category: Configuration Issue / Container Startup
Scope: All replicas (deployment-wide)
Urgency: P1 — production service is fully down
```

---

## Phase 5: Remediation

### Option A — Add missing env var (preferred, forward-fix)

Retrieve the connection string from AWS Secrets Manager (where it is stored):

```bash
DB_CONN=$(aws secretsmanager get-secret-value \
  --secret-id prod/api-server/db-connection \
  --query SecretString --output text)
```

Patch the deployment to add `DB_CONNECTION_STRING` from a Secret:

```bash
# Create the Kubernetes Secret (if it doesn't exist)
kubectl create secret generic api-server-db-secret \
  --from-literal=DB_CONNECTION_STRING="$DB_CONN" \
  -n production

# Patch deployment to use the secret
kubectl patch deployment api-server -n production --patch '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "api-server",
          "env": [{
            "name": "DB_CONNECTION_STRING",
            "valueFrom": {
              "secretKeyRef": {
                "name": "api-server-db-secret",
                "key": "DB_CONNECTION_STRING"
              }
            }
          }]
        }]
      }
    }
  }
}'
```

### Option B — Roll back to v2.0.x (immediate mitigation)

```bash
kubectl rollout undo deployment/api-server -n production
kubectl rollout status deployment/api-server -n production
```

---

## Validation

```bash
# Watch pods stabilize
kubectl get pods -n production -l app=api-server -w

# Expected output after fix:
# api-server-7c8b9f6d4-abc12   1/1     Running   0          45s
# api-server-7c8b9f6d4-def34   1/1     Running   0          30s
# api-server-7c8b9f6d4-ghi56   1/1     Running   0          20s

# Confirm no more restarts
kubectl get pods -n production -l app=api-server \
  -o custom-columns="NAME:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount,STATUS:.status.phase"

# Smoke test the service
kubectl run smoke-test --image=curlimages/curl:8.7.1 --restart=Never -it --rm -n production \
  -- curl -sf http://api-server.production.svc.cluster.local:8080/healthz
```

---

## Debug Report

```markdown
## 🔍 EKS Debugging Report

### Context

- **Cluster**: my-cluster / us-east-1 / k8s 1.30
- **Workload**: Deployment/api-server in production (3 replicas)
- **Symptom**: CrashLoopBackOff on all replicas after deploying v2.1.0

### Diagnostic Steps Taken

1. `kubectl get pods` → All 3 replicas in CrashLoopBackOff, RESTARTS=6-7
2. `kubectl describe pod` → Image pulled successfully, exit code 1, clean crash in ~2s
3. `kubectl logs --previous` → "required environment variable DB_CONNECTION_STRING is not set"
4. `kubectl get deployment -o jsonpath env` → DB_CONNECTION_STRING absent from env vars

### Root Cause

The api-server v2.1.0 image refactored database configuration to use a single
`DB_CONNECTION_STRING` environment variable instead of individual `DB_HOST`, `DB_PORT`, etc.
variables. The deployment was not updated with the new variable before rolling out the image,
causing all pods to crash immediately at startup.

### Recommended Fix

1. Retrieve connection string from AWS Secrets Manager (`prod/api-server/db-connection`)
2. Create Kubernetes Secret `api-server-db-secret` in `production` namespace
3. Patch deployment to inject `DB_CONNECTION_STRING` from the secret
4. Monitor rollout until all pods reach Running state

### Validation

Watch `kubectl get pods -n production -w` until all pods show `1/1 Running` with 0 new restarts.
Run healthcheck: `curl http://api-server.production.svc.cluster.local:8080/healthz`

### Rollback Plan

`kubectl rollout undo deployment/api-server -n production` to immediately revert to v2.0.x
while the correct config is prepared.

### Prevention

- Add startup validation to the deployment pipeline: require a config review step
  when env var changes are detected in a new image
- Use a pre-deployment checklist that compares new image's required env vars against
  the existing deployment spec
- Add a readiness probe on /healthz so pods failing config validation never receive traffic
```

---

## Key Takeaways

1. **Always read `--previous` logs** — current logs may be empty if the container crashes instantly
2. **Exit code 1 ≠ OOMKilled** — OOMKilled is always exit code `137`
3. **All replicas crashing = config/image issue**, not a node issue
4. **Rollback first, fix forward** — for P1 incidents, roll back to restore service, then fix the config
5. **Store secrets in Secrets Manager, not env literals** — use secretKeyRef or External Secrets Operator
