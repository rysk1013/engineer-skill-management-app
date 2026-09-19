# Exception設計

## 1. 目的

Exception設計は、各Layerで発生するFailureを適切な責務へ分離し、

- Business Rule違反
- UseCase実行失敗
- Persistence / External Service障害
- HTTP Error Response

を混同しないために行う。

本システムでは、

> Exceptionは発生したLayerの意味で表現し、HTTPへの変換はPresentation Layerで行う

ことを基本方針とする。

---

## 2. 基本方針

- Domain ExceptionはBusiness Rule違反を表現する
- Application ExceptionはUseCase成立失敗を表現する
- Infrastructure Exceptionは技術的失敗を表現する
- Presentation LayerでHTTP Status / Error CodeへMappingする
- Domain / Application ExceptionにHTTP Statusを持たせない
- Domain / ApplicationからLaravel Responseを返さない
- PostgreSQL / PDO / Eloquent固有ExceptionをPresentationへ直接漏らさない
- Machine-readable Error Codeを利用する
- FrontendはError Message文字列ではなくError Codeで分岐する
- Error Response形式を統一する
- Expected ErrorとUnexpected Errorを区別する
- Unexpected Errorの詳細をClientへ公開しない
- Exceptionを正常な分岐処理の代替として乱用しない
- Exceptionを握り潰さない

---

## 3. Exception全体構造

概念的には以下とする。

```text
Domain Exception
        │
        ├──────────────┐
        │              │
        ↓              │
Application Handler    │
        │              │
Application Exception │
        │              │
        └──────┬───────┘
               ↓
       Presentation
   Exception Mapping
               ↓
        HTTP Response
```

Infrastructure Failureの場合:

```text
PostgreSQL / Laravel / External API
                ↓
      Infrastructure Exception
                ↓
      Application / Presentation
                ↓
       Exception Mapping
                ↓
          HTTP Response
```

---

## 4. Layerごとの責務

### Domain

DomainはBusiness Invariant違反を表現する。

### Application

ApplicationはUseCaseとして成立しない状態を表現する。

### Infrastructure

InfrastructureはDatabase / External Systemなどの技術的Failureを扱う。

### Presentation

PresentationはExceptionをHTTP StatusとAPI Error Responseへ変換する。

---

## 5. Domain Exception

Domain Exceptionは、

> Domain ModelがBusiness Rule上許可できない状態・操作

を表現する。

例:

```text
InvalidSkillLevelForNoExperience
ExperiencePeriodRequired
LastUsedMonthRequired
PermissionManagerRequired
```

Domain ExceptionはBusiness Languageで命名する。

---

## 6. Domain Exceptionの例

EmployeeSkillでは、以下のInvariantが存在する。

```text
実務未経験
    ↓
Level 1のみ
```

違反時:

```php
final class InvalidSkillLevelForNoExperience
    extends DomainException
{
}
```

Domain側では、

```php
if (
    $workExperience === WorkExperience::NONE
    && $skillLevel !== SkillLevel::LEVEL_1
) {
    throw new InvalidSkillLevelForNoExperience();
}
```

のように表現する。

---

## 7. Domain ExceptionにHTTP情報を持たせない

避ける例:

```php
final class InvalidSkillLevelForNoExperience
    extends DomainException
{
    public int $status = 409;

    public string $errorCode =
        'INVALID_SKILL_LEVEL_FOR_NO_EXPERIENCE';
}
```

Domainは以下を知らない。

- HTTP Status
- JSON
- API Error Code
- Response
- Laravel
- REST

Domain ExceptionはBusiness上の失敗だけを表現する。

---

## 8. Domain Exception Base Class

Domain Exception用のBase Classを持つことは許容する。

例:

```php
abstract class DomainException
    extends RuntimeException
{
}
```

ただし、Base Classへ以下を詰め込まない。

- HTTP Status
- Response生成
- Logging
- Translation
- Error Code Mapping
- Laravel依存

Base ClassはException分類のための最小限の役割とする。

---

## 9. Domain Exceptionの粒度

ExceptionはBusiness上意味のある単位で定義する。

推奨:

```text
InvalidSkillLevelForNoExperience
ExperiencePeriodRequired
LastUsedMonthRequired
PermissionManagerRequired
```

避ける:

