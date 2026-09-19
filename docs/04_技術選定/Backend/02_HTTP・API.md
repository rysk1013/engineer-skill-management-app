# Backend 技術・Library選定 - HTTP・API

## 1. 目的

本ドキュメントでは、Engineer Skill Management App BackendにおけるHTTP API設計方針と採用技術を定義する。

対象：

- REST API
- Laravel Routing
- API Versioning
- Controller
- Request / Response
- HTTP Status
- OpenAPI
- Error Response
- Pagination
- Filtering / Sorting / Search
- API Contract Test

本Projectでは、

> OpenAPIをSource of Truthとし、Laravelをその実装として扱うREST API

を基本方針とする。

---

# 2. 基本方針

Backend APIはRESTを基本とする。

```text
Client / BFF
    ↓
HTTP API
    ↓
Laravel Presentation Layer
    ↓
Application Layer
```

APIはResource-orientedに設計する。

例：

```text
/api/v1/employees
/api/v1/employees/{employee_id}

/api/v1/skills
/api/v1/skills/{skill_id}

/api/v1/employees/{employee_id}/skills
```

RPC形式を全面的には採用しない。

---

# 3. OpenAPI First

API ContractはOpenAPIをSource of Truthとする。

```text
Requirement
    ↓
OpenAPI
    ↓
Review
    ↓
Backend Implementation
    ↓
Frontend / BFF Implementation
    ↓
Contract Test
```

Laravel実装からOpenAPIを生成する方式は採用しない。

---

# 4. OpenAPI Version

OpenAPI 3.1.xを採用する。

SpecificationはYAMLで管理する。

初期構成：

```text
openapi/
└── openapi.yaml
```

Specificationが大きくなった場合は、

```text
openapi/
├── openapi.yaml
├── paths/
├── schemas/
├── parameters/
├── responses/
└── security/
```

等へ分割する。

最初から過剰分割しない。

---

# 5. OpenAPIで管理する内容

最低限以下をOpenAPIへ定義する。

```text
Path
HTTP Method
Request Parameter
Request Body
Response
HTTP Status
Schema
Enum
Validation Constraint
Authentication
Error Response
Pagination
```

---

# 6. OpenAPIとImplementation

OpenAPI：

```text
External Contract
```

Laravel：

```text
Contract Implementation
```

とする。

Laravel側のClass構造をOpenAPIへそのままExposeしない。

---

# 7. Code-first不採用

以下は採用しない。

```text
swagger-php
L5-Swagger
Laravel AnnotationからOpenAPI生成
PHP AttributeからOpenAPI生成
```

理由：

```text
OpenAPI
    ↓
Backend / Frontend
```

というContract First Flowを維持するため。

---

# 8. API Versioning

URL Versioningを採用する。

```text
/api/v1
```

例：

```text
GET /api/v1/employees
GET /api/v1/employees/{employee_id}
POST /api/v1/employee-skills
```

---

# 9. Laravel Prefix

Laravel側でAPI Prefixを二重化しない。

例えばFramework側ですでに`/api` Prefixを設定している場合、

```text
/api/api/v1
```

にならないよう注意する。

最終External URL：

```text
/api/v1/...
```

を基準とする。

---

# 10. Version追加

Breaking Changeが必要になった場合に、

```text
/api/v2
```

を検討する。

小さな変更ごとにVersionを増やさない。

---

# 11. Resource-oriented API

URLは可能な限りResourceを表現する。

推奨：

```text
POST /employees/{employee_id}/skills
```

またはResource Modelによって、

```text
POST /employee-skills
```

等を利用する。

避ける：

```text
POST /addEmployeeSkill
POST /updateEmployeeSkillLevel
```

ただしBusiness OperationがCRUDとして不自然な場合は、無理にCRUD形式へ押し込まない。

---

# 12. HTTP Method

基本：

| Operation | Method |
|---|---|
| 一覧取得 | GET |
| 詳細取得 | GET |
| 作成 | POST |
| 全体更新 | PUT |
| 部分更新 | PATCH |
| 削除 | DELETE |

---

# 13. PUT / PATCH

意味を区別する。

```text
PUT
    → Resource全体の置換に近い更新

PATCH
    → Resourceの部分更新
```

本Projectでは部分更新が多い場合、PATCHを優先してよい。

---

# 14. Laravel Routing

Laravel標準Routingを採用する。

External API RoutingはPresentation Layerに配置する。

例：

