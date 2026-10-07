# Backend 技術・Library選定 - Observability

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend におけるObservability方針を定義する。

対象：

- Logs
- Metrics
- Traces
- Request ID / Trace ID
- OpenTelemetry
- Health Check
- Liveness / Readiness
- Error Monitoring
- Slow Query Monitoring
- Alerting
- Dashboard
- Telemetry DataのSecurity
- Environment / Release情報
- Library採用判断

本Projectでは、Observabilityを以下のSignalsで構成する。

```text
Logs
    → Eventを記録する

Metrics
    → System状態を数値で把握する

Traces
    → Request処理経路を追跡する

Health Check
    → Serviceが利用可能か判定する

Alerting
    → 異常を人へ通知する
```

---

## 2. 基本方針

Observabilityでは、

> System内部で何が起きているかを、Production環境でも外部から理解できる状態にする

ことを目的とする。

以下を基本原則とする。

- OpenTelemetryをObservability Standardとして採用する
- Vendor固有APIへの依存を最小化する
- Logs / Metrics / Tracesの役割を分離する
- Request IDとTrace IDを区別する
- Structured Telemetryを利用する
- Domain LayerへObservability依存を持ち込まない
- High Cardinality DataをMetricsへ入れない
- Sensitive DataをTelemetryへ出さない
- Health CheckをLiveness / Readinessへ分離する
- Error Monitoringを導入する
- AlertはActionが必要なEventへ限定する
- Business AnalyticsとSystem Observabilityを分離する

---

## 3. Loggingとの境界

`09_Log・Audit.md`で定義したLogging方針を継承する。

```text
Application Log
    → System Operation / Error Investigation

Security Log
    → Security Event

Audit Log
    → Business Operation Evidence

Metrics
    → Aggregate System State

Traces
    → Request Processing Flow
```

ObservabilityはAudit Logを代替しない。

また、Application LogだけでObservabilityを完結させない。

---

## 4. Observability Signals

本Projectでは以下を利用する。

| Signal | 採用 |
|---|---|
| Logs | 採用 |
| Metrics | 採用 |
| Traces | 採用 |
| Health Check | 採用 |
| Alerting | 採用 |
| Audit | 別設計として採用 |

基本構成：

```text
Application
    ├── Logs
    ├── Metrics
    ├── Traces
    └── Health

        ↓

Observability Platform

        ↓

Dashboard / Alert / Investigation
```

---

## 5. 段階導入

すべてをMVP初日から最大構成で導入しない。

推奨段階：

```text
Phase 1
├── Structured Logging
├── Request ID
├── Health Check
└── Error Monitoring

Phase 2
├── OpenTelemetry Trace
├── Metrics
├── Trace / Log Correlation
└── Slow Query Monitoring

Phase 3
├── Dashboard高度化
├── Alert最適化
├── Sampling最適化
└── SLO運用
```

Architectureとしては最初からOpenTelemetryを基準とする。

---

## 6. OpenTelemetry

Observability StandardとしてOpenTelemetryを採用する。

基本構成：

```text
Laravel Backend
    ↓
OpenTelemetry
    ↓
OTLP
    ↓
OpenTelemetry Collector
    ↓
Observability Backend
```

これによりApplicationを特定Observability Vendorへ強く依存させない。

---

## 7. Vendor Neutral方針

以下のようなVendor固有APIをApplication Code全体へ直接記述しない。

```text
Datadog::...
Sentry::...
CloudWatch::...
NewRelic::...
```

基本：

```text
Application
    ↓
OpenTelemetry Standard
```

Vendor固有機能が必要な場合もIntegration Boundaryを限定する。

---

## 8. OpenTelemetry Collector

ProductionではOpenTelemetry Collectorの利用を推奨する。

```text
Application
    ↓ OTLP
OpenTelemetry Collector
    ↓
Observability Backend
```

Collector側へ以下の責務を寄せられる。

```text
Routing
Filtering
Batching
Sampling
Export
Backend変更
```

Applicationが直接複数Backendへ送信する構成を避ける。

---

## 9. MVPでのCollector

OpenTelemetry CollectorはProductionで推奨するが、Local Developmentで必須にしない。

```text
Local
    → Collector Optional

Staging
    → Collector推奨

Production
    → Collector推奨
```

Observability Stackが停止していてもApplication Developmentを継続できる構成とする。

---

## 10. Auto Instrumentation

