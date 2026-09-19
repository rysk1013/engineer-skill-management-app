# Backend 技術選定

## 1. 本ディレクトリの目的

本ディレクトリでは、Engineer Skill Management App のBackendで採用する技術・Library・Framework・開発ツール・運用方針を管理する。

対象：

```text
Language / Framework
HTTP / API
Authentication / Authorization
Domain / Application
Database / ORM
Validation
Exception / Error Handling
Serialization / Date / ID
Logging / Audit
Observability
Cache / Queue / Async
Testing
Static Analysis / Code Quality
Developer Experience
Security
CI / Automation
```

本ディレクトリは、Backend Architectureで決定した設計を、

> どの技術・Library・Framework・Toolで実現するか

へ落とし込むことを目的とする。

---

## 2. Backend技術選定の基本方針

技術選定では、以下の順序を基本とする。

```text
PHP Standard
    ↓
Laravel Standard
    ↓
Laravel First-party
    ↓
External Package
    ↓
Custom Implementation
```

Libraryを追加すること自体を目的としない。

以下を基準に技術を選定する。

```text
Maintainability
Type Safety
Testability
Security
Observability
Reproducibility
Developer Experience
```

---

## 3. Architectureとの関係

Backend Architectureでは、

```text
Clean Architecture
+
Domain-Driven Design
+
Lightweight CQRS
```

を採用する。

本ディレクトリでは、そのArchitectureを実装するための具体的な技術を定義する。

```text
Backend Architecture
    ↓
Design Rules
    ↓
Backend Technology Selection
    ↓
Implementation
```

---

## 4. Backend Technology Stack

主要Technology Stack：

```text
Language
└── PHP 8.5

Framework
└── Laravel 13

Database
└── PostgreSQL 18.x

Persistence
├── Eloquent
└── Laravel Query Builder

API
├── REST
├── OpenAPI 3.1.x
├── Laravel Form Request
├── Laravel JsonResource
└── RFC 9457 Problem Details

Authentication
├── Auth.js
└── Laravel Sanctum

Authorization
└── Laravel Policy

Architecture
├── Clean Architecture
├── DDD
└── Lightweight CQRS

Testing
├── Pest
├── PHPUnit
├── Real PostgreSQL
├── OpenAPI Contract Test
└── Pest Architecture Test

Code Quality
├── PHPStan
├── Larastan
├── Laravel Pint
├── PHPMD
└── Rector

Observability
├── OpenTelemetry
├── OTLP
├── Monolog
└── Structured Logging

Development
├── Docker
├── Docker Compose
├── Make
└── Xdebug

Security
├── Laravel Rate Limiting
├── Composer Audit
├── Dependabot
├── Secret Scanning
└── Trivy

CI / Automation
└── GitHub Actions
```

Auth.jsはBackend Packageではなく、BFFとのAuthentication Architectureを構成する関連技術として記載する。

---

## 5. Backend全体像

```text
Browser
    ↓
Next.js / Auth.js
    ↓
BFF
    ↓
Sanctum Bearer Token
    ↓
Laravel Backend
    ↓
PostgreSQL
```

Backend内部：

```text
Presentation
    ↓
Application
    ↓
Domain

Infrastructure
    ├── Repository Implementation
    ├── Mapper
    ├── Eloquent
    ├── Query Service
    ├── External Adapter
    └── Framework Integration
```

---

## 6. Layer Dependency

基本Dependency：

```text
Presentation
    ↓
Application
    ↓
Domain
```

InfrastructureはDomain / Applicationで定義されたInterfaceを実装する。

Framework依存方針：

```text
Presentation
    → Laravel依存可

Application
    → Laravel依存を最小化

Domain
    → Pure PHP

Infrastructure
    → Laravel / Eloquent / External Library依存可
```

Domainは以下へ依存しない。

```text
Laravel
Eloquent
HTTP
Database
Logging Framework
OpenTelemetry
```

---

## 7. Core Domain

Bounded Context：

```text
Employee Management
Skill Management
Access Control
Authentication
```

Core Domain：

```text
Skill Management
```

主要Aggregate Root：

```text
Department
Employee
SkillCategory
Skill
EmployeeSkill
User
```

