# Example: Technical Architecture Doc → Jira Breakdown

## Input Document: Event-Driven Analytics Pipeline

> **Technical Architecture: Real-Time Analytics Pipeline**
> Author: Alex Chen | Reviewed: Engineering Leadership
>
> **Overview:** We're replacing our batch ETL (runs nightly) with a real-time event streaming pipeline to support live dashboards and sub-minute data freshness.
>
> **Current State:** 
> - Events written to PostgreSQL
> - Nightly Airflow DAG exports to S3
> - Redshift warehouse loaded from S3
> - Metabase queries Redshift
>
> **Target State:**
> - Events → Kafka topics
> - Kafka → Flink streaming jobs → ClickHouse OLAP
> - Metabase / custom dashboards query ClickHouse
> - PostgreSQL still used for operational data (not analytics)
>
> **Components to build:**
> 1. Kafka cluster (managed, MSK on AWS)
> 2. Event producer library (wraps existing event emission code)
> 3. Flink job: raw events → enriched events
> 4. Flink job: enriched events → aggregated metrics
> 5. ClickHouse cluster + schema
> 6. Dual-write period (write to both old and new pipeline during migration)
> 7. Backfill historical data
> 8. Cutover and deprecation of old pipeline
>
> **Open questions:**
> - What's our Kafka message schema format? (Avro vs JSON vs Protobuf)
> - Flink deployment: self-managed vs Amazon Kinesis Data Analytics?
> - ClickHouse cloud vs self-managed?

---

## Output: Complete Jira Breakdown

---

## 🗂️ EPIC: [EPIC-1] Kafka Infrastructure & Event Schema
**Goal:** Establish the message bus and schema standards that all producers and consumers will use.
**Labels:** infrastructure, kafka, platform, data-pipeline
**Estimated Size:** M
**Dependencies:** None (foundational — must complete first)

---

### 🔬 SPIKE: [SPIKE-1] Kafka message schema format decision (Avro vs JSON vs Protobuf)
**Type:** Spike
**Parent Epic:** [EPIC-1]
**Goal:** Evaluate schema formats for Kafka messages. Consider: schema evolution support, serialization performance, tooling ecosystem, and team familiarity.
**Time-box:** 2 days
**Output:** ADR with chosen format, schema registry approach, and migration path
**Story Points:** 5
**BLOCKS:** [TASK-1] Schema registry setup, [TASK-3] Producer library

---

### 🔬 SPIKE: [SPIKE-2] Flink deployment decision (self-managed vs KDA)
**Type:** Spike
**Parent Epic:** [EPIC-2]
**Goal:** Evaluate Amazon Kinesis Data Analytics (managed Flink) vs self-managed Flink on EKS. Assess: operational overhead, cost at scale, feature limitations, upgrade path.
**Time-box:** 2 days
**Output:** Cost model + ADR with recommendation
**Story Points:** 5
**BLOCKS:** [TASK-7] Flink infrastructure

---

### 🔬 SPIKE: [SPIKE-3] ClickHouse deployment model (cloud vs self-managed)
**Type:** Spike
**Parent Epic:** [EPIC-3]
**Goal:** Evaluate ClickHouse Cloud (managed) vs self-managed on EC2/EKS. Assess: cost at our projected data volume, managed service limitations, HA configuration complexity.
**Time-box:** 2 days
**Output:** Cost model comparison + recommended deployment approach
**Story Points:** 5
**BLOCKS:** [TASK-10] ClickHouse cluster provisioning

---

#### ✅ TASK: [TASK-1] MSK (Kafka) cluster provisioning
**Type:** Task
**Parent Epic:** [EPIC-1]
**Description:** Provision Amazon MSK cluster. Configure: broker count, instance types, storage, replication factor (3), retention policy, network access (VPC private subnets), TLS encryption.

