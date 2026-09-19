# Backend 技術・Library選定 - Cache・Queue・Async

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend における以下を定義する。

- Cache
- Redis採用方針
- Cache Pattern
- Cache Invalidation
- Queue
- Queue Driver
- Async Processing
- TransactionとQueue Dispatch
- Retry
- Idempotency
- Failed Jobs
- Scheduler
- Async API
- Cache / Queue Failure時の扱い
- Testing
- Library採用判断

本Projectでは、Cache / Queue / Asyncを必須Architectureにはしない。

基本方針：

```text
Default
    → PostgreSQLから取得
    → 同期処理

必要性が明確になった場合のみ
    ├── Cache
    └── Queue / Async
```

---

## 2. 基本方針

Cache / Queue / Asyncについて、以下を最重要原則とする。

```text
PostgreSQL
    → Source of Truth

Cache
    → Performance Optimization

Queue
    → Optional Async Execution
```

CacheやQueueが存在しないとBusiness Correctnessを維持できないArchitectureをMVPでは避ける。

また、

> 利用可能だから導入するのではなく、具体的なProblemが発生した場合に導入する

ことを原則とする。

---

## 3. 同期処理をDefaultとする

MVPでは同期処理をDefaultとする。

対象：

```text
Employee作成
Employee更新
Employee退職

EmployeeSkill登録
EmployeeSkill更新
EmployeeSkill削除

Skill作成
Skill更新
Skill無効化

User Role変更
Permission変更

SubManagerAssignment変更
TeamLeaderAssignment変更

Audit Log書き込み
```

ClientがSuccess Responseを受け取った時点で、主要Business Stateが確定している状態を基本とする。

---

# Cache

## 4. Cacheの位置付け

CacheはPerformance Optimizationとしてのみ利用する。

```text
Cache Hit
    → Cacheから返す

Cache Miss
    → PostgreSQL
    → 正常動作
```

CacheがなくてもApplicationの主要機能が成立するようにする。

---

## 5. Redis

RedisはMVP必須Dependencyとしない。

必須：

```text
PostgreSQL
```

Optional：

```text
Redis
```

現時点では、

```text
Employee CRUD
Skill CRUD
EmployeeSkill CRUD
Authorization
Dashboard
```

をPostgreSQL + 適切なIndexで実装する。

実測上のPerformance Requirementが発生した場合にRedis導入を判断する。

---

## 6. Redisを最初から導入しない理由

主な理由：

- Runtime Serviceが増える
- Development Environmentが複雑になる
- Failure Pointが増える
- Cache Invalidation設計が必要になる
- Monitoring対象が増える
- MVP規模ではPostgreSQLだけで十分な可能性が高い

Cache / QueueのためだけにRedisを先行導入しない。

---

## 7. Cache候補

将来的にCache候補となるData：

```text
Skill Category一覧
Skill Master一覧
Reference Data
重いDashboard集計結果
```

特に、

```text
Read頻度が高い
Write頻度が低い
多少のStalenessを許容可能
```

というDataを優先候補とする。

---

## 8. Cache対象にしないData

MVPでは以下をApplication Cacheへ載せない。

```text
User Role
can_manage_permissions
Authorization結果
Administrator最低人数判定
EmployeeSkillのCurrent Write State
Transaction途中のState
Security Critical State
```

理由：

```text
Stale Cache
    ↓
Authorization / Business Rule誤判定
```

を避けるため。

---

## 9. Authorization Cache

独自のAuthorization CacheはMVPでは採用しない。

```text
User Role
Permission
SubManager Assignment
TeamLeader Assignment
```

についてはPostgreSQLをSource of Truthとする。

Framework内部の通常最適化とは別Conceptとして扱う。

---

## 10. Cache Pattern

Cacheを利用する場合は基本的にCache-Aside Patternを採用する。

