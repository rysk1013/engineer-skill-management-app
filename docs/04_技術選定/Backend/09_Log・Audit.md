# Backend 技術・Library選定 - Log・Audit

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend における以下を定義する。

- Application Log
- Security Log
- Audit Log
- Log Level
- Structured Logging
- Request ID
- Log Context
- Sensitive Informationの扱い
- Audit対象Operation
- Audit Data設計
- Audit Transaction整合性
- Logging / AuditのTesting方針
- Library採用判断

本Projectでは、Application Log・Security Log・Audit Logを明確に分離する。

```text id="8hgd9w"
Application Log
    → 障害調査・運用

Security Log
    → 認証・認可・Security Event

Audit Log
    → 誰が・いつ・何を変更したか
```

---

## 2. 基本方針

最重要原則は以下とする。

```text id="vkaq2u"
Log
    ≠
Audit Log
```

Application Logは、

> System内部で何が起きたか

を調査するためのOperational Dataとする。

Audit Logは、

> 誰が、いつ、どのBusiness Operationを行ったか

を追跡する証跡とする。

そのため、

```php id="lyzp0l"
Log::info('Employee updated.');
```

のみでAudit Requirementを満たしたことにはしない。

---

## 3. Log分類

Loggingを以下の3種類へ分類する。

| 分類 | 主目的 | 主な保存先 |
|---|---|---|
| Application Log | 運用・障害調査 | Logging Platform |
| Security Log | Security Event監視 | Logging Platform |
| Audit Log | Business操作証跡 | PostgreSQL |

例：

```text id="slf38f"
Database Connection Failure
    → Application Log

Suspicious Authorization Failure
    → Security Log

User Role Change
    → Audit Log
```

1つのEventが複数の目的を持つ場合は複数へ記録してよい。

---

## 4. Application Log

Application LogではOperational / Technical Eventを扱う。

主な対象：

```text id="me07xw"
Unexpected Exception
Database Failure
External API Failure
Queue Failure
Cache Failure
Background Job Failure
Performance Warning
Application Lifecycle Event
Important Operational Event
```

通常のCRUD成功をすべてLogしない。

以下のような過剰Loggingは避ける。

```php id="hwyeqp"
Log::info('Employee fetched.');
```

```php id="j3g0ha"
Log::info('Skill fetched.');
```

通常のGET Request単位でBusiness Logを増やさない。

---

## 5. Security Log

Security LogではSecurity上意味のあるEventを扱う。

対象候補：

```text id="8p7o2i"
Authentication Failure
Invalid Token
Expired Token
Revoked Token
Repeated Authorization Failure
Permission Management Failure
Administrator Role Change
can_manage_permissions Change
User Disable
Forced Logout
Suspicious Rate Limit Activity
```

Security LogはSystem Error Logとは分離して考える。

例えば403は通常System Errorではない。

ただし、

```text id="xs8dlf"
権限管理EndpointへのRepeated Forbidden
管理者操作の不審なFailure
```

などはSecurity Eventとして記録できる。

---

## 6. Audit Log

Audit LogではBusiness上重要なWrite Operationを記録する。

対象候補：

```text id="mkf8xe"
Employee作成
Employee変更
Employee退職
Employee削除

EmployeeSkill登録
EmployeeSkill変更
EmployeeSkill削除

Skill作成
Skill変更
Skill無効化

SkillCategory変更

User Role変更
User Permission変更

SubManagerAssignment追加
SubManagerAssignment削除

TeamLeaderAssignment追加
TeamLeaderAssignment削除
```

Audit対象はBusiness Meaningを基準に定義する。

---

## 7. Read操作のAudit

MVPでは通常のRead OperationをAudit対象としない。

例：

```text id="m8pcsm"
Employee一覧閲覧
Employee詳細閲覧
Skill一覧閲覧
Dashboard閲覧
```

理由：

```text id="yomdgm"
Audit Volume増加
Noise増加
Storage増加
重要なWrite Auditが埋もれる
```

ため。

将来、