ObservabilityではAuto Instrumentationを優先する。

対象候補：

```text
HTTP Server Request
Laravel Framework
Database
HTTP Client
Queue
```

一般的なFramework処理へ手動Instrumentationを大量に追加しない。

---

## 11. Manual Instrumentation

Manual Instrumentationは重要なUseCaseやBoundaryへ限定する。

候補：

```text
RegisterEmployeeSkill
UpdateEmployeeSkill
ChangeUserRole
ChangeUserPermission
DeleteRetiredEmployee
```

例：

```text
HTTP Server Span
    ↓
RegisterEmployeeSkill
    ↓
PostgreSQL Query
```

すべてのMethodへSpanを付与しない。

---

## 12. Domain Instrumentation

Domain LayerではTracing / Metrics / Logging Frameworkを利用しない。

禁止例：

```php
$tracer->spanBuilder(
    'EmployeeSkill.changeLevel',
)->startSpan();
```

Domainは以下を維持する。

```text
Domain
    → Pure Business Logic
```

Observability Instrumentationは、

```text
Presentation
Application Boundary
Infrastructure
```

へ配置する。

---

## 13. Application Instrumentation

Application Handler BoundaryはManual Spanを追加する候補とする。

例：

```text
RegisterEmployeeSkillHandler
ChangeUserRoleHandler
```

ただし全Handlerへ機械的にInstrumentation Codeを埋め込まない。

共通Instrumentationが必要な場合はDecorator等によるCross-cutting実装を検討する。

---

## 14. Metrics基本方針

MetricsはSystem状態を数値として把握するために利用する。

代表Metrics：

```text
HTTP Request Rate
HTTP Error Rate
HTTP Response Duration
Database Duration
External Service Duration
Queue Processing Duration
Queue Failure
```

---

## 15. HTTP Metrics

HTTP APIでは最低限以下を観測する。

```text
Request Count
Request Duration
Status Code
Error Rate
```

Attribute候補：

```text
route
method
status_code
```

---

## 16. Route Template

MetricsではRaw URLをAttributeへ使用しない。

避ける：

```text
/api/v1/employees/123
/api/v1/employees/456
```

推奨：

```text
/api/v1/employees/{employee}
```

High Cardinalityを防ぐ。

---

## 17. Metrics High Cardinality

Metrics Label / Attributeへ以下を入れない。

```text
user_id
employee_id
skill_id
request_id
trace_id
email
name
search_keyword
```

理由：

```text
High Cardinality
    ↓
Metric Storage増加
Query Performance低下
Cost増加
```

MetricsはAggregate Dataを扱う。

---

## 18. Identifierの使い分け

以下を使い分ける。

```text
Metrics
    → Aggregate Dimension

Logs
    → request_id / user_id等

Traces
    → trace_id / span_id

Audit
    → actor / target / request_id
```

同じContextをすべてのSignalへ無条件に複製しない。

---

## 19. Database Metrics

Databaseでは以下を監視対象とする。

```text
Query Duration
Slow Query
Connection Failure
Connection Usage
Transaction Failure
```

全SQL TextをMetric Labelへ入れない。

---

## 20. Slow Query Monitoring

Slow Query Monitoringを採用する。

目的：

```text
Response遅延
N+1
Missing Index
Inefficient Query
Lock問題
```

を発見すること。

ThresholdはEnvironmentや実測値に応じて調整する。

初期調査基準として、

```text
500ms ～ 1s程度
```

を候補にできるが、固定Requirementとはしない。

---

## 21. Slow QueryとLogging

Productionでは全SQLを常時Logしない。

代わりに、

```text
Slow Query
    ↓
Metric
Trace
必要に応じWarning Log
```

として観測する。

SQL BindingへSensitive Dataが含まれる可能性を考慮する。

---

## 22. N+1

N+1は主に以下で防止する。

```text
Development
Test
Code Review
Query Design
```

Observabilityでは異常に多数のDB Spanや高Latencyから補助的に検出する。

Production Monitoringだけに依存しない。

---

## 23. External Service Metrics

External Service利用時には以下を観測する。

```text
Request Count
Duration
Status
Failure Count
Timeout Count
Retry Count
```

Attribute候補：

```text
service
operation
status_code
```

以下はAttributeへ出さない。

```text
Token
Authorization Header
Sensitive Query Parameter
Request Body
Response Body
```

---