```text
InvalidDomainException
BusinessException
ValidationException
RuleViolationException
```

すべてをGeneric Exceptionへまとめすぎない。

---

## 10. Value Object生成失敗

Value Object生成時の不正値もDomain Exceptionとして扱える。

例えば、

```php
ExperiencePeriod::fromMonths(0)
```

がBusiness上不正な場合、

```text
InvalidExperiencePeriod
```

などのDomain Exceptionを投げる。

ただし、単純なHTTP形式エラーまでDomain Exceptionへ持ち込まない。

---

## 11. Application Exception

Application Exceptionは、

> Domain Ruleそのものではないが、そのUseCaseを成立させられない状態

を表現する。

例:

```text
EmployeeNotFound
SkillNotFound
EmployeeSkillNotFound
UnauthorizedEmployeeAccess
DuplicateEmployeeSkill
```

---

## 12. Not Found

Repositoryの `find()` が `null` を返した場合、Application HandlerがUseCase上のNot Foundとして判断する。

例:

```php
$employeeSkill =
    $repository->find($id);

if ($employeeSkill === null) {
    throw new EmployeeSkillNotFound(
        $id,
    );
}
```

Repository自身がHTTP `404` を判断しない。

---

## 13. Not Found Exception

例:

```php
final class EmployeeSkillNotFound
    extends ApplicationException
{
    public function __construct(
        EmployeeSkillId $id,
    ) {
        parent::__construct(
            sprintf(
                'EmployeeSkill not found: %s',
                $id->value(),
            ),
        );
    }
}
```

このMessageはServer-side debugging用途であり、Clientへそのまま返すことを前提としない。

---

## 14. Authorization Failure

Application LayerでUseCase Authorizationに失敗した場合、Application Exceptionとして扱う。

例:

```text
EmployeeAccessDenied
PermissionManagementDenied
```

Laravel PolicyによるAuthorization Failureとは実装経路が異なる場合があるが、Presentationでは最終的に `403 Forbidden` へ統一できる。

---

## 15. Authentication Failure

Authentication Failureは基本的にPresentation / Framework Boundaryで扱う。

例:

- Sanctum Tokenなし
- Invalid Token
- Authentication Contextなし

これらはDomain / Application Exceptionにしない。

HTTP上は通常、

```text
401 Unauthorized
```

へMappingする。

---

## 16. Business Conflict

現在のBusiness Stateとの競合によってUseCaseが成立しない場合はConflictとして扱う。

例:

```text
EmployeeSkillが既に登録済み
最後のPermission Managerを解除しようとした
現在Stateでは許可されない状態遷移
```

HTTP上では原則として、

```text
409 Conflict
```

へMappingする。

ただしDomain Exception自身は `409` を知らない。

---

## 17. Duplicate EmployeeSkill

EmployeeSkill重複は、

```text
Application事前確認
+
Database UNIQUE Constraint
```

によって防御する。

事前確認で検出した場合:

```text
DuplicateEmployeeSkill
```

をApplication Exceptionとして扱える。

Concurrent RequestによってDatabase Constraintで初めて検出した場合も、Infrastructureで同じ意味のExceptionへ変換する。

最終的にPresentationでは同一Error Code / HTTP StatusへMappingする。

---

## 18. Application Exception Base Class

Application Exception用Base Classを持つことは許容する。

例:

```php
abstract class ApplicationException
    extends RuntimeException
{
}
```

ここにもHTTP StatusやResponse生成責務を持たせない。

---

## 19. Infrastructure Exception

Infrastructure Exceptionは技術的なFailureを表現する。

例:

```text
DatabaseConnectionException
PersistenceException
ConstraintViolationException
DeadlockException
LockTimeoutException
ExternalServiceUnavailable
ExternalServiceTimeout
AuthenticationInfrastructureException
```

Infrastructure固有FailureとBusiness Failureを区別する。

---

## 20. Driver Exceptionを直接漏らさない

以下をそのままPresentationまで流さない。

```text
PDOException
Illuminate\Database\QueryException
PostgreSQL SQLSTATE
HTTP Client固有Exception
ConnectionException
```

Infrastructure Boundaryで必要に応じて意味のあるExceptionへ変換する。

---

## 21. Exception Translation