```text id="5uzrwe"
機密情報閲覧
個人情報閲覧
Compliance Requirement
```

が追加された場合はRead Auditを再検討する。

---

## 8. Log Level

Laravel / Monolog / PSR-3標準Levelを利用する。

利用可能Level：

```text id="1qqmxp"
debug
info
notice
warning
error
critical
alert
emergency
```

本Projectでは主に以下を利用する。

```text id="9f63q0"
debug
info
warning
error
critical
```

---

## 9. Log Level基準

基本基準：

| Level | 用途 |
|---|---|
| debug | Local / 詳細調査 |
| info | 正常だが運用上意味のあるEvent |
| warning | 異常兆候だが処理継続可能 |
| error | Operation Failure / Unexpected Failure |
| critical | System機能へ重大な影響 |

例：

```text id="ybrlca"
Expected 404
    → 原則Logしない

422 Validation Error
    → 原則Logしない

Retry可能なExternal Failure
    → warning候補

Unexpected Exception
    → error

Database全体Connection Failure
    → critical候補
```

---

## 10. Structured Logging

Structured Loggingを正式採用する。

Log Messageへ値を文字列連結せず、ContextをKey-Valueで保持する。

推奨：

```php id="dyf2od"
Log::error(
    'External API request failed.',
    [
        'request_id' => $requestId,
        'service' => 'example-service',
        'operation' => 'fetch_employee',
        'status_code' => 503,
    ],
);
```

避ける：

```php id="ftrjv2"
Log::error(
    'External API failed user='
    . $userId
    . ' request='
    . $requestId,
);
```

---

## 11. Production Log Format

ProductionではJSON Structured Logを基本とする。

例：

```json id="4621b4"
{
  "level": "error",
  "message": "External API request failed.",
  "request_id": "01...",
  "service": "example-service",
  "operation": "fetch_employee",
  "status_code": 503
}
```

これにより将来的に、

```text id="f80mio"
CloudWatch
Grafana Loki
OpenSearch
Datadog
```

等へ送信しやすくする。

Observability Backendは`10_Observability.md`で決定する。

---

## 12. Request ID

すべてのHTTP RequestにRequest IDを付与する。

基本Flow：

```text id="l7ar4o"
Client / BFF
    ↓
Laravel
    ↓
Request ID確定
    ↓
Log Context
    ↓
Response Header
```

Response Headerは以下を利用する。

```http id="sc4l7c"
X-Request-ID: ...
```

---

## 13. Request ID生成

Request IDの決定方針：

```text id="n9m1li"
信頼可能なBFF Request IDあり
    ↓
Format Validation後に引き継ぐ

Request IDなし
    ↓
Laravel Backendで生成
```

任意Clientから送られた値を無条件にLog Identifierとして信用しない。

Length / Character等をValidationして利用する。

---

## 14. Request ID Format

Request IDにはUUID / ULID等のTechnical Identifierを利用できる。

これはDomain Entity IDとは別概念である。

```text id="0xi03p"
EmployeeId
    → bigint / PostgreSQL Sequence

Request ID
    → UUID / ULID等
```

Domain ID StrategyをRequest IDへ適用しない。

External ID Libraryの追加が必要になるほど複雑な実装は避ける。

---

## 15. Trace ID

MVPではRequest IDを必須とする。

```text id="dwl0gl"
Request ID
    → 採用
```

Distributed Trace IDについては、

```text id="ppzgvd"
Trace ID
    → 10_Observability.mdで決定
```

とする。

独自Distributed Tracing機構を本章で実装しない。

---

## 16. Common Log Context

HTTP Request中の共通Context候補：

```text id="3i90u3"
request_id
user_id
route
http_method
operation
resource_type
resource_id
```

必要に応じて追加：

```text id="jsl2p7"
trace_id
job_id
queue
external_service
```

すべてのLogに無条件で大量Contextを付与しない。

必要なContextだけ持たせる。

---

## 17. User Context

Authenticated Requestでは、

```text id="ltlt36"
user_id
```

を共通Contextとして利用する。