特に `EmployeeSkill` は、Skill Managementにおける重要なAggregateとして扱う。

---

## 8. Document構成

```text
Backend/
├── README.md
├── 01_基本技術.md
├── 02_HTTP・API.md
├── 03_認証・認可.md
├── 04_Domain・Application.md
├── 05_Database・ORM.md
├── 06_Validation.md
├── 07_Exception・Error-Handling.md
├── 08_Serialization・Date・ID.md
├── 09_Log・Audit.md
├── 10_Observability.md
├── 11_Cache・Queue・Async.md
├── 12_Test.md
├── 13_Static-Analysis・Code-Quality.md
├── 14_Developer-Experience.md
├── 15_Security.md
├── 16_CI・Automation.md
└── 17_採用技術一覧.md
```

---

## 9. Documentの責務

### `01_基本技術.md`

Backendの基盤Technologyを定義する。

主な対象：

```text
PHP
Laravel
Composer
PostgreSQL
Docker
Coding Policy
Dependency Policy
```

---

### `02_HTTP・API.md`

HTTP APIの技術・Contractを定義する。

主な対象：

```text
REST
OpenAPI First
Routing
API Versioning
Controller
Form Request
JsonResource
HTTP Status
RFC 9457
Pagination
Filtering
Sorting
Contract Test
```

---

### `03_認証・認可.md`

Authentication / Authorization Architectureを定義する。

主な対象：

```text
Auth.js
Laravel Sanctum
Bearer Token
Token Lifecycle
Laravel Policy
Role
Employee Assignment
Special Permission
```

---

### `04_Domain・Application.md`

Domain / Application Layerで使用する技術と実装方針を定義する。

主な対象：

```text
Aggregate
Entity
Value Object
Enum
Domain Service
Repository Interface
Command
Query
Handler
Read Model
ID Generator Port
Clock Port
```

---

### `05_Database・ORM.md`

Persistence技術を定義する。

主な対象：

```text
PostgreSQL
Eloquent
Query Builder
Repository Implementation
Mapper
Migration
Constraint
Sequence
Transaction
Lock
Index
```

---

### `06_Validation.md`

Validationの責務分離と実装方針を定義する。

```text
Presentation
    → Input Validity

Application
    → UseCase Validity

Domain
    → Business Validity

Database
    → Data Integrity
```

---

### `07_Exception・Error-Handling.md`

ExceptionとExternal Error Contractを定義する。

主な対象：

```text
Domain Exception
Application Exception
Infrastructure Exception
Central Exception Handling
RFC 9457 Problem Details
Stable Error Code
```

---

### `08_Serialization・Date・ID.md`

API / Application / Domain / Database間のRepresentationを定義する。

主な対象：

```text
JsonResource
DateTimeImmutable
UTC
RFC3339
YearMonth
ExperiencePeriod
Entity ID
```

---

### `09_Log・Audit.md`

LoggingとAuditを定義する。

```text
Application Log
Security Log
Audit Log
```

を明確に分離する。

---

### `10_Observability.md`

Production Observabilityを定義する。

主な対象：

```text
Logs
Metrics
Traces
Health
OpenTelemetry
OTLP
Request ID
Trace ID
SLI
Alert
```

---

### `11_Cache・Queue・Async.md`

Cache / Queue / Async Processingの導入基準を定義する。

基本：

```text
PostgreSQL
+
Synchronous Processing
```

をDefaultとする。

---

### `12_Test.md`

Backend Test Strategyを定義する。

主な対象：

```text
Pest
Unit Test
Application Test
Integration Test
Feature Test
Contract Test
Architecture Test
Real PostgreSQL
```

---

### `13_Static-Analysis・Code-Quality.md`

Static Analysis / Formatting / Complexity / Refactoringを定義する。

主な対象：

```text
PHPStan
Larastan
Pint
PHPMD
Pest Architecture
Rector
```

---

### `14_Developer-Experience.md`

Local DevelopmentとDeveloper Workflowを定義する。

主な対象：

```text
Makefile
Composer Scripts
Docker Compose
Xdebug
.editorconfig
Seeder
Git Hooks
```

---

### `15_Security.md`

Backend Securityの基本方針を定義する。

主な対象：

