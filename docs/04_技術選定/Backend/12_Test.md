# Backend 技術・Library選定 - Test

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend におけるTest Strategyと採用技術を定義する。

対象：

- Test Framework
- Unit Test
- Application Test
- Integration Test
- Feature Test
- OpenAPI Contract Test
- Architecture Test
- Database Test
- Authentication / Authorization Test
- Transaction / Concurrency Test
- Queue / Cache Test
- Observability Test
- Fake / Mock方針
- Test Data
- Parallel Test
- Code Coverage
- CIでのTest実行方針

本Projectでは、

> Testの種類をLayerの責務に合わせて明確に分離する

ことを基本方針とする。

---

## 2. 基本方針

Test全体では以下を原則とする。

```text
Domain
    → Pure PHP Unit Test

Application
    → Unit / Application Test

Infrastructure
    → Integration Test

Presentation / API
    → Feature Test

OpenAPI
    → Contract Test

Architecture
    → Architecture Test
```

Testの目的は、

```text
Business Rule
Architecture Rule
Database Integrity
HTTP Contract
API Contract
```

をそれぞれ適切なLevelで保証することである。

---

## 3. Test Pyramid

本Projectでは以下を基本とする。

```text
                    E2E
                     ▲
                    / \
                   /   \
             Feature / Contract
                /         \
               /           \
        Integration / Application
            /                 \
           /                   \
          Domain / Unit Tests
```

方針：

```text
Domain Unit Test
    → 多い・高速

Application Test
    → 多め・高速

Integration Test
    → 必要なBoundary

Feature / Contract Test
    → API中心

E2E
    → 最小限
```

Slow TestへBusiness Rule Testを集中させない。

---

# Test Framework

## 4. Pest

Backend Test FrameworkとしてPestを採用する。

```text
Test Syntax
    → Pest

Underlying Test Framework
    → PHPUnit
```

Projectで新規作成するTestは原則Pest Styleへ統一する。

---

## 5. PHPUnit

PHPUnitはPestの基盤として利用する。

PHPUnit Class StyleをProject TestのDefaultにはしない。

ただし、

```text
Framework
Third-party Package
Existing Tooling
```

等とのIntegration上必要な場合まで禁止しない。

---

## 6. Pest Laravel Plugin

Laravel IntegrationにはPestのLaravel Pluginを利用する。

利用対象：

```text
HTTP Testing
Database Testing
Authentication
Laravel Fake
Application Container
```

Laravel標準Testing APIをPestから利用する。

---

# Domain Test

## 7. Domain Test

Domain LayerはPure PHP Unit Testを中心とする。

対象：

```text
Aggregate
Entity
Value Object
Domain Service
Domain Exception
Invariant
State Transition
```

Laravel ApplicationをBootしない。

---

## 8. Domain Testで利用しないもの

Domain Unit Testでは以下を利用しない。

```text
Laravel Container
Eloquent
PostgreSQL
HTTP
Queue
Cache
Filesystem
External API
```

Domain RuleをFrameworkから独立してTestする。

---

## 9. EmployeeSkill Invariant

EmployeeSkillの重要InvariantをDomain Testで保証する。

例：

```text
未経験
+
Level 1
    → OK
```

```text
未経験
+
Level 2〜5
    → Reject
```

```text
未経験
+
Experience Periodあり
    → Reject
```

```text
未経験
+
Last Usedあり
    → Reject
```

```text
実務経験あり
+
Experience Period < 1 month
    → Reject
```

```text
実務経験あり
+
Last Usedなし
    → Reject
```

```text
実務経験あり
+
Experience Period >= 1 month
+
Last Usedあり
    → OK
```

---

## 10. Aggregate Behavior

Aggregateの変更はBehavior Method経由でTestする。

例：

```text
EmployeeSkill.changeLevel()
Employee.retire()
Skill.deactivate()
```

Generic SetterをTestするArchitectureにはしない。

---

## 11. Value Object Test

Value ObjectはUnit Testする。

対象候補：

```text
EmployeeId
SkillId
UserId
ExperiencePeriod
YearMonth
```

確認対象：

```text
Valid Construction
Invalid Construction
Equality
Boundary Value
Conversion
```

---

## 12. Typed ID

Typed IDでは少なくとも以下をTestする。

```text
positive int
    → OK

0
negative value
    → Reject
```