原則として以下を毎回Logしない。

```text id="lcaqto"
User Name
Email
Employee Name
Session ID
Token
```

識別目的にはIDを優先する。

---

## 18. Laravel Log Context

Request Middleware等で共通Contextを設定する。

概念：

```text id="js2suh"
Request
    ↓
Request ID生成 / 取得
    ↓
User ID取得
    ↓
Laravel Shared Log Context
    ↓
Application Logs
```

各Log Callで同じ`request_id`を手動設定し続ける設計を避ける。

---

## 19. Domain Logging

Domain LayerではLoggingを行わない。

以下は禁止する。

```php id="gpl54t"
Log::info(...);
```

```php id="00yfiu"
logger()->info(...);
```

```text id="70p2ka"
Psr\Log\LoggerInterfaceをDomain ServiceへInjection
```

理由：

```text id="u2hz3r"
Domain
    → Framework / Operational Concern非依存
```

を維持するため。

---

## 20. Application Logging

Application LayerでもLoggerを全Handlerへ機械的にInjectionしない。

以下のような設計は避ける。

```text id="vcckmg"
全Command Handler
    ↓
LoggerInterface Injection
```

ApplicationからOperational Loggingが必要な場合は、

1. Presentation / Infrastructureで記録できないか検討する
2. Business上本当に必要か確認する
3. 明確なBoundaryが必要な場合のみPort化する

という順序で判断する。

---

## 21. PSR-3

Laravel LoggingはPSR-3互換を利用する。

ただし、

```text id="a61cwb"
PSR-3だからDomainでも使う
```

とはしない。

PSR標準であってもLogging ConcernをDomainへ持ち込まない。

---

## 22. Exception Logging

`07_Exception・Error-Handling.md`の方針を継承する。

```text id="n5zegs"
Expected 4xx
    → 原則Reportしない

Unexpected 5xx
    → Report
```

例：

```text id="mc9w07"
Validation Error
Expected Not Found
Expected Conflict
Expected Forbidden
```

を毎回Error Logへ記録しない。

---

## 23. Expected 4xx

以下は通常Application Flowとして扱う。

```text id="hoeyxl"
401
403
404
409
422
429
```

すべてを`error`としてLogするとNoiseが増えるため避ける。

ただし、

```text id="aaivj0"
Security上不審
Rateが異常
Repeated Failure
```

の場合はSecurity Log / Monitoring対象になり得る。

---

## 24. Unexpected 5xx

Unexpected Server FailureはReporting対象とする。

代表例：

```text id="y8p41s"
Unexpected RuntimeException
Database Connection Failure
External API Unexpected Failure
Programming Error
Impossible State
```

Internal LogではStack Trace等を保持できる。

Client Responseへは公開しない。

---

## 25. HTTP Request Logging

Application CodeからRequest Body全体を常時Logしない。

禁止例：

```php id="6sg0rh"
Log::info(
    'Request received.',
    $request->all(),
);
```

理由：

```text id="p2hivv"
Authentication Data
PII
Secret
Unexpected Payload
Large Payload
```

が混入するRiskがあるため。

必要なFieldだけ明示的に抽出する。

---

## 26. HTTP Response Logging

Response Body全体を常時Logしない。

特に、

```text id="03zw63"
User Data
Employee Data
Error Detail
Internal Metadata
```

を大量に保存しない。

Response Body DumpはLocal Debug等の限定用途にする。

---

## 27. Access Log

HTTP Access LogはApplication Codeで独自実装するより、

```text id="p8g3hy"
Reverse Proxy
Load Balancer
Container Runtime
Cloud Platform
```

側のAccess Logを基本とする。

Backend Application LoggingではBusiness / Operational Contextへ集中する。

---

## 28. Database Query Logging

Productionで全SQLを常時Logしない。

以下の常時Loggingを避ける。

```text id="w0zxkf"
Full SQL
Bindings
All Query Results
```

理由：

```text id="pbbaqv"
PII Leak
Secret Leak
Log Volume
Performance Impact
```

