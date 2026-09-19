# Skill API

Engineer Skill Management App の Skill Management に関する Backend API を定義します。

本ドキュメントでは `SkillCategory` および `Skill` の API 契約を扱います。

Skill Management は本システムの Core Domain の一部として扱い、EmployeeSkill から利用する Skill Master を管理します。

API 契約の Source of Truth は OpenAPI とし、本ドキュメントは OpenAPI 定義前の個別 API 設計として位置付けます。

---

## 1. 対象API

MVP では以下の API を提供します。

### SkillCategory

| Use Case | Method | Endpoint |
|---|---|---|
| SkillCategory一覧取得 | GET | `/api/v1/skill-categories` |
| SkillCategory登録 | POST | `/api/v1/skill-categories` |
| SkillCategory更新 | PATCH | `/api/v1/skill-categories/{skillCategoryId}` |

### Skill

| Use Case | Method | Endpoint |
|---|---|---|
| Skill一覧取得 | GET | `/api/v1/skills` |
| Skill詳細取得 | GET | `/api/v1/skills/{skillId}` |
| Skill登録 | POST | `/api/v1/skills` |
| Skill更新 | PATCH | `/api/v1/skills/{skillId}` |
| Skill無効化 | POST | `/api/v1/skills/{skillId}/deactivation` |

Employee と Skill の関連情報は本 API に含めません。

EmployeeSkill は `07_EmployeeSkill-API.md` で定義します。

---

# 2. Skill Management基本方針

Skill Management は以下の関係を基本とします。

```text
SkillCategory
      │
      └── Skill
             │
             └── EmployeeSkill
```

SkillCategory は Skill を分類する Master です。

MVP のカテゴリは以下を基本とします。

```text
Language
Framework
OS
Middleware
Cloud
Development Tool
```

Skill は EmployeeSkill から参照される Master とします。

例えば、

```text
Language
├── PHP
├── TypeScript
└── Go

Framework
├── Laravel
├── Next.js
└── React

Cloud
└── AWS
```

のように管理します。

---

# 3. Skill登録ルール

EmployeeSkill から Skill 名を自由入力することは禁止します。

```text
NG

EmployeeSkill
skillName = "Laravel"
```

必ず既存の Skill Master を参照します。

```text
EmployeeSkill
    │
    └── SkillId
            │
            ▼
          Skill
```

Master に存在しない技術を登録する場合は、

```text
Skill登録
    ↓
Skill Master
    ↓
EmployeeSkill登録
```

の順番とします。

---

# 4. Authorization

Skill Management の基本 Authorization は以下とします。

| Role | 参照 | SkillCategory登録・更新 | Skill登録・更新・無効化 |
|---|---:|---:|---:|
| Administrator | ○ | ○ | ○ |
| Manager | ○ | × | × |
| SubManager | ○ | × | × |
| TeamLeader | ○ | × | × |

Skill Master の変更は Administrator のみ許可します。

Manager / SubManager / TeamLeader は Skill Master を参照できますが変更できません。

Authorization は Laravel Backend で必ず実施します。

---

# 5. SkillCategory一覧取得

## 5.1 Endpoint

```http
GET /api/v1/skill-categories
```

SkillCategory 一覧を取得します。

---

## 5.2 Authentication

必須です。

---

## 5.3 Authorization

すべての Application User が利用できます。

```text
Administrator
Manager
SubManager
TeamLeader
```

---

## 5.4 Query Parameters

MVP では Query Parameter を使用しません。

SkillCategory は少数の Master Data であるため、Pagination も使用しません。

---

## 5.5 Response

```http
200 OK
```

例:

```json
{
  "data": [
    {
      "id": 1,
      "name": "Language"
    },
    {
      "id": 2,
      "name": "Framework"
    },
    {
      "id": 3,
      "name": "OS"
    },
    {
      "id": 4,
      "name": "Middleware"
    },
    {
      "id": 5,
      "name": "Cloud"
    },
    {
      "id": 6,
      "name": "Development Tool"
    }
  ]
}
```