```text
Read
    ↓
Cache Lookup
    ├── Hit
    │    ↓
    │  Return
    │
    └── Miss
         ↓
      PostgreSQL
         ↓
      Cache Store
         ↓
       Return
```

Cache自体をAuthoritative Storageにしない。

---

## 11. Write-through / Write-behind

MVPでは以下を採用しない。

```text
Write-through Cache
Write-behind Cache
```

理由：

```text
Database
Cache
Transaction
Failure Handling
```

間のConsistency管理が複雑になるため。

---

## 12. Cache Invalidation

Write Operation後は必要なCacheを明示的にInvalidationする。

例：

```text
Skill作成
Skill更新
Skill無効化
    ↓
Skill Master Cache Invalidate
```

重要なStateを、

```text
TTLが切れるまで待つ
```

だけで更新する設計は避ける。

---

## 13. Cache更新とTransaction

Cache OperationをDatabase Transactionの一部として扱わない。

避ける：

```text
BEGIN

DB UPDATE
Cache DELETE

ROLLBACK
```

基本：

```text
BEGIN

DB UPDATE

COMMIT

↓
Cache Invalidate
```

とする。

---

## 14. Cache Invalidation Failure

Cache Invalidation FailureによってBusiness TransactionをRollbackしない。

```text
Cache Failure
    ≠
Business Transaction Failure
```

CacheはOptimizationだからである。

ただしCache StalenessがSecurity / Correctnessへ影響するDataは、そもそもCache対象にしない。

---

## 15. TTL

TTLはData特性ごとに決定する。

例：

```text
Skill Category
    → 比較的長め

Skill Master
    → 中程度

Dashboard Aggregate
    → 数十秒〜数分候補

Highly Dynamic State
    → Cacheしない
```

全Cacheへ一律TTLを設定しない。

---

## 16. Cache Key

Cache Key Naming Ruleを定義する。

例：

```text
skill_categories:v1
skills:v1
dashboard:department:{id}:v1
```

Versionを含めることでSchema / Serialization変更時に切り替えやすくする。

---

## 17. Cache KeyにSensitive Dataを入れない

以下をCache Keyへ直接含めない。

```text
Email
Employee Name
Search Keyword
Token
Session
```

必要な場合はStable Identifierを利用する。

---

## 18. High Cardinality Cache

MVPでは個々のEntityを大量にCacheしない。

例：

```text
employee:{id}
employee_skill:{id}
```

を無差別にCacheしない。

まずは、

```text
Reference Data
Expensive Aggregate
```

中心とする。

---

## 19. Cache Failure

Cacheが利用できない場合でも、可能な限りPostgreSQLへFallbackする。

```text
Cache unavailable
    ↓
PostgreSQL
    ↓
正常処理
```

Core CRUDをRedis Availabilityへ依存させない。

---

# Queue

## 20. Queueの位置付け

Queueは、

> HTTP Request中に完了させる必要のない処理

へ利用する。

基本Flow：

```text
HTTP Request
    ↓
Business Transaction
    ↓
Commit
    ↓
必要ならJob Dispatch
    ↓
HTTP Response
```

---

## 21. Queue対象候補

Queue向きの処理：

```text
Email通知
CSV Export
Large Import
Report生成
External Service通知
Retention Maintenance
大量Cleanup
重い集計
Background Processing
```

同期処理するとUser ExperienceやTimeoutへ影響する処理を候補とする。

---

## 22. Queue化しない処理

以下は同期処理を維持する。

```text
Employee作成 / 更新
EmployeeSkill登録 / 更新
Skill無効化
User Role変更
Permission変更
Administrator変更
Assignment変更
Audit Log
```

Request成功時点でBusiness Stateを確定させる必要があるため。

---

## 23. Audit

`09_Log・Audit.md`の方針を維持する。

```text
Business Change
+
Audit Insert
    ↓
Same Transaction
```

AuditWriterをQueue化しない。

不採用：

```text
AuditWriter
    ↓
Queue
    ↓
Audit Insert
```