があるため。

SQL DebuggingはLocal / Development中心とする。

Slow Query Monitoringは`10_Observability.md`で定義する。

---

## 29. External Service Logging

External Service Callでは必要に応じて以下を記録する。

```text id="zj61s3"
service
operation
duration
status_code
request_id
```

ただし以下を記録しない。

```text id="35k6dg"
Authorization Header
API Token
Full Request Body
Full Response Body
Secret
```

Raw Payload LoggingをDefaultにしない。

---

## 30. Sensitive Information

Application Log / Security Log / Audit Logすべてで以下を記録禁止とする。

```text id="sa8spy"
Password
Sanctum Token
Better Auth Session Token
Cookie
Authorization Header
API Key
Secret
CSRF Token
Database Password
Private Key
Encryption Key
```

---

## 31. PII

個人情報は必要最小限とする。

可能なら、

```text id="4wleki"
user_id
employee_id
```

等のIdentifierを利用する。

例えばEmployeeを識別するためだけに、

```text id="mle8t2"
employee_name
```

を毎回Logしない。

---

## 32. Masking

どうしてもSensitive Fieldを含むStructureを扱う場合はMaskingする。

例：

```json id="e6fqjc"
{
  "authorization": "[REDACTED]"
}
```

ただし基本方針は、

```text id="yvfat8"
まず記録しない
    ↓
必要な場合だけMask
```

とする。

Maskingを理由に何でもLogすることは禁止する。

---

## 33. Audit Logの目的

Audit Logは以下を追跡可能にする。

```text id="5f1obt"
Who
When
What
Target
Request
Before
After
```

例：

```text id="7s43kl"
Actor
    → User 10

When
    → 2026-09-12T10:00:00Z

Action
    → USER_ROLE_CHANGED

Target
    → User 42

Before
    → manager

After
    → administrator
```

---

## 34. Audit Event Name

Audit ActionはMachine-readableな安定Identifierとする。

Naming：

```text id="58wbxj"
UPPER_SNAKE_CASE
```

例：

```text id="f8mdio"
EMPLOYEE_CREATED
EMPLOYEE_UPDATED
EMPLOYEE_RETIRED
EMPLOYEE_DELETED

EMPLOYEE_SKILL_REGISTERED
EMPLOYEE_SKILL_UPDATED
EMPLOYEE_SKILL_REMOVED

SKILL_CREATED
SKILL_UPDATED
SKILL_DEACTIVATED

SKILL_CATEGORY_CREATED
SKILL_CATEGORY_UPDATED
SKILL_CATEGORY_DEACTIVATED

USER_ROLE_CHANGED
USER_PERMISSION_CHANGED

SUB_MANAGER_ASSIGNED
SUB_MANAGER_UNASSIGNED

TEAM_LEADER_ASSIGNED
TEAM_LEADER_UNASSIGNED
```

Event NameはAudit Contractとして安定させる。

---

## 35. Audit Storage

Audit LogはPostgreSQLへ永続保存する。

Table：

```text id="ajg0bm"
audit_logs
```

Application Logと同じFile / Logging Channelだけで監査証跡を管理しない。

---

## 36. Audit Schema

基本Schema候補：

```text id="uqab07"
audit_logs

id
occurred_at
actor_user_id
action
target_type
target_id
request_id
before_data
after_data
metadata
```

必要性が明確なColumnのみ追加する。

---

## 37. Audit ID

Audit Record自身のPrimary Keyは、

```text id="xjvwbx"
bigint
```

を利用する。

PostgreSQL Sequenceでよい。

Audit LogはDDD Aggregateとして扱わない。

Infrastructure / Cross-cutting Dataとして扱う。

---

## 38. occurred_at

Audit Event日時は、

```text id="axssfz"
occurred_at
```

として保持する。

日時方針は`08_Serialization・Date・ID.md`に従う。

```text id="87vfkj"
Application
    → DateTimeImmutable UTC

Database
    → timestamptz
```

現在日時取得にはClockを利用する。

---