0件の場合:

```json
{
  "data": []
}
```

---

## 5.6 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 5.7 Application Layer

CQRS の Query として扱います。

```text
ListSkillCategoriesQuery
        ↓
ListSkillCategoriesQueryHandler
        ↓
SkillCategoryQueryService
```

一覧取得のため Aggregate を復元しません。

---

# 6. SkillCategory登録

## 6.1 Endpoint

```http
POST /api/v1/skill-categories
```

---

## 6.2 Authentication

必須です。

---

## 6.3 Authorization

Administrator のみ許可します。

その他の Role:

```text
403 FORBIDDEN
```

---

## 6.4 Request

```json
{
  "name": "Database"
}
```

---

## 6.5 Request Schema

| Field | Type | Required | Description |
|---|---|---:|---|
| `name` | string | Yes | SkillCategory名 |

---

## 6.6 Validation

Presentation Layer では以下を確認します。

```text
name
- required
- string
- length制約
```

---

## 6.7 Business Rule

SkillCategory 名は重複不可とします。

Application 側で重複を確認し、Database の UNIQUE Constraint でも最終防衛します。

重複時:

```text
409 SKILL_CATEGORY_NAME_ALREADY_EXISTS
```

---

## 6.8 Response

```http
201 Created
```

```json
{
  "id": 7,
  "name": "Database",
  "createdAt": "2026-09-14T20:00:00+09:00",
  "updatedAt": "2026-09-14T20:00:00+09:00"
}
```

---

## 6.9 Status Code

| Status | Error Code |
|---|---|
| 201 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 409 | `SKILL_CATEGORY_NAME_ALREADY_EXISTS` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 6.10 Application Layer

```text
CreateSkillCategoryCommand
        ↓
CreateSkillCategoryCommandHandler
        ↓
SkillCategory::register()
        ↓
SkillCategoryRepository
```

1 Use Case = 1 Transaction とします。

---

# 7. SkillCategory更新

## 7.1 Endpoint

```http
PATCH /api/v1/skill-categories/{skillCategoryId}
```

---

## 7.2 Path Parameter

| Parameter | Type | Required |
|---|---|---:|
| `skillCategoryId` | integer | Yes |

---

## 7.3 Authentication

必須です。

---

## 7.4 Authorization

Administrator のみ許可します。

---

## 7.5 Request

```json
{
  "name": "Cloud Platform"
}
```

---

## 7.6 更新可能Field

MVP では以下のみ更新できます。

```text
name
```

---

## 7.7 Business Rule

SkillCategory 名の一意性を維持します。

対象 SkillCategory が存在しない場合:

```text
404 SKILL_CATEGORY_NOT_FOUND
```

変更後の名前が他の SkillCategory と重複する場合:

```text
409 SKILL_CATEGORY_NAME_ALREADY_EXISTS
```

SkillCategory 名を変更しても、所属する Skill との関連は維持します。

---

## 7.8 Response

```http
200 OK
```

```json
{
  "id": 7,
  "name": "Cloud Platform",
  "createdAt": "2026-09-14T20:00:00+09:00",
  "updatedAt": "2026-09-14T20:30:00+09:00"
}
```

---

## 7.9 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `SKILL_CATEGORY_NOT_FOUND` |
| 409 | `SKILL_CATEGORY_NAME_ALREADY_EXISTS` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 7.10 Application Layer

```text
UpdateSkillCategoryCommand
        ↓
UpdateSkillCategoryCommandHandler
        ↓
SkillCategoryRepository
        ↓
SkillCategory Behavior
```

Generic Setter は使用せず、

```text
rename()
```

等の Domain Behavior を利用します。

---

# 8. Skill一覧取得

## 8.1 Endpoint

```http
GET /api/v1/skills
```

Skill Master の一覧を取得します。

---

## 8.2 Authentication

必須です。

---

## 8.3 Authorization

すべての Application User が利用できます。

