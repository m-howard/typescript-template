# EKS-Specific Debugging Reference

Guidance and commands specific to Amazon Elastic Kubernetes Service (EKS).

---

## Cluster Authentication & Context

```bash
# Generate/refresh kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region <region>

# Verify cluster connectivity
kubectl cluster-info
aws eks describe-cluster --name <cluster-name> --region <region> \
  --query 'cluster.{Status:status,Version:version,Endpoint:endpoint}'
```

---

## EKS Cluster Status

```bash
# Full cluster description
aws eks describe-cluster --name <cluster-name> --region <region>

# List all clusters in account
aws eks list-clusters --region <region>

# Check supported Kubernetes version
aws eks describe-addon-versions --region <region> | jq '.addons[].addonVersions[].compatibilities[].clusterVersion' | sort -u
```

---

## Managed Node Groups

```bash
# List nodegroups
aws eks list-nodegroups --cluster-name <cluster-name>

# Describe a nodegroup (status, instance types, capacity)
aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>

# Update nodegroup scaling config
aws eks update-nodegroup-config \
  --cluster-name <cluster-name> \
  --nodegroup-name <nodegroup-name> \
  --scaling-config minSize=<min>,maxSize=<max>,desiredSize=<desired>

# Check EC2 Auto Scaling Group behind the nodegroup
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <asg-name>

# Force replace all nodes (rolling update)
aws eks update-nodegroup-version \
  --cluster-name <cluster-name> \
  --nodegroup-name <nodegroup-name> \
  --force
```

### Common Nodegroup Issues

| Symptom                    | Likely Cause                                | Fix                                         |
| -------------------------- | ------------------------------------------- | ------------------------------------------- |
| Nodegroup `CREATE_FAILED`  | IAM role missing, subnet capacity exhausted | Check CloudFormation stack events           |
| Nodes not joining cluster  | aws-auth ConfigMap missing node role        | Add node IAM role to aws-auth               |
| Nodes joining but NotReady | VPC CNI issue, kubelet error                | Check `aws-node` and `kubelet` logs via SSM |
| Nodegroup update stuck     | Pod disruption budget blocking eviction     | Delete PDB or lower `minAvailable`          |

---

## EKS Managed Add-ons

```bash
# List installed add-ons
aws eks list-addons --cluster-name <cluster-name>

# Describe add-on (status, version, config)
aws eks describe-addon --cluster-name <cluster-name> --addon-name <addon-name>

# List available add-on versions
aws eks describe-addon-versions --addon-name <addon-name>

# Update add-on to latest recommended version
aws eks update-addon \
  --cluster-name <cluster-name> \
  --addon-name <addon-name> \
  --resolve-conflicts OVERWRITE

# Delete and reinstall a degraded add-on
aws eks delete-addon --cluster-name <cluster-name> --addon-name <addon-name>
aws eks create-addon --cluster-name <cluster-name> --addon-name <addon-name>
```

### Key Add-ons to Check

| Add-on               | Namespace                       | Pod Label                     | Common Issues                                       |
| -------------------- | ------------------------------- | ----------------------------- | --------------------------------------------------- |
| `vpc-cni`            | `kube-system`                   | `k8s-app=aws-node`            | ENI exhaustion, IPAMD crash, missing IAM perms      |
| `coredns`            | `kube-system`                   | `k8s-app=kube-dns`            | OOMKilled, misconfigured Corefile, too few replicas |
| `kube-proxy`         | `kube-system`                   | `k8s-app=kube-proxy`          | iptables rules stale, version mismatch              |
| `aws-ebs-csi-driver` | `kube-system`                   | `app=ebs-csi-controller`      | IRSA missing, PVC stuck in Pending                  |
| `aws-efs-csi-driver` | `kube-system`                   | `app=efs-csi-controller`      | Security group rules, mount target availability     |
| `adot`               | `opentelemetry-operator-system` | `app.kubernetes.io/name=adot` | Collector config error, IRSA                        |

---

## VPC CNI (aws-node) Debugging

The VPC CNI is responsible for assigning AWS ENI IP addresses to pods. It is the most common
source of EKS networking issues.

