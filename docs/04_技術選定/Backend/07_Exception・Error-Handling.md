# Backend 技術・Library選定 - Exception・Error Handling

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend における Exception分類、Layer間のException Translation、HTTP Error Response、Laravel Exception Handling、Reporting / Loggingとの責務分離を定義する。

本Projectでは以下を基本方針とする。

- Domain ExceptionへHTTP概念を持ち込まない
- Application ExceptionはUseCase実行不能を表現する
- Infrastructure固有Exceptionを外部へ直接露出しない
- HTTP Responseへの変換はPresentation側へ集約する
- Error ResponseにはRFC 9457 Problem Detailsを採用する
- Project固有のMachine-readable Error Codeを持つ
- Expected 4xx ErrorとUnexpected 5xx Errorを区別する
- RenderingとReportingを分離する
- Controller単位のException Handlingを原則行わない
- Sensitive InformationをError Responseへ含めない

---

## 2. 基本方針

ExceptionとHTTP Responseを直接結び付けない。

```text
Domain / Application / Infrastructure
            ↓
         Exception
            ↓
Presentation Exception Mapping
            ↓
RFC 9457 Problem Details
            ↓
HTTP Response
```

最重要原則は以下とする。

```text
Domain Exception
    ≠
HTTP Exception
```

例えばDomain Exception自身へ以下を持たせない。

```text
HTTP Status
JsonResponse
Content-Type
Laravel Request
Log Level
Problem Details
```

HTTPへの変換責務はPresentation Layerへ配置する。

---

## 3. Exception分類

Exceptionは主に以下へ分類する。

| 分類 | 責務 |
|---|---|
| Domain Exception | Business Invariant違反 |
| Application Exception | UseCase実行不能 |
| Infrastructure Exception | DB・外部Service等の技術的失敗 |
| Presentation Exception | HTTP Boundary固有の失敗 |
| Unexpected Exception | 想定外のSystem Failure / Programming Error |

Exception ClassはLayerだけを理由に大量作成しない。

専用Exceptionを作成する基準は以下とする。

```text
呼び出し側で失敗理由を区別する必要がある
Mapping結果が異なる
Testで意味的に識別したい
Audit / Handling方法が異なる
```

---

## 4. Domain Exception

Domain ExceptionはBusiness Invariant違反を表現する。

例：

```text
InvalidSkillLevelForUnexperiencedEmployee
InvalidExperiencePeriod
CannotRemoveLastPermissionAdministrator
```

例：

```php
final class InvalidSkillLevelForUnexperiencedEmployee
    extends DomainException
{
}
```

Domain ExceptionはPure PHPとして実装する。

Laravel / HTTP / Databaseへ依存しない。

---

## 5. Domain Exceptionの粒度

意味のあるBusiness Ruleについては専用Exceptionを利用する。

以下のような曖昧なExceptionだけに集約しない。

```php
throw new DomainException('Invalid domain operation.');
```

一方で、細かすぎるException Explosionも避ける。

専用Classを作成するかは以下で判断する。

```text
Client / Applicationで意味を区別する必要があるか
HTTP Mappingが異なるか
Business上重要なRuleか
Test上明示的に識別したいか
```

---

## 6. Application Exception

Application Exceptionは、

> Input形式としては妥当だが、そのUseCaseを現在実行できない

状態を表現する。

例：

```text
EmployeeNotFound
SkillNotFound
SkillInactive
EmployeeSkillAlreadyExists
OperationConflict
```

例えば、

```php
final class SkillNotFound extends RuntimeException
{
    public function __construct(
        public readonly SkillId $skillId,
    ) {
        parent::__construct('Skill was not found.');
    }
}
```

のように実装できる。

---

## 7. Resource Not Found

RepositoryのLookup結果が存在しない場合、Application Layerで意味のあるExceptionへ変換する。

```text
Repository
    ↓
null
    ↓
Application Handler
    ↓
EmployeeNotFound
```

例：

```php
$employee = $this->employees->findById(
    $command->employeeId,
);

if ($employee === null) {
    throw new EmployeeNotFound(
        $command->employeeId,
    );
}
```

RepositoryからHTTP 404 Exceptionを直接投げない。

---

## 8. Infrastructure Exception

Infrastructure Layerでは以下の技術的Failureが発生し得る。

```text
Database
External API
Filesystem
Cache
Queue
Network
```