## 24. Queue Metrics

Queue利用時は以下を監視する。

```text
Queued Job Count
Queue Latency
Processing Duration
Failed Job Count
Retry Count
```

Audit処理は既存方針通りQueue化しない。

---

## 25. Tracing

Tracingでは1つのRequestが複数Componentを通る処理経路を追跡する。

想定：

```text
Browser
    ↓
Next.js BFF
    ↓
Laravel Backend
    ↓
PostgreSQL
```

将来的には、

```text
BFF
    ↓
Backend
```

を同一Distributed Traceとして接続できる構成を目指す。

---

## 26. W3C Trace Context

Distributed Trace ContextにはW3C Trace Contextを利用する。

代表Header：

```text
traceparent
tracestate
```

独自Trace Headerを設計しない。

Trace Context PropagationはOpenTelemetryへ委ねる。

---

## 27. Trace ID

Trace IDは、

> Distributed Request Chain全体

を識別する。

例：

```text
Browser
    ↓
BFF
    ↓
Laravel
    ↓
External Service
```

これらを1つのTraceとして関連付ける。

---

## 28. Request IDとの違い

`09_Log・Audit.md`で採用したRequest IDとTrace IDは別Conceptとする。

```text
Request ID
    → 1 HTTP Requestを識別

Trace ID
    → Distributed処理全体を識別
```

例えば：

```text
Trace ID = A

BFF Request
    Request ID = B

Laravel Request
    Request ID = C
```

という構成を許容する。

---

## 29. Request ID

Request IDは継続して利用する。

```text
X-Request-ID
```

をResponseへ返す。

主用途：

```text
User問い合わせ
Application Log検索
Security Log検索
Audit Log検索
```

---

## 30. Log / Trace Correlation

Application Logへ以下をContextとして追加できるようにする。

```text
request_id
trace_id
span_id
```

これにより、

```text
Error Log
    ↓
trace_id
    ↓
Trace
    ↓
Database Span
External API Span
```

という調査を可能にする。

---

## 31. Audit / Trace Correlation

Audit Logでは既存方針通り、

```text
request_id
```

を必須Correlation Identifierとする。

MVPでは、

```text
trace_id
```

のAudit保存は必須としない。

必要性が明確になった場合に追加する。

---

## 32. Span Naming

Span Nameは安定した意味を持たせる。

推奨：

```text
RegisterEmployeeSkill
ChangeUserRole
```

避ける：

```text
RegisterEmployeeSkill:user=123
GET:/employees/123
```

Dynamic ValueをSpan Nameへ埋め込まない。

---

## 33. Span Attribute

AttributeもCardinalityとSensitive Dataに注意する。

利用候補：

```text
operation
resource_type
result
```

必要性が明確でない場合、

```text
user_id
employee_id
```

等をTraceへ大量に追加しない。

---

## 34. Sampling

Production TraceではSamplingを採用する。

基本：

```text
Normal Request
    → Sampling

Error / Important Trace
    → より高い保持率
```

具体的Sampling Rateは以下を考慮して決定する。

```text
Traffic
Storage Cost
Observability Backend
Incident Investigation Requirement
```

固定値をArchitectureで決め打ちしない。

---

## 35. Head / Tail Sampling

MVPでは高度なSampling StrategyをApplicationへ実装しない。

必要に応じてOpenTelemetry Collector等で、

```text
Head Sampling
Tail Sampling
```

を検討する。

Application側のBusiness LogicへSampling Ruleを混在させない。

---

## 36. Health Check

Health Checkを正式採用する。

最低限以下を分離する。

```text
Liveness
Readiness
```

---

## 37. Liveness

Livenessは、

> Application Processが動作可能か

を判定する。

例：

```http
GET /up
```

確認対象：

```text
Laravelが起動している
HTTP Responseを返せる
```

Database等の外部Dependencyを毎回確認しない。

---

## 38. Liveness Failure

Liveness Failureは、

> Process自体のRestartが必要な可能性がある

ことを意味する。

Database一時FailureだけでApplication ProcessをDead判定しない。

---

## 39. Readiness

Readinessは、

> 現在Trafficを処理できる状態か

を判定する。

例：

```http
GET /ready
```

確認候補：

```text
Application Boot完了
Database接続可能
Critical Dependency利用可能
```

---

## 40. Liveness / Readiness分離

以下を明確に分ける。

