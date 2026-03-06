# Pulumi Component Patterns

Reusable design patterns for common AWS infrastructure components in Pulumi TypeScript.

---

## Networking Components

### VpcComponent

**URN:** `aws:networking:VpcComponent`
**Stack layer:** `net-foundation`

**Key child resources:**
- `aws.ec2.Vpc` — primary VPC
- `aws.ec2.InternetGateway` — for public subnets
- `aws.ec2.EgressOnlyInternetGateway` — for IPv6 egress (optional)
- `aws.ec2.VpcDhcpOptions` — custom DNS settings (optional)
- `aws.ec2.VpcDhcpOptionsAssociation` — associate DHCP options

**Outputs:**
- `vpcId: pulumi.Output<string>`
- `vpcArn: pulumi.Output<string>`
- `internetGatewayId: pulumi.Output<string>`

**Design notes:**
- Always enable DNS resolution and DNS hostnames for ECS service discovery
- Reserve a `/16` CIDR minimum for production environments

---

### SubnetComponent

**URN:** `aws:networking:SubnetComponent`
**Stack layer:** `net-foundation`
**Dependencies:** `VpcComponent`

**Key child resources:**
- `aws.ec2.Subnet[]` — public, private, and data tier subnets across AZs
- `aws.ec2.RouteTable[]` — one per AZ for private subnets, one shared for public
- `aws.ec2.RouteTableAssociation[]` — subnet-to-route-table bindings
- `aws.ec2.NatGateway[]` — one per AZ for HA (prd), one shared for lower envs
- `aws.ec2.Eip[]` — elastic IPs for NAT gateways

**Outputs:**
- `publicSubnetIds: pulumi.Output<string[]>`
- `privateSubnetIds: pulumi.Output<string[]>`
- `dataSubnetIds: pulumi.Output<string[]>`
- `publicRouteTableId: pulumi.Output<string>`
- `privateRouteTableIds: pulumi.Output<string[]>`

**Design notes:**
- Use 3 tiers: public (ALB), private (application), data (RDS, ElastiCache)
- Use at least 2 AZs; use 3 AZs for production
- Size subnets to avoid future re-addressing: `/24` minimum per subnet per AZ

**Subnet CIDR allocation example for `10.0.0.0/16`:**

| Tier    | AZ-a          | AZ-b          | AZ-c          |
|---------|---------------|---------------|---------------|
| public  | 10.0.0.0/24   | 10.0.1.0/24   | 10.0.2.0/24   |
| private | 10.0.10.0/23  | 10.0.12.0/23  | 10.0.14.0/23  |
| data    | 10.0.20.0/24  | 10.0.21.0/24  | 10.0.22.0/24  |

---

### SecurityGroupComponent

**URN:** `aws:networking:SecurityGroupComponent`
**Stack layer:** `net-foundation`
**Dependencies:** `VpcComponent`

**Key child resources:**
- `aws.ec2.SecurityGroup` (ALB, application, database, cache — one each)
- `aws.vpc.SecurityGroupIngressRule[]`
- `aws.vpc.SecurityGroupEgressRule[]`

**Outputs:**
- `albSecurityGroupId: pulumi.Output<string>`
- `appSecurityGroupId: pulumi.Output<string>`
- `dbSecurityGroupId: pulumi.Output<string>`
- `cacheSecurityGroupId: pulumi.Output<string>`

**Design notes:**
- Use `aws.vpc.SecurityGroupIngressRule` / `EgressRule` (newer resources) instead of inline rules
  on `aws.ec2.SecurityGroup` to avoid Pulumi drift issues
- Application SG: allow inbound from ALB SG only — no direct internet access
- DB SG: allow inbound from app SG only on the DB port
- ALB SG: allow inbound 443 from `0.0.0.0/0` (and 80 for redirect)
- Default egress: allow all outbound from app SG (restrict further if compliance requires)

---

## Compute Components

### EcsClusterComponent

**URN:** `aws:compute:EcsClusterComponent`
**Stack layer:** `svc-platform`

**Key child resources:**
- `aws.ecs.Cluster`
- `aws.ecs.ClusterCapacityProviders` — Fargate and FARGATE_SPOT
- `aws.cloudwatch.LogGroup` — cluster-level container insights logs

**Outputs:**
- `clusterArn: pulumi.Output<string>`
- `clusterName: pulumi.Output<string>`

**Design notes:**
- Enable Container Insights for production environments
- Default to Fargate; add Fargate Spot for cost savings on non-critical workloads

---

### AlbComponent

**URN:** `aws:compute:AlbComponent`
**Stack layer:** `svc-platform`
**Dependencies:** `SubnetComponent`, `SecurityGroupComponent`

**Key child resources:**
- `aws.lb.LoadBalancer` — internet-facing ALB
- `aws.lb.Listener` — HTTPS (443), HTTP redirect to HTTPS (80)
- `aws.lb.TargetGroup` — default fixed-response or shared target group
- `aws.acm.Certificate` (optional — if managed here)

**Outputs:**
- `albArn: pulumi.Output<string>`
- `albDnsName: pulumi.Output<string>`
- `httpsListenerArn: pulumi.Output<string>`
- `httpListenerArn: pulumi.Output<string>`

**Design notes:**
- Always terminate TLS at the ALB; use ACM certificates
- HTTP listener should return 301 redirect to HTTPS, not serve traffic
- Enable access logs to S3 for audit and troubleshooting
- Use `ip` target type for Fargate (not `instance`)

---

### EcsServiceComponent

**URN:** `aws:compute:EcsServiceComponent`
**Stack layer:** `workload`
**Dependencies:** `EcsClusterComponent`, `AlbComponent`, `SubnetComponent`, `SecurityGroupComponent`