```bash
# Check aws-node DaemonSet health
kubectl get daemonset aws-node -n kube-system
kubectl get pods -n kube-system -l k8s-app=aws-node -o wide

# Read aws-node logs (look for ENI errors, IPAMD warnings)
kubectl logs -n kube-system -l k8s-app=aws-node --tail=100

# Check VPC CNI configuration
kubectl describe daemonset aws-node -n kube-system

# Get current VPC CNI environment variables (WARM_ENI_TARGET, MAX_ENI, etc.)
kubectl get daemonset aws-node -n kube-system \
  -o jsonpath='{.spec.template.spec.containers[0].env[*]}' | jq .

# Check available IPs per subnet
aws ec2 describe-subnets \
  --filters "Name=tag:kubernetes.io/cluster/<cluster-name>,Values=shared,owned" \
  --query 'Subnets[*].{ID:SubnetId,AZ:AvailabilityZone,AvailableIPs:AvailableIpAddressCount}'

# Enable prefix delegation (greatly increases pod density — EKS 1.21+)
kubectl set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true
kubectl set env daemonset aws-node -n kube-system WARM_PREFIX_TARGET=1
```

### IP Exhaustion Checklist

- [ ] Verify `/28` prefix delegation is not enabled on subnets with conflicting CIDRs
- [ ] Check subnet size — `/24` gives 251 usable IPs; each ENI attachment consumes IPs
- [ ] Consider using secondary CIDR block for pods (VPC CNI custom networking)
- [ ] Review `WARM_ENI_TARGET` and `MINIMUM_IP_TARGET` settings to avoid over-provisioning

---

## IAM Roles for Service Accounts (IRSA)

IRSA lets pods assume IAM roles without sharing node instance role permissions.

```bash
# Check if OIDC provider is associated with the cluster
aws eks describe-cluster --name <cluster-name> \
  --query 'cluster.identity.oidc.issuer' --output text

# List OIDC providers in account
aws iam list-open-id-connect-providers

# Check service account annotation
kubectl get serviceaccount <sa-name> -n <namespace> \
  -o jsonpath='{.metadata.annotations}'
# Expected: {"eks.amazonaws.com/role-arn": "arn:aws:iam::<account>:role/<role-name>"}

# Verify IAM role trust policy
aws iam get-role --role-name <role-name> \
  --query 'Role.AssumeRolePolicyDocument'
# Trust policy must contain the OIDC provider and Condition matching namespace/SA

# Check attached policies on the role
aws iam list-attached-role-policies --role-name <role-name>
aws iam list-role-policies --role-name <role-name>

# Test IRSA from inside a pod
kubectl exec -it <pod-name> -n <namespace> -- \
  aws sts get-caller-identity
```

### IRSA Trust Policy Template

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::<account-id>:oidc-provider/oidc.eks.<region>.amazonaws.com/id/<oidc-id>"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.<region>.amazonaws.com/id/<oidc-id>:sub": "system:serviceaccount:<namespace>:<sa-name>",
                    "oidc.eks.<region>.amazonaws.com/id/<oidc-id>:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
```

---

## aws-auth ConfigMap (Legacy IAM Mapping)

> **Note:** EKS 1.29+ supports API-based Access Entries. Prefer that over aws-auth for new clusters.

```bash
# View the current aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml

# Edit aws-auth (CAUTION: malformed YAML can lock you out)
kubectl edit configmap aws-auth -n kube-system
```

### aws-auth Structure

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
    name: aws-auth
    namespace: kube-system
data:
    mapRoles: |
        - rolearn: arn:aws:iam::<account>:role/<node-role>
          username: system:node:{{EC2PrivateDNSName}}
          groups:
              - system:bootstrappers
              - system:nodes
        - rolearn: arn:aws:iam::<account>:role/<admin-role>
          username: admin
          groups:
              - system:masters
    mapUsers: |
        - userarn: arn:aws:iam::<account>:user/<username>
          username: <username>
          groups:
              - system:masters
```

---

## EKS Access Entries (API-based Auth, EKS 1.29+)

