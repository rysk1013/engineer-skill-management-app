# API品質

## 1. 目的

本ドキュメントでは、Engineer Skill Management App におけるAPI品質に関する非機能要件を定義する。

APIの一貫性、契約、Validation、Error Handling、Versioning、互換性および保守性を確保し、Frontend / BFFとBackend間で安定した連携を維持することを目的とする。

---

## 2. 基本方針

以下を基本方針とする。

- OpenAPI Firstを採用する。
- OpenAPIをAPI ContractのSingle Source of Truthとする。
- API実装前にAPI仕様を定義・Reviewする。
- RESTfulなHTTP APIを基本とする。
- JSONを標準Data Formatとする。
- API全体で命名、Status Code、Error形式を統一する。
- HTTP BoundaryでRequest Validationを行う。
- AuthorizationはBackendで必ず実施する。
- Breaking Changeを意識してAPIを変更する。
- API仕様と実装の乖離を最小化する。
- OpenAPIのLint / ValidationをCIで実施する。

---

## 3. API構成

基本的な通信経路は以下とする。

```text
Browser
   │
   ▼
Next.js
Frontend / BFF
   │
   │ HTTPS + Sanctum Token
   ▼
Laravel API
```

BrowserからLaravel APIを直接利用することは原則禁止する。

Laravel APIはNext.js BFFから利用される内部APIとして設計する。

---

## 4. OpenAPI First

API開発では以下の流れを基本とする。

```text
Requirement
    ↓
API Design
    ↓
OpenAPI変更
    ↓
Review
    ↓
Implementation
    ↓
Test
```

Laravel実装後にOpenAPIを生成する方式を基本とせず、OpenAPIを先に定義する。

API変更時もImplementationより先にOpenAPIを更新することを基本とする。

---

## 5. OpenAPI管理

OpenAPIには最低限以下を定義する。

- Path
- HTTP Method
- Request Parameter
- Request Body
- Response
- HTTP Status Code
- Validation
- Authentication
- Schema
- Error Response

OpenAPIファイルはGit Repositoryで管理する。

CIでLint / Validationを実施し、不正なOpenAPI定義が存在する場合はMergeを禁止する。

---

## 6. API Versioning

API VersioningにはURL Path Versioningを採用する。

MVPでは以下を基本Pathとする。

```text
/api/v1
```

例:

```text
/api/v1/employees
/api/v1/skills
/api/v1/departments
```

API VersionはLaravel APIの公開Contractを表す。

---

## 7. URL設計

Resource中心のURLを基本とする。

例:

```text
GET    /api/v1/employees
GET    /api/v1/employees/{employeeId}
POST   /api/v1/employees
PATCH  /api/v1/employees/{employeeId}
DELETE /api/v1/employees/{employeeId}
```

以下のようなAction名中心のURLは原則避ける。

```text
/getEmployees
/updateEmployee
/deleteEmployee
```

ただしResource CRUDとして自然に表現できないDomain Actionについては例外を許可する。

---

## 8. HTTP Method

HTTP Methodは以下の用途を基本とする。

| Method | 用途 |
|---|---|
| GET | Resource取得 |
| POST | Resource作成 / Command |
| PUT | Resource全体更新 |
| PATCH | Resource部分更新 |
| DELETE | Resource削除 |

GET RequestでServer-side Stateを変更することを禁止する。

PUT / PATCHは対象Resourceの更新方式に応じて明確に使い分ける。

---

## 9. HTTP Status Code

API全体でHTTP Status Codeの利用方針を統一する。

主に以下を使用する。

### Success

```text
200 OK
201 Created
204 No Content
```

### Client Error

```text
400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
422 Unprocessable Entity
429 Too Many Requests
```

### Server Error

```text
500 Internal Server Error
503 Service Unavailable
```

### 401 / 403

以下を明確に区別する。

```text
401 Unauthorized
→ Authenticationされていない
  またはAuthentication情報が無効

403 Forbidden
→ Authentication済みだが
  対象操作を実行する権限がない
```

---

## 10. Error Response

API全体で統一されたError Response形式を使用する。

基本形式:

```json
{
  "error": {
    "code": "EMPLOYEE_NOT_FOUND",
    "message": "Employee was not found.",
    "request_id": "..."
  }
}
```

Validation Errorでは必要に応じて詳細を含める。

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request is invalid.",
    "details": {
      "skill_id": [
        "The selected skill is invalid."
      ]
    },
    "request_id": "..."
  }
}
```

APIごとに独自のError形式を定義しない。

---

## 11. Application Error Code

HTTP Status Codeとは別にApplication Error Codeを定義する。

例:

```text
VALIDATION_ERROR
UNAUTHENTICATED
FORBIDDEN
EMPLOYEE_NOT_FOUND
SKILL_NOT_FOUND
EMPLOYEE_SKILL_ALREADY_EXISTS
PERMISSION_MANAGER_REQUIRED
```

Application Error CodeはMachine-readableな安定した識別子として利用する。

BFFがLaravelのException Class名や内部Exception Messageに依存しないようにする。

---

## 12. Error Message

Productionでは内部実装情報をResponseへ公開しない。

以下をResponseへ含めない。

- Stack Trace
- SQL
- Database情報
- Exception Class
- Server内部Path
- Environment Variable
- Secret
- Token
- Credential

利用者向けError Messageと調査用内部Logを分離する。

---

## 13. Request ID

API RequestにはRequest IDを使用する。

```text
Next.js BFF
     │
     │ Request ID
     ▼