InfrastructureではLow-level ExceptionをHigher-level Exceptionへ変換できる。

例:

```text
PostgreSQL Unique Violation
        ↓
Constraint Name判定
        ↓
DuplicateEmployeeSkill
```

または、

```text
External HTTP Timeout
        ↓
ExternalServiceTimeout
```

とする。

Low-level技術情報をInner LayerやClientへそのまま露出しない。

---

## 22. Constraint Name

重要なDatabase Constraintには明示的な名前を付ける。

例:

```text
uq_employee_skills_employee_id_skill_id
```

InfrastructureでConstraint Nameを利用してFailureの意味を判定する。

SQL Error Message文字列の曖昧な部分一致だけに依存しない。

---

## 23. UNIQUE Constraint Mapping

例:

```text
uq_employee_skills_employee_id_skill_id
        ↓
DuplicateEmployeeSkill
        ↓
409 Conflict
```

Database側から発生した場合でも、Clientから見えるError SemanticsをApplication事前確認時と揃える。

---

## 24. CHECK Constraint

CHECK Constraint違反は通常、

```text
Domain / Application Bug
```

または、

```text
Persistence Data不整合
```

である可能性が高い。

Domainで保証しているInvariantがCHECK Constraintで失敗した場合、Client入力の通常エラーとして安易に扱わない。

原因を確認し、Unexpected Errorとして扱うことも検討する。

---

## 25. Foreign Key Violation

Foreign Key Violationも状況によって意味が異なる。

例えば、

```text
参照先ResourceがConcurrent Deleteされた
```

などがBusiness上想定される場合はMeaningful Exceptionへ変換できる。

一方、通常発生しないはずのFK ViolationはInfrastructure / Programming Errorとして扱う。

すべてのFK Violationを機械的に `404` へMappingしない。

---

## 26. Deadlock

DeadlockはInfrastructure Failureとして扱う。

```text
PostgreSQL Deadlock
    ↓
Transaction Rollback
    ↓
Infrastructure Exception
```

MVPでは無条件Automatic Retryを採用しない。

Clientへどう返すかはFailureの性質に応じてPresentationで判断する。

通常はServer-side Failureとして扱い、詳細をClientへ公開しない。

---

## 27. Lock Timeout

Lock TimeoutもInfrastructure Failureとする。

ClientがBusiness Rule違反を起こしたわけではないため、Domain Exceptionにはしない。

必要に応じて、

```text
503 Service Unavailable
```

などへのMappingを検討できるが、MVP開始時点では一般的なUnexpected Infrastructure Failureとして扱ってよい。

---

## 28. External Service Error

External Serviceとの通信では以下が発生し得る。

- Timeout
- Connection Failure
- 4xx
- 5xx
- Invalid Response
- Unexpected Payload

Infrastructure Adapterで外部Client固有Exceptionをそのまま漏らさず、Applicationが理解できるFailureへ変換する。

---

## 29. External 4xxをそのまま返さない

External APIから、

```text
404
422
500
```

が返ってきても、そのHTTP Statusを本システムのClientへそのまま転送しない。

External Service上のHTTP Semanticsと本システムのAPI Semanticsは別である。

Application上の意味へ変換した後、Presentationで本システムとして適切なStatusを決定する。

---

## 30. Presentation Exception Mapping

Presentation LayerはExceptionをHTTP ResponseへMappingする。

概念:

```text
Exception
    ↓
Exception Mapper / Handler
    ↓
HTTP Status
    +
Error Code
    +
Client Message
```

LaravelのException Handling Mechanismを利用する。

---

## 31. Laravel Exception Handling

Laravel標準のException Handlingを積極的に利用する。

Framework標準のException設定境界でMappingを行う。

Clean Architectureのために独自Exception Frameworkを再実装しない。

ただしMapping定義が肥大化する場合は、責務を整理した専用Mapper / Renderer Classへ分割できる。

---

## 32. HTTP Status基本方針

本システムでは以下を基本とする。

| Status | 用途 |
|---|---|
| `400 Bad Request` | HTTPとして不正なRequest |
| `401 Unauthorized` | Authentication Failure |
| `403 Forbidden` | Authorization Failure |
| `404 Not Found` | 対象Resource / UseCase対象が存在しない |
| `409 Conflict` | 現在状態とのBusiness Conflict |
| `422 Unprocessable Entity` | Request Validationまたは入力内容のBusiness Rule違反 |
| `500 Internal Server Error` | Unexpected Server Error |
| `503 Service Unavailable` | 一時的Infrastructure障害で必要な場合 |