```bash
# List access entries
aws eks list-access-entries --cluster-name <cluster-name>

# Describe an access entry
aws eks describe-access-entry \
  --cluster-name <cluster-name> \
  --principal-arn <iam-role-or-user-arn>

# Create a new access entry (replaces aws-auth for new principals)
aws eks create-access-entry \
  --cluster-name <cluster-name> \
  --principal-arn <iam-role-arn>

# Associate an access policy
aws eks associate-access-policy \
  --cluster-name <cluster-name> \
  --principal-arn <iam-role-arn> \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

---

## Cluster Autoscaler / Karpenter

```bash
# Cluster Autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler --tail=100

# Karpenter controller logs
kubectl logs -n kube-system -l app=karpenter --tail=100

# Check Karpenter NodePool and NodeClaim status
kubectl get nodepool
kubectl get nodeclaim
kubectl describe nodeclaim <name>

# Check pending pods that need to trigger scale-out
kubectl get pods --all-namespaces --field-selector status.phase=Pending
```

---

## Load Balancer Controller

```bash
# AWS Load Balancer Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=100

# Check Ingress and ALB status
kubectl get ingress --all-namespaces
kubectl describe ingress <name> -n <namespace>

# Check TargetGroupBinding
kubectl get targetgroupbinding -n <namespace>

# Verify IRSA for LBC
kubectl get serviceaccount aws-load-balancer-controller -n kube-system \
  -o jsonpath='{.metadata.annotations}'
```

---

## CloudWatch Container Insights

```bash
# Check if Container Insights is enabled
aws eks describe-addon --cluster-name <cluster-name> --addon-name amazon-cloudwatch-observability

# List CloudWatch log groups for the cluster
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/containerinsights/<cluster-name>" \
  --query 'logGroups[*].logGroupName'

# Query recent pod crash logs via CloudWatch Insights
aws logs start-query \
  --log-group-name "/aws/containerinsights/<cluster-name>/application" \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, log | filter log like /ERROR/ | sort @timestamp desc | limit 50'
```

---

## SSM Access to EKS Nodes

For node-level debugging when kubectl is insufficient:

```bash
# List running EC2 instances in a nodegroup
aws ec2 describe-instances \
  --filters "Name=tag:eks:nodegroup-name,Values=<nodegroup-name>" \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,IP:PrivateIpAddress}'

# Start SSM session (no SSH required, no bastion needed)
aws ssm start-session --target <instance-id>

# Run kubelet logs on node via SSM
aws ssm send-command \
  --instance-ids <instance-id> \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["journalctl -u kubelet --no-pager -n 200"]' \
  --query 'Command.CommandId'
```

---

## Security Groups for Pods

EKS supports assigning AWS Security Groups directly to individual pods using the
Security Groups for Pods feature.

```bash
# Check if Security Groups for Pods is enabled on VPC CNI
kubectl get daemonset aws-node -n kube-system \
  -o jsonpath='{.spec.template.spec.containers[0].env}' | \
  jq '.[] | select(.name=="ENABLE_POD_ENI")'

# List SecurityGroupPolicy resources
kubectl get securitygrouppolicy --all-namespaces
kubectl describe securitygrouppolicy <name> -n <namespace>
```

---

## Fargate Profiles (if using EKS Fargate)

```bash
# List Fargate profiles
aws eks list-fargate-profiles --cluster-name <cluster-name>

# Describe a profile (selectors, pod execution role)
aws eks describe-fargate-profile \
  --cluster-name <cluster-name> \
  --fargate-profile-name <profile-name>

# Fargate pod logs go to CloudWatch by default
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/eks/<cluster-name>/fargate"
```

---

## Useful AWS CLI Filters for EKS Debugging

```bash
# Find EC2 instances belonging to a cluster
aws ec2 describe-instances \
  --filters "Name=tag:eks:cluster-name,Values=<cluster-name>" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,AZ:Placement.AvailabilityZone}'

# Check CloudTrail for recent EKS API calls
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::EKS::Cluster \
  --start-time $(date -d '24 hours ago' --iso-8601=seconds) \
  --query 'Events[*].{Time:EventTime,Name:EventName,User:Username}' \
  --max-results 20
```