```text
Authentication
Authorization
Input Security
Output Security
Rate Limiting
CORS
HTTPS
Secrets
Dependency Security
Container Security
Security Testing
```

---

### `16_CI・Automation.md`

CI / Automation / Deployment Flowを定義する。

主な対象：

```text
GitHub Actions
Required Checks
Branch Protection
Testing
Security Scan
Trivy
Container Build
Immutable Artifact
Staging Deployment
Production Approval
Migration
```

---

### `17_採用技術一覧.md`

`01`〜`16`で決定した技術を一覧化する。

主な対象：

```text
採用
条件付き採用
将来候補
不採用
```

詳細なWhy / Howは各Documentへ委譲する。

---

## 10. Document責務の違い

```text
README
    → Where / How to read

01〜16
    → Why / How / Rules

17
    → What / Decision Index
```

READMEや`17_採用技術一覧.md`へ詳細設計を重複記述しない。

---

## 11. 推奨読了順

### Backend全体を素早く把握する場合

```text
README
    ↓
17_採用技術一覧
    ↓
必要な詳細Document
```

---

### Backend技術選定を体系的に理解する場合

```text
README
    ↓
01
    ↓
02
    ↓
03
    ↓
...
    ↓
16
    ↓
17
```

---

### 実装時

実装対象に対応するDocumentを参照する。

例：

```text
API Endpoint実装
    ↓
02_HTTP・API
06_Validation
07_Exception・Error-Handling
08_Serialization・Date・ID
15_Security
```

```text
Repository実装
    ↓
04_Domain・Application
05_Database・ORM
12_Test
```

```text
CI構築
    ↓
12_Test
13_Static-Analysis・Code-Quality
15_Security
16_CI・Automation
```

---

## 12. 重要Decision Quick Reference

### Architecture

```text
Clean Architecture
+
DDD
+
Lightweight CQRS
```

---

### Domain

```text
Domain
    → Framework Independent
```

Domain ModelとEloquent Modelを分離する。

```text
Domain Model
    ≠
Eloquent Model
```

---

### Persistence

```text
Eloquent
    → Infrastructure Only
```

Write：

```text
Aggregate
    ↓
Repository
    ↓
Mapper
    ↓
Eloquent
    ↓
PostgreSQL
```

Read：

```text
Query
    ↓
Query Handler / Query Service
    ↓
Query Builder
    ↓
Read Model
```

---

### API

```text
OpenAPI
    = Source of Truth
```

Laravel実装からOpenAPIを生成しない。

---

### API ID

```text
Database
    → bigint

PHP
    → positive int + Typed ID

API
    → positive digit string

TypeScript
    → string
```

---

### Error

```text
RFC 9457 Problem Details
```

を採用する。

```text
application/problem+json
```

Project Extension：

```text
code
errors
```

---

### Authentication

```text
Browser
    ↓
Auth.js Session
    ↓
BFF
    ↓
Sanctum Bearer Token
    ↓
Laravel
```

Sanctum TokenをBrowserへExposeしない。

---

### Authorization

```text
Frontend / BFF
    → UX Control

Laravel Policy
    → Security Boundary
```

---

### Validation

```text
Presentation
    → HTTP Input

Application
    → UseCase

Domain
    → Invariant

Database
    → Integrity
```

---

### Transaction

```text
1 UseCase
    =
1 Transaction
```

Application Handler Boundaryを基本とする。

---

### Concurrency

```text
READ COMMITTED
+
Pessimistic Lock when required
```

Lock OrderはID昇順を基本とする。

---

### Audit

```text
Business Mutation
+
Audit Insert
=
Same Transaction
```

Auditは非同期化しない。

---

### Cache / Queue

```text
PostgreSQL
+
Synchronous Processing
=
Default
```

RedisはMVP必須ではない。

Queueも必要性が発生した場合のみ導入する。

---

### Test

```text
Pest
+
Real PostgreSQL
+
OpenAPI Contract Test
+
Architecture Test
```

---

### Code Quality

```text
Pint
+
PHPStan / Larastan
+
PHPMD
+
Pest Architecture
+
Rector
```

---

### Observability

```text
OpenTelemetry
+
Structured Logging
+
Request ID
+
Trace Context
+
Health Check
```

