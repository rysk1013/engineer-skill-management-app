# API共通仕様

Engineer Skill Management App のLaravel Backend APIにおける、すべてのEndpointで共通して適用するAPI契約ルールを定義します。

個別ResourceのEndpoint、Request、Responseは各API設計およびOpenAPIで定義し、本書ではVersioning、Naming、Pagination、Error Response、Date／Time、Status Codeなどの横断的な共通仕様を管理します。

Backend API契約のSource of TruthはOpenAPIです。本書とOpenAPIに差異がある場合は、OpenAPIを確認したうえで差異を解消します。

## 1. 目的・適用範囲

本書の目的は、APIごとに異なる表現や実装判断が発生することを防ぎ、Next.js BFFとLaravel Backend API間で一貫した契約を維持することです。

対象は、Next.js BFFからLaravel Backend APIへアクセスするすべてのHTTP APIとします。

```text
Browser
   │
   ▼
Next.js Frontend / BFF
   │
   │ HTTP / JSON
   │ OpenAPI Contract
   ▼
Laravel Backend API
```

BrowserからLaravel Backend APIを直接呼び出すことは想定しません。

個別APIでは、本書で定義した共通仕様を原則として再定義しません。共通仕様と異なる扱いが必要な場合のみ、個別API設計およびOpenAPIへ理由と仕様を明記します。

## 2. Base URL・Versioning

MVPのBackend APIは、URL PathによるVersioningを採用します。

```text
/api/v1
```

例：

```http
GET /api/v1/employees
GET /api/v1/employees/123
POST /api/v1/skills
```

API VersionはResourceごとではなく、Backend API全体で統一します。

MVPでは`v1`のみを提供します。

Breaking Changeが必要になった場合は、既存Versionへの影響、Next.js BFFの移行、旧Versionの廃止方法を検討したうえで、新Versionの追加を判断します。

Versionを安易に増やさず、Backward Compatibleな変更は可能な限り既存Version内で行います。

## 3. HTTP Method

HTTP Methodは、操作の意味に応じて次のように使用します。

| Method | 用途 |
| --- | --- |
| `GET` | Resourceまたは一覧の取得 |
| `POST` | Resourceの作成、Domain Operationの実行 |
| `PATCH` | Resourceの部分更新 |
| `DELETE` | ResourceまたはRelationの削除 |

MVPでは、Resource全体を完全置換する用途がない限り`PUT`は原則使用せず、更新には`PATCH`を使用します。

CRUDだけでは業務上の意味が不明確になる場合は、Domain Operation Endpointを使用できます。

例：

```http
POST /api/v1/employees/{employeeId}/retire
POST /api/v1/skills/{skillId}/deactivate
```

Domain Operation Endpointを使用する場合は、単なるCRUDの別名ではなく、業務上独立した操作であることを条件とします。

## 4. Naming Rule

APIで使用するNaming Ruleは次のとおりです。

| 対象 | 形式 |
| --- | --- |
| JSON Property | `camelCase` |
| Path Parameter | `camelCase` |
| Query Parameter | `camelCase` |
| Resource Path | `kebab-case`または英単語の複数形 |
| Error Code | `UPPER_SNAKE_CASE` |
| Database Table／Column | `snake_case` |

例：

```json
{
  "employeeId": 123,
  "lastUsedYearMonth": "2026-09",
  "workExperience": "experienced"
}
```

Query Parameter：

```http
GET /api/v1/employees?departmentId=10&employmentStatus=active
```

Error Code：

```text
EMPLOYEE_NOT_FOUND
VALIDATION_ERROR
PERMISSION_DENIED
```

LaravelやDatabase内部で使用している`snake_case`を、そのままAPI Responseへ公開しません。

## 5. ID表現

Entity IDはJSON上では整数として表現します。

OpenAPIでは原則として次の型を使用します。

```yaml
type: integer
format: int64
```

例：

```json
{
  "id": 123
}
```

Path Parameterも同様に整数として扱います。

```http
GET /api/v1/employees/123
```