DB bigintやHTTP stringへの変換はBoundary側のTestで確認する。

---

## 13. ExperiencePeriod

ExperiencePeriodでは、

```text
Total Months
```

をDomain Representationとする。

Boundary Valueを明示的にTestする。

---

## 14. YearMonth

YearMonthでは以下をTestする。

```text
Valid Year / Month
Invalid Month
December → January
Leap Yearを含むCalendar Boundary
String Conversion
```

YearMonthをTimestampとしてTestしない。

---

## 15. Domain Exception

Invariant違反時には期待するDomain Exceptionが発生することをTestする。

例：

```text
InvalidSkillLevelForUnexperiencedEmployee

InvalidExperiencePeriod

CannotRemoveLastPermissionAdministrator
```

HTTP StatusについてDomain Testでは検証しない。

---

# Application Test

## 16. Application Test

Application LayerではUseCase / Handlerを中心にTestする。

対象：

```text
Command Handler
Query Handler
Application Validation
Repository Coordination
ID Generation
Clock
AuditWriter
Transaction Coordination
```

---

## 17. Application Testの目的

Application Testでは、

> UseCaseが正しくOrchestrationされるか

を確認する。

Business RuleそのものはDomainへ委譲する。

---

## 18. Application Test例

例えば、

```text
RegisterEmployeeSkillHandler
```

では、

```text
Employee exists
Skill exists
Skill active
Duplicateなし
Input valid
    ↓
EmployeeSkill作成
    ↓
Repository保存
    ↓
Audit記録
```

を確認する。

---

## 19. Repository Fake

Application TestではRepository Interfaceに対してFakeを利用できる。

```text
Application
    ↓
EmployeeRepository
    ↓
FakeEmployeeRepository
```

Infrastructure DBへ接続しない。

---

## 20. Fake優先

Test Doubleの優先順位：

```text
Real Object
    ↓
Fake
    ↓
Stub
    ↓
Mock
```

Mock Frameworkへ過剰に依存しない。

---

## 21. Mockを使う場面

MockはInteraction自体に意味がある場合へ限定する。

候補：

```text
External Service Call
通知送信
一度のみ必要なSide Effect
```

Implementation内部のCall Sequenceを過剰に固定しない。

---

## 22. Mock中心設計を避ける

以下のようなTestを大量に作らない。

```text
expects findById once
expects save once
expects transaction once
expects ...
```

Implementation変更に弱くなるためである。

Result / Stateを中心にTestする。

---

# Clock

## 23. Clock Port

既に採用しているClock PortをTestで活用する。

Production：

```text
SystemClock
```

Test：

```text
FakeClock
```

---

## 24. Current Timeを固定する

Application / Domain TestではCurrent Timeを明示的に固定する。

例：

```text
2026-09-12T10:00:00Z
```

これにより、

```text
occurred_at
retired_at
Audit time
Retention判定
```

等をDeterministicにTestできる。

---

## 25. Current Time直接取得を避ける

Domain / Application Test対象Codeでは、

```text
now()
Carbon::now()
new DateTimeImmutable('now')
```

へ直接依存しない。

Clock経由とする。

---

# ID Generator

## 26. Fake ID Generator

Application TestではID GeneratorをFake化できる。

例：

```text
FakeEmployeeIdGenerator
    → EmployeeId(123)
```

Test結果をDeterministicにする。

---

## 27. Sequenceとの分離

Application TestではPostgreSQL Sequence自体をTestしない。

```text
Application
    → Fake ID Generator

Infrastructure
    → PostgreSQL Sequence
```

へ分離する。

---

# Infrastructure Test

## 28. Integration Test

Infrastructure LayerではIntegration Testを採用する。

対象：

```text
Eloquent Model
Repository Implementation
Mapper
Query Service
Migration
Database Constraint
PostgreSQL Sequence
Transaction
Pessimistic Lock
Infrastructure Adapter
```

---

## 29. Real PostgreSQL

Database Integration TestではProductionと同じPostgreSQLを利用する。

```text
Production
    → PostgreSQL

Local Integration Test
    → PostgreSQL

CI Integration Test
    → PostgreSQL
```

---

## 30. SQLiteを代用しない

Database TestでSQLiteをPostgreSQLの代替として利用しない。

理由：

```text
SQL Dialect
Sequence
Lock
Constraint
JSONB
timestamptz
Transaction Behavior
PostgreSQL-specific Feature
```