## 39. actor_user_id

Human操作では操作Userを、

```text id="z4bwkj"
actor_user_id
```

として保持する。

MVPではUser Actorを中心にする。

将来的に、

```text id="bocykh"
System
Scheduled Job
Migration
External System
```

等が必要になった場合、

```text id="dxyeim"
actor_type
actor_id
```

への拡張を検討する。

---

## 40. Target

Audit対象は、

```text id="g1715p"
target_type
target_id
```

で保持する。

例：

```text id="zffwne"
target_type = employee_skill
target_id   = 123
```

Target Typeは安定したIdentifierを利用する。

Laravel Eloquent Morph Relationへ強く依存させない。

---

## 41. request_id

Audit LogにもRequest IDを保存する。

```text id="t9my1g"
audit_logs.request_id
```

これにより、

```text id="v6aaka"
Audit Log
        ↕
request_id
        ↕
Application Log
        ↕
Security Log
```

を横断検索できる。

---

## 42. before_data / after_data

変更Auditでは、

```text id="06p6th"
before_data
after_data
```

をJSONBで保持できる。

例：

```json id="4z4odn"
{
  "before_data": {
    "role": "manager"
  },
  "after_data": {
    "role": "administrator"
  }
}
```

---

## 43. Audit Dataの粒度

Aggregate全体を毎回Snapshot保存しない。

Audit上意味のある変更Fieldのみ保持する。

推奨：

```json id="gpf4t0"
{
  "before_data": {
    "skill_level": 2
  },
  "after_data": {
    "skill_level": 3
  }
}
```

避ける：

```text id="wfukhi"
Employee Aggregate全体
Relation全件
不要なMetadata
Authentication Data
```

---

## 44. Audit Sensitive Data

Audit LogでもSensitive Dataを保存しない。

禁止：

```text id="i8lxlg"
Password
Token
Session
Secret
Authentication Credential
Private Key
```

不要なPIIも保存しない。

AuditであることはSensitive Data保存の免罪符ではない。

---

## 45. metadata

補助情報は、

```text id="d61dyn"
metadata JSONB
```

へ保持できる。

例：

```json id="7tpvk7"
{
  "reason": "permission management",
  "source": "web"
}
```

ただし頻繁にFilter / Sort / Joinする値はColumn化を検討する。

何でも`metadata`へ押し込まない。

---

## 46. Audit Transaction

Business変更とAudit Recordを同一Transactionで保存する。

例：

```text id="5orlyg"
BEGIN

User Role UPDATE
Audit Log INSERT

COMMIT
```

これを基本とする。

---

## 47. Audit整合性

以下の状態を避ける。

```text id="9c75qc"
Business変更成功
    +
Audit書き込み失敗
```

監査対象Operationでは、

```text id="fwt9d6"
Audit Insert Failure
    ↓
Transaction Rollback
```

とする。

---

## 48. 重要Audit Operation

特に以下はAudit欠損を許容しない。

```text id="f1js21"
User Role変更
can_manage_permissions変更
Administrator関連変更
Employee削除
Employee退職
Skill無効化
Assignment変更
```

Business変更とAuditを同一Transactionで保証する。

---

## 49. Auditの非同期化

MVPではAudit Record書き込みをQueueへ非同期化しない。

不採用：

```text id="o6abvp"
Business Operation
    ↓
Queue
    ↓
Audit Insert
```

理由：

```text id="pwg6f8"
Queue Failure
Worker Failure
Process Crash
Delay
```

によるAudit欠損を避けるため。

採用：

```text id="2wpeu0"
Business Operation
    ↓
Audit Insert
    ↓
Same Transaction
```

---

## 50. Eloquent ObserverによるAudit

Eloquent ObserverをAudit中心機構として利用しない。

不採用：

```text id="99dav4"
Model updated
    ↓
Observer
    ↓
Audit
```

理由：

```text id="gg3kzm"
Actor
Request ID
UseCase
Business Intent
Action Name
```

を正確に表現しにくいため。

---

## 51. Database TriggerによるAudit