Databaseでは`bigint`を使用しますが、Database内部のSequenceや採番方式はAPI契約へ公開しません。

IDに業務上の意味を持たせません。

MVPではUUID、ULID、複合IDは採用しません。

## 6. Request共通ルール

Request BodyはJSONを基本とします。

```http
Content-Type: application/json
```

Request BodyのPropertyは`camelCase`を使用します。

例：

```json
{
  "skillId": 10,
  "skillLevel": 3,
  "workExperience": "experienced",
  "experienceMonths": 24,
  "lastUsedYearMonth": "2026-09"
}
```

更新APIでは、変更対象のみを送信できる部分更新方式を基本とします。

```http
PATCH /api/v1/employees/123
```

```json
{
  "name": "Taro Yamada"
}
```

Request Bodyに存在しないPropertyは、「変更しない」ことを意味します。

`null`を明示的に送信することと、Propertyを省略することは区別します。

Requestで未知のPropertyを受け入れるかどうかはOpenAPIとLaravel Validationで制御し、意図しないInputを業務データへ保存しません。

## 7. Response共通ルール

ResponseはJSONを基本とします。

```http
Content-Type: application/json
```

単一ResourceのSuccess Responseでは、不要な共通Envelopeを付与しません。

推奨：

```json
{
  "id": 10,
  "name": "Laravel",
  "isActive": true
}
```

次のような常時`data`で包む形式は採用しません。

```json
{
  "data": {
    "id": 10,
    "name": "Laravel"
  }
}
```

一覧Responseについては、PaginationなどのMetadataを含める必要があるため、専用のResponse構造を使用します。

ResponseへLaravelやDatabase内部の構造をそのまま公開しません。

次の情報は公開対象外です。

- Eloquent ModelのRelation構造
- Database Column名
- Internal Class名
- Stack Trace
- SQL
- Secret
- Access Token
- 内部Exception Message

## 8. Pagination

一覧APIで件数が増える可能性があるResourceには、Page-based Paginationを使用します。

Query Parameter：

```http
?page=1&perPage=20
```

| Parameter | 内容 |
| --- | --- |
| `page` | 取得するPage番号 |
| `perPage` | 1Pageあたりの件数 |

`page`は`1`から開始します。

Default値は次を基本とします。

```text
page = 1
perPage = 20
```

`perPage`には上限を設定します。

MVPでは次を基本値とします。

```text
max perPage = 100
```

Pagination Response：

```json
{
  "items": [
    {
      "id": 1,
      "name": "Laravel"
    },
    {
      "id": 2,
      "name": "React"
    }
  ],
  "pagination": {
    "page": 1,
    "perPage": 20,
    "total": 42,
    "totalPages": 3
  }
}
```

共通構造：

```text
items
pagination
  ├── page
  ├── perPage
  ├── total
  └── totalPages
```

Pagination不要な少量のMaster Dataなどについては、単純なArray Responseを使用できます。

その判断は個別API設計で明記します。

## 9. Filtering

FilteringにはQuery Parameterを使用します。

例：

```http
GET /api/v1/employees?departmentId=10&employmentStatus=active
```

原則として、1条件につき1Query Parameterを使用します。

Filtering Parameterは`camelCase`を使用します。

Filter条件は、OpenAPIで許可されたものだけを利用可能とします。

任意のDatabase Columnを指定できる汎用Filter機構は提供しません。

複数条件が指定された場合は、原則としてAND条件として扱います。

例：

```http
GET /api/v1/employees?departmentId=10&employmentStatus=active
```

```text
departmentId = 10
AND
employmentStatus = active
```

OR検索や複雑な検索条件が必要になった場合は、用途ごとに明示的なQuery ParameterまたはSearch Endpointを設計します。

## 10. Sorting

Sortingには`sort`Query Parameterを使用します。

Ascending：

```http
?sort=name
```

Descending：

```http
?sort=-createdAt
```

複数Sortが必要な場合は`,`区切りとします。

```http
?sort=-createdAt,name
```