例：

```text
PDOException
QueryException
ConnectionException
External API Client Exception
Timeout Exception
```

Infrastructure固有ExceptionをそのままHTTP Responseへ露出させない。

---

## 9. Exception Translation

Infrastructure FailureにApplication / Domain上の意味がある場合は、Layer境界で意味のあるExceptionへ変換する。

例：

```text
PostgreSQL UNIQUE Violation
        ↓
Infrastructure Repository
        ↓
EmployeeSkillAlreadyExists
        ↓
Presentation
        ↓
409 Conflict
```

ただし、すべてのInfrastructure ErrorをBusiness Exceptionへ変換しない。

例えば、

```text
Database Connection Failure
Unknown SQL Error
Driver Failure
```

はUnexpected Infrastructure Failureとして上位へ伝播させる。

---

## 10. RFC 9457 Problem Details

Error Response形式としてRFC 9457 Problem Detailsを採用する。

JSON ResponseのMedia Typeは以下とする。

```http
Content-Type: application/problem+json
```

基本Memberは以下。

```text
type
title
status
detail
instance
```

本ProjectではExtension Memberとして以下を追加する。

```text
code
errors
```

`code`はProject固有のMachine-readable Error Identifierとする。

`errors`はValidation Error用とする。

---

## 11. 独自Error Envelopeの廃止

これまでの暫定形式、

```json
{
  "error": {
    "code": "EMPLOYEE_NOT_FOUND",
    "message": "Employee not found."
  }
}
```

は正式採用しない。

RFC 9457へ統一する。

```text
独自 error Envelope
    ↓
不採用

RFC 9457 Problem Details
    ↓
採用
```

`02_HTTP・API.md`のError Response部分は横断レビュー時に本方針へ更新する。

---

## 12. 基本Problem Details

Employeeが存在しない場合の例：

```json
{
  "type": "https://api.example.com/problems/employee-not-found",
  "title": "Employee not found",
  "status": 404,
  "detail": "The specified employee does not exist.",
  "code": "EMPLOYEE_NOT_FOUND"
}
```

Header：

```http
Content-Type: application/problem+json
```

---

## 13. `type`

`type`はProblem Typeを表す安定したIdentifierとして利用する。

形式は以下を基本とする。

```text
https://api.example.com/problems/{problem-name}
```

例：

```text
https://api.example.com/problems/employee-not-found
https://api.example.com/problems/validation-error
https://api.example.com/problems/forbidden
```

MVP開始時点でProblem Documentation Siteの大規模構築までは必須としない。

ただしURIは公開Contractとして安定させる。

---

## 14. `title`

`title`はHuman-readableな短いProblem Summaryとする。

例：

```text
Employee not found
Validation failed
Forbidden
Internal server error
```

Program Logicで`title`を判定しない。

---

## 15. `status`

`status`にはHTTP Status Codeを設定する。

例：

```json
{
  "status": 404
}
```

HTTP Response Statusと一致させる。

---

## 16. `detail`

`detail`はUser / Clientが問題を理解するためのHuman-readable説明とする。

例：

```json
{
  "detail": "The specified employee does not exist."
}
```

`detail`へ以下を含めない。

```text
Stack Trace
SQL
Class Name
Absolute Path
Internal Host
Database Error
Secret
Token
```

また、Frontend / BFF Logicで`detail`文字列を解析しない。

---

## 17. `instance`

`instance`は個別のProblem occurrenceを識別するために利用できる。

MVPではOptionalとする。

```text
instance
    → Optional
```

将来的にRequest ID / Trace ID等との連携が必要になった場合に導入を検討する。

無理に全Responseへ設定しない。

---

## 18. Project Error Code

RFC 9457 Extension Memberとして`code`を必須採用する。

例：

```json
{
  "code": "EMPLOYEE_NOT_FOUND"
}
```

Frontend / BFFは原則以下でError種別を判断する。

```text
HTTP Status
+
code
```

Human-readable Message文字列では判断しない。

---

## 19. Error Code命名規則

Error Codeは以下に統一する。

```text
UPPER_SNAKE_CASE
```

例：

```text
VALIDATION_ERROR
UNAUTHENTICATED
FORBIDDEN
EMPLOYEE_NOT_FOUND
SKILL_NOT_FOUND
EMPLOYEE_SKILL_ALREADY_EXISTS
SKILL_INACTIVE
INTERNAL_SERVER_ERROR
```