---

## 33. `400 Bad Request`

`400` はRequest自体がHTTP / JSONとして正しく解釈できない場合などに利用する。

通常のForm Request Validationには `422` を利用する。

Business Rule違反を一律 `400` にしない。

---

## 34. `401 Unauthorized`

Authenticationに失敗した場合に利用する。

例:

- Sanctum Tokenなし
- Invalid Token
- Authentication Contextなし

Authorization Failureとは分離する。

---

## 35. `403 Forbidden`

認証済みActorが対象操作を許可されていない場合に利用する。

例:

- Team Leaderが更新APIを実行
- Sub Managerが未担当社員を更新
- Permission管理権限のないAdministratorが権限変更

---

## 36. `404 Not Found`

対象Resource / UseCase対象が存在しない場合に利用する。

例:

```text
EmployeeNotFound
SkillNotFound
EmployeeSkillNotFound
```

Security上、存在有無を隠す必要があるEndpointでは `403` / `404` の使い分けを個別に検討できる。

---

## 37. `409 Conflict`

現在のResource StateやBusiness Stateとの競合に利用する。

例:

```text
DuplicateEmployeeSkill
PermissionManagerRequired
InvalidStateTransition
```

Request Format自体は正しいが、現在状態では操作できないケースを基本とする。

---

## 38. `422 Unprocessable Entity`

Form RequestによるHTTP Input Validation Failureに利用する。

例:

- Required
- Type
- Length
- Number Range
- Date Format
- Enum Input
- Request Structure

また、Request内容そのものがBusiness Ruleへ違反している場合にも利用できる。

---

## 39. Domain ExceptionとHTTP Status

Domain Exceptionをすべて `422` へMappingしない。

Domain Rule違反の意味に応じて判断する。

例えば、

```text
実務未経験なのにLevel 3
```

はRequest内容そのものがBusiness Ruleに反するため `422` とする。

一方、

```text
最後のPermission Managerを解除
```

は現在StateとのConflictであるため `409` とする。

したがって、

> ExceptionのLayerではなくFailureの意味でHTTP Statusを決定する

ことを原則とする。

---

## 40. `500 Internal Server Error`

想定外のServer Errorに利用する。

例:

- Programming Error
- 想定外のDatabase Error
- Mapper Bug
- 未想定Exception
- Domain上あり得ないPersistence Data

ClientへInternal Detailを返さない。

---

## 41. `503 Service Unavailable`

一時的Infrastructure障害で、再試行可能性をClientへ表現する必要がある場合に利用できる。

例:

- 必須External Service一時停止
- Database一時Unavailable

ただしMVPではInfrastructure Errorを細かくHTTP分類すること自体を目的化しない。

---

## 42. Error Response形式

API Error Responseは原則として以下の形式へ統一する。

```json
{
  "error": {
    "code": "DUPLICATE_EMPLOYEE_SKILL",
    "message": "The employee skill is already registered."
  }
}
```

`code` はMachine-readable Identifierとする。

`message` はHuman-readable Messageとする。

---

## 43. Error Code

Error CodeはFrontendなどClientがError種類を識別するために利用する。

例:

```text
EMPLOYEE_NOT_FOUND
SKILL_NOT_FOUND
EMPLOYEE_SKILL_NOT_FOUND
DUPLICATE_EMPLOYEE_SKILL
INVALID_SKILL_LEVEL_FOR_NO_EXPERIENCE
EXPERIENCE_PERIOD_REQUIRED
LAST_USED_MONTH_REQUIRED
PERMISSION_MANAGER_REQUIRED
FORBIDDEN_EMPLOYEE_ACCESS
```

---

## 44. Error Codeの命名

Error Codeは原則として、

```text
UPPER_SNAKE_CASE
```

とする。

Business意味が分かる安定した名前を利用する。

避ける:

```text
ERROR_001
VALIDATION_ERROR_3
DB_ERROR
INVALID
```

---

## 45. Error CodeをException自身に持たせない