意味：

```text
createdAt DESC
name ASC
```

Sort可能なFieldはOpenAPIで明示します。

任意のPropertyやDatabase ColumnをSort対象として指定できる仕様にはしません。

Sort未指定時のDefault Sortは、個別APIで明示します。

一意な順序を保証する必要がある場合は、IDなどを最終Sort Keyとして使用します。

## 11. Date・Time表現

TimestampはRFC 3339準拠のUTC表現を使用します。

例：

```text
2026-09-13T08:30:00Z
```

OpenAPIでは次を基本とします。

```yaml
type: string
format: date-time
```

Date：

```text
2026-09-13
```

OpenAPI：

```yaml
type: string
format: date
```

Year Month：

```text
2026-09
```

Year MonthはOpenAPI標準Formatが存在しないため、Patternで制約します。

```yaml
type: string
pattern: '^\d{4}-(0[1-9]|1[0-2])$'
```

APIではTimezone付きのLocal Timeを原則として返さず、TimestampはUTCへ統一します。

画面表示時のTimezone変換はNext.js Frontend側で行います。

## 12. Nullable・Optional

`nullable`と`optional`は異なる意味として扱います。

### Optional

Property自体が存在しない状態です。

PATCH Requestでは、Property省略を「変更しない」という意味で使用します。

例：

```json
{
  "name": "Taro Yamada"
}
```

このRequestでは、`departmentId`など他のFieldは変更しません。

### Nullable

Propertyは存在するが、値が存在しないことを意味します。

例：

```json
{
  "lastUsedYearMonth": null
}
```

`null`を許可するのは、業務上「値が存在しない」状態に意味がある場合だけとします。

単にValidationを簡単にする目的でNullableを増やしません。

OpenAPIではRequiredとNullableを明確に分離して定義します。

## 13. Empty Value・Empty Collection

Collectionが0件の場合は、`null`ではなく空Arrayを返します。

```json
{
  "items": []
}
```

または、Pagination不要な場合：

```json
[]
```

空String：

```text
""
```

は、業務上明確な意味がある場合を除き使用しません。

値なしを表現する場合は、用途に応じて次を使い分けます。

```text
Property省略
null
[]
```

`null`とEmpty Stringを同じ意味として扱いません。

## 14. HTTP Status Code

Success Responseでは次を基本とします。

| 状況 | Status |
| --- | --- |
| Resource取得成功 | `200 OK` |
| 一覧取得成功 | `200 OK` |
| Resource作成成功 | `201 Created` |
| Resource更新成功 | `200 OK` |
| Domain Operation成功 | `200 OK`または`204 No Content` |
| Response Body不要な削除成功 | `204 No Content` |

Resource作成時に作成済みResourceを返す場合は`201 Created`を使用します。

```http
HTTP/1.1 201 Created
```

```json
{
  "id": 123,
  "name": "Laravel"
}
```

削除などResponse Bodyが不要な操作では、原則として`204 No Content`を使用します。

Error Response：

| 状況 | Status |
| --- | --- |
| Authentication Error | `401 Unauthorized` |
| Authorization Error | `403 Forbidden` |
| Resource Not Found | `404 Not Found` |
| Business Conflict | `409 Conflict` |
| Input Validation Error | `422 Unprocessable Entity` |
| Unexpected Server Error | `500 Internal Server Error` |

HTTP Statusだけで業務Errorを識別せず、Error Codeと組み合わせて使用します。

## 15. Error Response

Error Responseは共通Schemaを使用します。

基本形：

```json
{
  "code": "EMPLOYEE_NOT_FOUND",
  "message": "Employee was not found."
}
```

共通Property：

| Property | 内容 |
| --- | --- |
| `code` | 機械判定可能なError Code |
| `message` | 利用者向けの概要Message |

Error Codeは`UPPER_SNAKE_CASE`を使用します。

例：

```text
AUTHENTICATION_REQUIRED
PERMISSION_DENIED
EMPLOYEE_NOT_FOUND
SKILL_NOT_FOUND
VALIDATION_ERROR
EMPLOYEE_ALREADY_RETIRED
```