Laravel API
```

Next.js BFFからLaravel APIへRequest IDを引き継ぐ。

Error ResponseにはRequest IDを含める。

これによりClient側で発生したErrorとServer-side Logを関連付けられるようにする。

---

## 14. Request Validation

HTTP BoundaryではRequest Validationを必ず実施する。

主な対象:

- Type
- Required / Optional
- String Length
- Numeric Range
- Enum
- Date
- Format
- Array
- Array Size
- Pagination
- Resource ID

LaravelではForm Request等を利用する。

ただしHTTP ValidationのみでDomain Ruleを保証しない。

以下の多層防御を基本とする。

```text
HTTP Validation
      │
      ▼
Domain Invariant
      │
      ▼
Database Constraint
```

---

## 15. Response形式

API ResponseはJSONを基本とする。

### 単一Resource

```json
{
  "data": {
    "id": "1"
  }
}
```

### Collection

```json
{
  "data": []
}
```

### Pagination付きCollection

```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "last_page": 5
  }
}
```

API全体でResponse Envelopeを統一する。

---

## 16. Pagination

一覧APIでは原則としてPaginationを必須とする。

MVPでは以下を採用する。

- Offset Pagination
- 1ページ20〜50件程度
- APIごとに適切なDefault件数を設定
- API側で最大件数を制限

Clientから無制限な件数を要求できる設計を禁止する。

大量データにより性能問題が発生した場合はCursor Paginationを検討する。

---

## 17. Filtering

FilteringはQuery Parameterを利用する。

例:

```text
GET /api/v1/employees?department_id=10

GET /api/v1/employees?keyword=php
```

同種のFilterについてAPIごとに異なる命名を乱用せず、一貫した命名規則を使用する。

---

## 18. Sorting

SortingについてもQuery Parameterを使用する。

例:

```text
GET /api/v1/employees?sort=created_at&order=desc
```

Sort対象FieldはServer-side Allowlistで制限する。

Clientから指定された任意の文字列をDatabase Column名として直接利用してはならない。

---

## 19. ID

Database Primary Keyには `bigint` を使用する。

API Contract上のIDは **string** として扱う。

```text
Database
   ↓
bigint

OpenAPI / JSON
   ↓
string
```

JSON例:

```json
{
  "id": "123"
}
```

JavaScriptの安全整数範囲への依存を避け、将来的なID増加による精度問題を防止する。

OpenAPI SchemaではIDをstringとして明示する。

---

## 20. 日時

API上の日時はISO 8601形式を使用する。

例:

```text
2026-09-01T11:30:00Z
```

基本方針:

```text
Database / API
      ↓
UTC

Frontend表示
      ↓
Asia/Tokyo
```

Timezoneを含まない曖昧な日時形式を避ける。

---

## 21. 年月型

最終利用年月等、年月だけを表すDomain Valueについては通常の日時とは区別する。

OpenAPI上で専用Schemaまたは明確なFormatを定義する。

例えば以下のような形式を利用できる。

```text
YYYY-MM
```

例:

```text
2026-09
```

具体的なSchemaはDate / Time設計に従う。

---

## 22. Required / Optional / Nullable

以下を明確に区別する。

```text
Required
Optional
Nullable
```

OpenAPI Schemaでそれぞれを明示する。

`null` と「Fieldが存在しない状態」をAPIごとに無秩序に混在させない。

---

## 23. Authentication

Laravel APIの保護対象EndpointにはAuthenticationを必須とする。

Next.js BFF → Laravel APIではSanctum Tokenを使用する。

認証情報はBrowserへ公開しない。

Authentication方式の詳細は `セキュリティ.md` に従う。

---

## 24. Authorization

ResourceへのAccess可否はLaravel Backendで必ず確認する。

Roleだけではなく、必要に応じてResource Scopeも確認する。

特に以下を重点的に確認する。

- Administrator Permission
- Sub Manager担当Employee
- Team Leader担当Employee
- Employee
- EmployeeSkill

Frontendの表示制御だけをAuthorizationとして扱わない。

---

## 25. Backward Compatibility

同一Major Version内では可能な限り後方互換性を維持する。

### 比較的安全な変更

例:

```text
Optional Field追加

新Endpoint追加

新しいOptional Query Parameter追加
```

### Breaking Change

例:

```text
Field削除

Field名変更

Field Type変更

Fieldの意味変更

Required Field追加

既存Endpoint削除

既存Status Codeの意味変更
```

Breaking Changeを実施する場合はAPI Version変更を検討する。

---

## 26. API Version変更

重大なBreaking Changeが必要な場合は新しいMajor Versionを導入できる。

例:

```text
/api/v1/employees