Error CodeはPublic API Contractの一部として扱う。

---

## 20. Error Codeの安定性

一度公開したError Codeを理由なく変更しない。

```text
code
    ↓
Machine-readable
    ↓
Stable Contract
```

一方で、

```text
title
detail
```

はHuman-readable Textのため、意味を維持した文言調整を許容する。

---

## 21. Validation Error

Validation ErrorもRFC 9457形式へ統一する。

例：

```json
{
  "type": "https://api.example.com/problems/validation-error",
  "title": "Validation failed",
  "status": 422,
  "detail": "The request contains invalid values.",
  "code": "VALIDATION_ERROR",
  "errors": {
    "skill_level": [
      "The skill level must be between 1 and 5."
    ],
    "last_used_year_month": [
      "The last used year month is required."
    ]
  }
}
```

---

## 22. Validation `errors`

Validation Error専用Extensionとして、

```text
errors
```

を採用する。

基本形は以下。

```text
Field Name
    ↓
Message Array
```

例：

```json
{
  "errors": {
    "name": [
      "The name field is required."
    ]
  }
}
```

Validation RuleごとのMachine-readable CodeまではMVPでは定義しない。

必要性が明確になった場合のみ拡張する。

---

## 23. HTTP Status Mapping

基本Mappingは以下とする。

| Failure | HTTP Status |
|---|---:|
| Authentication Failure | 401 |
| Authorization Failure | 403 |
| Resource Not Found | 404 |
| Method Not Allowed | 405 |
| Resource / State Conflict | 409 |
| Request Validation Failure | 422 |
| Rate Limit | 429 |
| Unexpected Server Failure | 500 |
| Upstream Failure | 502 / 503を状況に応じ利用 |

---

## 24. 401 Unauthorized

401はAuthenticationできない場合に利用する。

例：

```text
Tokenなし
Invalid Token
Expired Token
Revoked Token
Authenticated Userが無効
```

例：

```json
{
  "type": "https://api.example.com/problems/unauthenticated",
  "title": "Authentication required",
  "status": 401,
  "code": "UNAUTHENTICATED"
}
```

---

## 25. 403 Forbidden

403はAuthentication済みだがAuthorizationされていない場合に利用する。

例：

```json
{
  "type": "https://api.example.com/problems/forbidden",
  "title": "Forbidden",
  "status": 403,
  "code": "FORBIDDEN"
}
```

Role / Assignment / Policyの詳細情報を不用意にResponseへ含めない。

---

## 26. 404 Not Found

Resourceが存在しない場合は404とする。

例：

```text
EmployeeNotFound
SkillNotFound
DepartmentNotFound
```

Security上Resourceの存在有無を隠す必要があるケースではPolicy設計と合わせて個別判断する。

---

## 27. 409 Conflict

409は、

> Request形式は妥当だが、現在のResource StateとのConflictによって処理できない

場合に利用する。

例：

```text
EmployeeSkillAlreadyExists
SkillInactive
Current Stateでは変更不可
Concurrent State Conflict
```

何でも409へ分類しない。

---

## 28. 422 Validation Error

422はHTTP Input Validation Failureに利用する。

例：

```text
required
type
format
range
enum
conditional input
```

```text
Form Request Failure
    ↓
422
```

Domain Exceptionを一律422へ変換しない。

---

## 29. 429 Too Many Requests

Rate Limit超過時は429を利用する。

必要に応じて、

```http
Retry-After
```

を付与する。

Rate Limitの具体的設定はSecurity / API設計側で定義する。

---

## 30. 500 Internal Server Error

想定外Exceptionは500へ統一する。

例：

```json
{
  "type": "https://api.example.com/problems/internal-server-error",
  "title": "Internal server error",
  "status": 500,
  "code": "INTERNAL_SERVER_ERROR"
}
```

Production Responseへ内部Error Detailを含めない。

---

## 31. Upstream Failure

External Serviceが原因の場合は状況に応じて502 / 503等を利用する。

例：

```text
Invalid Upstream Response
    → 502候補

Temporary Service Unavailable
    → 503候補
```

External ServiceのRaw Error ResponseをClientへそのまま返さない。

---

## 32. Database Constraint Violation

予測可能なDatabase Constraint Violationは意味のあるApplication Errorへ変換する。