に差異があるため。

---

## 31. Test Database

Test専用PostgreSQL Databaseを用意する。

例：

```text
engineer_skill_management
engineer_skill_management_test
```

またはCIごとに専用Database / Containerを作成する。

Production DatabaseをTestから利用しない。

---

## 32. Migration

Integration Test DatabaseはMigrationから構築できる状態を維持する。

```text
Migration
    ↓
Test Database
```

Migrationが正しいSchemaを再現できることも重要なQualityとする。

---

# Repository Test

## 33. Repository Implementation

Repository Implementationでは以下を確認する。

```text
findById()
save()
Persistence Mapping
Reconstitution
Not Found
```

Repository Interface自体をTestするのではなく、Infrastructure実装をTestする。

---

## 34. Repository Round Trip

重要AggregateではRound Trip Testを利用する。

```text
Domain Aggregate
    ↓
Repository.save()
    ↓
PostgreSQL
    ↓
Repository.findById()
    ↓
Domain Aggregate
```

意味的に同一のDomain Stateが復元されることを確認する。

---

# Mapper Test

## 35. Mapper

Mapperは明示的なInfrastructure ComponentなのでTestする。

対象：

```text
toDomain()
fillModel()
```

---

## 36. Mapper対象

特に以下のBoundary変換を確認する。

```text
Typed ID
Enum
DateTimeImmutable
YearMonth
ExperiencePeriod
Nullable Field
```

---

## 37. MapperにBusiness Ruleを書かない

Mapper Testが複雑なBusiness Rule Testになった場合は、責務配置を見直す。

Mapperは、

```text
Persistence Representation
    ↕
Domain Representation
```

の変換へ限定する。

---

# Database Constraint

## 38. DB Constraint Test

DB ConstraintはReal PostgreSQLで確認する。

対象：

```text
PK
FK
UNIQUE
CHECK
NOT NULL
```

Application ValidationだけでIntegrityを保証したことにしない。

---

## 39. EmployeeSkill Unique

例えば、

```text
UNIQUE(employee_id, skill_id)
```

についてDuplicate INSERTがDBで拒否されることをIntegration Testする。

---

## 40. Constraint Translation

Known Constraint Violationが、

```text
Infrastructure Exception
    ↓
Semantic Application Error
```

へ適切に変換される場合、そのMappingもIntegration / Feature Testで確認する。

例：

```text
EmployeeSkill UNIQUE violation
    ↓
EmployeeSkillAlreadyExists
    ↓
409 Conflict
```

---

# PostgreSQL Sequence

## 41. Sequence Test

ID GeneratorのInfrastructure実装について、

```text
PostgreSQL Sequence
    ↓
nextval()
    ↓
positive bigint
    ↓
Typed ID
```

を確認する。

---

## 42. Sequence Gap

Sequenceの欠番を許容するため、

```text
1
2
3
4
```

のような完全連番をTest Requirementにしない。

---

# Transaction

## 43. Transaction Integration Test

Transactionは重要なBusiness OperationについてIntegration Testする。

確認対象：

```text
Commit
Rollback
Exception時Rollback
AuditとのAtomicity
```

---

## 44. Audit Atomicity

`09_Log・Audit.md`の決定に従い、

```text
Business Change
+
Audit Insert
```

が同一Transactionとなることを確認する。

例：

```text
Business Change成功
Audit Insert失敗
    ↓
ROLLBACK
    ↓
Business Changeも残らない
```

---

# Concurrency

## 45. Pessimistic Lock

Business Invariantに重要なPessimistic LockはReal PostgreSQLでTestする。

代表例：

```text
ADMINISTRATOR
+
can_manage_permissions = true
```

を最低1人維持するRule。

---

## 46. Concurrent Operation Test

必要な箇所では複数Transactionを利用してConcurrencyを確認する。

ただしConcurrency Testは、

```text
遅い
複雑
Flakyになりやすい
```

ため、Critical Invariantへ限定する。

---

## 47. Lock順序

複数RecordをLockするUseCaseでは、

```text
ID昇順
```

という既存Ruleが守られていることを重要Scenarioで確認する。

---

# Query Service

## 48. Query Service Test

Read Side Query ServiceはIntegration Testする。

対象：

```text
Filter
Search
Sort
Pagination
Read Model Mapping
```

---

## 49. Query Test Data

