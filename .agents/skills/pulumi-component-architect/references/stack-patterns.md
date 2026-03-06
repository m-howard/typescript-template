# Pulumi Stack Patterns

Multi-environment stack layouts, cross-stack reference strategies, and lifecycle management
patterns for Pulumi TypeScript projects.

---

## Standard Multi-Environment Stack Topology

This project uses a layered stack topology where each layer deploys independently and passes
outputs to dependent layers via Stack References or SSM Parameter Store.

```
acct-baseline (dev/val/prd)
    └── net-foundation (dev/val/prd)
            ├── svc-platform (dev/val/prd)
            │       └── workload (dev/val/prd)
            │               └── monitoring (dev/val/prd)
            └── stateful-data (dev/val/prd)
                    └── workload (dev/val/prd)
```

**Rule:** Never create circular dependencies between layers. Data always flows from foundational
layers upward; it never flows back down.

---

## Layer Descriptions

### `acct-baseline`
- **Purpose:** Account-level guardrails and shared IAM infrastructure
- **Typical contents:** IAM roles (cross-account, CI/CD), AWS Config rules, CloudTrail, SCPs
- **Deployment frequency:** Rarely — only when account governance changes
- **Team ownership:** Platform / Security team

### `net-foundation`
- **Purpose:** Network infrastructure shared by all workloads in an environment
- **Typical contents:** VPC, subnets, route tables, NAT gateways, security groups, VPC Flow Logs
- **Deployment frequency:** Rarely — network changes have blast radius
- **Team ownership:** Platform / Networking team

### `svc-platform`
- **Purpose:** Shared compute and load-balancing infrastructure for services
- **Typical contents:** ECS cluster, ALB, ECR repositories, Route 53 hosted zone, ACM certs
- **Deployment frequency:** Occasionally — when adding new services or changing ALB rules
- **Team ownership:** Platform team

### `stateful-data`
- **Purpose:** All stateful storage infrastructure
- **Typical contents:** RDS, Aurora, ElastiCache, S3 buckets, Secrets Manager secrets
- **Deployment frequency:** Rarely — stateful changes carry high risk
- **Team ownership:** Data / Platform team

### `workload`
- **Purpose:** Application-level resources — the things that change with each deploy
- **Typical contents:** ECS services, task definitions, Lambda functions, API Gateway
- **Deployment frequency:** Frequently — on every application release
- **Team ownership:** Application teams

### `monitoring`
- **Purpose:** Observability resources
- **Typical contents:** CloudWatch dashboards, alarms, SNS topics, PagerDuty integrations
- **Deployment frequency:** With workload or platform changes
- **Team ownership:** Platform / SRE team

---

## Environment Differentiation Patterns

Parameterize differences between environments using Pulumi config:

```typescript
const config = new pulumi.Config();
const env = config.require('environment'); // "dev" | "val" | "prd"

// Environment-specific sizing
const instanceSizes: Record<string, string> = {
    dev: 'db.t3.micro',
    val: 'db.t3.small',
    prd: 'db.r6g.large',
};

const instanceClass = instanceSizes[env] ?? 'db.t3.micro';
```

**Environment flags pattern:**

```typescript
const isPrd = env === 'prd';

const rdsInstance = new aws.rds.Instance(`${name}-db`, {
    instanceClass,
    multiAz: isPrd,
    deletionProtection: isPrd,
    backupRetentionPeriod: isPrd ? 14 : 1,
    skipFinalSnapshot: !isPrd,
}, { parent: this });
```

---

## Cross-Stack Reference Strategy

### Option A: Pulumi Stack References (recommended for Pulumi-managed stacks)

Use when all stacks are managed by the same Pulumi organization and backend.

```typescript
// In the consuming stack (e.g., svc-platform)
const org = pulumi.getOrganization();
const env = new pulumi.Config().require('environment');

const netFoundation = new pulumi.StackReference(
    `${org}/net-foundation/${env}`,
);

const vpcId = netFoundation.requireOutput('vpcId') as pulumi.Output<string>;
const privateSubnetIds = netFoundation.requireOutput('privateSubnetIds') as pulumi.Output<string[]>;
```

**Advantages:**
- Type-safe and tracked by Pulumi
- `pulumi up` shows when upstream outputs change
- No manual synchronization required

**Disadvantages:**
- Requires all stacks to be in the same Pulumi org/backend
- Creates a hard deploy-time dependency on the upstream stack being up-to-date

---

### Option B: AWS SSM Parameter Store (recommended for cross-team or hybrid scenarios)

Use when stacks are owned by different teams, or some consumers are not Pulumi stacks.

**Writing outputs (in the producing stack):**

```typescript
new aws.ssm.Parameter(`${name}-vpc-id`, {
    name: `/infra/${env}/networking/vpc-id`,
    type: aws.ssm.ParameterType.String,
    value: vpc.id,
    tags,
}, { parent: this });
```

**Reading outputs (in the consuming stack):**

```typescript
const vpcId = aws.ssm.getParameterOutput({
    name: `/infra/${env}/networking/vpc-id`,
}).value;
```

**Advantages:**
- Works across teams, accounts, and non-Pulumi consumers
- No hard deploy-time coupling
- Easy to inspect values in AWS console

**Disadvantages:**
- Values are strings only; complex types must be serialized (JSON)
- No automatic tracking of upstream changes in Pulumi plan output
- Requires IAM permissions for SSM reads

---

### Choosing Between Options

