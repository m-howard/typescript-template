---
name: eks-kubectl-debug
description: >
    Use this skill when the user wants to debug, diagnose, or troubleshoot Kubernetes workloads
    running on Amazon EKS using kubectl. Trigger when the user describes problems like pods not
    starting, services unreachable, nodes not ready, deployments stuck, OOMKilled containers,
    CrashLoopBackOff errors, ImagePullBackOff errors, permission denied errors, or any other
    Kubernetes/EKS operational issue. Also trigger on phrases like "my pod won't start",
    "debug my EKS cluster", "why is my deployment failing", "kubectl troubleshoot",
    "investigate Kubernetes issue", "EKS node not ready", or "diagnose my workload".
    Always use this skill before recommending infrastructure changes for runtime issues.
---

# EKS Kubernetes Debugging Skill

A structured, step-by-step approach for diagnosing and resolving issues in Kubernetes workloads
running on Amazon EKS using `kubectl` and AWS CLI tooling.

---

## Overview

This skill guides you through a systematic debugging workflow:

```
Phase 1: Gather Context
Phase 2: Identify Issue Category
Phase 3: Run Targeted Diagnostics
Phase 4: Analyze Findings
Phase 5: Propose & Validate Remediation
```

Read `references/kubectl-commands.md` for a quick-reference command cheatsheet.
Read `references/eks-specifics.md` for EKS-specific diagnostics (IAM, nodegroups, VPC CNI, add-ons).

---

## Phase 1: Gather Context

Before running any commands, ask the user for the following (combine into a single message):

**Required:**

- What is the symptom? (e.g., pod not starting, service unreachable, high latency, crash)
- What is the **namespace** and **workload name** (Deployment, StatefulSet, DaemonSet, Job)?
- What **EKS cluster** (name and region) and **Kubernetes version** are in use?
- When did the problem start? Did anything change recently (deployment, config, scaling event)?
- What have you already tried?

**Optional but valuable:**

- Does the issue affect all replicas or only some?
- Is the cluster behind a private endpoint or public?
- Are there any recent AWS events (spot interruptions, maintenance, quota changes)?
- What IAM role is being used (node instance role, IRSA, kube2iam)?

Once enough context is collected, confirm the scope and move to Phase 2.

---

## Phase 2: Identify Issue Category

Map the symptom to one of the following categories to focus diagnostics:

| Category                 | Symptoms                                              | Go To     |
| ------------------------ | ----------------------------------------------------- | --------- |
| **Pod Scheduling**       | Pending, Unschedulable                                | Phase 3-A |
| **Container Startup**    | CrashLoopBackOff, Error, OOMKilled                    | Phase 3-B |
| **Image Pull**           | ImagePullBackOff, ErrImagePull                        | Phase 3-C |
| **Networking / Service** | Service unreachable, connection refused, DNS failure  | Phase 3-D |
| **Node Health**          | NotReady, disk/memory/PID pressure, node draining     | Phase 3-E |
| **RBAC / Permissions**   | Forbidden, Unauthorized, aws-auth mapping             | Phase 3-F |
| **Resource Limits**      | OOMKilled, CPU throttling, quota exceeded             | Phase 3-G |
| **Configuration**        | Missing ConfigMap/Secret, wrong env vars, wrong mount | Phase 3-H |
| **EKS-Specific**         | Add-on failure, VPC CNI, nodegroup issue, IRSA        | Phase 3-I |

If the category is unclear, start with Phase 3-A and work down.

---

## Phase 3: Targeted Diagnostics

### Phase 3-A: Pod Scheduling (Pending / Unschedulable)

```bash
# Describe the pod — look for Events section
kubectl describe pod <pod-name> -n <namespace>

# Check node capacity and available resources
kubectl get nodes -o wide
kubectl describe nodes | grep -A 10 "Allocated resources"

# Check if there are taints blocking scheduling
kubectl get nodes -o json | jq '.items[].spec.taints'

# Check node selectors / affinity on the pod spec
kubectl get pod <pod-name> -n <namespace> -o yaml | grep -A 20 "affinity\|nodeSelector\|tolerations"

# Check PodDisruptionBudgets blocking eviction / scaling
kubectl get pdb -n <namespace>

# Check ResourceQuota limits in the namespace
kubectl describe resourcequota -n <namespace>
```

**Look for:**

- `Insufficient cpu/memory` → nodes are full; scale nodegroup or right-size requests
- `no nodes matched node selector` → fix nodeSelector or node labels
- `node(s) had taints that the pod didn't tolerate` → add tolerations or remove taint
- `exceeded quota` → raise quota or reduce requests

---

### Phase 3-B: Container Startup (CrashLoopBackOff / Error / OOMKilled)

