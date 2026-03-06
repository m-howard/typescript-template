# kubectl Debugging Command Reference

Quick-reference cheatsheet for Kubernetes debugging with `kubectl`.

---

## Cluster & Context

```bash
# List and switch contexts
kubectl config get-contexts
kubectl config use-context <context-name>
kubectl config current-context

# Update kubeconfig for an EKS cluster
aws eks update-kubeconfig --name <cluster-name> --region <region>

# Cluster info
kubectl cluster-info
kubectl version --short
```

---

## Pods

```bash
# List pods with status
kubectl get pods -n <namespace> -o wide
kubectl get pods --all-namespaces

# Watch pod status in real-time
kubectl get pods -n <namespace> -w

# Describe pod (events, conditions, volumes, resources)
kubectl describe pod <pod-name> -n <namespace>

# Get pod YAML spec
kubectl get pod <pod-name> -n <namespace> -o yaml

# Logs — current
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --tail=100 -f

# Logs — previous (crashed) container
kubectl logs <pod-name> -n <namespace> --previous

# Logs — specific container in multi-container pod
kubectl logs <pod-name> -c <container-name> -n <namespace>

# Exec into a running container
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Exec into a specific container
kubectl exec -it <pod-name> -c <container-name> -n <namespace> -- /bin/bash

# Run a one-off debug pod (auto-deleted)
kubectl run debug-pod --image=busybox:1.36 --restart=Never -it --rm -n <namespace> -- sh

# Ephemeral debug container (K8s 1.23+, non-destructive)
kubectl debug -it <pod-name> -n <namespace> --image=busybox:1.36 --target=<container-name>

# Copy a crashing pod for debugging (adds debug container without killing original)
kubectl debug <pod-name> -n <namespace> --image=ubuntu:22.04 --copy-to=<pod-name>-debug -it
```

---

## Deployments & ReplicaSets

```bash
# Deployment status
kubectl get deployments -n <namespace>
kubectl describe deployment <name> -n <namespace>

# Watch rollout
kubectl rollout status deployment/<name> -n <namespace>

# View rollout history
kubectl rollout history deployment/<name> -n <namespace>

# Roll back to previous version
kubectl rollout undo deployment/<name> -n <namespace>

# Roll back to specific revision
kubectl rollout undo deployment/<name> -n <namespace> --to-revision=<N>

# Scale deployment
kubectl scale deployment <name> -n <namespace> --replicas=<N>

# Restart all pods in deployment (rolling)
kubectl rollout restart deployment/<name> -n <namespace>

# Check ReplicaSet for a deployment
kubectl get replicasets -n <namespace> -l app=<label>
```

---

## Services & Endpoints

```bash
# List services
kubectl get services -n <namespace>

# Describe service (selectors, ports, endpoints)
kubectl describe service <name> -n <namespace>

# Check if endpoints are populated (empty = no healthy pods matching selector)
kubectl get endpoints <name> -n <namespace>

# Port-forward service to local machine for testing
kubectl port-forward svc/<name> <local-port>:<service-port> -n <namespace>

# Port-forward a specific pod
kubectl port-forward pod/<pod-name> <local-port>:<container-port> -n <namespace>
```

---

## Nodes

```bash
# Node status and capacity
kubectl get nodes -o wide
kubectl describe node <node-name>

# Resource utilization (requires metrics-server)
kubectl top nodes
kubectl top pods -n <namespace>
kubectl top pods --all-namespaces --sort-by=memory

# List pods on a specific node
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node-name>

# Cordon — stop scheduling new pods on node
kubectl cordon <node-name>

# Drain node (evict all pods, cordon first)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --grace-period=60

# Uncordon — re-enable scheduling
kubectl uncordon <node-name>
```

---

## Events

