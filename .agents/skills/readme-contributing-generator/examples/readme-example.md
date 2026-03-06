# Pulumi AWS Infrastructure

Automated, multi-environment AWS infrastructure deployments using Pulumi's Automation API and TypeScript. Deploy complete web application infrastructure — networking, compute, storage, and monitoring — in a single command.

[![CI](https://github.com/your-org/pulumi-aws-infra/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/pulumi-aws-infra/actions/workflows/ci.yml)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.7.3-blue?style=flat-square&logo=typescript)](https://www.typescriptlang.org/)
[![Jest](https://img.shields.io/badge/Jest-29.7.0-red?style=flat-square&logo=jest)](https://jestjs.io/)
[![ESLint](https://img.shields.io/badge/ESLint-9.18.0-purple?style=flat-square&logo=eslint)](https://eslint.org/)
[![License: UNLICENSED](https://img.shields.io/badge/License-UNLICENSED-lightgrey?style=flat-square)](./LICENSE)

## ✨ Features

- **Multi-environment deployments** — separate dev, val, and prd stacks with isolated state
- **Layered architecture** — deploy only what you need: foundation, platform, or full stack
- **Reusable Pulumi components** — VPC, ECS services, RDS, ElastiCache wrapped in typed classes
- **Multi-region support** — deploy workloads to us-east-1, us-west-2, or multiple regions simultaneously
- **Programmatic automation** — use Pulumi's Automation API for CI/CD-friendly deployments without the Pulumi CLI interactive prompts
- **Infrastructure testing** — Jest-based unit tests for all components

## 📋 Prerequisites

- Node.js >= 20
- [Pulumi CLI](https://www.pulumi.com/docs/install/) >= 3.x
- AWS credentials configured (`aws configure` or environment variables)
- An S3 bucket for Pulumi state storage (or Pulumi Cloud account)

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Preview changes in development
npm run preview:dev

# Deploy to development
npm run deploy:dev
```

To deploy a specific layer only:

```bash
npx ts-node src/index.ts deploy dev --scope net-foundation --regions us-east-1
```

## 💻 Usage

### Deploy by Environment

```bash
npm run deploy:dev   # Development — full stack
npm run deploy:val   # Validation / staging
npm run deploy:prd   # Production
```

### Deploy by Layer

```bash
npm run deploy:foundation   # Account baseline + networking only
npm run deploy:platform     # Foundation + services + data
```

### Multi-Region Deployment

```bash
npm run deploy:multi-region
# or directly:
npx ts-node src/index.ts deploy prd --scope workload --regions us-east-1,us-west-2
```

### Preview Changes

```bash
npm run preview:dev   # Dry-run for development
npm run preview:val   # Dry-run for validation
npm run preview:prd   # Dry-run for production
```

### Destroy Infrastructure

```bash
npm run destroy:dev   # Tear down development
npm run destroy:prd   # Tear down production (use with care)
```

## ⚙️ Configuration

Configuration files live in `configs/` with environment-specific overrides.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AWS_REGION` | No | `us-east-1` | Primary deployment region |
| `PULUMI_BACKEND_URL` | Yes | — | S3 or Pulumi Cloud state backend URL |
| `AWS_ACCESS_KEY_ID` | Yes | — | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Yes | — | AWS secret key |

## 🏗️ Architecture

```
                    ┌─────────────┐
                    │  acct-baseline│  Account-level: IAM roles, SCPs, budgets
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │net-foundation│  VPC, subnets, security groups, Route53
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
       ┌──────▼──────┐     │      ┌─────▼──────┐
       │svc-platform │     │      │stateful-data│  ECS, ALB │ RDS, ElastiCache, S3
       └─────────────┘     │      └────────────┘
                    ┌──────▼──────┐
                    │  monitoring │  CloudWatch dashboards, alarms, SNS
                    └─────────────┘
```

## 📁 Project Structure

```text
src/
├── index.ts              # Automation API entry point and CLI
├── components/
│   ├── networking/       # VpcComponent, SubnetComponent, SecurityGroupComponent
│   ├── compute/          # EcsServiceComponent, AlbComponent
│   ├── storage/          # RdsComponent, ElastiCacheComponent, S3BucketComponent
│   ├── monitoring/       # AlarmComponent, DashboardComponent
│   └── index.ts          # Component barrel exports
├── stacks/               # Stack definitions per layer
└── utils/
    ├── helpers.ts        # Config merging, tag utilities
    └── logger.ts         # Winston logger

configs/                  # Environment configuration files
  ├── dev.json
  ├── val.json
  └── prd.json

tests/
├── *.spec.ts             # Unit tests
└── jest-e2e.json         # E2E test config

.github/workflows/
├── ci.yml                # Lint, test, type-check
└── deploy.yml            # Environment deployments
```

## 🧪 Testing

```bash
npm test              # Unit tests
npm run test:cov      # With coverage report
npm run test:e2e      # End-to-end infrastructure tests
npm run test:watch    # Watch mode for development
```

Coverage target: >80% for all `src/` modules.

## 🤝 Contributing

We welcome contributions! Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for development
setup, branching conventions, and PR guidelines.

## 📄 License

UNLICENSED — not available for public use or redistribution.