```text
Administrator
Manager
SubManager
TeamLeader
```

---

## 8.4 Query Parameters

| Parameter | Type | Required | Description |
|---|---|---:|---|
| `page` | integer | No | Page番号 |
| `perPage` | integer | No | 1 Pageあたりの件数 |
| `keyword` | string | No | Keyword Search |
| `skillCategoryId` | integer | No | SkillCategory Filter |
| `status` | string | No | Skill状態Filter |
| `sort` | string | No | Sort対象 |
| `order` | string | No | `asc` / `desc` |

---

## 8.5 Pagination

Offset Pagination を使用します。

Default:

```text
page = 1
perPage = 20
```

Maximum:

```text
perPage = 100
```

---

## 8.6 Keyword Search

```text
keyword
```

を使用します。

MVP の検索対象:

```text
Skill.name
```

例:

```text
GET /api/v1/skills?keyword=Laravel
```

---

## 8.7 Filtering

### SkillCategory

```text
skillCategoryId
```

例:

```text
GET /api/v1/skills?skillCategoryId=2
```

### Status

以下を許可します。

```text
active
inactive
```

例:

```text
GET /api/v1/skills?status=active
```

EmployeeSkill の登録候補を取得する場合は、

```text
status=active
```

を利用します。

---

## 8.8 Sorting

MVP では以下を許可します。

```text
sort=name
sort=createdAt
sort=updatedAt
```

Order:

```text
asc
desc
```

Default:

```text
sort=name
order=asc
```

---

## 8.9 Response

```http
200 OK
```

例:

```json
{
  "data": [
    {
      "id": 10,
      "name": "Laravel",
      "category": {
        "id": 2,
        "name": "Framework"
      },
      "status": "active"
    },
    {
      "id": 11,
      "name": "React",
      "category": {
        "id": 2,
        "name": "Framework"
      },
      "status": "active"
    }
  ],
  "pagination": {
    "page": 1,
    "perPage": 20,
    "total": 35,
    "totalPages": 2
  }
}
```

---

## 8.10 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 8.11 Application Layer

```text
ListSkillsQuery
        ↓
ListSkillsQueryHandler
        ↓
SkillQueryService
        ↓
Read Model
```

Skill Aggregate を一覧件数分復元しません。

---

# 9. Skill詳細取得

## 9.1 Endpoint

```http
GET /api/v1/skills/{skillId}
```

---

## 9.2 Path Parameter

| Parameter | Type | Required |
|---|---|---:|
| `skillId` | integer | Yes |

---

## 9.3 Authentication

必須です。

---

## 9.4 Authorization

すべての Application User が利用できます。

---

## 9.5 Response

```http
200 OK
```

```json
{
  "id": 10,
  "name": "Laravel",
  "category": {
    "id": 2,
    "name": "Framework"
  },
  "status": "active",
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-10T15:30:00+09:00"
}
```

EmployeeSkill や Employee 一覧は含めません。

---

## 9.6 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 404 | `SKILL_NOT_FOUND` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 9.7 Application Layer

```text
GetSkillQuery
        ↓
GetSkillQueryHandler
        ↓
SkillQueryService
```

Read Use Case のため Aggregate の復元を必須としません。

---

# 10. Skill登録

## 10.1 Endpoint

```http
POST /api/v1/skills
```

---

## 10.2 Authentication

必須です。

---

## 10.3 Authorization

Administrator のみ許可します。

---

## 10.4 Request

```json
{
  "name": "Laravel",
  "skillCategoryId": 2
}
```

---

## 10.5 Request Schema

| Field | Type | Required | Description |
|---|---|---:|---|
| `name` | string | Yes | Skill名 |
| `skillCategoryId` | integer | Yes | SkillCategory ID |

`status` は Client から指定しません。

新規 Skill は、

```text
active
```

として登録します。

---

## 10.6 Validation

Presentation Layer では以下を確認します。

```text
name
- required
- string
- length制約

skillCategoryId
- required
- integer
```

---