---

## 24. Permission Operation

以下をQueue化しない。

```text
Role変更
Permission変更
can_manage_permissions変更
Administrator変更
```

特に、

```text
ADMINISTRATOR
+
can_manage_permissions = true
```

を最低1人維持するInvariantがあるため、同期Transactionで処理する。

---

## 25. Laravel Queue

Queueが必要になった場合はLaravel Queueを採用する。

```text
Application / Infrastructure
    ↓
Laravel Queue
    ↓
Queue Driver
```

独自Queue Frameworkを作らない。

---

## 26. Queue Driver

Queue APIはLaravelへ統一するが、Queue DriverはInfrastructure Decisionとする。

候補：

```text
Database
Redis
Amazon SQS
```

Application CodeからDriver固有APIへ依存しない。

---

## 27. Database Queue

初期の少量Queue用途ではLaravel Database Queueを候補とする。

メリット：

```text
追加Infrastructure不要
Redis不要
Local Developmentが簡単
```

向いている用途：

```text
少量Job
低〜中Throughput
MVP
```

大量Job / 高Throughputが必要になった場合は再検討する。

---

## 28. Redis Queue

Redis QueueはMVP必須としない。

以下のような理由が出た場合に採用を検討する。

```text
Queue量増加
低Latency Queueが必要
RedisをCacheでも採用済み
Database QueueがBottle Neck
```

Queueのためだけに先行導入しない。

---

## 29. Amazon SQS

ProductionがAWS ECSとなった場合、Amazon SQSを有力候補とする。

構成：

```text
Laravel
    ↓
Amazon SQS
    ↓
ECS Worker
```

メリット：

```text
Managed Service
Durability
Scale
Stateless Worker
AWS ECSとの親和性
```

本番Infrastructure未確定のため、本章では正式採用まで行わない。

---

# Transaction / Dispatch

## 30. Transaction中のJob Dispatch

Database Transaction途中でJobを実行可能状態にしない。

危険例：

```text
BEGIN

Employee INSERT

Job Dispatch
    ↓
Worker Starts

ROLLBACK
```

WorkerがまだCommitされていないDataやRollbackされたDataを参照するRiskがある。

---

## 31. afterCommit

Queue Jobは原則Commit後にDispatchする。

```text
BEGIN

Business Change

COMMIT

↓
Job Dispatch
```

Laravelのafter-commit機構を利用する。

---

## 32. Queue DispatchとBusiness Transaction

Queue Dispatch Failureの扱いはJobのBusiness Importanceによって分ける。

非Critical例：

```text
Business Operation成功
Email Job Dispatch失敗
```

では、

```text
Business Operationは成功
Queue FailureをLog / Monitor
```

という設計を許容する。

Queue処理をBusiness Critical Pathへ安易に置かない。

---

## 33. Transactional Outbox

MVPではTransactional Outbox Patternを採用しない。

不採用理由：

```text
Outbox Table
Publisher
Delivery State
Retry
Worker
Monitoring
```

などArchitecture / Operationが増えるため。

将来、

```text
DB Commit
+
External Message Publication
```

の取りこぼしを絶対に許容できないRequirementが発生した場合に再検討する。

---

# Job Design

## 34. Jobの責務

Jobは小さく保つ。

推奨：

```text
Job
    ↓
Application UseCase
```

または、

```text
Job
    ↓
明確な1つのAsync Task
```

とする。

---

## 35. JobにBusiness Logicを書かない

避ける：

```php
final class SomeJob
{
    public function handle(): void
    {
        // 大量のBusiness Rule
    }
}
```

基本：

```text
Laravel Job
    ↓
Application Handler / Service
    ↓
Domain
```

とする。

---

## 36. JobとLayer

Laravel JobはInfrastructure / Framework Boundaryとして扱う。

JobからDomain Aggregateを直接複雑に操作せず、Application UseCaseを呼び出す。

