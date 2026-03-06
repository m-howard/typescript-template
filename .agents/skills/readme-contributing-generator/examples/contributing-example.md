# Contributing to Pulumi AWS Infrastructure

Thank you for your interest in contributing! This guide covers everything you need to get
a working development environment, understand our conventions, and submit high-quality
changes.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

---

## Getting Started

### Prerequisites

- Node.js >= 20 (use [nvm](https://github.com/nvm-sh/nvm) to manage versions)
- [Pulumi CLI](https://www.pulumi.com/docs/install/) >= 3.x
- AWS credentials configured locally (`aws configure` or environment variables)
- Git >= 2.x

### Development Setup

```bash
# Clone the repository
git clone https://github.com/your-org/pulumi-aws-infra.git
cd pulumi-aws-infra

# Install dependencies
npm install

# Verify your setup — all tests should pass
npm test

# Run lint to confirm code style is clean
npm run lint:check
```

No additional environment variables are needed for running tests (tests mock AWS resources).
For deploying to a real environment, configure AWS credentials and set `PULUMI_BACKEND_URL`.

---

## Development Workflow

### Branching Strategy

Branch from `main`. Use these naming conventions:

| Type | Pattern | Example |
|------|---------|---------|
| New feature | `feature/<short-description>` | `feature/add-rds-component` |
| Bug fix | `fix/<issue-number>-description` | `fix/42-vpc-cidr-validation` |
| Documentation | `docs/<short-description>` | `docs/update-contributing-guide` |
| Refactor | `refactor/<short-description>` | `refactor/extract-subnet-logic` |
| Chore/deps | `chore/<short-description>` | `chore/bump-pulumi-aws` |

### Making Changes

```bash
# 1. Create your feature branch
git checkout -b feature/my-new-component

# 2. Make your changes
# ...

# 3. Run tests and linting before committing
npm test
npm run lint:check
npm run format:check

# 4. Commit your changes (see commit conventions below)
git commit -m "feat(compute): add Fargate auto-scaling component"

# 5. Push and open a PR
git push origin feature/my-new-component
```

### Commit Messages

We follow **Conventional Commits**. Each commit message must have this structure:

```
<type>(<scope>): <short description>

[optional body — explain WHY, not WHAT]

[optional footer — breaking changes, issue refs]
```

**Types:**

| Type | When to use |
|------|-------------|
| `feat` | A new feature or component |
| `fix` | A bug fix |
| `docs` | Documentation changes only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Build process, dependencies, tooling |
| `perf` | Performance improvements |
| `ci` | CI/CD pipeline changes |

**Scopes** (optional but encouraged): `networking`, `compute`, `storage`, `monitoring`,
`stacks`, `utils`, `ci`

**Examples:**

```
feat(networking): add VPC flow logs component
fix(compute): resolve ECS task definition memory calculation
docs(readme): add multi-region deployment example
test(storage): add unit tests for RDS parameter groups
chore(deps): bump @pulumi/aws to 6.x
```

---

## Code Standards

### Linting & Formatting

We use ESLint and Prettier. Both run automatically on staged files via Husky pre-commit
hooks, but you can run them manually:

```bash
npm run lint          # ESLint with auto-fix
npm run lint:check    # ESLint without auto-fix (CI mode)
npm run format        # Prettier with auto-fix
npm run format:check  # Prettier without auto-fix (CI mode)
```

If your commit is blocked by lint errors, run `npm run lint` to auto-fix what it can,
then manually fix the rest.

### TypeScript Guidelines

- **Strict mode** is enabled — no `any` types, no implicit returns
- Use **interfaces** for object shapes, **types** for unions and primitives
- Name classes with PascalCase (`VpcComponent`), functions with camelCase (`createVpc`),
  constants with UPPER_SNAKE_CASE (`DEFAULT_REGION`)
- File names: kebab-case (`vpc-component.ts`)
- Use `async/await` — never raw Promise chains or callbacks
- Prefer optional chaining (`?.`) over manual null guards

### Infrastructure Component Conventions

- All Pulumi components must extend `pulumi.ComponentResource`
- Call `this.registerOutputs({...})` at the end of every constructor
- Accept a typed `args` interface — no untyped spreads
- Apply resource tags consistently using the shared tagging utility
- Add JSDoc to every exported class and public method

---

## Testing Requirements

Every change must maintain or improve test coverage. The target is **>80% coverage** for
all `src/` modules.

### What to Test

| Change type | Required tests |
|------------|---------------|
| New Pulumi component | Unit tests for all resource configurations and outputs |
| New utility function | Unit tests covering happy path + edge cases |
| Bug fix | Regression test that would have caught the original bug |
| Config change | Verify config is consumed correctly in affected components |

### Running Tests

```bash
npm test              # All unit tests
npm run test:cov      # Unit tests + coverage report
npm run test:watch    # Watch mode (useful during development)
npm run test:e2e      # End-to-end tests (requires AWS credentials)
```

### Test Conventions

- Test files live alongside source files or in `tests/` — mirror the `src/` structure
- File naming: `<component>.spec.ts`
- Use `describe` to group by component, `it` to describe behavior:

```typescript
describe('VpcComponent', () => {
    it('should create a VPC with the specified CIDR block', () => { ... });
    it('should enable DNS hostnames when enableDnsHostnames is true', () => { ... });
    it('should throw ValidationError for an invalid CIDR block', () => { ... });
});
```

---

## Pull Request Process

### Before Opening a PR

Verify everything locally:

- [ ] `npm test` — all tests pass
- [ ] `npm run lint:check` — no lint errors
- [ ] `npm run format:check` — formatting is correct
- [ ] New or modified components have unit tests
- [ ] JSDoc comments added to new public APIs
- [ ] No hardcoded credentials, region names, or account IDs

### PR Description

Your PR description should answer:

1. **What** — what was changed and why
2. **How to test** — how a reviewer can verify the change works
3. **Screenshots or output** — if there are infrastructure changes, include a `pulumi preview` output snippet

### Review Process

- PRs require at least **1 approving review** before merging
- CI must be green (lint, type-check, tests)
- Keep PRs focused — one logical change per PR is easier to review and revert
- Respond to review comments within 48 hours; if you need more time, say so
- Squash your commits when merging to keep `main` history clean

---

## Reporting Issues

### Bug Reports

Open a [GitHub Issue](https://github.com/your-org/pulumi-aws-infra/issues/new) and include:

- **Steps to reproduce** — exact commands and configuration
- **Expected behavior** — what should have happened
- **Actual behavior** — what happened instead, including error messages and stack traces
- **Environment** — Node.js version, Pulumi CLI version, AWS region, OS

### Feature Requests

Open a GitHub Issue with the label `enhancement`. Describe:

- The use case — what problem does this solve?
- Proposed approach — how might it work?
- Any alternatives you've considered

Please wait for feedback before investing significant implementation time.

---

## Questions?

Open a [GitHub Discussion](https://github.com/your-org/pulumi-aws-infra/discussions) for
general questions. Use Issues only for bugs and feature requests.