```text
routes/api.php
```

またはProject Structureに応じた分割を許容する。

---

# 15. Controller

Single Action Controllerを採用する。

例：

```php
final class RegisterEmployeeSkillController
{
    public function __invoke(
        RegisterEmployeeSkillRequest $request,
        RegisterEmployeeSkillHandler $handler,
    ): JsonResponse {
        // ...
    }
}
```

Controllerは薄く保つ。

---

# 16. Controller責務

Controllerが担当するもの：

```text
HTTP Request受取
Authentication / Authorization接続
Form Request利用
Command / Query生成
Handler呼出
Resource / Response返却
```

---

# 17. Controllerへ置かないもの

以下をControllerへ置かない。

```text
Business Rule
複雑なValidation
Database Query
Transaction
Eloquent Persistence
複雑なMapping
```

---

# 18. Request Validation

HTTP Request ValidationにはLaravel Form Requestを採用する。

```text
HTTP
    ↓
Form Request
    ↓
validated data
    ↓
Command / Query
```

---

# 19. RequestからApplication

Form Request自体をApplication Layerへ渡さない。

禁止：

```php
$handler->handle($request);
```

推奨：

```text
Form Request
    ↓
Primitive / Enum / Value Object
    ↓
Command / Query
    ↓
Handler
```

---

# 20. Request Input Mapping

Inputを明示的にApplication型へ変換する。

例：

```text
HTTP
{
  "skill_id": "12",
  "skill_level": 3
}

↓ Presentation

SkillId(12)
SkillLevel::LEVEL_3

↓ Command

RegisterEmployeeSkillCommand
```

HTTP InputとDomain / Application Modelを直接結合しない。

---

# 21. Entity IDのAPI表現

Entity IDはHTTP API上ではstringとして扱う。

```text
PostgreSQL
    ↓
bigint

PHP
    ↓
positive int
    ↓
Typed ID Value Object

API
    ↓
positive decimal digit string

TypeScript
    ↓
string
```

---

# 22. ID Response

Response Example：

```json
{
  "id": "123"
}
```

以下は採用しない。

```json
{
  "id": 123
}
```

理由：

```text
PostgreSQL bigint
    ↓
JavaScript Number Safe Integerを超える可能性
```

を考慮するため。

---

# 23. ID Request

Path Parameter / Request Bodyでも同じContractを利用する。

例：

```text
GET /api/v1/employees/123
```

OpenAPI上では`employee_id`をstringとして定義する。

Request Body：

```json
{
  "employee_id": "123",
  "skill_id": "45"
}
```

---

# 24. OpenAPI ID Schema

Semantic IDごとにSchemaを定義する。

例：

```yaml
EmployeeId:
  type: string
  pattern: '^[1-9][0-9]*$'
  example: '123'

SkillId:
  type: string
  pattern: '^[1-9][0-9]*$'
  example: '45'
```

Primitive表現が同じでも、

```text
EmployeeId
SkillId
DepartmentId
UserId
```

等をSemantic Schemaとして分ける。

---

# 25. ID変換

Presentation Layerで、

```text
"123"
    ↓
Positive Decimal Digit Validation
    ↓
PHP int Range Check
    ↓
123
    ↓
EmployeeId
```

へ変換する。

Application / DomainへHTTP string IDをそのまま渡さない。

---

# 26. Response Serialization

Response SerializationにはLaravel JsonResourceを採用する。

```text
Application Result
or
Read Model
    ↓
JsonResource
    ↓
JSON
```

---

# 27. Eloquent Direct Response禁止

禁止：

```php
return EmployeeModel::find($id);
```

または、

```php
return $employeeModel;
```

---

# 28. Domain Object Direct Response禁止

Domain Entity / Aggregateを直接JSON Responseとして返さない。

```text
Domain
    ≠
API Representation
```

を維持する。

---

# 29. JsonResource責務

JsonResourceは以下を担当する。

```text
API Field Name
ID Serialization
Enum Serialization
Date / Time Serialization
Nullable Field
Nested Resource
Collection Representation
```

---

# 30. JsonResourceへ置かないもの

以下をResourceへ置かない。

```text
Business Rule
Database Query
Transaction
State Mutation
複雑なAuthorization
```

---

# 31. JSON Naming

API JSON Field Nameは、

```text
snake_case
```

を採用する。

例：

```json
{
  "employee_id": "123",
  "skill_level": 3,
  "last_used_year_month": "2026-09"
}
```