---

## 37. Job Payload

Job Payloadには必要最小限のIdentifierを渡す。

推奨：

```text
employee_id
export_id
report_id
notification_id
```

避ける：

```text
巨大なEloquent Model
大量Relation
Full HTTP Request
Sensitive Payload
```

---

## 38. Eloquent ModelをJobへ渡さない

LaravelにはModel Serialization機能が存在するが、本Architectureでは原則としてIDをJobへ渡す。

```text
Job Payload
    ↓
Primitive / Typed ID相当
    ↓
Execution時に最新Data取得
```

Persistence ModelをAsync Contractへ直接露出しない。

---

## 39. 最新State

Queue Job実行時には、Dispatch時Snapshotではなく最新Stateを取得する設計を基本とする。

SnapshotがRequirementの場合のみ、必要なDataを明示的に保存する。

---

# Retry

## 40. Retry基本方針

Retryは、

> 再実行によって成功する可能性のあるTransient Failure

へ利用する。

対象候補：

```text
Network Timeout
Temporary Connection Failure
External Service 5xx
Rate Limit
Temporary Dependency Failure
```

---

## 41. RetryしないError

以下は原則Retryしない。

```text
Validation Failure
Domain Rule Violation
Authorization Failure
Not Found
Invalid Input
Permanent External Error
```

同じInputで再実行しても成功しないため。

---

## 42. Exponential Backoff

RetryにはExponential Backoffを採用する。

概念例：

```text
10 seconds
30 seconds
90 seconds
```

具体的な値はJobごとのFailure特性に合わせて決定する。

---

## 43. Retry回数

すべてのJobへ共通Retry回数を適用しない。

以下の特性ごとに決める。

```text
Email
External API
Export
Import
Maintenance
```

無限Retryは禁止する。

---

## 44. Jitter

外部ServiceへのRetryが集中する可能性がある場合は、BackoffへJitterを追加することを検討する。

目的：

```text
同時Failure
    ↓
同時Retry
    ↓
Thundering Herd
```

を防ぐこと。

MVPで独自Retry Frameworkは作らない。

---

## 45. Failed Jobs

Retry上限を超えたJobはFailed Jobとして記録する。

```text
Job
    ↓
Retry
    ↓
Retry Limit
    ↓
Failed Job
```

Failed Jobを無限放置しない。

---

## 46. Failed Job Monitoring

以下をObservability対象とする。

```text
Failed Job Count
Retry Count
Queue Latency
Processing Duration
```

`10_Observability.md`の方針と連携する。

---

## 47. Failed Job Retry

Failed JobのManual Retryを可能にする場合も、Idempotencyを前提とする。

同じJobを再実行することで二重処理が発生しないようにする。

---

# Idempotency

## 48. Job Idempotency

Queue Jobは可能な限りIdempotentに設計する。

```text
同じJobを複数回実行
    ↓
最終結果が壊れない
```

ことを目標とする。

---

## 49. Delivery Semantics

Application側で、

```text
Exactly Once
```

を安易に前提にしない。

基本的には、

```text
At-least-once
```

の可能性を考慮する。

Duplicate Executionへ耐えられる設計を優先する。

---

## 50. Idempotencyの実現方法

優先順位：

```text
DB State Check
    ↓
UNIQUE Constraint
    ↓
Idempotent State Transition
    ↓
必要ならDedicated Idempotency Record
    ↓
必要ならLock
```

とする。

---

## 51. Export Job例

例：

```text
GenerateExport(export_id)
```

実行時：

```text
Export already completed?
    ├── Yes → Return
    └── No  → Generate
```

とすることでDuplicate Executionへ対応できる。

---

## 52. Notification重複

Notificationで重複送信がProblemになる場合は、

```text
notification_delivery
```

等のDelivery Stateを持たせることを検討する。

Queue自体のExactly Once Deliveryへ依存しない。

---

# Lock