Query Testでは明示的なFixtureを用意し、

```text
入力条件
    ↓
期待するResult Set
```

を確認する。

Sort / Paginationでは順序も明示的に検証する。

---

## 50. Sort Allowlist

許可していないSort Columnを利用できないことをPresentation / Query Testで確認する。

Raw User Inputをそのまま`ORDER BY`へ渡さない。

---

# Feature Test

## 51. Feature Test

Presentation / HTTP APIはLaravel Feature Testで確認する。

対象：

```text
Routing
Authentication
Authorization
Validation
Controller
Handler Integration
Resource Serialization
Exception Mapping
HTTP Status
Response Headers
Response JSON
```

---

## 52. Feature Testの粒度

例えばEmployeeSkill登録APIなら、

```text
Valid Request
    → 201

Unauthenticated
    → 401

Unauthorized
    → 403

Employee Not Found
    → 404

Duplicate
    → 409

Invalid Input
    → 422
```

を確認する。

---

# Serialization

## 53. API Representation

`08_Serialization・Date・ID.md`で定義したAPI RepresentationをFeature Testする。

必須確認：

```text
ID
    → string

Enum
    → backed value

Instant
    → timezone-aware RFC3339

YearMonth
    → YYYY-MM

Nullable
    → Contract通り
```

---

## 54. ID String

DatabaseではbigintだがPublic APIではstringとする。

例：

```json
{
  "id": "123"
}
```

Feature / Contract TestでNumberへ戻っていないことを確認する。

---

## 55. Request ID Conversion

Request Path / BodyのIDについて、

```text
positive digit string
    ↓
positive PHP int
    ↓
Typed ID
```

への変換をTestする。

以下をRejectする。

```text
0
-1
1.5
abc
PHP int範囲外
```

---

# Exception / Problem Details

## 56. Problem Details Test

`07_Exception・Error-Handling.md`に従い、HTTP Error ResponseはRFC 9457 Problem DetailsとしてTestする。

確認：

```text
Content-Type
    → application/problem+json

type
title
status
detail
instance
code
```

Validation Errorでは、

```text
errors
```

も確認する。

---

## 57. Internal Information Leak

Unexpected Error時に以下がResponseへ出ないことをTestする。

```text
Stack Trace
SQL
Database Host
Filesystem Path
Secret
Internal Exception Detail
```

---

# Validation

## 58. Form Request Test

Laravel Built-in Validationそのものを再Testしない。

例えば、

```text
required
string
integer
max
```

がLaravelで動くことをProject Testで網羅しない。

---

## 59. Project Validation Contract

Project固有のHTTP ContractをTestする。

対象：

```text
IDがpositive digit string
YearMonthがYYYY-MM
Enum値
Conditional Field
禁止Field
Cross-field HTTP Consistency
```

---

## 60. ValidationとDomain Rule

同じRuleを複数Layerで防御していても、それぞれの責務をTestする。

```text
Presentation
    → HTTP InputとしてReject

Domain
    → Aggregate InvariantとしてReject
```

一見重複していても目的が異なる。

---

# Authentication

## 61. Sanctum Authentication

Laravel BackendではSanctum Bearer Token AuthenticationをFeature Testする。

対象：

```text
Valid Token
Missing Token
Invalid Token
Expired Token
Revoked Token
Disabled User
```

---

## 62. Auth.js

Auth.js Browser Session自体はNext.js BFF側の責務とする。

Laravel Backend Testでは、

```text
Auth.js Login Flow
Browser Session Cookie
```

まで再現しない。

Laravelへ届くAuthenticated API RequestからTestする。

---

# Authorization

## 63. Policy Test

Laravel PolicyをTestする。

Role：

```text
Administrator
Manager
SubManager
TeamLeader
```

について主要OperationのAllowed / Deniedを確認する。

---

## 64. Relationship-based Authorization

特に以下を重点的に確認する。

```text
SubManager
    → Assigned Employeeのみ操作可能

TeamLeader
    → Assigned Employeeのみ閲覧可能
```

---

## 65. Administrator Permission

以下を確認する。

```text
role = ADMINISTRATOR
+
can_manage_permissions = true
    → Permission Management可能
```

どちらか一方だけではPermission Managementできない。

---

## 66. Permission Matrix

Role × Operation TestにはPest Datasetを利用する。

概念：

```text
Role
Operation
Expected Result
```

をData-drivenに定義する。