```bash
# Check pod status and recent events
kubectl describe pod <pod-name> -n <namespace>

# Get current container logs
kubectl logs <pod-name> -n <namespace> --tail=100

# Get logs from the PREVIOUS (crashed) container instance
kubectl logs <pod-name> -n <namespace> --previous --tail=200

# For multi-container pods, specify container name
kubectl logs <pod-name> -c <container-name> -n <namespace> --previous

# Check exit code — OOMKilled = 137, general crash = non-zero
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.status.containerStatuses[*].lastState.terminated}'

# Run a debug container alongside the crashing pod (K8s 1.23+)
kubectl debug -it <pod-name> -n <namespace> --image=busybox --share-processes --copy-to=debug-pod
```

**Look for:**

- Exit code `137` / reason `OOMKilled` → increase memory limit (Phase 3-G)
- Exit code `1` or `2` → application error; read logs carefully
- `exec format error` → wrong container image architecture (arm64 vs amd64)
- Liveness probe failure → misconfigured probe; check `failureThreshold` and `initialDelaySeconds`

---

### Phase 3-C: Image Pull Failures (ImagePullBackOff / ErrImagePull)

```bash
# Describe the pod to see the exact pull error message
kubectl describe pod <pod-name> -n <namespace>

# Check imagePullSecrets configured on the pod
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.imagePullSecrets}'

# Verify the secret exists in the correct namespace
kubectl get secret <secret-name> -n <namespace>

# Check ECR login status (for AWS ECR images)
aws ecr describe-repositories --region <region>
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com

# Verify node IAM role has ECR pull permissions
aws iam list-attached-role-policies --role-name <node-role-name>
```

**Look for:**

- `unauthorized` or `403` → node IAM role missing `ecr:GetAuthorizationToken` and `ecr:BatchGetImage`
- `manifest unknown` → image tag does not exist in registry
- `no such host` → DNS resolution failure on the node; check CoreDNS (Phase 3-D)
- Private registry → ensure `imagePullSecret` is set and correct

---

### Phase 3-D: Networking / Service Issues

```bash
# Check service endpoints — empty endpoints means no healthy pods match selector
kubectl get endpoints <service-name> -n <namespace>
kubectl describe service <service-name> -n <namespace>

# Verify pod labels match service selector
kubectl get pods -n <namespace> --show-labels
kubectl get service <service-name> -n <namespace> -o jsonpath='{.spec.selector}'

# Test DNS resolution from inside the cluster
kubectl run dns-test --image=busybox:1.36 --restart=Never -it --rm -- nslookup <service-name>.<namespace>.svc.cluster.local

# Test connectivity to a service from inside the cluster
kubectl run curl-test --image=curlimages/curl:8.7.1 --restart=Never -it --rm -- curl -v http://<service-name>.<namespace>.svc.cluster.local:<port>

# Check CoreDNS health
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

# Check NetworkPolicies that may be blocking traffic
kubectl get networkpolicy -n <namespace>
kubectl describe networkpolicy -n <namespace>

# Check AWS Security Groups and NACLs for the node VPC (EKS-specific)
aws ec2 describe-security-groups --group-ids <node-sg-id>
```

**Look for:**

- Empty `Endpoints` list → selector mismatch or pods not Ready
- DNS NXDOMAIN → CoreDNS misconfiguration or pod identity issue
- `Connection refused` → wrong port, app not listening, or NetworkPolicy blocking
- AWS-specific: check Security Group rules allow traffic between node groups and pods

---

### Phase 3-E: Node Health (NotReady / Pressure Conditions)

```bash
# Overall node status
kubectl get nodes -o wide

# Detailed node conditions (look for MemoryPressure, DiskPressure, PIDPressure, NotReady)
kubectl describe node <node-name>

# Check node-level system logs via AWS Systems Manager (SSM)
aws ssm start-session --target <instance-id>

# List all pods on the affected node (to identify noisy neighbors)
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node-name>

# Drain the node for maintenance (non-destructive — pods are rescheduled)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --grace-period=60

# Check nodegroup status in EKS console or CLI
aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>

# Check for spot interruption notices (if using Spot instances)
aws ec2 describe-spot-instance-requests --filter "Name=instance-id,Values=<instance-id>"
```

**Look for:**

- `DiskPressure` → clean up unused images/logs on node; consider larger EBS volumes
- `MemoryPressure` → eviction of low-priority pods; right-size workloads or scale out
- `NotReady` after AWS event → check nodegroup lifecycle, EC2 instance health, SSM agent logs
- Spot interruption → ensure PodDisruptionBudgets and topologySpreadConstraints are set

---

### Phase 3-F: RBAC / Permissions (Forbidden / Unauthorized)