例：

```text
UNIQUE(employee_id, skill_id)
        ↓
EmployeeSkillAlreadyExists
        ↓
409 Conflict
```

Database DriverのException MessageやSQLSTATEを直接API Contractへしない。

---

## 33. Unexpected Database Error

以下は通常500として扱う。

```text
Database Connection Failure
Unknown Query Failure
Unexpected Foreign Key Failure
Schema Mismatch
Driver Failure
```

無理にBusiness Exceptionへ変換しない。

---

## 34. Laravel Exception Handling

HTTP Error RenderingはLaravelのCentral Exception Handlingへ集約する。

概念構成：

```text
bootstrap/app.php
    ↓
withExceptions(...)
    ↓
Exception Mapping
    ↓
Problem Details
    ↓
JsonResponse
```

ControllerごとにResponse Mappingを記述しない。

---

## 35. Controller `try/catch`

以下のようなController単位のException Handlingは原則禁止する。

```php
public function __invoke(...): JsonResponse
{
    try {
        // UseCase
    } catch (EmployeeNotFound $exception) {
        return response()->json(..., 404);
    }
}
```

代わりに以下とする。

```text
Controller
    ↓
Application Handler
    ↓
Exception
    ↓
Central Exception Handler
    ↓
Problem Details
```

---

## 36. Exception `render()`

Domain / Application Exception自身にLaravelの`render()`を実装しない。

以下のような構造は禁止する。

```php
final class EmployeeNotFound extends RuntimeException
{
    public function render(
        Request $request,
    ): JsonResponse {
        // ...
    }
}
```

理由：

```text
Domain / Application
    ↓
Laravel / HTTP dependency
```

を発生させないため。

---

## 37. Problem Details Mapper

Exception数が増えた場合はPresentation側に小さなMapperを導入できる。

概念：

```text
Throwable
    ↓
ProblemDetailsMapper
    ↓
ProblemDetails
    ↓
HTTP Response
```

例：

```php
final class ProblemDetailsMapper
{
    public function map(
        Throwable $exception,
    ): ProblemDetails {
        // ...
    }
}
```

最初から巨大な独自Exception Frameworkを作成しない。

---

## 38. ProblemDetails DTO

RFC 9457 Response構築用にPresentation専用DTOを利用できる。

例：

```php
final readonly class ProblemDetails
{
    public function __construct(
        public string $type,
        public string $title,
        public int $status,
        public ?string $detail,
        public string $code,
        public ?array $errors = null,
    ) {
    }
}
```

このDTOはPresentation Layerに属する。

Domain / Applicationへ持ち込まない。

---

## 39. RenderingとReporting

Exception Handlingでは以下を明確に分離する。

```text
Rendering
    ↓
Clientへ何を返すか

Reporting
    ↓
Application内部で何を記録・通知するか
```

例えば、

```text
EmployeeNotFound
```

は404としてRenderingする必要があるが、通常はSystem ErrorとしてReportする必要はない。

一方、

```text
Unexpected Database Connection Failure
```

は500としてRenderingし、Report対象とする。

---

## 40. ReportしないException

以下は原則としてSystem Error Report対象外とする。

```text
Validation Error
Expected Authentication Failure
Expected Authorization Failure
Expected Not Found
Expected Conflict
```

ただしSecurity Audit上必要なEventはException Reportingではなく、Security / Audit Loggingとして別途記録する。

---

## 41. ReportするException

以下は原則Report対象とする。

```text
Unexpected Exception
Database Connection Failure
Unexpected External API Failure
Programming Error
Unexpected Infrastructure Failure
Impossible State
```

具体的なLog Level / Monitoring通知は`09_Log・Audit.md`および`10_Observability.md`で定義する。

---

## 42. Authorization FailureとAudit

403を毎回Error Reportへ送信しない。

必要なAuthorization Failureは、

```text
Security Event
Audit Event
```

として記録する。

例：

```text
Permission変更失敗
不正な管理操作試行
Forbidden Operation
```

Exception ReportingとAudit Loggingを混同しない。

---

## 43. External Service Error

External Service利用時はFailureを以下のように分類する。

```text
Timeout
Connection Failure
4xx Response
5xx Response
Invalid Response
```

Infrastructure固有ExceptionをそのままClientへ返さない。

必要に応じてApplication上意味のあるErrorへ変換する。

---

## 44. Retry可能Error