大量のほぼ同一Testをコピーしない。

---

# OpenAPI Contract Test

## 67. Contract Test

OpenAPI First方針に従いContract Testを正式採用する。

採用済み：

```text
kirschbaum-development/laravel-openapi-validator
```

Development Dependencyとして利用する。

---

## 68. OpenAPI Source of Truth

```text
OpenAPI
    → Source of Truth

Laravel
    → Implementation

Contract Test
    → Drift Detection
```

とする。

LaravelからOpenAPIを生成しない。

---

## 69. Contract Test対象

確認対象：

```text
Request
Response
HTTP Status
Content-Type
Required Field
Schema
Enum
ID String
date-time
date
YearMonth
Problem Details
Validation Problem Details
```

---

## 70. Feature Testとの違い

Feature Test：

```text
HTTP / Business Behaviorが正しいか
```

Contract Test：

```text
OpenAPI Contractと一致するか
```

両方を利用する。

Contract TestだけでBusiness Correctnessを保証しない。

---

# Architecture Test

## 71. Architecture Test

Pest Architecture Testingを正式採用する。

Clean ArchitectureのDependency RuleをCIで機械的に検証する。

---

## 72. Domain Dependency Rule

Domainは以下へ依存してはならない。

```text
Illuminate
Laravel
Eloquent
Presentation
Infrastructure
HTTP
Database
OpenTelemetry
Logging Framework
```

---

## 73. Application Dependency Rule

Applicationは以下へ依存させない。

```text
Presentation
Eloquent
Infrastructure Implementation
HTTP Request
JsonResponse
Laravel Controller
```

Laravel依存は極力避ける。

---

## 74. Infrastructure Dependency Rule

Infrastructureは、

```text
Domain Interface
Application Port
```

を実装できる。

逆方向Dependencyを発生させない。

---

## 75. Presentation Dependency Rule

Presentationは、

```text
Application
Laravel HTTP
```

を利用できる。

Domain Aggregateを直接Persistence目的で操作しない。

---

## 76. Eloquent Leak

特に、

```text
Domain
Application
```

へEloquent Model / Builderが侵入しないことをArchitecture Testで保証する。

---

## 77. Framework Independence

Architecture Testは今回のProjectにおいて重要Quality Gateとする。

理由：

```text
Clean Architecture
DDD
Framework Isolation
```

を学習目的も含めて明示的に採用しているため。

---

# Browser / E2E

## 78. Backend Browser Test

BackendではLaravel Duskを採用しない。

BackendはAPI Applicationなので、

```text
Feature Test
Integration Test
Contract Test
```

を中心とする。

---

## 79. Frontend E2E

Browser E2E TestはFrontend / BFF側で実施する。

例：

```text
Browser
    ↓
Next.js
    ↓
BFF
    ↓
Laravel
```

までをSystem E2E Testとして扱う。

Backend単体のTest Strategyと分離する。

---

# Test Directory

## 80. Directory構成

以下を推奨構成とする。

```text
tests/
├── Unit/
│   ├── Domain/
│   │   ├── EmployeeManagement/
│   │   ├── SkillManagement/
│   │   └── AccessControl/
│   │
│   └── Application/
│
├── Integration/
│   ├── Infrastructure/
│   │   ├── Persistence/
│   │   ├── Repository/
│   │   ├── Query/
│   │   └── Adapter/
│   │
│   └── Database/
│
├── Feature/
│   └── Api/
│
├── Contract/
│   └── OpenApi/
│
└── Architecture/
```

---

## 81. Bounded Context単位

各Test Directory内部はProduction Codeと同様にBounded Contextを意識する。

例：

```text
tests/
└── Unit/
    └── Domain/
        ├── EmployeeManagement/
        ├── SkillManagement/
        └── AccessControl/
```

Test Codeから対象Contextを追いやすくする。

---

# Test Naming

## 82. Behavior-based Naming

Test NameはMethod NameよりBehaviorを表現する。

推奨：

```text
it rejects an unexperienced skill above level 1
```

```text
it prevents removing the last permission administrator
```

---

## 83. Test Nameの原則

Test名から、

```text
Condition
Expected Behavior
```

が理解できるようにする。

---

# Test Structure

## 84. Arrange / Act / Assert

基本構造：

```text
Arrange
Act
Assert
```

とする。

ただし短いTestでAAA Commentの記述を強制しない。

