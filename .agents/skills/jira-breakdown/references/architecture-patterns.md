# Technical Architecture Breakdown Patterns

## Architecture Document → Jira Issues

Architecture docs describe **what to build**, not **why**. Issues derived from architecture docs are mostly Technical Tasks and Infrastructure Tasks, with some Stories for service capabilities.

## Extraction Map

| Architecture Section | What to Extract | Issue Type |
|---|---|---|
| System diagram / components | Each new service/component → Epic or Story | Epic / Story |
| Data models / schemas | Each entity or schema change → Task | Task |
| API contracts | Each API surface → Task | Task |
| Message queues / events | Each queue/topic → Task (infra) + Task (producer) + Task (consumer) | 3x Tasks |
| External integrations | Each third-party service → Spike (evaluate) + Task (implement) | Spike + Task |
| Deployment topology | Infrastructure provisioning → Tasks | Tasks |
| Security requirements | Auth, encryption, secrets mgmt → Tasks | Tasks |
| Migration plan | Each migration step → Task with ordering | Tasks with strict dependencies |
| Monitoring / observability | Dashboards, alerts, logging → Tasks | Tasks |

## Infrastructure Dependency Chain (Always Apply)

```
Networking / VPC setup
  └─ blocks ─► Database provisioning
                 └─ blocks ─► Schema migrations
                               └─ blocks ─► Service deployment
                                             └─ blocks ─► Load balancer / routing
                                                           └─ blocks ─► Feature tasks
```

## Service Decomposition Pattern

For each **new service** in an architecture:

```
EPIC: {Service Name} Service

  TASK: Infrastructure provisioning
    - VM / container resources
    - Environment variables / secrets
    - Service mesh / networking config
    Points: 2-3

  TASK: Service scaffold & CI/CD
    - Repo setup, build pipeline
    - Test harness
    - Deployment pipeline (dev/staging/prod)
    Points: 3

  TASK: Data model / schema
    - Database schema
    - Migration scripts
    - Seed data
    Points: 2-5 (depends on complexity)
    BLOCKED BY: [Infrastructure provisioning]

  TASK: Core business logic
    - Domain models
    - Service layer
    Points: varies

  TASK: API / interface layer
    - REST/GraphQL/gRPC endpoints
    - Request validation
    - Error handling
    Points: varies
    BLOCKED BY: [Data model task]

  TASK: Integration tests
    - Contract tests with consumers
    - Integration tests with dependencies
    Points: 3
    BLOCKED BY: [API layer task]

  TASK: Monitoring & observability
    - Structured logging
    - Metrics emission
    - Health check endpoint
    - Alerts configured
    Points: 2
```

## Event-Driven Architecture Pattern

For each **event/message** in the system:

```
TASK: Define event schema (in shared schema registry)
  BLOCKS: producer task, consumer tasks

TASK: Implement producer
  - Emit event on trigger condition
  - Include retry logic
  BLOCKED BY: schema task

TASK: Implement consumer(s) — one task per consumer service
  - Subscribe and process
  - Idempotency handling
  - Dead letter queue handling
  BLOCKED BY: schema task
```

## Database / Schema Task Details

Always break schema work into:

```
TASK: Design schema (ERD)
  Output: ERD diagram approved by team
  BLOCKS: all implementation tasks

TASK: Write migration scripts
  BLOCKED BY: Schema design

TASK: Validate migration on staging
  BLOCKED BY: Write migration scripts
  BLOCKS: Production migration

TASK: Run production migration
  BLOCKED BY: Validate on staging
  Note: Schedule maintenance window if needed
```

## Integration Spike Pattern

For every **external service integration** not previously used:

```
SPIKE: Evaluate {Service Name} integration
  Time-box: 1-2 days
  Output: POC + decision doc covering:
    - API limitations discovered
    - Authentication requirements
    - Rate limits and cost implications
    - Recommended approach
  BLOCKS: Implementation task for this integration
```

## Microservices Communication Patterns

### Synchronous (REST/gRPC)
- Task: Service A endpoint
- Task: Service B client (calling A)
- Task: Circuit breaker / retry config
- Task: Contract test (A from B's perspective)

### Asynchronous (Events/Queue)
- Task: Schema definition
- Task: Producer implementation
- Task: Consumer implementation
- Task: DLQ + retry logic
- Task: Event monitoring dashboard

## Architecture Story Point Anchors

```
2pt  → Config change, env variable, simple infra resource
3pt  → New endpoint with CRUD, simple service scaffold
5pt  → Service with business logic, multi-step integration
8pt  → New service from scratch, complex migration, new external integration
```

## Migration-Specific Patterns

For any **migration** (data, service, infrastructure):

```
EPIC: Migrate {X} to {Y}

  SPIKE: Migration risk assessment
    Output: Risk doc + rollback plan
    BLOCKS: All migration tasks

  TASK: Build migration tooling / scripts
    BLOCKED BY: Spike

  TASK: Test migration on non-prod data
    BLOCKED BY: Migration tooling
    BLOCKS: Staging migration

  TASK: Run staging migration + validation
    BLOCKED BY: Test on non-prod
    BLOCKS: Production migration

  TASK: Production migration (batch 1)
    BLOCKED BY: Staging validation
    Note: Include rollback procedure

  TASK: Production migration (remaining batches)
    BLOCKED BY: Batch 1 success

  TASK: Decommission old system
    BLOCKED BY: All migration batches complete + validation period
    Note: Keep old system available for 30 days post-migration
```