---

# 32. Enum

EnumはPHP Case NameではなくBacked ValueをAPIへ返す。

例：

```php
enum SkillLevel: int
{
    case LEVEL_1 = 1;
    case LEVEL_2 = 2;
}
```

API：

```json
{
  "skill_level": 1
}
```

---

# 33. Date / Time

Instantはtimezone-aware RFC 3339で返す。

推奨：

```text
2026-09-13T07:00:00Z
```

内部基準はUTCとする。

---

# 34. Date-only

Dateのみを表す場合：

```text
YYYY-MM-DD
```

を利用する。

---

# 35. YearMonth

最終利用年月等は、

```text
YYYY-MM
```

とする。

例：

```json
{
  "last_used_year_month": "2026-09"
}
```

---

# 36. HTTP Status

基本Statusを以下とする。

| Situation | Status |
|---|---:|
| GET成功 | 200 |
| POST作成成功 | 201 |
| PUT / PATCH成功 | 200 |
| Response Body不要な更新 | 204 |
| DELETE成功 | 204 |
| Authentication Failure | 401 |
| Authorization Failure | 403 |
| Resource Not Found | 404 |
| Method Not Allowed | 405 |
| State Conflict | 409 |
| Validation Failure | 422 |
| Rate Limit Exceeded | 429 |
| Unexpected Server Error | 500 |
| Upstream Failure | 502 |
| Service Unavailable | 503 |

---

# 37. POST

Resource作成時：

```text
201 Created
```

を基本とする。

必要な場合は作成ResourceをResponse Bodyとして返す。

---

# 38. DELETE

Delete成功時は、

```text
204 No Content
```

を基本とする。

---

# 39. 409 Conflict

Request自体は構造的に正しいが、現在StateとのConflictによって実行できない場合：

```text
409 Conflict
```

を使用する。

例：

```text
EmployeeSkill duplicate
Inactive Skillへの登録
Current StateではOperation不可
```

ただし具体的なMappingはException設計に従う。

---

# 40. 422

422は主にHTTP Input Validation Failureへ利用する。

```text
Malformed Business State
```

をすべて422へMappingしない。

Domain / Application Errorは意味に応じて404 / 409等へMappingする。

---

# 41. 429

Rate Limit超過：

```text
429 Too Many Requests
```

を返す。

可能な場合：

```text
Retry-After
```

Headerを付与する。

Error BodyはRFC 9457 Problem Detailsとする。

---

# 42. Error Response

Error ResponseはRFC 9457 Problem Detailsを採用する。

独自の、

```json
{
  "error": {
    "code": "...",
    "message": "...",
    "details": {}
  }
}
```

形式は採用しない。

---

# 43. Problem Details

Content-Type：

```text
application/problem+json
```

Standard Member：

```text
type
title
status
detail
instance
```

Project Extension：

```text
code
errors
```

---

# 44. Error Code

Machine-readableなProject独自Error Codeを必須とする。

形式：

```text
UPPER_SNAKE_CASE
```

例：

```text
EMPLOYEE_NOT_FOUND
EMPLOYEE_SKILL_ALREADY_EXISTS
SKILL_INACTIVE
VALIDATION_ERROR
RATE_LIMIT_EXCEEDED
```

---

# 45. Error Example

例：

```json
{
  "type": "https://example.com/problems/employee-not-found",
  "title": "Employee Not Found",
  "status": 404,
  "detail": "The requested employee was not found.",
  "instance": "/api/v1/employees/123",
  "code": "EMPLOYEE_NOT_FOUND"
}
```

`type` URIの正式HostはAPI Domain確定時に決定する。

---

# 46. Validation Error

Validation FailureでもRFC 9457を利用する。

例：

```json
{
  "type": "https://example.com/problems/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "The request contains invalid fields.",
  "instance": "/api/v1/employee-skills",
  "code": "VALIDATION_ERROR",
  "errors": {
    "skill_level": [
      "The selected skill level is invalid."
    ],
    "last_used_year_month": [
      "The last used year month is required."
    ]
  }
}
```

---

# 47. `errors`

`errors`はValidation Error等でField単位の詳細を返すExtensionとして利用する。

旧`details`形式は使用しない。

---

# 48. Machine-readable Contract

Frontend / BFFはHuman-readable Messageで分岐しない。

```text
HTTP Status
+
code
```

を利用する。

`title` / `detail`はHuman-readable Textとする。

---

# 49. Internal Information