## 53. Lock基本方針

二重処理防止の優先順位：

```text
DB Constraint
    ↓
State Check
    ↓
Idempotent Design
    ↓
必要ならLock
```

Lockを最初の解決策にしない。

---

## 54. PostgreSQL Lock

Business Correctnessに必要なConcurrency Controlは既存方針通りPostgreSQLを優先する。

```text
SELECT FOR UPDATE
UNIQUE
CHECK
```

等を利用する。

---

## 55. Redis Distributed Lock

Redis Distributed LockはMVPでは原則利用しない。

特に、

```text
RedisがUnavailable
    ↓
Business Ruleを保証できない
```

というArchitectureは避ける。

必要性が明確になった場合のみ採用を検討する。

---

# Scheduler

## 56. Laravel Scheduler

定期処理にはLaravel Schedulerを採用する。

候補：

```text
Retention Candidate抽出
Periodic Maintenance
期限確認
Notification候補生成
Cleanup
```

独自Scheduler Frameworkは作らない。

---

## 57. Retired Employee

退職社員について、

```text
退職
    ↓
3年保持
    ↓
Administrator確認
    ↓
削除
```

というRequirementを維持する。

したがって、

```text
3年経過
    ↓
自動削除
```

は採用しない。

---

## 58. Retention Scheduler

Schedulerでは例えば以下までとする。

```text
3年以上経過したEmployee抽出
    ↓
Delete Candidate化
    ↓
Administrator確認対象
```

最終削除は明示的なBusiness Operationとする。

---

## 59. Scheduler重複実行

複数Application Instance環境ではSchedulerの重複実行を防止する。

Infrastructureでは以下を検討する。

```text
Dedicated Scheduler Instance
Single Scheduler Task
Managed Scheduler
Leader Election
```

具体方式はDeployment Infrastructure確定時に決定する。

---

## 60. Scheduled Job Lock

同じScheduled Taskの重複実行防止が必要な場合はLaravel標準機構等を利用する。

ただしRedis Lockを必須前提にしない。

Infrastructureに応じた実装を選択する。

---

# Async API

## 61. Async API

Long-running Operationで必要な場合のみAsync APIを採用する。

対象候補：

```text
CSV Export
Large Import
Long-running Report
Bulk Operation
```

通常CRUDへAsync APIを導入しない。

---

## 62. HTTP 202

Async Processingを受け付けた場合は、

```http
202 Accepted
```

を利用できる。

これは、

> Requestを受理したが処理はまだ完了していない

ことを表す。

---

## 63. Async Resource

Userが進捗を確認する必要がある場合はTechnical Queue JobをPublic APIへ直接公開しない。

代わりに、

```text
ExportRequest
ImportRequest
```

等のApplication Resourceを設計する。

State例：

```text
queued
processing
completed
failed
```

---

## 64. Queue Job IDの公開禁止

以下は避ける。

```text
GET /jobs/{laravel_queue_job_id}
```

Laravel Queue内部IDをPublic API Contractにしない。

Queue Implementation DetailをPresentationへ漏らさない。

---

## 65. Async Result

Async Operation完了後のResultはApplication Resource経由で取得する。

例：

```text
POST /exports
    ↓
202

GET /exports/{id}
    ↓
status = completed
    ↓
download information
```

のようにApplication Conceptとして表現する。

---

# Failure Handling

## 66. Cache FailureとBusiness Failure

```text
Cache Failure
    ≠
Business Failure
```

を基本とする。

可能ならDB Fallbackする。

---

## 67. Queue FailureとBusiness Failure

Queueが非Criticalな場合：

```text
Business Operation
    → Success

Queue Dispatch
    → Failure

Result
    → Business Operationは原則Rollbackしない
```

Queue FailureはLogging / Observability対象とする。

---

## 68. Critical Async Processing

Async Processing自体がBusiness Requirement上Criticalになった場合は、単純なQueue Dispatchだけではなく、