| Criteria                                          | Use Stack References | Use SSM |
|---------------------------------------------------|----------------------|---------|
| All stacks owned by one team / same Pulumi org    | ✅                   |         |
| Cross-team or cross-account dependencies          |                      | ✅      |
| Non-Pulumi consumers (scripts, Lambda, ECS tasks) |                      | ✅      |
| Complex typed output (arrays, objects)            | ✅                   |         |
| Audit trail of configuration reads               |                      | ✅      |
| Fastest iteration / no manual sync               | ✅                   |         |

---

## Stack State and Backend

Use the Pulumi Cloud backend (recommended) or an S3 backend for team environments:

**S3 backend setup (self-managed):**

```typescript
// In Pulumi.yaml or via CLI
// pulumi login s3://my-pulumi-state-bucket
```

**State locking:**
- Pulumi Cloud provides automatic state locking
- S3 backend uses DynamoDB for locking — always configure it

**State isolation:**
- Each stack (`net-foundation/dev`, `net-foundation/prd`) gets its own state file
- Never share state between environments

---

## Stack Lifecycle Management

### Deployment Order (fresh environment)

Deploy layers in dependency order:

1. `acct-baseline/{env}`
2. `net-foundation/{env}`
3. `svc-platform/{env}` and `stateful-data/{env}` (can be parallel)
4. `workload/{env}`
5. `monitoring/{env}`

### Destroy Order (teardown)

Destroy in reverse dependency order:

1. `monitoring/{env}`
2. `workload/{env}`
3. `svc-platform/{env}` and `stateful-data/{env}` (can be parallel)
4. `net-foundation/{env}`
5. `acct-baseline/{env}`

### Partial Stack Updates

Use `--target` to update specific resources within a stack without deploying the full stack:

```bash
pulumi up --target 'urn:pulumi:prd::workload::aws:ecs/service:Service::my-api-service'
```

Use `--target-dependents` to include all downstream resources automatically.

---

## Multi-Region Patterns

For multi-region deployments, add `region` to the stack naming convention:

```
net-foundation/prd/us-east-1
net-foundation/prd/us-west-2
```

Use AWS provider aliases for multi-region resource creation within a single stack:

```typescript
const usEast1 = new aws.Provider('us-east-1', { region: 'us-east-1' });
const usWest2 = new aws.Provider('us-west-2', { region: 'us-west-2' });

const primaryBucket = new aws.s3.BucketV2('primary', {}, { provider: usEast1, parent: this });
const replicaBucket = new aws.s3.BucketV2('replica', {}, { provider: usWest2, parent: this });
```

---

## Stack Output Conventions

All stack-level outputs should be registered in the stack's `index.ts` using `export`:

```typescript
// In the stack's index.ts
export const vpcId = vpcComponent.vpcId;
export const privateSubnetIds = subnetComponent.privateSubnetIds;
export const dbSecurityGroupId = securityGroupComponent.dbSecurityGroupId;
```

Output naming conventions:
- Use `camelCase` for all output keys
- Use descriptive names that indicate resource type and attribute: `vpcId`, `clusterArn`, `albDnsName`
- Document each output with a JSDoc comment in the source

---

## Pulumi Program Structure for a Stack Layer

```typescript
// src/stacks/net-foundation/index.ts

import * as pulumi from '@pulumi/pulumi';
import { VpcComponent } from '../../components/networking/vpc-component';
import { SubnetComponent } from '../../components/networking/subnet-component';
import { SecurityGroupComponent } from '../../components/networking/security-group-component';

const config = new pulumi.Config();
const env = config.require('environment');
const appName = config.require('appName');

// Deploy VPC
const vpc = new VpcComponent(`${appName}-${env}`, {
    cidrBlock: config.require('vpcCidr'),
    tags: { Environment: env, Stack: 'net-foundation' },
});

// Deploy Subnets (depends on VPC)
const subnets = new SubnetComponent(`${appName}-${env}`, {
    availabilityZones: ['us-east-1a', 'us-east-1b', 'us-east-1c'],
    tags: { Environment: env },
}, { vpcId: vpc.vpcId, internetGatewayId: vpc.internetGatewayId });

// Deploy Security Groups (depends on VPC)
const securityGroups = new SecurityGroupComponent(`${appName}-${env}`, {
    tags: { Environment: env },
}, { vpcId: vpc.vpcId });

// Stack outputs consumed by downstream stacks
export const vpcId = vpc.vpcId;
export const publicSubnetIds = subnets.publicSubnetIds;
export const privateSubnetIds = subnets.privateSubnetIds;
export const dataSubnetIds = subnets.dataSubnetIds;
export const albSecurityGroupId = securityGroups.albSecurityGroupId;
export const appSecurityGroupId = securityGroups.appSecurityGroupId;
export const dbSecurityGroupId = securityGroups.dbSecurityGroupId;
```

---

## CI/CD Stack Deployment Pattern (GitHub Actions)

Each environment has its own deployment job gated by environment protection rules:

```yaml
jobs:
  deploy-dev:
    environment: dev
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pulumi/actions@v5
        with:
          command: up
          stack-name: org/net-foundation/dev
          work-dir: src/stacks/net-foundation
        env:
          PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

  deploy-prd:
    environment: prd          # Requires manual approval
    needs: [deploy-dev]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pulumi/actions@v5
        with:
          command: up
          stack-name: org/net-foundation/prd
          work-dir: src/stacks/net-foundation
        env:
          PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID_PRD }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY_PRD }}
```