Domain / Application Exception自身へAPI Error Codeを直接持たせない。

例えば、

```php
public const ERROR_CODE =
    'PERMISSION_MANAGER_REQUIRED';
```

をDomain Exceptionへ持たせる設計は原則採用しない。

Error CodeはAPI Contractの一部であるため、Presentation側のMappingで定義する。

---

## 46. ExceptionとError Code Mapping

概念:

```text
PermissionManagerRequired
        ↓
Presentation Mapping
        ↓
HTTP 409
        +
PERMISSION_MANAGER_REQUIRED
```

```text
EmployeeNotFound
        ↓
Presentation Mapping
        ↓
HTTP 404
        +
EMPLOYEE_NOT_FOUND
```

MappingをPresentation Boundaryへ集約する。

---

## 47. Error Message

Client向けMessageは内部Exception Messageと分離する。

内部:

```text
EmployeeSkill 123 was not found.
```

Client:

```text
The employee skill was not found.
```

IDやInternal Stateなどを不用意に公開しない。

---

## 48. Frontendでの扱い

Frontend / BFFはError `code` を利用して必要な処理を判断する。

避ける:

```ts
if (
  error.message.includes(
    'already registered'
  )
) {
  ...
}
```

推奨:

```ts
if (
  error.code ===
  'DUPLICATE_EMPLOYEE_SKILL'
) {
  ...
}
```

Message文字列をAPI Contractとして扱わない。

---

## 49. Validation Error Response

Form Request Validation FailureではField Errorを含める。

例:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request is invalid.",
    "details": {
      "skillLevel": [
        "The skill level field is required."
      ],
      "lastUsedMonth": [
        "The last used month must be in YYYY-MM format."
      ]
    }
  }
}
```

通常のBusiness Errorでは `details` は必須としない。

---

## 50. Validation Field Name

Validation ErrorのField NameはAPI Contractに合わせてcamelCaseとする。

```text
skillLevel
lastUsedMonth
experienceMonths
```

Database Columnのsnake_caseをClientへ漏らさない。

---

## 51. Validation Error Code

Form Request Validation Failureは共通して、

```text
VALIDATION_ERROR
```

を利用する。

各Field Validation Ruleごとに大量のError Codeを定義することはMVPでは行わない。

Business上特別な意味を持つFailureのみ専用Codeを持たせる。

---

## 52. Error Codeの安定性

Error CodeはFrontendとのContractになるため、一度公開したものを安易に変更しない。

Error Messageは改善・翻訳できるが、Error CodeはVersioned API Contractとして扱う。

---

## 53. OpenAPIとの整合

Error ResponseとError CodeはOpenAPI Specificationへ定義する。

OpenAPIでは以下を明示する。

- HTTP Status
- Error Response Schema
- `error.code`
- `error.message`
- Validation `details`
- Endpointごとに想定される主要Error

Laravel実装からOpenAPIを逆生成してSource of Truthにしない。

---

## 54. Error Code一覧

Error Codeが増えてきた場合は一覧を管理する。

例えば、

```text
API Error Catalog
```

をOpenAPIまたは関連Documentで管理できる。

ただし、Domain Exception一覧とAPI Error Code一覧を同一概念として扱わない。

---

## 55. Expected Exception

Expected Exceptionとは、Business / UseCase上想定されるFailureを指す。

例:

- Not Found
- Authorization Failure
- Duplicate
- Invalid State
- Domain Rule Violation

これらはClientへ適切な4xx Responseとして返す。

---

## 56. Unexpected Exception

Unexpected Exceptionは通常Client側では解決できないFailureである。

例:

- Programming Error
- DB接続障害
- Unexpected Driver Error
- Mapper Bug
- 未想定Exception

原則として `500` とする。

必要に応じて明確な一時的Infrastructure障害のみ `503` を検討する。

---

## 57. Unexpected Error Response

Unexpected ErrorではInternal DetailをClientへ返さない。

推奨:

```json
{
  "error": {
    "code": "INTERNAL_SERVER_ERROR",
    "message": "An unexpected error occurred."
  }
}
```

避ける:

```json
{
  "error": {
    "message": "SQLSTATE[23505]..."
  }
}
```

---

## 58. ProductionでStack Traceを公開しない

Production API Responseへ以下を含めない。

- Stack Trace
- SQL
- Database Table Name
- Constraint Detail
- File Path
- Source Code Line
- Environment Variable
- Token
- Credential

Debug情報はServer-side Logging / Observabilityで扱う。

---

## 59. Logging

Unexpected Exceptionは原則としてServer-sideで記録する。

必要な情報の例:

- Request ID / Correlation ID
- Exception Class
- Stack Trace
- Endpoint
- Actor ID
- Relevant Resource ID
- Timestamp

ただしSensitive DataやCredentialを記録しない。

---

## 60. Expected ExceptionのLogging

4xx系Expected ErrorをすべてError Logへ出力しない。

例えば、

```text
EmployeeNotFound
Validation Error
Forbidden
Duplicate
```

は通常のApplication Flowとして発生し得る。

必要に応じてInfo / Warning / Auditとして記録するが、すべてをError Levelにしない。

---

## 61. ExceptionとAudit Log

Security / Permission変更など重要操作の失敗はAudit対象になる場合がある。

ただし、

```text
Exception Logging
```

と、

```text
Audit Logging
```

は目的が異なる。

Exception HandlerへAudit責務をすべて集約しない。

---

## 62. ExceptionをFlow Controlに乱用しない

通常の分岐でExceptionを利用しすぎない。

例えばRepositoryの `find()` は、

```php
$skill = $repository->find($id);