```text
Transactional Outbox
Durable State
Delivery Tracking
```

等を再検討する。

MVPでは対象外とする。

---

## 69. Redis Failure

Redisを将来採用した場合でもCore Business FunctionをRedis Availabilityへ強く依存させない。

```text
Redis
    → Supporting Infrastructure

PostgreSQL
    → Source of Truth
```

とする。

---

# Testing

## 70. Cache Test

Cache利用機能では以下をTestする。

```text
Cache Hit
Cache Miss
Cache Invalidation
DB Fallback
```

Cache Framework内部動作を再Testしない。

---

## 71. Cache Invalidation Test

Write後に必要なCacheが無効化されることを確認する。

例：

```text
Skill Update
    ↓
Skill Cache Invalidate
```

TTL切れだけを頼りにするTestは避ける。

---

## 72. Queue Dispatch Test

Laravel Queue Fake等を利用して以下を確認する。

```text
必要なJobがDispatchされた
不要なJobがDispatchされない
正しいPayload
Commit後にDispatchされる
```

---

## 73. Job Test

Jobでは以下を中心にTestする。

```text
Application UseCaseを呼び出す
Retryable Failure分類
Non-retryable Failure分類
Idempotency
```

Business RuleはDomain / Application Testへ置く。

---

## 74. Retry Test

重要Jobでは、

```text
Transient Failure
    → Retry

Permanent Failure
    → Retryしない
```

ことを確認する。

具体的Backoff Library内部の挙動までTestしない。

---

## 75. Idempotency Test

同一Jobを複数回実行しても、

```text
Duplicate Record
Duplicate Notification
Invalid State Transition
```

等が発生しないことを確認する。

---

## 76. Async Integration Test

重要なAsync Flowでは必要に応じ、

```text
HTTP Request
    ↓
Dispatch
    ↓
Worker
    ↓
Result State
```

までIntegration Testする。

全JobをEnd-to-End Test対象にはしない。

---

## 77. Scheduler Test

Schedulerについては、

```text
対象抽出条件
実行対象UseCase
自動削除しないこと
```

等のProject固有BehaviorをTestする。

Laravel Scheduler FrameworkそのものはTestしない。

---

## 78. Observability

Queue導入時は以下をObservability対象とする。

```text
Queue Depth
Queue Latency
Processing Duration
Retry Count
Failed Job Count
```

Cache採用時には必要に応じ、

```text
Cache Hit Rate
Cache Miss Rate
Cache Failure
```

を追加する。

---

## 79. Library採用判断

| Library / 技術 | 判断 |
|---|---|
| Laravel Cache | 必要時採用 |
| Cache-Aside | 採用 |
| Redis | MVP必須にしない |
| Redis Cache | 必要性が出た場合に採用 |
| Permission Cache | MVPでは不採用 |
| Write-through Cache | 不採用 |
| Write-behind Cache | 不採用 |
| Laravel Queue | Queue利用時採用 |
| Database Queue | 初期候補 |
| Redis Queue | 必要時候補 |
| Amazon SQS | AWS ECS時の有力候補 |
| Laravel Scheduler | 採用 |
| afterCommit Dispatch | 採用 |
| Retry | 採用 |
| Exponential Backoff | 採用 |
| Infinite Retry | 不採用 |
| Failed Jobs | 採用 |
| Job Idempotency | 採用 |
| Redis Distributed Lock | MVPでは原則不採用 |
| Transactional Outbox | MVPでは不採用 |
| Audit Async | 不採用 |
| Permission Async | 不採用 |
| Async API | Long-running処理のみ |
| Queue Job ID Public API | 不採用 |

---

## 80. 採用技術・方針一覧