**Key child resources:**
- `aws.ecs.TaskDefinition` — Fargate task with container definitions
- `aws.ecs.Service` — desired count, network config, load balancer binding
- `aws.lb.TargetGroup` — per service
- `aws.lb.ListenerRule` — path or host-based routing rule on ALB listener
- `aws.iam.Role` — task execution role and task role (separate)
- `aws.iam.RolePolicy` — inline policies for task role permissions
- `aws.cloudwatch.LogGroup` — per service

**Outputs:**
- `serviceArn: pulumi.Output<string>`
- `taskDefinitionArn: pulumi.Output<string>`
- `targetGroupArn: pulumi.Output<string>`
- `taskRoleArn: pulumi.Output<string>`

**Design notes:**
- Always create separate execution role (pulls images, writes logs) and task role (app permissions)
- Never grant `*` actions in task role policies
- Use `awslogs` log driver for all containers
- Set `healthCheckGracePeriodSeconds` to at least 60 for services with slow startup
- Pin task definition revisions in production to control rollout

---

## Storage Components

### RdsComponent

**URN:** `aws:storage:RdsComponent`
**Stack layer:** `stateful-data`
**Dependencies:** `SubnetComponent`, `SecurityGroupComponent`

**Key child resources:**
- `aws.rds.SubnetGroup`
- `aws.rds.ParameterGroup`
- `aws.rds.Instance` (single-AZ dev/val) or `aws.rds.Cluster` + instances (Multi-AZ prd)
- `aws.secretsmanager.Secret` — master credentials
- `aws.secretsmanager.SecretVersion` — initial password

**Outputs:**
- `instanceEndpoint: pulumi.Output<string>` (or `clusterEndpoint`)
- `readerEndpoint: pulumi.Output<string>` (Aurora clusters)
- `port: pulumi.Output<number>`
- `credentialsSecretArn: pulumi.Output<string>`

**Design notes:**
- Use Secrets Manager for credentials; never pass passwords as plain Pulumi config
- Enable deletion protection in production (`deletionProtection: true`)
- Enable automated backups with at least 7-day retention for production
- Use `aws.rds.Cluster` (Aurora) for production for multi-AZ HA
- Encrypt at rest using KMS CMK

---

### S3BucketComponent

**URN:** `aws:storage:S3BucketComponent`
**Stack layer:** varies (often `stateful-data` or `svc-platform`)

**Key child resources:**
- `aws.s3.BucketV2`
- `aws.s3.BucketServerSideEncryptionConfigurationV2`
- `aws.s3.BucketVersioningV2`
- `aws.s3.BucketPublicAccessBlock`
- `aws.s3.BucketPolicy` (optional)
- `aws.s3.BucketLifecycleConfigurationV2` (optional)

**Outputs:**
- `bucketId: pulumi.Output<string>`
- `bucketArn: pulumi.Output<string>`
- `bucketDomainName: pulumi.Output<string>`

**Design notes:**
- Always block all public access unless the bucket is an intentional public asset bucket
- Always enable server-side encryption (SSE-S3 minimum; SSE-KMS for sensitive data)
- Enable versioning for buckets holding application state or Terraform/Pulumi state
- Use `aws.s3.BucketV2` (not deprecated `aws.s3.Bucket`) for new components

---

## IAM Patterns

### Task Execution Role (standard)

Every ECS task needs an execution role with at minimum:

```typescript
const executionRole = new aws.iam.Role(`${name}-exec-role`, {
    assumeRolePolicy: aws.iam.assumeRolePolicyForPrincipal({
        Service: 'ecs-tasks.amazonaws.com',
    }),
    managedPolicyArns: [
        'arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy',
    ],
    tags,
}, { parent: this });
```

Add additional inline policies only for:
- Reading secrets from Secrets Manager
- Reading parameters from SSM Parameter Store
- Decrypting with a specific KMS key

### Task Role (least-privilege)

```typescript
const taskRole = new aws.iam.Role(`${name}-task-role`, {
    assumeRolePolicy: aws.iam.assumeRolePolicyForPrincipal({
        Service: 'ecs-tasks.amazonaws.com',
    }),
    tags,
}, { parent: this });

// Add only required permissions as inline policies
new aws.iam.RolePolicy(`${name}-task-policy`, {
    role: taskRole.id,
    policy: pulumi.jsonStringify({
        Version: '2012-10-17',
        Statement: [
            {
                Effect: 'Allow',
                Action: ['s3:GetObject', 's3:PutObject'],
                Resource: [`${bucket.arn}/*`],
            },
        ],
    }),
}, { parent: this });
```

---

## Resource Naming Conventions

Use a consistent naming pattern across all resources:

```
{app-name}-{environment}-{component}-{resource-type}
```

Examples:
- `myapp-prd-vpc` (VPC)
- `myapp-prd-net-public-us-east-1a` (subnet)
- `myapp-prd-svc-ecs-cluster` (ECS cluster)
- `myapp-prd-svc-api-task-exec-role` (IAM role)

Implement as a helper:

```typescript
export const resourceName = (app: string, env: string, ...parts: string[]): string =>
    [app, env, ...parts].join('-');
```

---

## Component `parent` Option

Always pass `{ parent: this }` when creating child resources inside a `ComponentResource`:

```typescript
const vpc = new aws.ec2.Vpc(`${name}-vpc`, { ... }, { parent: this });
const igw = new aws.ec2.InternetGateway(`${name}-igw`, { ... }, { parent: this, dependsOn: [vpc] });
```

This ensures the Pulumi resource tree is correctly nested, and `pulumi destroy` removes children
before the parent component.