```bash
# All events in namespace, sorted by time
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Filter events by reason
kubectl get events -n <namespace> --field-selector reason=OOMKilling
kubectl get events -n <namespace> --field-selector reason=BackOff
kubectl get events -n <namespace> --field-selector reason=Failed

# Watch events live
kubectl get events -n <namespace> -w
```

---

## ConfigMaps & Secrets

```bash
# List ConfigMaps
kubectl get configmaps -n <namespace>
kubectl describe configmap <name> -n <namespace>
kubectl get configmap <name> -n <namespace> -o yaml

# List Secrets (do NOT print values in shared sessions)
kubectl get secrets -n <namespace>
kubectl get secret <name> -n <namespace> -o jsonpath='{.data}' | jq 'keys'

# Decode a specific secret field safely (local use only)
kubectl get secret <name> -n <namespace> -o jsonpath='{.data.<key>}' | base64 --decode
```

---

## RBAC

```bash
# Check permissions for a service account
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa> -n <ns>
kubectl auth can-i --list --as=system:serviceaccount:<ns>:<sa> -n <ns>

# List roles and bindings
kubectl get roles,rolebindings -n <namespace>
kubectl get clusterroles,clusterrolebindings

# Describe a binding to see subjects
kubectl describe rolebinding <name> -n <namespace>
kubectl describe clusterrolebinding <name>
```

---

## Networking

```bash
# DNS test from inside the cluster
kubectl run dns-test --image=busybox:1.36 --restart=Never -it --rm -- \
  nslookup <service>.<namespace>.svc.cluster.local

# HTTP connectivity test
kubectl run curl-test --image=curlimages/curl:8.7.1 --restart=Never -it --rm -- \
  curl -v http://<service>.<namespace>.svc.cluster.local:<port>/

# NetworkPolicy list
kubectl get networkpolicy -n <namespace>
kubectl describe networkpolicy <name> -n <namespace>
```

---

## Resource Quotas & Limits

```bash
# Namespace quota usage
kubectl describe resourcequota -n <namespace>

# LimitRange defaults
kubectl describe limitrange -n <namespace>

# Resource requests/limits for all pods in namespace
kubectl get pods -n <namespace> \
  -o custom-columns="NAME:.metadata.name,\
CPU-REQ:.spec.containers[*].resources.requests.cpu,\
MEM-REQ:.spec.containers[*].resources.requests.memory,\
CPU-LIM:.spec.containers[*].resources.limits.cpu,\
MEM-LIM:.spec.containers[*].resources.limits.memory"
```

---

## Jobs & CronJobs

```bash
# Job status
kubectl get jobs -n <namespace>
kubectl describe job <name> -n <namespace>

# CronJob schedule and last run
kubectl get cronjobs -n <namespace>
kubectl describe cronjob <name> -n <namespace>

# Get pods created by a job
kubectl get pods -n <namespace> --selector=job-name=<job-name>
```

---

## StatefulSets & PersistentVolumes

```bash
# StatefulSet status
kubectl get statefulsets -n <namespace>
kubectl describe statefulset <name> -n <namespace>
kubectl rollout status statefulset/<name> -n <namespace>

# PersistentVolumeClaims
kubectl get pvc -n <namespace>
kubectl describe pvc <name> -n <namespace>

# PersistentVolumes (cluster-wide)
kubectl get pv
kubectl describe pv <name>
```

---

## Applying & Patching

```bash
# Dry-run apply (validate without applying)
kubectl apply -f <file>.yaml --dry-run=server

# Diff pending changes
kubectl diff -f <file>.yaml

# Apply with server-side apply
kubectl apply -f <file>.yaml --server-side

# Patch a resource (e.g., update image)
kubectl patch deployment <name> -n <namespace> \
  --patch '{"spec":{"template":{"spec":{"containers":[{"name":"<c>","image":"<new-image>"}]}}}}'

# Force rollout (bump annotation)
kubectl annotate deployment <name> -n <namespace> \
  kubectl.kubernetes.io/restartedAt="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --overwrite
```