```text
/up
    → Process Alive?

/ready
    → Traffic Ready?
```

Dependency Failure時に、

```text
Liveness = Healthy
Readiness = Unhealthy
```

となる状態を許容する。

---

## 41. External Dependency Health

Readinessで全External Serviceへ毎回Requestしない。

理由：

```text
Health Check自体が負荷になる
Rate Limit消費
External Service障害とのCascade
Health Endpoint遅延
```

Critical Dependencyのみ対象とする。

---

## 42. PostgreSQL Health

PostgreSQLはBackendにとってCritical DependencyなのでReadiness対象候補とする。

ただし重いQueryは実行しない。

軽量Connection / Queryで確認する。

---

## 43. Health Response

Public Health Endpointへ内部情報を公開しない。

基本Response：

```json
{
  "status": "ok"
}
```

公開しない：

```text
Database Host
Database Version
Internal IP
Container Hostname
Stack Trace
SQL Error
Secret
Credential
```

---

## 44. Health HTTP Status

基本：

```text
Healthy
    → 200

Not Ready
    → 503
```

Health EndpointのConsumerが機械的に判定できるようにする。

---

## 45. Container / ECSとの連携

Health CheckはContainer Runtime / Load Balancerから利用可能にする。

将来AWS ECSを採用した場合も、

```text
Container
Load Balancer
Application
```

間でHealth判定を連携できるようにする。

Infrastructure固有設定はDeployment章で扱う。

---

## 46. Error Monitoring

Unexpected Errorを集約するError Monitoringを採用する。

対象：

```text
Unexpected Exception
Stack Trace
Environment
Release
Trace Context
Request Context
```

Expected Business ErrorをすべてError Monitoringへ送信しない。

---

## 47. Expected Error

以下は通常Error Monitoring対象としない。

```text
Validation Error
Expected Not Found
Expected Conflict
Expected Forbidden
```

Security上意味のあるFailureはSecurity Log側で扱う。

---

## 48. Sentry

SentryはError Monitoring Backendの有力候補とする。

ただし現時点ではBackend必須Dependencyとして確定しない。

位置付け：

```text
Observability Standard
    → OpenTelemetry

Error Monitoring Backend
    → Sentry候補
```

Production Infrastructure選定時に最終判断する。

---

## 49. Sentry Vendor Lock-in

Sentryを採用する場合もApplication全体をSentry固有APIへ依存させない。

例えば、

```text
Sentry::capture...
```

をDomain / Applicationへ大量に直接記述しない。

Integration Boundaryを限定する。

---

## 50. 二重Instrumentation

OpenTelemetryと別APM / Monitoring Agentを併用する場合、

```text
同じHTTP Request
同じDB Query
```

を二重Instrumentationしないよう注意する。

Observability Provider決定時にInstrumentation Responsibilityを整理する。

---

## 51. Performance Monitoring

Performance Monitoring対象：

```text
HTTP Latency
Database Latency
External Service Latency
Queue Latency
```

すべての内部Method Execution Timeを計測する必要はない。

User-visible Performanceと主要Dependencyを優先する。

---

## 52. RED Method

Web APIの基本MonitoringとしてREDを採用する。

```text
Rate
    → Request数

Errors
    → Error率

Duration
    → Response時間
```

Dashboardの基本指標とする。

---

## 53. Basic SLI

最初に確認するSLI：

```text
Availability
Request Rate
Error Rate
Latency
```

Database / External Serviceについても必要に応じ、

```text
Availability
Error Rate
Latency
```

を確認する。

---

## 54. SLO

SLOの概念は採用する。

ただし、

```text
Availability 99.99%
p95 100ms
```

等の具体値を根拠なく設定しない。

優先順位：

```text
Non-functional Requirement
    ↓
Production Measurement
    ↓
SLO
```

既存非機能要件に具体値がある場合はそちらをSource of Truthとする。

---

## 55. Alerting

Alertingを採用する。

Alert対象は、

> 人がActionを取る必要がある状態

へ限定する。

代表例：

```text
5xx Error Rate急増
Service Unavailable
Database Connection Failure継続
External Dependency Failure継続
Queue Failure急増
Readiness Failure継続
```

---

## 56. Alert Threshold

単発EventですぐAlertしない。

以下を組み合わせる。

```text
Rate
Threshold
Duration
Frequency
```

例：

```text
5xxが1件
    → Alertしない可能性

5xx Rateが一定時間急増
    → Alert
```