## 10.7 Business Rule

### SkillCategory

指定した SkillCategory が存在しない場合:

```text
404 SKILL_CATEGORY_NOT_FOUND
```

### Skill名

MVP では同一 SkillCategory 内で Skill 名を一意とします。

例えば、

```text
Framework / Laravel
Framework / Laravel
```

は登録できません。

一方、異なる Category に同名 Skill が必要となる場合は許可できる設計とします。

重複時:

```text
409 SKILL_NAME_ALREADY_EXISTS
```

Database でも以下に相当する UNIQUE Constraint を設定します。

```text
(skill_category_id, name)
```

---

## 10.8 Response

```http
201 Created
```

```json
{
  "id": 10,
  "name": "Laravel",
  "category": {
    "id": 2,
    "name": "Framework"
  },
  "status": "active",
  "createdAt": "2026-09-14T21:00:00+09:00",
  "updatedAt": "2026-09-14T21:00:00+09:00"
}
```

---

## 10.9 Status Code

| Status | Error Code |
|---|---|
| 201 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `SKILL_CATEGORY_NOT_FOUND` |
| 409 | `SKILL_NAME_ALREADY_EXISTS` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 10.10 Application Layer

```text
CreateSkillCommand
        ↓
CreateSkillCommandHandler
        ↓
Skill::register()
        ↓
SkillRepository
```

1 Use Case = 1 Transaction とします。

---

# 11. Skill更新

## 11.1 Endpoint

```http
PATCH /api/v1/skills/{skillId}
```

---

## 11.2 Authentication

必須です。

---

## 11.3 Authorization

Administrator のみ許可します。

---

## 11.4 Request

例:

```json
{
  "name": "Laravel Framework",
  "skillCategoryId": 2
}
```

---

## 11.5 更新可能Field

MVP では以下を更新できます。

```text
name
skillCategoryId
```

以下は直接更新できません。

```text
status
```

Skill の無効化には専用 Domain Operation を使用します。

---

## 11.6 PATCH Semantics

Property が存在しない場合は変更しません。

```text
Propertyなし
→ 変更しない
```

MVP の更新対象 Field は `null` を許可しません。

---

## 11.7 Business Rule

対象 Skill が存在しない場合:

```text
404 SKILL_NOT_FOUND
```

指定した SkillCategory が存在しない場合:

```text
404 SKILL_CATEGORY_NOT_FOUND
```

変更後の Category と Skill 名の組み合わせが重複する場合:

```text
409 SKILL_NAME_ALREADY_EXISTS
```

Skill の名前や Category を変更しても既存 EmployeeSkill との関連は維持します。

EmployeeSkill は Skill ID を参照するため、関連を作り直しません。

---

## 11.8 Response

```http
200 OK
```

```json
{
  "id": 10,
  "name": "Laravel Framework",
  "category": {
    "id": 2,
    "name": "Framework"
  },
  "status": "active",
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-14T21:30:00+09:00"
}
```

---

## 11.9 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `SKILL_NOT_FOUND` |
| 404 | `SKILL_CATEGORY_NOT_FOUND` |
| 409 | `SKILL_NAME_ALREADY_EXISTS` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 11.10 Application Layer

```text
UpdateSkillCommand
        ↓
UpdateSkillCommandHandler
        ↓
SkillRepository
        ↓
Skill Behavior
```

Generic Setter は使用しません。

概念的には、

```text
rename()
changeCategory()
```

などの Domain Behavior を利用します。

---

# 12. Skill無効化

## 12.1 Endpoint

```http
POST /api/v1/skills/{skillId}/deactivation
```

---

## 12.2 Domain Operation

Skill は完全削除しません。

```text
Skill
active
   ↓
deactivate()
   ↓
inactive
```

無効化後も Skill Record と既存 EmployeeSkill の関連を保持します。

そのため、

```http
DELETE /api/v1/skills/{skillId}
```

は使用しません。

---

## 12.3 Authentication

必須です。

---

## 12.4 Authorization