/api/v2/employees
```

MVPでは複数Major Versionを同時運用することを必須とはしない。

---

## 27. Deprecated API

既存APIを廃止する場合、可能な限り以下の順序を採用する。

```text
Deprecated
     ↓
移行期間
     ↓
Removal
```

利用側へ移行可能な期間を設けず、既存Endpointを突然削除することを避ける。

詳細なDeprecation Policyは必要性が発生した段階で定義する。

---

## 28. API Test

Feature / API Testでは最低限以下を確認する。

- Success
- Validation Error
- Authentication Error
- Authorization Error
- Not Found
- Conflict
- Domain Rule違反
- HTTP Status Code
- Error Response形式

AuthorizationおよびIDOR対策については重点的にTestする。

---

## 29. OpenAPI Validation

CIではOpenAPIのLint / Validationを必須とする。

以下を検出できる状態を維持する。

- Syntax Error
- Invalid Reference
- Schema不整合
- 不正なOpenAPI定義
- Project Rule違反

OpenAPI Validation失敗時は原則Mergeを禁止する。

---

## 30. Contract Test

OpenAPIと実際のAPI Response / Requestの整合性を自動確認するContract TestはMVPでは必須としない。

将来的に以下を検討する。

- OpenAPI Contract Test
- Schema Validation
- Consumer-driven Contract Test

API数やTeam規模が増えた場合に導入価値を再評価する。

---

## 31. API Documentation

OpenAPIから閲覧可能なAPI Documentationを生成可能な状態とする。

利用可能なTool例:

- Swagger UI
- Scalar
- その他OpenAPI対応Viewer

具体的なToolは実装・開発環境構築時に決定する。

Production環境でAPI Documentationを外部公開することは必須としない。

内部向けであっても公開範囲は適切に制御する。

---

## 32. Rate Limiting

APIには必要なRate Limitingを設定する。

主な対象:

- Authentication関連Endpoint
- API全般
- 高負荷な検索Endpoint
- 集計Endpoint

具体的なRequest数・WindowはInfrastructureおよび利用状況に応じて決定する。

Rate Limit超過時は原則として以下を返す。

```text
429 Too Many Requests
```

---

## 33. Timeout

BFF → Laravel API通信には明示的なTimeoutを設定する。

無制限にResponseを待機しない。

Timeout発生時には統一されたError Handlingを行い、必要に応じてApplication Error Codeを返す。

具体的なTimeout値は実装・Infrastructure設計時に定義する。

---

## 34. API変更Review

OpenAPI変更を含むPull Requestでは最低限以下をReviewする。

- Requirementとの整合性
- Naming
- Resource設計
- HTTP Method
- HTTP Status Code
- Request / Response Schema
- Error Response
- Authentication / Authorization
- Breaking Change有無
- Pagination / Filtering / Sorting
- Security
- Performance

Breaking Changeが含まれる場合は明示する。

---

## 35. MVP決定事項

| 項目 | 決定 |
|---|---|
| API Design | OpenAPI First |
| API Contract | OpenAPI |
| Data Format | JSON |
| Browser → Laravel | 原則禁止 |
| BFF → Laravel | 内部API |
| API Versioning | URL Path Versioning |
| MVP Version | `/api/v1` |
| REST Resource設計 | 基本採用 |
| GETで状態変更 | 禁止 |
| HTTP Status統一 | 必須 |
| 401 / 403区別 | 必須 |
| Error Response形式 | 統一 |
| Application Error Code | 採用 |
| Error Response Request ID | 必須 |
| HTTP Validation | 必須 |
| Domain Invariant | 必須 |
| DB Constraint | 必須 |
| Pagination | 原則必須 |
| Pagination方式 | Offset |
| 1ページ | 20〜50件程度 |
| 最大件数 | API側で制限 |
| Filtering命名 | 統一 |
| Sorting | Allowlist方式 |
| Response Envelope | 統一 |
| 日時 | ISO 8601 / UTC |
| 表示Timezone | Asia/Tokyo |
| API上のID | string |
| Database PK | bigint |
| Required / Optional / Nullable | OpenAPIで明示 |
| 同一Major Version | 可能な限り後方互換 |
| Breaking Change | Version変更を検討 |
| OpenAPI Git管理 | 必須 |
| OpenAPI Lint / Validation | CI必須 |
| API Feature Test | 必須 |
| Contract Test | 将来検討 |
| Production API Docs公開 | 必須ではない |

---

## 36. 将来検討

システム規模、API数、Team規模に応じて以下を検討する。

- OpenAPI Contract Test
- Consumer-driven Contract Testing
- API Schema自動Validation
- API Client自動生成
- API Mock Server
- API Changelog
- Formal Deprecation Policy
- Sunset Policy
- API Gateway
- Advanced Rate Limiting
- Cursor Pagination
- Idempotency Key
- API Metrics専用Dashboard
- API SLO / SLI
- External API公開