Retry可能性をError Message文字列で判断しない。

必要に応じてHTTP標準Headerを利用する。

例：

```http
Retry-After
```

MVPでは独自Extension、

```json
{
  "retryable": true
}
```

を標準採用しない。

Requirementが出た場合のみ追加する。

---

## 45. Sensitive Information

Problem DetailsにはClientが問題を理解するために必要な情報のみ含める。

以下は禁止する。

```text
Access Token
Session ID
Password
Secret
Environment Variable
SQL
Stack Trace
Absolute File Path
Internal Host
Internal IP
Class Name
Raw External API Response
Database Connection Information
```

---

## 46. Production Debug設定

Productionでは必ず以下とする。

```text
APP_DEBUG=false
```

Local / DevelopmentではDebug情報を利用可能とする。

Production Error ResponseではDebug Detailを表示しない。

---

## 47. Logging

Clientへ返すProblem Detailsと内部Logを分離する。

Client：

```text
安全なError情報
Stable Code
HTTP Status
```

Internal Log：

```text
Exception Class
Stack Trace
Request ID
Trace ID
Context
```

ただしTokenやSecret等はInternal Logでも記録しない。

---

## 48. Expected 4xx Logging

通常の4xxをすべてError LevelでLogしない。

例：

```text
422 Validation Error
404 Expected Not Found
409 Expected Conflict
```

は通常のApplication Flowとして扱う。

大量発生やSecurity兆候がある場合はMonitoring / Security側で別途検知する。

---

## 49. OpenAPI

Problem Details SchemaをOpenAPIへ定義する。

概念例：

```yaml
ProblemDetails:
  type: object
  required:
    - type
    - title
    - status
    - code
  properties:
    type:
      type: string
      format: uri
    title:
      type: string
    status:
      type: integer
    detail:
      type: string
    instance:
      type: string
      format: uri
    code:
      type: string
```

Validation用に別Schemaを定義する。

```text
ValidationProblemDetails
    ↓
ProblemDetails
    +
errors
```

---

## 50. OpenAPI Error Response Component

頻出ErrorはOpenAPI Componentsへ共通定義する。

例：

```text
UnauthenticatedProblem
ForbiddenProblem
NotFoundProblem
ConflictProblem
ValidationProblem
InternalServerErrorProblem
```

PathごとにSchemaを重複記述しない。

---

## 51. Contract Test

Error ResponseもOpenAPI Contract Test対象とする。

確認例：

```text
401
403
404
409
422
500
```

Responseについて以下を検証する。

```text
Content-Type
type
title
status
code
errors
```

---

## 52. Exception Handling Test

Exception HandlingはFeature Testを中心に確認する。

代表ケース：

```text
Invalid Request
    → 422

Unauthenticated
    → 401

Forbidden
    → 403

Resource Missing
    → 404

Duplicate
    → 409

Unexpected Failure
    → 500
```

---

## 53. Domain Exception Test

Domain ExceptionはDomain Unit Testで確認する。

例：

```text
未経験でLevel2を設定
    ↓
InvalidSkillLevelForUnexperiencedEmployee
```

HTTP ResponseまでDomain Unit Testで確認しない。

---

## 54. Application Exception Test

Application ExceptionはApplication Testで確認する。

例：

```text
存在しないSkill
    ↓
SkillNotFound

重複EmployeeSkill
    ↓
EmployeeSkillAlreadyExists
```

HTTP MappingはPresentation Feature Testで別途確認する。

---

## 55. Infrastructure Translation Test

Database Constraint等のException TranslationはInfrastructure / Integration Testで確認する。

例：

```text
PostgreSQL UNIQUE Violation
    ↓
EmployeeSkillAlreadyExists
```

Driver-specific ErrorがPresentationまで漏れないことを確認する。

---

## 56. External Exception Library

Exception Architecture用のExternal Libraryは採用しない。

利用するもの：

```text
PHP Exception / Throwable
Laravel Exception Handling
RFC 9457
Project固有Exception
```

以下のような独自Exception Frameworkは導入しない。

```text
Exception Mapping Framework
Domain Error Framework
Result Monad Library
Problem Details Framework
```

必要性が明確になるまではProject内の小さなMapperで十分とする。

---

## 57. Result Typeとの関係

Application Errorをすべて、

```text
Result<T, E>
Either
Error Monad
```