Administrator のみ許可します。

---

## 12.5 Request

Request Body は不要とします。

```http
POST /api/v1/skills/{skillId}/deactivation
```

---

## 12.6 Business Rule

Skill が存在しない場合:

```text
404 SKILL_NOT_FOUND
```

既に無効化済みの場合:

```text
409 SKILL_ALREADY_INACTIVE
```

MVP では無効化操作を Idempotent とせず、重複 Domain Operation を Conflict として扱います。

---

## 12.7 EmployeeSkillとの関係

Skill を無効化しても既存 EmployeeSkill は削除しません。

```text
Skill
inactive

      ↑
      │ 既存参照は維持
      │
EmployeeSkill
```

既存 EmployeeSkill の参照・表示も継続可能とします。

一方、新しい EmployeeSkill の登録では inactive Skill を選択できません。

```text
inactive Skill
+
新規EmployeeSkill登録

→ 不可
```

この Rule の詳細は `07_EmployeeSkill-API.md` で定義します。

---

## 12.8 Response

```http
200 OK
```

更新後の Skill を返します。

```json
{
  "id": 10,
  "name": "Laravel",
  "category": {
    "id": 2,
    "name": "Framework"
  },
  "status": "inactive",
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-14T22:00:00+09:00"
}
```

---

## 12.9 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `SKILL_NOT_FOUND` |
| 409 | `SKILL_ALREADY_INACTIVE` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 12.10 Application Layer

```text
DeactivateSkillCommand
        ↓
DeactivateSkillCommandHandler
        ↓
SkillRepository
        ↓
Skill::deactivate()
```

1 Use Case = 1 Transaction とします。

---

# 13. SkillCategory Response Schema

基本 Response:

```json
{
  "id": 2,
  "name": "Framework",
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-10T15:30:00+09:00"
}
```

一覧 API では必要最小限として、

```json
{
  "id": 2,
  "name": "Framework"
}
```

を返します。

---

# 14. Skill Response Schema

基本 Response:

```json
{
  "id": 10,
  "name": "Laravel",
  "category": {
    "id": 2,
    "name": "Framework"
  },
  "status": "active",
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-10T15:30:00+09:00"
}
```

一覧では必要最小限として、

```json
{
  "id": 10,
  "name": "Laravel",
  "category": {
    "id": 2,
    "name": "Framework"
  },
  "status": "active"
}
```

を返します。

---

# 15. Skill Status

API 上では Skill の状態を String Enum として表現します。

```text
active
inactive
```

PHP Enum や Database 内部表現を API へ直接公開しません。

OpenAPI の `enum` として定義します。

---

# 16. Error Code

Skill API で使用する Business 固有 Error Code は以下とします。

| Error Code | Status | Description |
|---|---:|---|
| `SKILL_CATEGORY_NOT_FOUND` | 404 | SkillCategory不存在 |
| `SKILL_NOT_FOUND` | 404 | Skill不存在 |
| `SKILL_CATEGORY_NAME_ALREADY_EXISTS` | 409 | SkillCategory名重複 |
| `SKILL_NAME_ALREADY_EXISTS` | 409 | 同一Category内のSkill名重複 |
| `SKILL_ALREADY_INACTIVE` | 409 | Skillが既に無効 |

共通 Error Code:

```text
UNAUTHENTICATED
FORBIDDEN
VALIDATION_ERROR
INTERNAL_SERVER_ERROR
```

については API 共通仕様に従います。

---

# 17. Domain / API境界

Domain Model を直接 API Response として公開しません。

```text
Skill Aggregate
      ↓
Application
      ↓
Presentation
      ↓
Skill Response Schema
```

以下の内部実装を API 契約へ露出しません。

```text
Skill Entity
SkillCategory Entity
Eloquent Model
Value Object
PHP Enum
Database Column
Database Constraint
```

---

# 18. Query / Command対応

## Query

```text
GET /skill-categories
→ ListSkillCategoriesQuery

GET /skills
→ ListSkillsQuery

GET /skills/{skillId}
→ GetSkillQuery
```