---

## 57. Alert Fatigue

以下のようなAlertは避ける。

```text
404が1回
422が1回
403が1回
Temporary Timeoutが1回
```

Noiseの多いAlertは最終的に無視されるため、

```text
Actionable Alert
```

を原則とする。

---

## 58. Security Alert

以下はSecurity Alert候補とする。

```text
Authentication Failure急増
Repeated Permission Failure
Suspicious Admin Access
Security-relevant Rate Limit
```

具体的Security Detection Ruleは`15_Security.md`で定義する。

---

## 59. Dashboard

最初のSystem Dashboardでは以下を表示する。

```text
Request Rate
Error Rate
Latency
Health Status
Database Latency
External Service Error
```

必要に応じて、

```text
Queue
Cache
Resource Usage
```

を追加する。

---

## 60. Dashboard設計原則

Dashboardを作ること自体を目的にしない。

Dashboardは、

```text
現在正常か
どこが遅いか
どこでErrorが発生しているか
```

を短時間で判断できるようにする。

---

## 61. Business Analyticsとの分離

以下はSystem Observabilityではない。

```text
社員数
Skill登録数
Skill Level分布
Department別Skill数
```

これらは、

```text
Business Dashboard
Analytics
Application Feature
```

として扱う。

System Metricsとは分離する。

---

## 62. Telemetry Attribute Naming

OpenTelemetryのSemantic Conventionが存在する場合はそれを優先する。

例：

```text
http.route
http.request.method
http.response.status_code
service.name
deployment.environment.name
```

独自Namingを無秩序に増やさない。

---

## 63. service.name

Backend Service Nameを固定する。

例：

```text
engineer-skill-management-backend
```

Next.js BFFは別Service Nameとする。

```text
engineer-skill-management-bff
```

Distributed TraceでServiceを識別できるようにする。

---

## 64. Environment

TelemetryにはEnvironment情報を付与する。

```text
local
test
staging
production
```

Staging / Production Telemetryを混在させない。

---

## 65. Release情報

可能なら以下をTelemetryへ付与する。

```text
Git Commit SHA
Release Version
Deployment Version
```

これにより、

```text
Deploy
    ↓
Error / Latency変化
```

を関連付けられるようにする。

CI/CDとの連携は`16_CI・Automation.md`で扱う。

---

## 66. Sensitive Data

Logs / Metrics / TracesすべてでSensitive Dataを記録禁止とする。

対象：

```text
Password
Sanctum Token
Better Auth Session Token
Authorization Header
Cookie
API Key
Secret
CSRF Token
Database Password
Private Key
Encryption Key
```

---

## 67. PII

TelemetryへPIIを無条件に送信しない。

避ける：

```text
employee_name
user_name
email
free-form search keyword
request body
response body
```

必要性が明確なIdentifierのみ利用する。

---

## 68. Search Keyword

検索ParameterはTrace / MetricへRaw Valueとして記録しない。

例えば、

```text
keyword=tanaka
```

をTelemetryへ送らない。

必要なら、

```text
has_keyword = true
```

等の非Sensitiveな情報へ変換する。

---

## 69. Request / Response Body

Tracing目的でもRequest / Response Body全体をDefaultで記録しない。

理由：

```text
PII
Credential
Large Payload
Future Sensitive Field
```

が含まれる可能性があるため。

---

## 70. Database Statement

SQL Statement / BindingもSensitive Dataの可能性を考慮する。

Productionでは、

```text
Raw SQL + Full Binding
```

を無条件にTrace Backendへ保存しない。

Provider / Instrumentation設定で適切に制御する。

---

## 71. Local Development

LocalではObservability Platformを必須としない。

最低限：

```text
Structured Log
Request ID
Health Endpoint
```

で開発可能にする。

必要に応じて、

```text
OpenTelemetry Collector
Tracing Backend
```

を起動できる構成とする。

---

## 72. Test Environment

Testでは外部Telemetry Backendへの実送信を行わない。

Exporterを、

```text
No-op
In-memory
Test Exporter
```

等へ差し替えられる構成とする。

Business TestがNetwork依存にならないようにする。

---

## 73. Health Check Test

Feature Testで以下を確認する。

```text
Application Healthy
    → 200

Critical Dependency Failure
    → Readiness 503

Sensitive Internal Detail
    → Responseへ出ない
```

---