---

### Security

```text
Defense in Depth
+
Explicit Input
+
Explicit Output
+
Backend Authorization
+
Supply-chain Security
```

Container Security ScanにはTrivyを採用する。

---

### CI / CD

```text
GitHub Actions
+
Required Checks
+
Immutable Container Image
+
Controlled Deployment
```

---

## 13. 採用Status

技術選定では以下のStatusを利用する。

| Status | 意味 |
|---|---|
| 採用 | MVPから正式利用する |
| 条件付き採用 | Requirementが発生した場合に利用する |
| 将来候補 | 現時点では利用しないが再検討対象 |
| 不採用 | 現Architecture / MVPでは利用しない |

詳細一覧は、

```text
17_採用技術一覧.md
```

を参照する。

---

## 14. 条件付きTechnology

以下のようなTechnologyは、最初からInfrastructureへ追加しない。

```text
Redis
Laravel Queue
Database Queue
Redis Queue
Amazon SQS
Laravel Horizon
Laravel Scheduler
```

Requirement / Measurementによって必要性が確認された時点で導入する。

---

## 15. Provider未決定項目

Architecture StandardとProvider選定を分離する。

例：

```text
Observability Standard
    → OpenTelemetry

Observability Backend
    → Infrastructure決定時
```

Sentry等は候補であり、現時点で正式Providerとして固定しない。

---

## 16. Infrastructure依存候補

以下はBackend技術として確定していない。

```text
Render
AWS ECS
Amazon ECR
Amazon SQS
AWS Secrets Manager
AWS Systems Manager Parameter Store
AWS OIDC
Specific Observability Backend
```

Infrastructure / Deployment設計時に最終決定する。

Backend Documentでは、これらを確定済みTechnologyとして扱わない。

---

## 17. Source of Truth

情報の種類ごとにSource of Truthを分ける。

| 対象 | Source of Truth |
|---|---|
| API Contract | OpenAPI |
| Domain Rule | Domain Model |
| UseCase Rule | Application |
| Authorization | Backend Policy / Domain Rule |
| Database Schema | Migration |
| Dependency Version | Lockfile |
| Runtime Definition | Docker |
| Local Commands | Makefile / Composer Scripts |
| CI Validation | GitHub Actions + Project Scripts |
| Technology Decision | 本ディレクトリ |
| Technology一覧 | `17_採用技術一覧.md` |

---

## 18. OpenAPIとBackend

API変更では、

```text
Requirement
    ↓
OpenAPI
    ↓
Review
    ↓
Backend
    ↓
Frontend / BFF
    ↓
Contract Test
    ↓
CI
```

を基本Flowとする。

---

## 19. Architecture Documentとの関係

Backend Architecture Documentsは、

```text
How Backend is structured
```

を定義する。

Backend Technology Selection Documentsは、

```text
Which technology implements it
```

を定義する。

Architecture上のRuleをLibraryの都合で変更しない。

---

## 20. Non-functional Requirementとの関係

以下のような横断的RequirementはNon-functional Requirementを上位Requirementとして扱う。

```text
Performance
Availability
Security
Backup
Logging
Audit
Observability
Maintainability
API Quality
Deployment
Accessibility
Compatibility
Internationalization
Date / Time
```

Backend技術選定は、それらを実現する具体的なImplementation Decisionを定義する。

---

## 21. Package追加ルール

新しいComposer Packageを追加する場合、以下を確認する。

```text
1. PHP標準で解決できないか
2. Laravel標準で解決できないか
3. Laravel First-partyで解決できないか
4. 既存採用Packageで解決できないか
5. 継続的なProblemなのか
6. Custom CodeよりPackageが適切か
7. Maintenance状況は問題ないか
8. Security Riskは許容できるか
9. Test可能か
10. Domain / ApplicationへDependencyがLeakしないか
11. 将来Remove可能なBoundaryになっているか
```

---

## 22. Packageを追加しない理由

以下だけを理由にPackageを導入しない。

```text
Popular
Convenient
Laravelでよく使われる
DDDっぽい
CQRSっぽい
コード量が少し減る
```

Packageは具体的なProblemを解決するために導入する。

---

## 23. Framework依存ルール