読みやすさを優先する。

---

# Test Data

## 85. Eloquent Factory

Integration / Feature TestではLaravel Model Factoryを利用する。

候補：

```text
UserFactory
EmployeeFactory
SkillFactory
SkillCategoryFactory
```

---

## 86. Domain TestでEloquent Factoryを使わない

Domain Unit TestではEloquent Factoryを利用しない。

必要に応じて軽量なTest Builder / Test Factoryを作成する。

---

## 87. Test Data Builder

Aggregate生成が複雑になった場合のみ、

```text
Test Data Builder
Object Mother
```

を導入する。

最初から巨大なFixture Frameworkを構築しない。

---

## 88. Explicit Data

Business Rule TestではExplicitなValueを優先する。

例：

```text
experience_months = 0
experience_months = 1
skill_level = 1
skill_level = 2
```

Random Valueへ依存させない。

---

## 89. Faker

Fakerは、

```text
非重要Field
大量Fixture
```

で利用できる。

Business Boundary Testでは明示値を優先する。

---

# Deterministic Test

## 90. Deterministic

TestはDeterministicであることを要求する。

避ける：

```text
Current Time直接依存
Uncontrolled Random
Real External Network
Execution Order Dependency
Shared Mutable State
```

---

## 91. External API

通常CIではReal External APIへ接続しない。

利用：

```text
Http::fake()
Stub
Fake Adapter
Test Server
```

Real Sandbox Integrationが必要な場合は別Test Suiteへ分離する。

---

# Laravel Fake

## 92. Laravel Fake

必要に応じ以下を利用する。

```text
Queue::fake()
Notification::fake()
Mail::fake()
Http::fake()
Storage::fake()
```

Framework自身の内部Behaviorを再実装してMockしない。

---

## 93. Fakeしすぎない

Integration Boundaryそのものを検証したいTestではFakeを利用しない。

例：

```text
Repository Integration Test
    → PostgreSQLをFakeしない
```

Test目的に応じて使い分ける。

---

# Queue

## 94. Queue Test

`11_Cache・Queue・Async.md`に従い、Queue利用時は以下をTestする。

```text
Job Dispatch
Payload
Commit後Dispatch
Retryable Failure
Non-retryable Failure
Idempotency
```

---

## 95. afterCommit

重要なJobではTransaction Commit前にWorkerから見える状態にならないことを確認する。

Laravel Framework自体を再Testするのではなく、Project Configuration / Usageを確認する。

---

## 96. Job Business Logic

Job内部のBusiness RuleをTestするのではなく、Application UseCaseをTestする。

Job Testは、

```text
correct UseCase invocation
correct input
correct retry behavior
```

中心とする。

---

# Cache

## 97. Cache Test

Cacheを実際に導入した機能だけTestする。

対象：

```text
Cache Hit
Cache Miss
Cache Invalidation
Database Fallback
```

MVPでCacheを利用していない箇所に不要なCache Testを作らない。

---

# Audit

## 98. Audit Test

Auditは重要Requirementなので明示的にTestする。

```text
Operation成功
    → Auditあり

Operation失敗
    → Success Auditなし

Audit Failure
    → Business Transaction Rollback
```

---

## 99. Audit Data

重要なAuditでは以下を確認する。

```text
actor_user_id
action
target_type
target_id
request_id
before_data
after_data
occurred_at
```

Sensitive DataがAuditへ入らないことも確認する。

---

# Observability

## 100. Observability Test

`10_Observability.md`に従い、Project固有部分をTestする。

対象候補：

```text
Health Endpoint
Readiness
Request ID
Trace Context Propagation
Sensitive Data Sanitization
重要Custom Span
```

---

## 101. OpenTelemetry SDK

OpenTelemetry SDK自体のInternal BehaviorをProject Testで再Testしない。

Project独自Instrumentationのみ必要な範囲で確認する。

---

# Health

## 102. Health Test

以下をFeature Testする。

```text
Liveness Healthy
    → 200

Readiness Healthy
    → 200

Critical Dependency Failure
    → 503

Internal Detail
    → Responseへ出ない
```

---

# Security

## 103. Sensitive Data Test

Logging / Error / Telemetry Boundaryでは必要に応じ以下が出力されないことをTestする。

```text
Password
Authorization Header
Sanctum Token
Auth.js Session Token
Cookie
Secret
```

---