Error Responseへ以下を出さない。

```text
Stack Trace
SQL
Table Name
Filesystem Path
Internal Host
Environment Variable
Secret
Raw Internal Exception
```

---

# 50. Laravel Exception Handling

Error MappingはLaravel Central Exception Handlingへ集約する。

Controllerごとに、

```php
try {
    // ...
} catch (...) {
    // ...
}
```

を大量に書かない。

---

# 51. Rendering / Reporting

```text
Rendering
    → Clientへ何を返すか

Reporting
    → Log / Monitoringへ何を送るか
```

を分離する。

Expected 4xxをすべてSystem ErrorとしてReportしない。

---

# 52. Pagination

MVPではOffset Paginationを採用する。

例：

```text
GET /api/v1/employees?page=2&per_page=20
```

---

# 53. Page Size

Default値とMaximum値を設定する。

Clientが無制限に、

```text
per_page=99999999
```

を指定できないようにする。

具体値はEndpoint特性・Non-functional Requirementに応じて決定する。

---

# 54. Pagination Response

Pagination MetadataをAPI Contractとして明示する。

概念例：

```json
{
  "data": [],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 100,
    "last_page": 5
  }
}
```

Laravel Paginatorの内部構造を無条件にExternal Contractとしない。

---

# 55. Cursor Pagination

MVPではDefaultに採用しない。

大量Data / Deep PaginationがPerformance Problemになった場合に再検討する。

---

# 56. Filtering

FilteringはQuery Parameterで表現する。

例：

```text
GET /api/v1/employees?department_id=12
```

---

# 57. Search

Search：

```text
GET /api/v1/employees?keyword=php
```

等を利用する。

---

# 58. Sorting

例：

```text
GET /api/v1/employees?sort=name
GET /api/v1/employees?sort=-created_at
```

実際のFormatは各EndpointのOpenAPI Contractで定義する。

---

# 59. Sort Allowlist

Client InputをSQL Columnとして直接利用しない。

```text
API sort key
    ↓
Allowlist
    ↓
Database column
```

とする。

---

# 60. Filter Flow

```text
HTTP Query Parameter
    ↓
Form Request
    ↓
Query DTO
    ↓
Query Handler / Query Service
```

とする。

---

# 61. Query Builder Package

`spatie/laravel-query-builder`は採用しない。

理由：

- MVP Query要件はLaravel標準で十分
- External API ContractをPackage Conventionへ寄せすぎない
- Query Serviceを明示的に設計する
- AllowlistをProject Codeで管理可能

---

# 62. Read Side

ReadではAggregate復元を必須としない。

```text
Query
    ↓
Query Handler / Query Service
    ↓
Query Builder
    ↓
Read Model
    ↓
JsonResource
```

を許容する。

---

# 63. Write Side

Write：

```text
HTTP
    ↓
Form Request
    ↓
Command
    ↓
Handler
    ↓
Domain
    ↓
Repository
```

を基本とする。

---

# 64. HTTP LayerとDomain

Domain Layerへ以下を持ち込まない。

```text
Request
Response
JsonResponse
HTTP Status
Header
Cookie
Route
```

---

# 65. API Authentication

Backend API AuthenticationはLaravel Sanctum Bearer Tokenを利用する。

OpenAPIではHTTP Bearer Schemeとして表現する。

例：

```yaml
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
```

Sanctum内部Token FormatはExternal Contractにしない。

---

# 66. Browser Access

基本Architecture：

```text
Browser
    ↓
Next.js BFF
    ↓
Laravel API
```

BrowserからLaravel APIを直接利用することをFrontend Contractにしない。

---

# 67. CORS

Laravel APIのCORSは必要最小限に設定する。

ProductionでWildcardをDefaultにしない。

ただしBFF → LaravelはServer-to-server通信であり、Browser CORSそのものはSecurity Boundaryではない。

---

# 68. Rate Limit

Laravel Rate Limitingを利用する。

API特性に応じて、

```text
General Read
Mutation
Sensitive Mutation
Expensive Search
```

等を分ける。

一律の固定値だけで全Endpointを管理しない。

---

# 69. Cache Control

Sensitive ResponseやUser-specific Responseに必要なCache Headerを明示する。

Browser / Proxyへ意図せずSensitive DataをCacheさせない。

具体設定はEndpoint / Infrastructure特性に応じて決定する。

---

# 70. Request ID

HTTP RequestにはRequest IDを付与する。

Response Header：