## 74. Trace Test

Auto Instrumentation自体をApplication Testで再検証しない。

Custom Instrumentationについて必要に応じ、

```text
重要UseCase Span
Trace Context Propagation
```

をIntegration Testする。

全Span NameをTestするような過剰なTestは避ける。

---

## 75. Metrics Test

Framework / OpenTelemetry標準MetricsをApplication側で細かくMock Testしない。

Project独自Metricを追加した場合のみ、

```text
Counter更新
Histogram記録
Attribute
```

等を必要に応じてTestする。

---

## 76. Logging Correlation Test

Request ID / Trace ID Correlationについて主要Flowで確認する。

```text
HTTP Request
    ↓
Request ID
Trace ID
    ↓
Application Log
```

Error Investigationに必要なIdentifierが失われないことを確認する。

---

## 77. Observability Failure

Observability Backendへの送信Failureによって通常Business Requestを失敗させない。

基本：

```text
Telemetry Export Failure
    ≠
Business Operation Failure
```

ObservabilityはBusiness TransactionのCritical Pathへ強く結合しない。

---

## 78. Auditとの違い

Auditだけは既存方針通りBusiness Transaction Integrityを要求する。

```text
Audit Failure
    → Business Transaction Rollback

Telemetry Export Failure
    → Business Transactionは原則継続
```

明確に分離する。

---

## 79. Library採用方針

OpenTelemetry導入時は必要最小限のPackageを採用する。

候補：

```text
OpenTelemetry API
OpenTelemetry SDK
OTLP Exporter
Laravel / Framework Instrumentation
```

必要のないInstrumentation Packageを一括導入しない。

---

## 80. OpenTelemetry API依存

Application Codeから直接Instrumentationする必要がある場合は、可能な限りOpenTelemetry API Boundaryへ依存する。

SDK / Exporter ConfigurationはInfrastructure側へ寄せる。

概念：

```text
Application Instrumentation
    ↓
OpenTelemetry API

Infrastructure
    ↓
OpenTelemetry SDK
Exporter
Collector Configuration
```

---

## 81. Custom Observability Framework

独自Observability Frameworkは作らない。

以下のようなものは避ける。

```text
Project独自Tracer Framework
Project独自Metrics Framework
Project独自Trace Header
Project独自APM Protocol
```

OpenTelemetry Standardを利用する。

---

## 82. Sentry採用判断

現時点では以下とする。

```text
Sentry
    → 採用候補
    → Backend Provider / Production Infrastructure決定時に最終判断
```

つまり、

```text
技術Standard
    → OpenTelemetry

Backend Product
    → 未確定
```

と分離する。

---

## 83. Observability Backend

以下は候補として扱い、本章では固定しない。

```text
Sentry
Grafana Stack
AWS CloudWatch
Datadog
New Relic
その他OTLP対応Backend
```

Hosting / Cost / Infrastructure方針確定後に決定する。

---

## 84. Laravel Octane

Observability設計をLaravel Octane前提にしない。

現在は通常のLaravel Runtimeを前提とする。

将来、

```text
Octane
RoadRunner
Swoole
```

等を採用する場合はLong-running Process向けTelemetry設定を再確認する。

---

## 85. Library採用判断

| Library / 技術 | 判断 |
|---|---|
| OpenTelemetry | 採用 |
| OpenTelemetry Trace | 採用 |
| OpenTelemetry Metrics | 採用 |
| OpenTelemetry Logs API | 必須とはしない |
| OTLP | 採用 |
| OpenTelemetry Collector | Productionで推奨 |
| Auto Instrumentation | 優先 |
| Manual Instrumentation | 重要UseCaseのみ |
| W3C Trace Context | 採用 |
| Request ID | 採用 |
| Trace ID | 採用 |
| Log / Trace Correlation | 採用 |
| Metrics | 採用 |
| Health Check | 採用 |
| Liveness | 採用 |
| Readiness | 採用 |
| Slow Query Monitoring | 採用 |
| Error Monitoring | 採用 |
| Sampling | Productionで採用 |
| Sentry | 候補・後で最終判断 |
| Custom APM Framework | 不採用 |
| Domain Instrumentation | 不採用 |
| Vendor固有APIへの全面依存 | 不採用 |

---

## 86. 採用技術・方針一覧