if ($skill === null) {
    throw new SkillNotFound($id);
}
```

とする。

Expected Valueの不存在とInfrastructure Failureを区別する。

---

## 63. `null` とException

Repositoryの `find()` は対象が存在しない場合 `null` を返す。

Application HandlerがUseCase上必要ならNot Found Exceptionへ変換する。

一方、

```text
Database接続失敗
```

などは `null` で隠さずExceptionとして扱う。

---

## 64. Catchする場所

Exceptionは意味を変換する必要があるLayerでCatchする。

例:

```text
PDO / QueryException
        ↓
InfrastructureでCatch
        ↓
Persistence Exception等へ変換
```

```text
Domain / Application Exception
        ↓
PresentationでMapping
        ↓
HTTP Response
```

意味を変えないなら無理にCatchしない。

---

## 65. `catch (\Throwable)` の扱い

Business Layerで広範囲な、

```php
catch (\Throwable $e)
```

を通常利用しない。

Programming ErrorまでBusiness Errorへ変換してしまう危険がある。

Top-level Exception HandlerでUnexpected Errorを捕捉する用途は許容する。

---

## 66. Original Exception

InfrastructureでException Translationする場合は、必要に応じてOriginal ExceptionをPrevious Exceptionとして保持する。

例:

```php
throw new PersistenceException(
    'Failed to save employee skill.',
    previous: $e,
);
```

これによりLogging時にRoot Causeを追跡できる。

ClientへPrevious Exception Detailは公開しない。

---

## 67. Message Translation / i18n

Domain Exception MessageをそのままUI文言として利用しない。

将来的に多言語化する場合も、

```text
Error Code
    ↓
Frontend / Presentation Message
```

のようにAPI Contractと表示文言を分離できる。

MVPではAPI Messageを統一した言語方針で返す。

---

## 68. Error ResponseとBFF

Laravel APIのError ResponseをNext.js BFFで受け取る。

BFFは基本的に以下を維持してFrontendへ伝達する。

- HTTP Status
- Error Code
- Error Message
- Validation Details

Laravel内部Exception Class名はBFFへ公開しない。

---

## 69. BFFでErrorを再定義しすぎない

Next.js BFFでLaravel Error Codeを毎回別の独自Error Codeへ変換しない。

Laravel API ContractとFrontend Contractを不要に二重管理しない。

ただしSecurity上隠す必要がある情報やBFF固有Failureについては別途Mappingしてよい。

---

## 70. Authentication Error

Authentication Errorの基本:

```text
Authentication Failure
    ↓
401
    ↓
UNAUTHENTICATED
```

例:

```json
{
  "error": {
    "code": "UNAUTHENTICATED",
    "message": "Authentication is required."
  }
}
```

---

## 71. Authorization Error

Authorization Failureの基本:

```text
Authorization Failure
    ↓
403
    ↓