**Acceptance Criteria:**
- [ ] MSK cluster created in dev, staging, and prod environments
- [ ] Replication factor: 3 (no single point of failure)
- [ ] Retention: 7 days for raw events topics
- [ ] TLS enabled, client authentication via IAM
- [ ] Private subnets only, no public access
- [ ] CloudWatch metrics + alerts configured for: consumer lag, broker disk, throughput
- [ ] Terraform code in infra repo, reviewed and merged

**Story Points:** 5
**Suggested Role:** DevOps / Platform Engineer
**BLOCKED BY:** None
**BLOCKS:** [TASK-2], [TASK-3]

#### ✅ TASK: [TASK-2] Schema registry setup
**Type:** Task
**Parent Epic:** [EPIC-1]
**Description:** Deploy Confluent Schema Registry (or AWS Glue Schema Registry, per SPIKE-1 outcome). Define governance process for schema registration and evolution.

**Acceptance Criteria:**
- [ ] Schema registry deployed and accessible from all services
- [ ] Dev/staging/prod environments have separate registries
- [ ] Compatibility mode set (BACKWARD_TRANSITIVE recommended)
- [ ] CI check: PRs that change event schemas are validated against registry
- [ ] Runbook: how to register a new schema, how to evolve an existing one

**Story Points:** 3
**Suggested Role:** Platform Engineer
**BLOCKED BY:** [SPIKE-1], [TASK-1]
**BLOCKS:** [TASK-3], [TASK-5]

---

## 🗂️ EPIC: [EPIC-2] Event Producer Library & Integration
**Goal:** Make it trivially easy for application services to emit events to Kafka with zero schema drift.
**Labels:** infrastructure, kafka, producer, platform
**Estimated Size:** M
**Dependencies:** BLOCKED BY: [EPIC-1]

#### ✅ TASK: [TASK-3] Event producer library (internal SDK)
**Type:** Task
**Parent Epic:** [EPIC-2]
**Description:** Build internal library that wraps Kafka producer. Handles: schema serialization, schema registry validation, retry logic, async batching, error reporting.

**Acceptance Criteria:**
- [ ] Library available as internal npm/pip/gem package
- [ ] `produce(topic, eventType, payload)` API — simple single call
- [ ] Validates payload against schema registry before sending
- [ ] Async batching with configurable flush interval
- [ ] Retry with exponential backoff on transient failures
- [ ] Synchronous fallback to PostgreSQL if Kafka is unreachable (dual-write safety net)
- [ ] 90%+ unit test coverage
- [ ] README with usage examples for each supported language

**Story Points:** 8
**Suggested Role:** Platform Engineer
**BLOCKED BY:** [TASK-2]
**BLOCKS:** [TASK-4]

#### ✅ TASK: [TASK-4] Migrate existing event emission code to producer library
**Type:** Task
**Parent Epic:** [EPIC-2]
**Description:** Replace all existing `INSERT INTO events` PostgreSQL calls with producer library calls. Services in scope: user-service, billing-service, product-service, notification-service.

**Acceptance Criteria:**
- [ ] All 4 services emit to Kafka using producer library
- [ ] Old PostgreSQL event writes still happen (dual-write mode)
- [ ] Verified: events appearing in Kafka topics in staging
- [ ] No increase in p99 latency for event-emitting endpoints