DB TriggerのみでAuditを実装しない。

理由：

```text id="yegbtd"
Actorを取得しにくい
Request IDを取得しにくい
UseCase Contextが分からない
Business Intentが失われる
```

既存Database方針通りTriggerをBusiness Logic / Audit中心には利用しない。

---

## 52. Audit Writer

Application LayerからAuditを記録するためのPortとして、

```text id="jkp2wa"
AuditWriter
```

を採用する。

例：

```php id="9k45ak"
interface AuditWriter
{
    public function record(
        AuditEntry $entry,
    ): void;
}
```

Infrastructure側でDatabase実装を持つ。

例：

```text id="lohfyk"
DatabaseAuditWriter
```

---

## 53. AuditEntry

AuditWriterへ渡すFramework非依存Dataとして、

```text id="41uicp"
AuditEntry
```

を用意する。

概念例：

```php id="1v2ztk"
final readonly class AuditEntry
{
    public function __construct(
        public DateTimeImmutable $occurredAt,
        public UserId $actorUserId,
        public string $action,
        public string $targetType,
        public string $targetId,
        public string $requestId,
        public ?array $beforeData,
        public ?array $afterData,
        public ?array $metadata,
    ) {
    }
}
```

AuditEntryはDomain Entityではない。

Application Port DTO / Valueとして扱う。

---

## 54. AuditWriterの配置

概念：

```text id="50ee0u"
Application
├── AuditWriter Interface
└── AuditEntry

Infrastructure
└── Persistence
    └── Audit
        └── DatabaseAuditWriter
```

ApplicationはPostgreSQL / Eloquentへ依存しない。

---

## 55. HandlerとAudit

Audit対象UseCaseではHandlerから明示的にAuditWriterを呼ぶ。

例：

```text id="rxfdr9"
ChangeUserRoleHandler
    ↓
User取得
    ↓
Business Rule確認
    ↓
Role変更
    ↓
Repository.save()
    ↓
AuditWriter.record()
    ↓
Commit
```

Business Intentを理解できるUseCase BoundaryからAudit Actionを決定する。

---

## 56. Domain Event

AuditのためだけにDomain Event / Event Busを導入しない。

MVPでは以下を採用しない。

```text id="gpod69"
Domain Event Infrastructure
Event Bus
Async Audit Listener
Outbox
```

既存方針通り、

```text id="f8sltf"
Handler
    ↓
AuditWriter
```

で十分とする。

---

## 57. Audit Retention

Audit LogはApplication Logより長期保持することを前提とする。

ただし具体的な保持期間は以下で決定する。

```text id="g3z77a"
Company Policy
Security Requirement
Legal Requirement
Storage Cost
Operational Requirement
```

技術選定だけを理由に永久保存とはしない。

---

## 58. Employee保持期間との分離

退職社員の、

```text id="mczyt7"
3年保持
```

というRequirementとAudit Log Retentionは別Conceptとして扱う。

```text id="x174ot"
Employee Data Retention
    ≠
Audit Log Retention
```

Audit保持期間は独立Policyとして定義する。

---

## 59. Audit Update禁止

Audit LogはImmutable Recordとして扱う。

通常Operationでは、

```text id="afqva8"
INSERT
SELECT
```

を中心とする。

Application Userによる、

```text id="bdy3zp"
UPDATE
DELETE
```

は許可しない。

Retentionによる削除は専用Maintenance Processでのみ実施する。

---

## 60. Audit Delete

Retention期限到達後の削除は、

```text id="ovyr5o"
Maintenance Job
```

等の管理Processへ限定する。

削除自体も必要であればOperational / Security Logへ記録する。

通常のCRUD APIからAudit Recordを削除できないようにする。

---

## 61. Audit Access Control

Audit Logは一般Userに公開しない。

閲覧可能Userは高権限Roleへ限定する。

特に、

```text id="hwqkr6"
Permission Audit
Role Audit
Security Audit
```

はSensitive Operational Dataとして扱う。

具体的な閲覧UI / APIはRequirementに応じて追加する。