FORBIDDEN
```

Business上区別する必要がある場合のみ、

```text
FORBIDDEN_EMPLOYEE_ACCESS
PERMISSION_MANAGEMENT_FORBIDDEN
```

などのCodeを利用する。

Error Codeを細分化するのはClient側で区別する価値がある場合だけとする。

---

## 72. Not Found Error

例:

```json
{
  "error": {
    "code": "EMPLOYEE_SKILL_NOT_FOUND",
    "message": "The employee skill was not found."
  }
}
```

HTTP:

```text
404 Not Found
```

---

## 73. Conflict Error

例:

```json
{
  "error": {
    "code": "DUPLICATE_EMPLOYEE_SKILL",
    "message": "The employee skill is already registered."
  }
}
```

HTTP:

```text
409 Conflict
```

---

## 74. Domain Rule Error

例:

```json
{
  "error": {
    "code": "INVALID_SKILL_LEVEL_FOR_NO_EXPERIENCE",
    "message": "The skill level is invalid for an employee without work experience."
  }
}
```

この例ではRequest内容自体がBusiness Ruleへ反するため、

```text
422 Unprocessable Entity
```

を基本とする。

---

## 75. Permission Manager Error

例:

```json
{
  "error": {
    "code": "PERMISSION_MANAGER_REQUIRED",
    "message": "At least one permission manager is required."
  }
}
```

これは現在StateとのConflictであるため、

```text
409 Conflict
```

を利用する。

---

## 76. Exception Mapping Table

代表的なMappingを以下とする。

| Exception / Failure | HTTP | Error Code |
|---|---:|---|
| Authentication Failure | 401 | `UNAUTHENTICATED` |
| Authorization Failure | 403 | `FORBIDDEN` |
| EmployeeNotFound | 404 | `EMPLOYEE_NOT_FOUND` |
| SkillNotFound | 404 | `SKILL_NOT_FOUND` |
| EmployeeSkillNotFound | 404 | `EMPLOYEE_SKILL_NOT_FOUND` |
| DuplicateEmployeeSkill | 409 | `DUPLICATE_EMPLOYEE_SKILL` |
| PermissionManagerRequired | 409 | `PERMISSION_MANAGER_REQUIRED` |
| InvalidSkillLevelForNoExperience | 422 | `INVALID_SKILL_LEVEL_FOR_NO_EXPERIENCE` |
| ExperiencePeriodRequired | 422 | `EXPERIENCE_PERIOD_REQUIRED` |
| LastUsedMonthRequired | 422 | `LAST_USED_MONTH_REQUIRED` |
| Form Request Validation | 422 | `VALIDATION_ERROR` |
| Unexpected Exception | 500 | `INTERNAL_SERVER_ERROR` |

このTableはOpenAPI Contractと整合させる。

---

## 77. Exception Directory

Domain Exceptionは各Business Conceptの近くへ配置する。

例:

```text
Domain/
└── SkillManagement/
    └── EmployeeSkill/
        └── Exceptions/
            ├── InvalidSkillLevelForNoExperience.php
            ├── ExperiencePeriodRequired.php
            └── LastUsedMonthRequired.php
```

Application ExceptionはUseCaseまたはContextに近い場所へ配置する。

例:

```text
Application/
└── SkillManagement/
    └── Exceptions/
        ├── EmployeeSkillNotFound.php
        └── DuplicateEmployeeSkill.php
```

---

## 78. Infrastructure Exception Directory

Infrastructure固有Exceptionが必要な場合は技術Contextの近くへ配置する。

例:

```text
Infrastructure/
└── Persistence/
    └── Exceptions/
        ├── PersistenceException.php
        ├── DeadlockException.php
        └── LockTimeoutException.php
```

ただしLow-level Exceptionをすべて独自Classへラップする必要はない。

Outer Layerへ意味を変えて伝える必要があるものだけ定義する。

---

## 79. Presentation Mappingの配置

PresentationのException MappingはLaravelのException Handling機構を中心に構成する。

Mappingが増えた場合は、概念的に以下のようなClassを設けてもよい。

```text
Presentation/
└── Http/
    └── Exceptions/
        └── ApiExceptionMapper.php