```text
X-Request-ID
```

を採用する。

Log / Audit / ObservabilityとのCorrelationに利用する。

---

# 71. Trace Context

Distributed TracingではW3C Trace Contextを利用する。

```text
traceparent
tracestate
```

を標準とする。

独自Trace Headerを作らない。

Request IDとTrace IDは別Conceptとして扱う。

---

# 72. Content-Type

通常JSON：

```text
application/json
```

Problem Details：

```text
application/problem+json
```

を利用する。

---

# 73. OpenAPI Common Schema

Common Schema候補：

```text
EmployeeId
SkillId
DepartmentId
UserId
YearMonth
ProblemDetails
ValidationProblemDetails
PaginationMeta
```

---

# 74. ProblemDetails Schema

概念：

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
      format: uri-reference
    title:
      type: string
    status:
      type: integer
    detail:
      type: string
    instance:
      type: string
      format: uri-reference
    code:
      type: string
```

---

# 75. ValidationProblemDetails Schema

概念：

```yaml
ValidationProblemDetails:
  allOf:
    - $ref: '#/components/schemas/ProblemDetails'
    - type: object
      required:
        - errors
      properties:
        errors:
          type: object
          additionalProperties:
            type: array
            items:
              type: string
```

---

# 76. DateTime Schema

Instant：

```yaml
type: string
format: date-time
```

---

# 77. Date Schema

Date-only：

```yaml
type: string
format: date
```

---

# 78. YearMonth Schema

```yaml
type: string
pattern: '^[0-9]{4}-(0[1-9]|1[0-2])$'
example: '2026-09'
```

---

# 79. Contract Test

OpenAPI Contract Testを採用する。

採用Library：

```text
kirschbaum-development/laravel-openapi-validator
```

Development Dependencyとして利用する。

---

# 80. Contract Test目的

```text
OpenAPI
    ≠
Laravel Implementation
```

のDriftを検出する。

---

# 81. Contract Test対象

以下を確認する。

```text
Request
Response
HTTP Status
Content-Type
Required Field
Enum
ID string
date-time
date
YearMonth
Problem Details
Validation errors
```

---

# 82. Runtime Validation

OpenAPI ValidatorをProductionの全Requestに対して毎回実行する方式は採用しない。

主用途：

```text
Feature / Contract Test
CI
```

とする。

---

# 83. API Change Flow

API変更時：

```text
Requirement
    ↓
OpenAPI変更
    ↓
Review
    ↓
Backend実装
    ↓
Frontend / BFF実装
    ↓
Contract Test
    ↓
CI
```

を基本とする。

---

# 84. OpenAPI Breaking Change

Breaking Change Detection ToolはMVP開始時点では必須としない。

API運用が安定した段階で導入候補とする。

---

# 85. API Inventory

OpenAPIをAPI Contractと同時にAPI Inventoryとして利用する。

ProductionにOpenAPI外の不要なEndpointを残さない。

避ける：

```text
Debug Route
Temporary Route
Forgotten Legacy Route
```

---

# 86. Security Boundary

API Securityでは、

```text
Authentication
    ≠
Authorization
```

を徹底する。

各Resource OperationでLaravel PolicyによるObject / Function Level Authorizationを行う。

---

# 87. Input Security

以下を禁止する。

```text
$request->all()
    ↓
Eloquent Model
```

Inputは明示的にCommand / QueryへMappingする。

---

# 88. Output Security

以下を禁止する。

```text
Eloquent Model
    ↓
Direct JSON
```

Output FieldはJsonResourceで明示する。

---

# 89. SQL Security

Filtering / Search / Sortでは、

```text
Parameter Binding
+
Allowlist
```

を利用する。

Client InputをRaw SQLへ直接結合しない。

---

# 90. OpenAPI Example

Employee ResponseのConcept Example：

```json
{
  "id": "123",
  "name": "Example Employee",
  "employment_status": "active",
  "created_at": "2026-09-13T07:00:00Z",
  "updated_at": "2026-09-13T07:00:00Z"
}
```

---

# 91. Error Example

```json
{
  "type": "https://example.com/problems/employee-skill-already-exists",
  "title": "Employee Skill Already Exists",
  "status": 409,
  "detail": "The employee already has the specified skill.",
  "instance": "/api/v1/employee-skills",
  "code": "EMPLOYEE_SKILL_ALREADY_EXISTS"
}
```

---

# 92. Validation Example

Request：

```json
{
  "employee_id": "123",
  "skill_id": "45",
  "work_experience": "experienced",
  "skill_level": 3,
  "experience_months": 0
}
```

Response：

```json
{
  "type": "https://example.com/problems/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "The request contains invalid fields.",
  "instance": "/api/v1/employee-skills",
  "code": "VALIDATION_ERROR",
  "errors": {
    "experience_months": [
      "The experience months must be at least 1."
    ]
  }
}
```

---

# 93. Directory

Presentation HTTP関連：

```text
Presentation/
└── Http/
    ├── Controllers/
    ├── Requests/
    └── Resources/