---

## 62. Laravel Logging Channel

Application / Security LoggingにはLaravel標準Loggingを利用する。

概念例：

```text id="ivthqh"
stack
application
security
```

必要に応じてChannelを分離する。

Application CodeからStorage Backendへ直接依存しない。

---

## 63. Monolog

Laravel標準Logging BackendであるMonologを利用する。

追加Logging Frameworkは採用しない。

```text id="id5b6x"
Laravel Logging
    ↓
Monolog
```

を基本とする。

---

## 64. AuditをLogging Channelにしない

Auditを以下だけで済ませない。

```php id="ki7qq1"
Log::channel('audit')->info(...);
```

理由：

```text id="rl5t9m"
Transaction Integrity
Queryability
Retention
Access Control
Business Structure
Before / After
Actor / Target
```

がApplication Logと異なるため。

AuditはDatabase Recordとして扱う。

---

## 65. Activity Log Package

以下のようなAutomatic Activity Log PackageはMVPでは採用しない。

```text id="ea64kq"
spatie/laravel-activitylog
```

理由：

- Eloquent Change中心になりやすい
- Business Intentを表現しにくい
- UseCase Action Nameを明示しにくい
- Audit TransactionをProject方針に合わせて制御したい
- Domain / Application Architectureとの境界を明確にしたい

---

## 66. Model ChangeとBusiness Audit

Database変更そのものではなくBusiness Meaningを記録する。

Database-oriented：

```text id="a4ab0i"
users.role changed
```

より、

```text id="96xei1"
USER_ROLE_CHANGED
```

を優先する。

同様に、

```text id="15hfag"
skills.active changed false
```

ではなく、

```text id="at77m4"
SKILL_DEACTIVATED
```

とする。

---

## 67. Log Testing

Logging自体を全UseCaseで細かくMock Testしない。

重要なBehaviorのみ確認する。

例：

```text id="r4q129"
Request IDがContextへ入る
Sensitive DataをLogしない
Unexpected ErrorがReportされる
重要Security Eventが記録される
```

Logの実装詳細にTestを過度に密結合させない。

---

## 68. Audit Testing

AuditはBusiness Requirementとして明示的にTestする。

代表ケース：

```text id="0i0m3d"
Role変更成功
    ↓
Audit Record作成

Skill無効化成功
    ↓
Audit Record作成

EmployeeSkill変更成功
    ↓
Before / After保存
```

---

## 69. Audit Rollback Test

Transaction整合性をTestする。

```text id="5whwsk"
Business変更
    ↓
Audit Insert Failure
    ↓
Rollback
```

結果：

```text id="t2ojda"
Business変更なし
Audit Recordなし
```

であることを確認する。

---

## 70. Failed OperationとAudit

Business Operation自体が失敗した場合、成功Auditを作らない。

例：

```text id="tfyt6m"
Permission Change
    ↓
Domain Rule Failure
    ↓
Rollback
    ↓
USER_PERMISSION_CHANGED Auditなし
```

必要なFailureについてはSecurity Logへ記録する。

---

## 71. Request ID Test

以下をTestする。

```text id="rj13xw"
Request IDなし
    → Backendで生成

Valid Request IDあり
    → 引き継ぎ

Invalid Request ID
    → 新規生成または拒否方針

Response
    → X-Request-ID

Log
    → 同一Request ID
```

---

## 72. Sensitive Data Test

少なくともSecurity上重要なFieldについて、Logへ出ないことをTestできるようにする。

対象：

```text id="u7qwlt"
Authorization
Cookie
Sanctum Token
Session Token
Password
Secret
```

全Log Stringを網羅Testするのではなく、共通Sanitization / Logging Boundaryを中心に確認する。

---

## 73. Library採用判断