# Database Isolation

## 104. Test Isolation

各Testは独立したStateを持つ。

```text
Test A
    ↓
Clean State

Test B
    ↓
Clean State
```

Test実行順序へ依存しない。

---

## 105. RefreshDatabase

Integration / Feature TestではLaravelのDatabase Reset機構を利用できる。

ただし、

```text
Transaction Behavior
Concurrency
Pessimistic Lock
```

そのものをTestする場合はTest Framework側のTransactionが干渉しないよう個別に構成する。

---

# Test Environment

## 106. Testing Environment

Test専用Configurationを利用する。

例：

```text
APP_ENV=testing
APP_DEBUG=false
```

DatabaseはTest専用PostgreSQLとする。

---

## 107. Queue / Cache

通常Testでは必要に応じ、

```text
CACHE_STORE=array
QUEUE_CONNECTION=sync
```

等を利用する。

ただし、

```text
Queue Integration Test
Cache Integration Test
```

では対象Driverへ切り替える。

---

## 108. Secrets

Production CredentialsをTestへ利用しない。

Test / CI専用Secretを利用する。

RepositoryへSecretをCommitしない。

---

# Parallel Testing

## 109. Parallel Test

Test Suiteが増加した段階でParallel Testを採用する。

特にCI時間短縮に利用する。

---

## 110. Database Isolation

Parallel TestではProcessごとにDatabase Stateを分離する。

```text
worker 1
    → test database 1

worker 2
    → test database 2
```

等のIsolationを保証する。

---

# Test Suite

## 111. Suite分割

CIで以下のSuiteを独立実行可能にする。

```text
Unit
Architecture
Integration
Feature
Contract
```

---

## 112. Fast Feedback

CIでは可能なら、

```text
Unit
Architecture
    ↓
Integration
Feature
Contract
```

のようにFast Testを先に実行する。

早期Failureを検出する。

---

## 113. Local Development

Localでは変更対象に応じたTestを高速に実行できる状態を重視する。

毎回Full Test Suiteを実行しなければ開発できない構成を避ける。

---

# CI

## 114. Pull Request

Pull Requestでは原則以下をすべて実行する。

```text
Unit
Architecture
Integration
Feature
Contract
```

具体的なCI Workflowは`16_CI・Automation.md`で定義する。

---

# Coverage

## 115. Code Coverage

Code Coverageを補助指標として利用する。

目的：

> Testされていない重要Codeを発見する

こと。

---

## 116. 100% Coverage

以下をGoalにしない。

```text
Coverage = 100%
```

Coverageを上げるためだけのValueの低いTestを書かない。

---

## 117. Layer別重要度

Coverageの重要度はLayerで異なる。

```text
Core Domain
    → 高いCoverageを重視

Application
    → UseCase Coverageを重視

Infrastructure
    → Scenario / Integration Test重視

Presentation
    → API Contract重視
```

---

## 118. Numeric Threshold

MVP開始時点では根拠なく、

```text
80%
90%
100%
```

等の一律Coverage Thresholdを固定しない。

実際のTest Suiteを構築後に必要ならQuality Gateとして設定する。

---

# Mutation Testing

## 119. Mutation Testing

Mutation Testingは将来候補とする。

候補：

```text
Infection
```

Core DomainのTest Quality評価には有効だが、MVP必須にはしない。

---

# Snapshot Test

## 120. Snapshot Testing

API Response全体のSnapshot TestをDefaultにしない。

理由：

```text
意図しない変更までSnapshot化
Updateが機械的になりやすい
Contract Intentが分かりにくい
```

---

## 121. Explicit Assertion優先

APIについては、

```text
Feature Assertions
+
OpenAPI Contract Test
```

を優先する。

Snapshotは明確なBenefitがある場合のみ利用する。

---

# Flaky Test

## 122. Flaky Test

Flaky Testを放置しない。

```text
たまにFailure
    ↓
Retryすればよい
```

を通常運用にしない。

---

## 123. Test Retry

CI側のAutomatic Retryは限定的に利用する。

Retryで隠すのではなく原因を修正する。

---

# Library採用判断

## 124. 採用技術