**Story Points:** 8
**Suggested Role:** Backend Engineers (cross-team)
**BLOCKED BY:** [TASK-3]
**BLOCKS:** [TASK-8] (Flink can't run without producers)

---

## 🗂️ EPIC: [EPIC-3] ClickHouse OLAP Storage
**Goal:** Provision and configure the analytical database that will serve all real-time dashboard queries.
**Labels:** infrastructure, clickhouse, data-pipeline, analytics
**Estimated Size:** M
**Dependencies:** None (can proceed in parallel with Kafka work after SPIKE-3)

#### ✅ TASK: [TASK-10] ClickHouse cluster provisioning
**Type:** Task
**Parent Epic:** [EPIC-3]
**Description:** Provision ClickHouse cluster per SPIKE-3 recommendation. Configure: replication, sharding, authentication, network access, backup policy.

**Acceptance Criteria:**
- [ ] ClickHouse cluster running in dev, staging, prod
- [ ] Replication across 2+ availability zones
- [ ] Authentication via username/password + IP allowlist
- [ ] Daily backups to S3
- [ ] Monitoring: queries/sec, memory, disk, slow query log
- [ ] Terraform in infra repo

**Story Points:** 5
**Suggested Role:** DevOps / Data Engineer
**BLOCKED BY:** [SPIKE-3]
**BLOCKS:** [TASK-11]

#### ✅ TASK: [TASK-11] ClickHouse schema design: raw_events + aggregated tables
**Type:** Task
**Parent Epic:** [EPIC-3]
**Description:** Design ClickHouse table schemas for: raw events (MergeTree), aggregated hourly metrics (SummingMergeTree), user-level rollups. Include partition keys and sort order for query patterns.

**Acceptance Criteria:**
- [ ] `raw_events` table: all event fields, partitioned by toYYYYMM(event_time), sorted by (event_type, user_id, event_time)
- [ ] `hourly_metrics` materialized view: counts/sums per event type per hour
- [ ] Schema reviewed by data team for query pattern fit
- [ ] Schema migration scripts checked into repo
- [ ] Tested: representative queries run in < 500ms on realistic data volume

**Story Points:** 5
**Suggested Role:** Data Engineer
**BLOCKED BY:** [TASK-10], [SPIKE-1] (schema format affects ClickHouse ingestion)
**BLOCKS:** [TASK-8], [TASK-9]

---

## 🗂️ EPIC: [EPIC-4] Flink Streaming Jobs
**Goal:** Transform and aggregate raw Kafka events into the ClickHouse tables powering dashboards.
**Labels:** flink, streaming, data-pipeline
**Estimated Size:** L
**Dependencies:** BLOCKED BY: [EPIC-1], [EPIC-3]

#### ✅ TASK: [TASK-7] Flink infrastructure provisioning
**Type:** Task
**Parent Epic:** [EPIC-4]
**Description:** Provision Flink cluster per SPIKE-2 recommendation. Configure: job parallelism, state backend (RocksDB), checkpointing to S3, network connectivity to Kafka and ClickHouse.

**Story Points:** 5
**Suggested Role:** DevOps / Data Engineer
**BLOCKED BY:** [SPIKE-2]
**BLOCKS:** [TASK-8], [TASK-9]

#### ✅ TASK: [TASK-8] Flink job: raw events enrichment
**Type:** Task
**Parent Epic:** [EPIC-4]
**Description:** Flink job that consumes from raw Kafka topics, enriches events (lookup user metadata, add geo info, normalize fields), and writes to ClickHouse `raw_events` table.

**Acceptance Criteria:**
- [ ] Consumes from all raw event topics
- [ ] Enriches: user_id → user_segment, country, account_age
- [ ] Handles late arrivals (5-minute watermark)
- [ ] Writes to ClickHouse with at-least-once delivery
- [ ] Checkpoints every 60 seconds
- [ ] Lag monitoring: alert if consumer lag > 10k messages

**Story Points:** 8
**Suggested Role:** Data Engineer
**BLOCKED BY:** [TASK-7], [TASK-11], [TASK-4]
**BLOCKS:** [TASK-9]

#### ✅ TASK: [TASK-9] Flink job: metric aggregation
**Type:** Task
**Parent Epic:** [EPIC-4]
**Description:** Flink job that reads enriched events and computes: hourly aggregates, daily rollups, funnel metrics. Writes to ClickHouse aggregated tables.

**Story Points:** 8
**Suggested Role:** Data Engineer
**BLOCKED BY:** [TASK-8]
**BLOCKS:** [EPIC-5 — migration tasks]

---

## 🗂️ EPIC: [EPIC-5] Migration & Cutover
**Goal:** Safely migrate from the old batch pipeline to the new streaming pipeline with no data loss.
**Labels:** migration, data-pipeline
**Estimated Size:** M
**Dependencies:** BLOCKED BY: [EPIC-4] (all Flink jobs working)

#### ✅ TASK: [TASK-12] Backfill historical data to ClickHouse
**Description:** One-time backfill of historical events (from PostgreSQL/S3) into ClickHouse, covering 24 months of history.
**Story Points:** 5
**BLOCKED BY:** [TASK-11]
**BLOCKS:** [TASK-13]

#### ✅ TASK: [TASK-13] Dual-write validation period (2 weeks)
**Description:** Run both pipelines in parallel. Compare: query results from Redshift (old) vs ClickHouse (new) for 2 weeks. Automated diff job flags discrepancies.
**Story Points:** 5
**BLOCKED BY:** [TASK-12], [TASK-9]
**BLOCKS:** [TASK-14]

#### ✅ TASK: [TASK-14] Cutover Metabase dashboards to ClickHouse
**Description:** Update all Metabase connection strings and queries to point to ClickHouse. Validate each dashboard.
**Story Points:** 3
**BLOCKED BY:** [TASK-13]
**BLOCKS:** [TASK-15]

#### ✅ TASK: [TASK-15] Decommission old pipeline (Airflow DAGs + Redshift)
**Description:** After 30-day post-cutover monitoring period, remove Airflow DAGs and decommission Redshift. Update runbooks.
**Story Points:** 2
**BLOCKED BY:** [TASK-14] + 30-day validation period

---

## 🔗 Dependency Graph

```
SPIKE-1 (Schema format) ──────────────────────────────────► TASK-2 (Schema registry)
                                                               └──► TASK-3 (Producer lib)
                                                                     └──► TASK-4 (Migrate emitters)
                                                                           └──► TASK-8 (Flink enrichment)

TASK-1 (MSK cluster) ─────────────────────────────────────► TASK-2 (Schema registry)

SPIKE-2 (Flink decision) ─────────────────────────────────► TASK-7 (Flink infra)
                                                               ├──► TASK-8 (Enrichment job)
                                                               └──► TASK-9 (Aggregation job)

SPIKE-3 (ClickHouse decision) ────────────────────────────► TASK-10 (ClickHouse cluster)
                                                               └──► TASK-11 (Schema design)
                                                                     ├──► TASK-8
                                                                     └──► TASK-12 (Backfill)

TASK-8 ──► TASK-9 ──► TASK-13 (Dual-write validation) ──► TASK-14 (Cutover) ──► TASK-15

⚠️  Critical Path: SPIKE-1 → TASK-2 → TASK-3 → TASK-4 → TASK-8 → TASK-9 → TASK-13 → TASK-14
Estimated Minimum Duration: ~8 weeks
```

---

## 📅 Suggested Sprint Breakdown

### Sprint 1 — Research & Foundation
- [SPIKE-1] Schema format (2 days) ← UNBLOCK EVERYTHING
- [SPIKE-2] Flink deployment (2 days)
- [SPIKE-3] ClickHouse deployment (2 days)
- [TASK-1] MSK cluster provisioning (5 pts)

### Sprint 2 — Schema & Storage Layer
- [TASK-2] Schema registry setup (3 pts)
- [TASK-10] ClickHouse provisioning (5 pts) ← parallel
- [TASK-11] ClickHouse schema design (5 pts)

### Sprint 3 — Producer & Flink Infra
- [TASK-3] Event producer library (8 pts)
- [TASK-7] Flink infrastructure (5 pts) ← parallel

### Sprint 4 — Integration
- [TASK-4] Migrate event emitters (8 pts)
- [TASK-8] Flink enrichment job (8 pts)

### Sprint 5 — Aggregation & Backfill
- [TASK-9] Flink aggregation job (8 pts)
- [TASK-12] Historical backfill (5 pts) ← parallel

### Sprint 6 — Migration
- [TASK-13] Dual-write validation (5 pts, 2-week period)
- [TASK-14] Cutover Metabase (3 pts)

### Sprint 7+ — Cleanup
- [TASK-15] Decommission old pipeline (2 pts) ← after 30-day validation

**Total Story Points:** ~98
**Estimated Duration:** ~8 sprints (16 weeks)