```

HTTP-specific CodeをApplication / Domainへ混在させない。

---

# 94. Package選定

HTTP / APIのために以下のPackageを追加しない。

```text
Generic API Framework
JSON:API Framework
Query Builder Framework
Serializer Framework
OpenAPI Code-first Framework
```

Laravel標準 + OpenAPI Firstを基本とする。

---

# 95. 採用一覧

| 項目 | 決定 |
|---|---|
| API Style | REST |
| API Contract | OpenAPI First |
| OpenAPI Version | 3.1.x |
| Format | YAML |
| Routing | Laravel Routing |
| Versioning | `/api/v1` |
| Controller | Single Action Controller |
| HTTP Validation | Laravel Form Request |
| Request → Application | Command / Queryへ明示Mapping |
| Response | JsonResource |
| Eloquent Direct Response | 不採用 |
| Domain Direct Response | 不採用 |
| JSON Naming | snake_case |
| API Entity ID | string |
| DB Entity ID | bigint |
| PHP Entity ID | positive int + Typed ID |
| Enum | Backed Value |
| Instant | RFC3339 timezone-aware |
| Internal Timezone | UTC |
| YearMonth | `YYYY-MM` |
| Error Format | RFC 9457 Problem Details |
| Error Content-Type | `application/problem+json` |
| Machine Error Code | `code` |
| Validation Extension | `errors` |
| Pagination | Offset Pagination |
| Pagination Maximum | 採用 |
| Filtering | Query Parameter |
| Sort | Allowlist |
| Search | Query Parameter |
| `spatie/laravel-query-builder` | 不採用 |
| JSON:API | 不採用 |
| swagger-php | 不採用 |
| L5-Swagger | 不採用 |
| Code-first OpenAPI | 不採用 |
| Contract Test | 採用 |
| OpenAPI Validator | `kirschbaum-development/laravel-openapi-validator` |
| Production Runtime OpenAPI Validation | 不採用 |
| Rate Limiting | Laravel標準を採用 |
| 429 | 採用 |
| Retry-After | 可能な範囲で採用 |
| Request ID | 採用 |
| W3C Trace Context | 採用 |

---

# 96. API Architecture

最終的なWrite Request Flow：

```text
HTTP Request
    ↓
Routing
    ↓
Authentication
    ↓
Rate Limiting
    ↓
Form Request
    ↓
Policy Authorization
    ↓
Command
    ↓
Handler
    ↓
Domain
    ↓
Repository
```

---

# 97. Read Flow

```text
HTTP Request
    ↓
Routing
    ↓
Authentication
    ↓
Policy Authorization
    ↓
Query
    ↓
Query Handler / Query Service
    ↓
Read Model
    ↓
JsonResource
    ↓
JSON
```

---

# 98. Error Flow

```text
Domain / Application / Infrastructure Exception
    ↓
Laravel Central Exception Handling
    ↓
Problem Details Mapping
    ↓
application/problem+json
```

---

# 99. Contract Flow

```text
OpenAPI
    ↓
Laravel Implementation
    ↓
Feature Test
    ↓
OpenAPI Contract Test
    ↓
CI
```

---

# 100. 最終原則

Backend HTTP APIでは、

> HTTP ContractとApplication / Domain Modelを明確に分離する

ことを基本とする。

```text
HTTP Input
    ≠
Application Model

Application / Domain Model
    ≠
HTTP Output
```

とする。

さらに、

```text
OpenAPI
    = External Contract
```

とし、Laravel実装をそのContractへ従わせる。

最終構成：

```text
OpenAPI First
+
REST
+
Laravel Routing
+
Form Request
+
Single Action Controller
+
Command / Query
+
JsonResource
+
RFC 9457 Problem Details
+
String Entity IDs
+
Contract Test
```

をEngineer Skill Management App Backend APIの標準構成とする。