で表現する方式はMVPでは採用しない。

Expected Failureについても、通常のPHP Exceptionを基本とする。

ただし、

```text
Validation Result
Batch処理で複数Failureを収集する
```

等、ExceptionよりResult型が自然なケースは個別検討できる。

---

## 58. Exception命名

Exception名には意味を明示する。

推奨：

```text
EmployeeNotFound
SkillNotFound
EmployeeSkillAlreadyExists
InvalidExperiencePeriod
CannotRemoveLastPermissionAdministrator
```

避ける：

```text
BusinessException
ApplicationException
InvalidOperationException
CustomException
```

抽象的すぎる名前だけで設計しない。

---

## 59. Library採用判断

| Library / 技術 | 判断 |
|---|---|
| PHP Exception / Throwable | 採用 |
| Laravel Central Exception Handling | 採用 |
| RFC 9457 Problem Details | 採用 |
| `application/problem+json` | 採用 |
| Project Error Code | 採用 |
| Validation `errors` Extension | 採用 |
| ProblemDetails DTO | 必要に応じ採用 |
| ProblemDetailsMapper | 必要に応じ採用 |
| Exception `render()` in Domain | 不採用 |
| Controller個別try/catch | 原則不採用 |
| External Exception Framework | 不採用 |
| Result Monad Library | 不採用 |
| Custom Problem Details Library | 原則不採用 |

---

## 60. 採用技術・方針一覧

| 項目 | 決定 |
|---|---|
| Error Response | RFC 9457 |
| Media Type | `application/problem+json` |
| 旧独自Error Envelope | 廃止 |
| Machine-readable Error | `code` |
| Validation Details | `errors` |
| Problem `type` | Project管理URI |
| `instance` | Optional |
| Domain Exception | Pure PHP |
| Application Exception | UseCase Failure |
| Infrastructure Exception | 技術的Failure |
| HTTP情報をDomainへ保持 | 禁止 |
| Exception Translation | Layer Boundary |
| Central Rendering | Laravel |
| Controller try/catch | 原則禁止 |
| Exception `render()` | Domain/Applicationでは禁止 |
| 401 | Authentication |
| 403 | Authorization |
| 404 | Not Found |
| 409 | Conflict |
| 422 | Validation |
| 429 | Rate Limit |
| 500 | Unexpected Error |
| 502 / 503 | Upstream Failure候補 |
| Expected 4xx Reporting | 原則不要 |
| Unexpected 5xx Reporting | 原則必須 |
| Production Debug | `APP_DEBUG=false` |
| Sensitive Information公開 | 禁止 |
| OpenAPI Error Schema | 定義 |
| Contract Test | 実施 |
| External Exception Library | 不採用 |

---

## 61. 最終Architecture

Business / Application Errorの流れ：

```text
Domain
    ↓
Domain Exception
    ↓
Application
    ↓
Application Exception / Propagation
    ↓
Presentation
    ↓
ProblemDetailsMapper
    ↓
RFC 9457
    ↓
HTTP Response
```

Infrastructure Errorの流れ：

```text
PostgreSQL / External Service
    ↓
Infrastructure Exception
    ↓
意味のあるFailureならException Translation
    ↓
Application Exception
    ↓
Presentation Mapping
```

Unexpected Error：

```text
Unexpected Throwable
    ↓
Laravel Exception Handler
    ↓
Internal Reporting
    ↓
Generic 500 Problem Details
```

---

## 62. 最終方針

Exception・Error Handlingでは、

> Inner Layerは失敗の意味を表現し、Outer LayerがTransportへ変換する

ことを基本とする。

```text
Domain
    ↓
Business Failure

Application
    ↓
UseCase Failure

Infrastructure
    ↓
Technical Failure

Presentation
    ↓
HTTP Problem Details
```

Domain / ApplicationへHTTP StatusやJsonResponseを持ち込まない。

HTTP Error Responseには、

```text
RFC 9457
+
Project Error Code
+
必要に応じたExtension
```

を利用する。

また、

```text
Rendering
    ≠
Reporting
```

を明確に分離し、

Expected 4xxは通常のApplication Flowとして扱い、Unexpected 5xxをSystem FailureとしてReportingする。

外部Exception Frameworkを追加せず、

> PHP Exception + Laravel Central Exception Handling + RFC 9457 + Project固有Exception

という構成を採用する。