## Command

```text
POST /skill-categories
→ CreateSkillCategoryCommand

PATCH /skill-categories/{skillCategoryId}
→ UpdateSkillCategoryCommand

POST /skills
→ CreateSkillCommand

PATCH /skills/{skillId}
→ UpdateSkillCommand

POST /skills/{skillId}/deactivation
→ DeactivateSkillCommand
```

各 Command / Query に Handler を1つ対応させます。

---

# 19. Transaction

Read:

```text
ListSkillCategories
ListSkills
GetSkill
```

では原則として明示的な Transaction を開始しません。

Write:

```text
CreateSkillCategory
UpdateSkillCategory
CreateSkill
UpdateSkill
DeactivateSkill
```

では、

```text
1 Use Case = 1 Transaction
```

とします。

Transaction Boundary は Application Handler に置きます。

---

# 20. Database整合性

Application / Domain Rule に加えて Database Constraint を最終防衛として利用します。

SkillCategory:

```text
UNIQUE(name)
```

Skill:

```text
UNIQUE(skill_category_id, name)
```

関連:

```text
Skill
    ↓ FK
SkillCategory
```

Application Check と Database Constraint の二重防御とします。

Database Constraint Error をそのまま API Response として公開しません。

---

# 21. Concurrency

MVP では Skill / SkillCategory の通常更新に Optimistic Lock を導入しません。

```text
READ COMMITTED
+
Last Write Wins
```

を基本とします。

名前の一意性は、

```text
Application Check
+
Database UNIQUE Constraint
```

で維持します。

---

# 22. OpenAPI定義方針

OpenAPI 実装時には概ね以下の Schema を作成します。

```text
SkillCategorySummary
SkillCategoryDetail
SkillCategoryListResponse
CreateSkillCategoryRequest
UpdateSkillCategoryRequest

SkillSummary
SkillDetail
SkillListResponse
CreateSkillRequest
UpdateSkillRequest
SkillStatus
```

共通 Schema:

```text
Pagination
ErrorResponse
ValidationErrorResponse
```

は共通 Components を参照します。

---

# 23. MVPで採用しないAPI

MVP では以下を作成しません。

```text
DELETE /skill-categories/{skillCategoryId}
DELETE /skills/{skillId}
```

Skill を物理削除しません。

SkillCategory の削除も行いません。

また、以下も対象外とします。

```text
Skill一括登録
Skill一括更新
Skill一括削除
SkillCategory一括操作
Skill自由入力API
Skill Merge API
Skill Alias API
Skill復元・再有効化API
```

Skill の再有効化が必要になった場合は Domain Operation として別途設計します。

---

# 24. 決定事項

Skill API の MVP 仕様として以下を採用します。

```text
SkillCategory

GET
/skill-categories

POST
/skill-categories

PATCH
/skill-categories/{skillCategoryId}
```

```text
Skill

GET
/skills

GET
/skills/{skillId}

POST
/skills

PATCH
/skills/{skillId}

POST
/skills/{skillId}/deactivation
```

Authorization:

```text
参照
Administrator
Manager
SubManager
TeamLeader

Master変更
Administratorのみ
```

Skill 登録:

```text
自由入力不可

SkillCategory
    ↓
Skill Master登録
    ↓
EmployeeSkillから参照
```

Skill Name:

```text
同一SkillCategory内で一意

Application Check
+
Database UNIQUE Constraint
```

Skill 無効化:

```text
active
 ↓
inactive

物理削除しない
既存EmployeeSkillとの関連を維持
新規EmployeeSkillへの登録は禁止
```

Read:

```text
Query Service
Read Model
```

Write:

```text
Aggregate
Repository
Domain Behavior
1 Use Case = 1 Transaction
```

Concurrency:

```text
READ COMMITTED
Last Write Wins
```

この設計を `Skill API` の OpenAPI 定義および Laravel Backend 実装の基準とします。