```bash
# Test what a given service account can do
kubectl auth can-i list pods --as=system:serviceaccount:<namespace>:<sa-name> -n <namespace>
kubectl auth can-i get secrets --as=system:serviceaccount:<namespace>:<sa-name> -n <namespace>

# Describe roles and bindings in namespace
kubectl get roles,rolebindings -n <namespace>
kubectl describe rolebinding <binding-name> -n <namespace>

# Describe cluster-wide roles
kubectl get clusterroles,clusterrolebindings | grep <sa-name>

# Check IRSA annotation on service account (EKS-specific)
kubectl describe serviceaccount <sa-name> -n <namespace>

# Verify IRSA trust policy for the IAM role
aws iam get-role --role-name <role-name>
aws iam list-role-policies --role-name <role-name>

# Check aws-auth ConfigMap for node/user mappings (legacy)
kubectl get configmap aws-auth -n kube-system -o yaml

# Check EKS Access Entries (API-based auth, EKS 1.29+)
aws eks list-access-entries --cluster-name <cluster-name>
aws eks describe-access-entry --cluster-name <cluster-name> --principal-arn <arn>
```

**Look for:**

- `cannot get resource "pods"` → missing Role or ClusterRole binding
- IRSA not working → check OIDC provider is associated with cluster, trust policy `Condition` matches SA
- `aws-auth` user not found → add IAM user/role mapping to `aws-auth` ConfigMap or use EKS Access Entries
- `401 Unauthorized` → expired credentials or wrong context; re-run `aws eks update-kubeconfig`

---

### Phase 3-G: Resource Limits (OOMKilled / CPU Throttling)

```bash
# Check current resource requests and limits for all pods in namespace
kubectl get pods -n <namespace> -o custom-columns=\
"NAME:.metadata.name,CPU-REQ:.spec.containers[*].resources.requests.cpu,\
MEM-REQ:.spec.containers[*].resources.requests.memory,\
CPU-LIM:.spec.containers[*].resources.limits.cpu,\
MEM-LIM:.spec.containers[*].resources.limits.memory"

# View live resource usage (requires metrics-server)
kubectl top pods -n <namespace>
kubectl top nodes

# Describe namespace ResourceQuota
kubectl describe resourcequota -n <namespace>

# Describe LimitRange defaults
kubectl describe limitrange -n <namespace>

# Get OOMKill events from recent pod history
kubectl get events -n <namespace> --field-selector reason=OOMKilling --sort-by='.lastTimestamp'
```

**Look for:**

- `OOMKilled` repeatedly → increase `resources.limits.memory`; check for memory leaks in app
- CPU throttling (not a crash but high latency) → increase `resources.limits.cpu` or use VPA
- Quota exceeded → coordinate with cluster admin to raise namespace quota
- No `requests` set → pods may be placed on already-full nodes; always set requests

---

### Phase 3-H: Configuration Issues (Missing ConfigMap / Secret / Env Vars)

```bash
# Check environment variables injected into the pod
kubectl exec -it <pod-name> -n <namespace> -- env | sort

# Check volume mounts and whether they resolved
kubectl describe pod <pod-name> -n <namespace> | grep -A 20 "Volumes\|Mounts"

# Verify ConfigMap exists and has expected keys
kubectl get configmap <cm-name> -n <namespace> -o yaml

# Verify Secret exists (values are base64 — do not print in shared sessions)
kubectl get secret <secret-name> -n <namespace>
kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data}' | jq 'keys'

# Check ExternalSecrets / Secrets Store CSI Driver sync status (if using)
kubectl get externalsecret -n <namespace>
kubectl describe secretproviderclass <name> -n <namespace>
```

**Look for:**

- `CreateContainerConfigError` → referenced ConfigMap or Secret does not exist in that namespace
- Wrong env var value → check if value comes from ConfigMap key vs literal
- Secret not synced → External Secrets Operator or CSI driver error; check operator pods

---

### Phase 3-I: EKS-Specific Issues

Read `references/eks-specifics.md` for full detail. Quick checks:

```bash
# EKS cluster status and version
aws eks describe-cluster --name <cluster-name> --region <region>

# Check all EKS-managed add-on statuses
aws eks list-addons --cluster-name <cluster-name>
aws eks describe-addon --cluster-name <cluster-name> --addon-name <addon-name>

# VPC CNI health (most common EKS networking issue)
kubectl get pods -n kube-system -l k8s-app=aws-node
kubectl describe daemonset aws-node -n kube-system
kubectl logs -n kube-system -l k8s-app=aws-node --tail=50

# Check available IPs in subnets (ENI exhaustion)
aws ec2 describe-subnets --subnet-ids <subnet-id> \
  --query 'Subnets[*].{ID:SubnetId,AvailableIPs:AvailableIpAddressCount}'

# Kube-proxy health
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=30

# CoreDNS health
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl describe configmap coredns -n kube-system
```

**Look for:**