```

ただしMVP初期から不要なException Frameworkを作らず、Laravel標準設定で十分ならそれを優先する。

---

## 80. Exception Handlerを巨大化させない

Exception Mappingが増加した場合、

```text
if / elseif
instanceof
```

を1ファイルへ大量に追加し続けない。

必要になった時点で、

- ApiExceptionMapper
- ErrorResponseFactory
- Exception Renderer

などへの分割を検討できる。

初期段階から過剰分割しない。

---

## 81. Exception Test

Domain Testでは以下を確認する。

- Invariant違反で正しいDomain Exceptionが発生する
- 不正状態を生成できない
- 状態変更MethodでもInvariantが維持される

Application Testでは以下を確認する。

- Not Found
- Authorization Failure
- Duplicate
- Domain Exception伝播
- Transaction Rollback

---

## 82. Infrastructure Exception Test

PostgreSQL Integration Testでは以下を確認する。

- UNIQUE Constraint Violation
- Constraint Name Mapping
- Rollback
- Deadlock / Lock関連で必要なケース
- Low-level Exception Translation

External Adapterが存在する場合は、

- Timeout
- 4xx / 5xx
- Invalid Response

などのMappingをTestする。

---

## 83. Presentation Exception Test

Feature TestではHTTP Contractを確認する。

例えば、

```text
DuplicateEmployeeSkill
    ↓
409
    ↓
DUPLICATE_EMPLOYEE_SKILL
```

をTestする。

同様に、

- 401
- 403
- 404
- 409
- 422
- 500

の代表ケースを確認する。

---

## 84. Error Response Contract Test

最低限以下を確認する。

```json
{
  "error": {
    "code": "...",
    "message": "..."
  }
}
```

Validation Errorでは、

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "...",
    "details": {}
  }
}
```

を確認する。

API JSONはcamelCaseを維持する。

---

## 85. OpenAPIとのContract Test

実装とOpenAPIで以下が乖離しないことを確認する。

- Status Code
- Error Schema
- Error Code
- Validation Details
- Required Fields

可能であればContract Testを導入する。

詳細はAPI品質 / Test Strategyに従う。

---

## 86. Exception設計で避けるもの

以下を避ける。

- Domain ExceptionにHTTP Statusを持たせる
- Domain ExceptionにLaravel Responseを持たせる
- ApplicationからJsonResponseを返す
- Repositoryから404を投げる
- PostgreSQL ExceptionをそのままClientへ返す
- Exception Message文字列でFrontend分岐
- 全Business Errorを `400`
- 全Domain Errorを `422`
- Database Errorを意味を見ずにすべて同一扱いする
- Exceptionを握り潰す
- `catch (\Throwable)` で全FailureをBusiness Errorへ変換
- ProductionでStack Trace公開
- Error Codeを頻繁に変更
- Error CodeとException Classを完全に同一概念として扱う
- External APIのStatusをそのままClientへ転送
- Infrastructure固有情報をAPI Contractへ漏らす

---

## 87. Exception責務の最終整理

```text
Business Invariant Violation
        ↓
Domain Exception

UseCase Failure
        ↓
Application Exception

Technical Failure
        ↓
Infrastructure Exception

HTTP Representation
        ↓
Presentation Exception Mapping
```

責務をLayerごとに明確に分離する。

---

## 88. 最終方針

本システムのException設計は、

> DomainではBusiness Rule違反、ApplicationではUseCase成立失敗、Infrastructureでは技術的Failureをそれぞれの意味で表現し、Presentation LayerでHTTP Status・Error Code・Client Messageへ変換する

方針とする。

Exception ClassそのものをHTTP Contractにはしない。

API Contractとして外部へ公開するのは、

```text
HTTP Status
+
Error Code
+
Error Response Schema
```

とする。

代表的な判断基準は以下とする。

```text
Authentication Failure
    ↓
401

Authorization Failure
    ↓
403

Not Found
    ↓
404

Current StateとのConflict
    ↓
409

Request / Business Inputが不正
    ↓
422

Unexpected Server Failure
    ↓
500
```

ただし、

> ExceptionがどのLayerで発生したかではなく、そのFailureがAPI Clientにとって何を意味するか

によってHTTP Statusを決定する。

最終的には、

> Business FailureとTechnical Failureを明確に区別しつつ、Clientには安定したMachine-readable Error Contractを提供すること

をException設計の基準とする。