| Library / 技術 | 判断 |
|---|---|
| Laravel Logging | 採用 |
| Monolog | 採用 |
| PSR-3 | Laravel内部で利用 |
| Structured Logging | 採用 |
| JSON Production Log | 採用 |
| Request ID | 採用 |
| `X-Request-ID` | 採用 |
| Shared Log Context | 採用 |
| PostgreSQL Audit Log | 採用 |
| JSONB Before / After | 採用 |
| AuditWriter Port | 採用 |
| AuditEntry | 採用 |
| Same Transaction Audit | 採用 |
| Async Audit | 不採用 |
| Eloquent Observer Audit | 不採用 |
| DB Trigger Audit | 不採用 |
| Domain Logging | 不採用 |
| Domain Event for Audit | 不採用 |
| `spatie/laravel-activitylog` | 不採用 |
| External Logging Framework | 不採用 |

---

## 74. 採用技術・方針一覧

| 項目 | 決定 |
|---|---|
| Application Log | Laravel / Monolog |
| Security Log | Laravel / Monolog |
| Audit Log | PostgreSQL |
| Structured Logging | 採用 |
| Production Log | JSON |
| Request ID | 必須 |
| Response Header | `X-Request-ID` |
| Trace ID | `10_Observability.md`で決定 |
| User Context | `user_id`中心 |
| Full Request Body Logging | 原則禁止 |
| Full Response Body Logging | 原則禁止 |
| Full SQL Logging | Productionでは禁止 |
| Token Logging | 禁止 |
| Session Logging | 禁止 |
| Sensitive Data | 記録禁止 |
| PII | 必要最小限 |
| Expected 4xx | 原則Error Log不要 |
| Unexpected 5xx | Report |
| Read Audit | MVPでは不採用 |
| Write Audit | 重要Operationで採用 |
| Audit Action | `UPPER_SNAKE_CASE` |
| Audit Storage | `audit_logs` |
| Audit日時 | UTC / `timestamptz` |
| Before / After | JSONB |
| Request ID | Auditへ保存 |
| Audit Transaction | Business変更と同一 |
| Audit Failure | Transaction Rollback |
| Async Audit | 不採用 |
| Observer Audit | 不採用 |
| Trigger Audit | 不採用 |
| Audit Writer | Application Port |
| Audit Package | 不採用 |
| Audit Record更新 | 禁止 |
| Audit Retention | 独立Policy |

---

## 75. 最終Architecture

Application Logging：

```text id="s61c7u"
HTTP / Infrastructure
        ↓
Operational Event
        ↓
Laravel Logging
        ↓
Monolog
        ↓
Structured JSON Log
        ↓
Observability Platform
```

Security Logging：

```text id="cmyryk"
Authentication / Authorization
        ↓
Security-relevant Event
        ↓
Security Logging Channel
        ↓
Structured Log
        ↓
Monitoring / Alerting
```

Audit：

```text id="h95txy"
Application Handler
        ↓
Business Operation
        ↓
Repository Save
        ↓
AuditWriter.record()
        ↓
PostgreSQL audit_logs
        ↓
Same Transaction
```

Correlation：

```text id="jymdz2"
HTTP Request
    ↓
request_id
    ├── Application Log
    ├── Security Log
    └── Audit Log
```

---

## 76. 最終方針

Log・Auditでは、

> Systemを調査するためのLogと、Business Operationを証明するAuditを分離する

ことを最重要原則とする。

```text id="3d4gkr"
Application Log
    → System Operation

Security Log
    → Security Event

Audit Log
    → Business Operation
```

Application / Security Loggingには、

```text id="xe601g"
Laravel Logging
+
Monolog
+
Structured JSON
+
Request ID
```

を利用する。

Auditでは、

```text id="oh1drc"
UseCase
    ↓
Business Intent
    ↓
AuditWriter
    ↓
PostgreSQL
```

とし、Eloquent ObserverやDatabase Triggerによる自動Auditを中心にしない。

また、

```text id="3ehoym"
Business Change
+
Audit Insert
```

を同一Transactionで実行し、Audit Failure時はBusiness OperationもRollbackする。

外部Audit / Logging Frameworkを追加せず、

> Laravel / Monolog + Project固有AuditWriter + PostgreSQL

という構成を採用する。