| 項目 | 決定 |
|---|---|
| Primary Source of Truth | PostgreSQL |
| Default Execution | 同期 |
| Cache | Optional Optimization |
| Redis | MVP必須ではない |
| Cache Pattern | Cache-Aside |
| Cache Invalidation | Write後に明示 |
| Cache Transaction | DB Transaction外 |
| Cache Failure | 原則DB Fallback |
| Permission Cache | 不採用 |
| Queue Framework | Laravel Queue |
| Queue Driver | Infrastructureで決定 |
| Database Queue | 初期候補 |
| Redis Queue | Optional |
| Amazon SQS | AWS時候補 |
| Audit Queue | 不採用 |
| Permission Queue | 不採用 |
| Job Dispatch | Commit後 |
| Outbox | MVP不採用 |
| Job Payload | ID中心 |
| Eloquent Model Payload | 原則不採用 |
| Retry | Transient Failureのみ |
| Backoff | Exponential |
| Infinite Retry | 禁止 |
| Failed Job | 採用 |
| Idempotency | 必須方針 |
| Exactly Once前提 | 不採用 |
| Distributed Lock | 必要時のみ |
| Scheduler | Laravel Scheduler |
| Retired Employee自動削除 | 不採用 |
| Async API | Long-runningのみ |
| HTTP Status | 必要時202 |
| Queue Internal ID公開 | 不採用 |

---

## 81. 最終Architecture

通常Flow：

```text
HTTP Request
    ↓
Application Handler
    ↓
Domain
    ↓
Repository
    ↓
PostgreSQL
    ↓
Commit
    ↓
HTTP Response
```

これをDefaultとする。

---

## 82. Cache Flow

Cache採用時：

```text
Query
    ↓
Cache
    ├── Hit
    │    ↓
    │  Response
    │
    └── Miss
         ↓
     PostgreSQL
         ↓
       Cache
         ↓
      Response
```

Source of Truthは常にPostgreSQLとする。

---

## 83. Write + Cache Flow

```text
Application Handler
    ↓
BEGIN
    ↓
PostgreSQL Write
    ↓
COMMIT
    ↓
Cache Invalidate
```

Cache FailureによってBusiness TransactionをRollbackしない。

---

## 84. Async Flow

```text
HTTP Request
    ↓
Application Handler
    ↓
Business Transaction
    ↓
COMMIT
    ↓
Job Dispatch
    ↓
Queue
    ↓
Worker
    ↓
Application UseCase
```

Queue DriverはApplicationから隠蔽する。

---

## 85. Auditとの関係

Audit：

```text
Business Change
    +
Audit Insert
    ↓
Same Transaction
```

Async：

```text
Non-critical Follow-up
    ↓
Commit後
    ↓
Queue
```

この2つを混同しない。

---

## 86. 最終方針

Cache・Queue・Asyncでは、

> PostgreSQLと同期処理をDefaultとし、必要性が明確になった箇所だけOptimization / Asyncを導入する

ことを基本方針とする。

Cacheは、

```text
PostgreSQL
    → Source of Truth

Cache
    → Optional Optimization
```

とする。

RedisはMVP必須Dependencyとせず、

```text
Performance Requirement
Queue Requirement
Operational Requirement
```

が明確になった場合に追加する。

QueueはLaravel Queueへ統一し、

```text
Database
Redis
Amazon SQS
```

等のDriver選択をInfrastructure Decisionとして残す。

Business Criticalな、

```text
主要CRUD
Permission変更
Role変更
Audit
```

は同期処理を維持する。

非同期処理では、

```text
Commit
    ↓
Dispatch
```

を原則とし、Transaction途中でJobを実行可能にしない。

また、

```text
Retry
Idempotency
Failed Jobs
Observability
```

をQueue設計の基本要素とする。

MVPでは、

```text
Transactional Outbox
Distributed Lock中心設計
Redis必須構成
Write-behind Cache
Exactly Once前提
```

などの複雑なArchitectureは採用しない。

最終的に、

> PostgreSQL + Synchronous by Default + Optional Cache + Laravel Queue

というシンプルな構成を採用する。