| Library / 技術 | 判断 |
|---|---|
| Pest | 採用 |
| PHPUnit | Pest基盤として採用 |
| Pest Laravel Plugin | 採用 |
| Pest Architecture Testing | 採用 |
| Laravel HTTP Test | 採用 |
| Laravel Model Factory | 採用 |
| Laravel Fake | 適切に採用 |
| Real PostgreSQL Test | 採用 |
| SQLite Test DB | 不採用 |
| OpenAPI Contract Test | 採用 |
| `kirschbaum-development/laravel-openapi-validator` | 採用済み |
| Laravel Dusk | Backendでは不採用 |
| Mock中心設計 | 不採用 |
| Fake中心Application Test | 採用 |
| Parallel Test | Test増加後採用 |
| Code Coverage | 補助指標として採用 |
| Coverage 100%目標 | 不採用 |
| Mutation Testing | 将来候補 |
| Snapshot中心Test | 不採用 |

---

## 125. Test Type一覧

| 対象 | Test Type |
|---|---|
| Aggregate | Unit |
| Value Object | Unit |
| Domain Service | Unit |
| Domain Invariant | Unit |
| Command Handler | Application / Unit |
| Query Handler | Application / Unit |
| Repository Interface利用 | FakeによるApplication Test |
| Repository Implementation | Integration |
| Mapper | Integration |
| Eloquent | Integration |
| Migration | Integration |
| DB Constraint | Integration |
| PostgreSQL Sequence | Integration |
| Transaction | Integration |
| Pessimistic Lock | Critical CaseのみIntegration |
| Query Service | Integration |
| Authentication | Feature |
| Authorization | Feature / Policy |
| Form Request | Feature |
| Controller | Feature |
| Resource Serialization | Feature |
| Exception Mapping | Feature |
| RFC 9457 | Feature |
| OpenAPI | Contract |
| Layer Dependency | Architecture |
| Queue Dispatch | Feature / Application |
| Queue Job | Unit / Integration |
| Cache | 使用時のみIntegration |
| Health | Feature |
| Custom Observability | Feature / Integration |

---

# 最終Test Architecture

## 126. Domain

```text
Domain
    ↓
Pure PHP
    ↓
Pest Unit Test
```

Framework / Databaseなしで高速に実行する。

---

## 127. Application

```text
Application Handler
    ↓
Fake Repository
Fake Clock
Fake ID Generator
Fake AuditWriter
    ↓
Pest Application Test
```

UseCase Orchestrationを確認する。

---

## 128. Infrastructure

```text
Repository / Mapper / Query Service
    ↓
Eloquent / Query Builder
    ↓
Real PostgreSQL
    ↓
Integration Test
```

Productionと同じDatabase Engineで確認する。

---

## 129. Presentation

```text
HTTP Request
    ↓
Laravel Routing
    ↓
Authentication
Authorization
Validation
Controller
Handler
Resource
Exception Mapping
    ↓
Feature Test
```

実際のAPI Behaviorを確認する。

---

## 130. Contract

```text
OpenAPI
    ↓
Laravel API
    ↓
Contract Validator
```

Schema DriftをCIで検出する。

---

## 131. Architecture

```text
Domain
Application
Presentation
Infrastructure
    ↓
Pest Architecture Test
```

Clean ArchitectureのDependency Ruleを自動で維持する。

---

## 132. 最終方針

Backend Testでは、

> LayerごとにTest目的を分離し、Business Ruleは高速に、Infrastructure BoundaryはReal Componentで検証する

ことを中心方針とする。

特に、

```text
Domain
    → Pure PHP Unit Test

Application
    → Fake中心のUseCase Test

Infrastructure
    → Real PostgreSQL Integration Test

Presentation
    → Laravel Feature Test

OpenAPI
    → Contract Test

Architecture
    → Pest Architecture Test
```

という構成を採用する。

Database TestではSQLiteを利用せず、Productionと同じPostgreSQLを利用する。

MockをDefaultにせず、

```text
Real Object
Fake
Stub
Mock
```

の順でSimpleなTest Doubleを優先する。

また、Architecture Testによって、

```text
Domain → Laravel依存禁止
Domain → Infrastructure依存禁止
Application → Eloquent依存禁止
Application → Presentation依存禁止
```

等のRuleをCIで継続的に保証する。

CoverageはQualityの補助指標とし、100%自体を目的にしない。

最終的に、

```text
Pest
+
PHPUnit
+
Laravel Testing
+
Real PostgreSQL
+
OpenAPI Contract Test
+
Architecture Test
```

をBackend Test Strategyの基本構成として採用する。