- Add-on in `DEGRADED` or `UPDATE_FAILED` state → update or reinstall add-on via EKS console/CLI
- VPC CNI `aws-node` crashlooping → insufficient ENI permissions on node IAM role
- Subnet IP exhaustion → expand subnet CIDR or enable prefix delegation on VPC CNI
- CoreDNS ConfigMap misconfigured → restore default `Corefile`

---

## Phase 4: Analyze Findings

After running diagnostics, synthesize findings into a structured summary:

```
### Diagnosis Summary

**Root Cause**: [One-sentence description of the actual problem]
**Evidence**:
  - [Key log line, event, or kubectl output that confirms the issue]
  - [Supporting evidence]
**Category**: [e.g., Resource Limits / RBAC / Node Health]
**Scope**: [Affects all replicas / specific node / specific namespace]
**Urgency**: [P1 - service down / P2 - degraded / P3 - non-critical]
```

---

## Phase 5: Propose & Validate Remediation

For each confirmed root cause, propose a targeted fix:

### Fix Template

```
### Fix: [Short Title]

**Problem**: [What is broken and why]
**Action**: [Exact kubectl / AWS CLI commands or YAML changes required]
**Validation**: [How to confirm the fix worked]
**Rollback**: [How to undo the change if it makes things worse]
**Risk**: [Low / Medium / High — and why]
```

### Common Fixes

| Problem                      | Fix                                                             |
| ---------------------------- | --------------------------------------------------------------- |
| OOMKilled                    | Increase `resources.limits.memory` in pod spec; consider VPA    |
| CrashLoopBackOff (app error) | Fix application bug; check logs for specific error              |
| ImagePullBackOff (ECR)       | Attach `AmazonEC2ContainerRegistryReadOnly` to node IAM role    |
| Pod Pending (no nodes)       | Scale nodegroup via `aws eks update-nodegroup-config`           |
| Pod Pending (taint)          | Add `tolerations` to pod spec matching node taints              |
| Service unreachable          | Fix label selector; verify `targetPort` matches container port  |
| RBAC Forbidden               | Create Role + RoleBinding for service account                   |
| IRSA not working             | Verify OIDC provider ARN, trust policy condition, SA annotation |
| Node NotReady (spot)         | Terminate and replace; enable Cluster Autoscaler or Karpenter   |
| Subnet IP exhaustion         | Enable VPC CNI prefix delegation or expand CIDR                 |

### Validation Commands

```bash
# Watch pod status in real-time until stable
kubectl get pods -n <namespace> -w

# Confirm rollout completed successfully
kubectl rollout status deployment/<deployment-name> -n <namespace>

# Run a connectivity test after networking fix
kubectl run smoke-test --image=curlimages/curl:8.7.1 --restart=Never -it --rm \
  -- curl -f http://<service-name>.<namespace>.svc.cluster.local:<port>/healthz

# Re-check events for errors after applying changes
kubectl get events -n <namespace> --sort-by='.lastTimestamp' | tail -20
```

---

## Output Format

Produce a structured debug report for the user:

```markdown
## 🔍 EKS Debugging Report

### Context

- **Cluster**: [name / region / k8s version]
- **Workload**: [kind/name in namespace]
- **Symptom**: [what the user reported]

### Diagnostic Steps Taken

1. [Command run] → [Key finding]
2. [Command run] → [Key finding]

### Root Cause

[Clear, one-paragraph explanation]

### Evidence

- [Log snippet or kubectl output]

### Recommended Fix

[Exact commands or YAML changes, with explanation]

### Validation

[How to confirm it worked]

### Rollback Plan

[How to undo if needed]

### Prevention

[How to avoid this in future: monitoring, limits, alerts]
```

---

## Behavior Guidelines

- **Confirm before destructive actions** — never `kubectl delete`, `kubectl drain`, or scale down without explicit user approval
- **Namespace-scope by default** — always include `-n <namespace>` to avoid cross-namespace confusion
- **Do not print secrets** — use `jq 'keys'` or `--dry-run` instead of printing raw secret values
- **Prefer non-invasive first** — read logs and describe before exec'ing into pods
- **EKS context** — always verify `kubectl config current-context` matches the intended cluster
- **Escalate clearly** — if the issue requires AWS Support or is beyond kubectl scope, say so

---

## Quality Checklist

Before delivering the debug report, verify:

- [ ] Root cause is confirmed with evidence (not just a guess)
- [ ] All diagnostic commands used the correct namespace
- [ ] Fix is targeted (no unnecessary changes to unrelated resources)
- [ ] Validation steps are provided and runnable
- [ ] Rollback plan is included for any change with Medium or High risk
- [ ] No secret values were printed or shared
- [ ] EKS-specific considerations (IRSA, VPC CNI, add-ons) were checked if relevant
- [ ] Prevention / monitoring recommendation included