Next.js BFFでは、必要に応じて`code`を利用して画面表示や制御を行います。

`message`文字列そのものを条件分岐へ使用しません。

### Validation Error

Validation ErrorではFieldごとの詳細を`errors`として返します。

```json
{
  "code": "VALIDATION_ERROR",
  "message": "The request contains invalid values.",
  "errors": {
    "name": [
      "Name is required."
    ],
    "experienceMonths": [
      "Experience months must be at least 1."
    ]
  }
}
```

`errors`のKeyにはAPI Property名を使用します。

Laravel内部のValidation Rule名やDatabase Column名は公開しません。

### Unexpected Error

予期しないServer Errorでは、内部情報をResponseへ含めません。

```json
{
  "code": "INTERNAL_SERVER_ERROR",
  "message": "An unexpected error occurred."
}
```

次の情報は返却しません。

- Stack Trace
- SQL
- Database Connection情報
- File Path
- Internal Exception Class
- Secret
- Token
- Credential

詳細な原因はServer-side Loggingで確認します。

## 16. Authentication・Authorization

Backend APIはLaravel Sanctum Bearer TokenによるAuthenticationを使用します。

```http
Authorization: Bearer <token>
```

Laravel用TokenはNext.js BFFで管理し、Browserへ公開しません。

```text
Browser
   │ Auth.js Session
   ▼
Next.js BFF
   │ Sanctum Bearer Token
   ▼
Laravel Backend API
```

Authentication失敗：

```http
401 Unauthorized
```

Authentication済みだが操作権限がない場合：

```http
403 Forbidden
```

Authorization RuleはLaravel Policy、Application Layer、Domain Ruleの責務に応じて適用します。

OpenAPIでは、Authenticationが必要なEndpointへSecurity Requirementを定義します。

## 17. Idempotency

HTTP Methodが本来持つIdempotencyの意味を可能な限り維持します。

| Method | 基本的な扱い |
| --- | --- |
| `GET` | Idempotent |
| `PATCH` | 同一内容を複数回適用しても最終状態が同じになる設計を基本とする |
| `DELETE` | 可能な範囲でIdempotent |
| `POST` | 原則としてNon-idempotent |

MVPでは、汎用的な`Idempotency-Key`機構は導入しません。

二重実行による重大な問題が発生するDomain Operationが追加された場合は、そのUse Case単位でIdempotency対応を検討します。

## 18. Concurrency

MVPではHTTP APIレベルのOptimistic Lock機構は導入しません。

`ETag`、`If-Match`、Version Numberによる更新競合制御は採用しません。

通常の更新ではLast Write Winsを許容します。

業務Invariant維持のために競合制御が必要なUse Caseについては、Application LayerのTransactionとDatabase Lockを使用します。

例：

```text
権限管理ユーザーを最低1人維持する
```

このような業務制約はHTTP APIの共通機構ではなく、Application／Domain／Databaseで保証します。

将来、同一Resourceへの同時編集が問題になる場合はOptimistic Lock導入を再検討します。

## 19. Cache

Backend APIの業務Resourceについて、MVPでは汎用的なHTTP Response Cacheを前提としません。

次のHeaderを利用した高度なCache制御は、MVPの共通仕様には含めません。

```text
ETag
If-None-Match
Last-Modified
If-Modified-Since
```

Next.js側のData CacheやUI CacheについてはFrontend Architectureで管理します。

個別APIでCacheが必要になった場合は、データの更新頻度、Authorization、情報漏えいリスクを確認して設計します。

## 20. Security

APIでは次のSecurity Ruleを共通して適用します。