| 項目 | 決定 |
|---|---|
| Observability Standard | OpenTelemetry |
| Trace Transport | OTLP |
| Collector | Production推奨 |
| Auto Instrumentation | 優先 |
| Manual Span | 重要UseCaseのみ |
| Domain Tracing | 不採用 |
| HTTP Metrics | 採用 |
| DB Metrics | 採用 |
| External Service Metrics | 採用 |
| Queue Metrics | Queue利用時採用 |
| High Cardinality Metric | 禁止 |
| Raw URL Metric | 禁止 |
| Request ID | 必須 |
| Request Header | `X-Request-ID` |
| Trace ID | 採用 |
| Trace Propagation | W3C Trace Context |
| Log / Trace Correlation | 採用 |
| Audit Trace ID | MVPではOptional |
| Sampling | Production採用 |
| Health Check | 必須 |
| Liveness | `/up`候補 |
| Readiness | `/ready`候補 |
| Healthy Status | 200 |
| Not Ready | 503 |
| Slow Query | Monitoring対象 |
| Error Monitoring | 採用 |
| Sentry | Provider候補 |
| RED | API Monitoring基本 |
| SLI | Availability / Rate / Error / Latency |
| SLO | 実測・非機能要件から決定 |
| Alert | Actionable Eventのみ |
| Telemetry PII | 原則禁止 |
| Sensitive Data | 記録禁止 |
| Business Analytics | Observabilityと分離 |
| Telemetry Failure | Business Transactionを失敗させない |

---

## 87. 最終Architecture

Observability全体：

```text
Laravel Backend
    │
    ├── Structured Logs
    │
    ├── Metrics
    │
    ├── Traces
    │
    └── Health
    │
    ↓
OpenTelemetry
    │
    ↓ OTLP
OpenTelemetry Collector
    │
    ↓
Observability Backend
    │
    ├── Dashboard
    ├── Error Investigation
    └── Alerting
```

---

## 88. Distributed Trace

```text
Browser
    ↓
Next.js BFF
    │
    │ W3C Trace Context
    ↓
Laravel Backend
    │
    ├── Application UseCase Span
    ├── PostgreSQL Span
    └── External Service Span
```

Trace IDによって処理全体を関連付ける。

---

## 89. Correlation

```text
HTTP Request
    │
    ├── request_id
    └── trace_id
         │
         ├── Application Log
         ├── Security Log
         └── Trace
```

Audit：

```text
Audit Log
    ↓
request_id
    ↓
Application / Security Log
```

とする。

---

## 90. Health Architecture

```text
/up
    ↓
Application Process
    ↓
Liveness
```

```text
/ready
    ↓
Application
    +
Critical Dependency
    ↓
Readiness
```

この2つを明確に分離する。

---

## 91. Logging・Audit・Observabilityの関係

```text
Application Log
    → What happened technically?

Security Log
    → What happened from a security perspective?

Audit Log
    → Who changed what?

Metrics
    → Is the system healthy?

Trace
    → Where did the request spend time?

Health
    → Can this instance serve traffic?

Alert
    → Does someone need to act?
```

それぞれの責務を混在させない。

---

## 92. 最終方針

Observabilityでは、

> OpenTelemetryを標準Boundaryとして、ApplicationとObservability Backendを分離する

ことを中心方針とする。

```text
Application
    ↓
OpenTelemetry
    ↓
OTLP
    ↓
Collector
    ↓
Provider
```

とすることで、

```text
Sentry
Grafana
CloudWatch
Datadog
New Relic
```

等のBackend選択をInfrastructure Decisionとして残す。

また、

```text
Logs
Metrics
Traces
Health
Alerts
```

をそれぞれ異なる目的のSignalとして扱う。

Request Correlationは、

```text
Request ID
+
Trace ID
```

で行う。

Health Checkは、

```text
Liveness
+
Readiness
```

へ分離する。

System Monitoringでは、

```text
Rate
Errors
Duration
```

を基本とし、Slow QueryやExternal Dependencyも観測対象とする。

Domain LayerはObservability Frameworkから独立させる。

TelemetryにはSensitive Data / PIIを原則含めず、High Cardinalityを避ける。

そして、

```text
Telemetry Failure
    ≠
Business Failure
```

とし、Observability Infrastructure障害によって通常のBusiness Transactionを失敗させない。

最終的に、

> OpenTelemetry + OTLP + OpenTelemetry Collector + Provider選択可能なObservability Backend

というVendor-neutralな構成を採用する。