Laravelは積極的に利用するが、Framework依存をすべてのLayerへ広げない。

```text
Presentation
Infrastructure
    → Laravelを積極利用

Application
    → Framework Dependency最小化

Domain
    → Pure PHP
```

Laravelを避けること自体を目的にはしない。

---

## 24. External Library依存ルール

External Libraryは可能な限りBoundaryの外側へ配置する。

```text
Domain
    ← Application
        ← Presentation / Infrastructure
            ← Framework / External Library
```

Domain ModelをPackage APIへ合わせない。

---

## 25. 技術選定変更ルール

採用Technologyを変更する場合、

```text
Requirement
    ↓
Impact確認
    ↓
該当Document更新
    ↓
17_採用技術一覧更新
    ↓
必要ならREADME更新
    ↓
Implementation
    ↓
Test / CI更新
```

とする。

---

## 26. Decision変更時の確認対象

Technology変更時は最低限以下への影響を確認する。

```text
Architecture
OpenAPI
Database
Security
Testing
CI
Developer Experience
Deployment
Documentation
```

---

## 27. Document更新ルール

詳細Decisionは該当する `01`〜`16` を先に更新する。

その後、

```text
17_採用技術一覧.md
```

を更新する。

READMEはNavigation / Overviewに影響する場合のみ更新する。

---

## 28. Decision重複を避ける

同じDecisionを複数Documentへ詳細にコピーしない。

例：

```text
RFC 9457詳細
    → 07_Exception・Error-Handling.md

README
    → RFC 9457採用のみ

17
    → RFC 9457 = 採用
```

とする。

---

## 29. Cross-document Consistency

後からDecisionが変更された場合、古いDecisionを残さない。

特に以下は横断的なDecisionとして統一する。

```text
API Error
    → RFC 9457 Problem Details

Validation Error Extension
    → errors

API Entity ID
    → positive digit string

Database Entity ID
    → bigint

Audit
    → synchronous

Redis
    → MVP mandatoryではない

OpenAPI
    → Source of Truth

Eloquent
    → Infrastructure only

Domain
    → Framework independent

Container Security
    → Trivy

CI / CD
    → GitHub Actions
```

---

## 30. 実装開始時の考え方

設計Documentをそのまま大量のBoilerplateへ変換しない。

必要なUseCaseからIncrementalに実装する。

```text
Requirement
    ↓
OpenAPI / UseCase
    ↓
必要なDomain Model
    ↓
Application Handler
    ↓
Infrastructure
    ↓
Presentation
    ↓
Test
```

---

## 31. Overengineeringの扱い

本Projectでは学習目的として、

```text
Clean Architecture
DDD
Lightweight CQRS
Repository / Mapper
Application Port
```

等を意図的に採用する。

一方で、

```text
Full CQRS
Event Sourcing
Microservices
Saga
Generic Framework
Excessive Interface
Excessive Abstraction
```

は導入しない。

---

## 32. Implementation Principle

実装では、

```text
Simple First
Explicit Boundary
Strong Type
Framework at the Edge
Test Important Behavior
Measure Before Optimize
```

を基本とする。

---

## 33. 最終構成

Backend技術選定全体は、

```text
PHP 8.5
+
Laravel 13
+
PostgreSQL 18.x
+
Docker
+
Clean Architecture
+
DDD
+
Lightweight CQRS
+
OpenAPI First
+
Sanctum
+
RFC 9457
+
Pest
+
Static Analysis
+
OpenTelemetry
+
Security Automation
+
GitHub Actions
```

を中心とする。

---

## 34. 最終原則

Engineer Skill Management App Backendでは、

> Architecture Boundaryを明確にしながら、PHP / Laravel標準機能を最大限活用し、必要性のないLibrary・Infrastructure・Abstractionを増やさない

ことを技術選定の基本原則とする。

```text
Architecture
    → Boundaryを守る

Domain
    → Business Ruleを守る

OpenAPI
    → External Contractを守る

Database
    → Data Integrityを守る

Test
    → Behaviorを守る

Static Analysis
    → Type / Code Qualityを守る

Security
    → Trust Boundaryを守る

Observability
    → Productionを理解可能にする

CI
    → Quality Gateを自動化する
```