- Backend APIをBrowserから直接利用させない
- Sanctum TokenをBrowserへ公開しない
- AuthorizationをFrontendだけに依存しない
- OpenAPIにAuthentication Requirementを定義する
- Inputを信用せず、Laravel側でもValidationする
- Domain InvariantをDomain Layerで保証する
- Database Constraintを最終防衛として使用する
- Mass Assignmentによって意図しないFieldを更新しない
- Error Responseへ内部情報を含めない
- Eloquent ModelをそのままSerializationしない
- Database構造をAPI契約として公開しない
- Secret、Token、CredentialをResponseやLogへ不用意に出力しない

Next.js BFFからのRequestであっても、Laravel Backend APIはRequest内容とAuthorizationを独立して検証します。

## 21. OpenAPI記述ルール

本書で定義した共通仕様はOpenAPIへ反映します。

OpenAPIでは少なくとも次を明示します。

- Path
- HTTP Method
- Operation ID
- Path Parameter
- Query Parameter
- Request Body
- Response Body
- HTTP Status
- Error Response
- Security Requirement
- Pagination
- Nullable／Required
- Date／Time Format
- Enum
- Validation Constraint

共通Schemaは再利用可能な単位で`components`または分割Schemaとして管理します。

例：

```text
schemas/
├── common/
│   ├── ErrorResponse.yaml
│   ├── ValidationErrorResponse.yaml
│   └── Pagination.yaml
├── employee/
├── skill/
└── employee-skill/
```

Schemaを共通化する際は、単にShapeが似ているという理由だけで異なる意味のSchemaを共有しません。

意味と変更理由が同じものだけを共通化します。

Generated Typeは直接編集せず、OpenAPI変更後に再生成します。

## 共通仕様まとめ

| 項目 | 採用方針 |
| --- | --- |
| API Version | `/api/v1` |
| Format | JSON |
| JSON Property | `camelCase` |
| ID | `integer / int64` |
| Update | `PATCH` |
| Pagination | Page-based |
| Pagination Parameter | `page`, `perPage` |
| Default `perPage` | `20` |
| Maximum `perPage` | `100` |
| Filtering | Query Parameter |
| Sorting | `sort=name`, `sort=-createdAt` |
| Timestamp | RFC 3339 / UTC |
| Date | `YYYY-MM-DD` |
| Year Month | `YYYY-MM` |
| Empty Collection | `[]` |
| Single Resource Envelope | 使用しない |
| Create | `201 Created` |
| Update | `200 OK` |
| Delete | `204 No Content` |
| Authentication Error | `401` |
| Authorization Error | `403` |
| Not Found | `404` |
| Business Conflict | `409` |
| Validation Error | `422` |
| Authentication | Sanctum Bearer Token |
| Error識別 | Error Code |
| Generic Idempotency Key | MVPでは不採用 |
| Optimistic Lock | MVPでは不採用 |
| HTTP Response Cache | MVPでは原則不採用 |

## 関連ドキュメント

- [API設計](./README.md)
- [API仕様管理](./01_API仕様管理.md)
- [OpenAPI運用方式](./02_OpenAPI運用方式.md)
- [認証・認可設計](../02_認証・認可/README.md)
- [API Resource決定事項](../../02_アーキテクチャ/Laravel/01_内部アーキテクチャ決定事項/21_API-Resource/)
- [API決定事項](../../02_アーキテクチャ/Laravel/01_内部アーキテクチャ決定事項/22_API/)
- [Error Handling決定事項](../../02_アーキテクチャ/Laravel/01_内部アーキテクチャ決定事項/23_Error-Handling/)
- [Date・Time設計](../01_データベース/08_Date・Time設計.md)

## 文書管理ルール

- API共通仕様を変更する場合は、既存のすべてのAPIへの影響を確認します。
- OpenAPIと本書を同一の契約方針へ保ちます。
- Naming、Pagination、Error Responseなどの共通ルールを個別APIごとに独自定義しません。
- 共通仕様から逸脱する場合は、個別API設計に理由を明記します。
- Breaking Changeとなる変更では、VersioningとNext.js BFFへの影響を確認します。
- LaravelやDatabase内部の都合だけを理由にAPI契約を変更しません。

[API設計へ戻る](./README.md) / [システム設計へ戻る](../README.md)
