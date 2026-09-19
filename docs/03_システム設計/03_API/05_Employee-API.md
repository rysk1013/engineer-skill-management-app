# Employee API

Engineer Skill Management App の Employee Management に関する Backend API を定義します。

本ドキュメントでは、Employee および Employee から参照する Department の API 契約を扱います。

API 契約の Source of Truth は OpenAPI とし、本ドキュメントは OpenAPI 定義前の個別 API 設計として位置付けます。

---

## 1. 対象API

MVP では以下の API を提供します。

| Use Case | Method | Endpoint |
|---|---|---|
| 社員一覧取得 | GET | `/api/v1/employees` |
| 社員詳細取得 | GET | `/api/v1/employees/{employeeId}` |
| 社員登録 | POST | `/api/v1/employees` |
| 社員更新 | PATCH | `/api/v1/employees/{employeeId}` |
| 社員退職 | POST | `/api/v1/employees/{employeeId}/retirement` |
| 部署一覧取得 | GET | `/api/v1/departments` |

EmployeeSkill は本 API に含めず、`07_EmployeeSkill-API.md` で定義します。

---

# 2. Employee Resource

## 2.1 基本方針

Employee は社員の基本情報を管理する Aggregate Root とします。

Employee API では主に以下を扱います。

```text
Employee
├── Employee ID
├── Employee Number
├── Name
├── Department
├── Employment Status
└── Retirement Date
```

以下は Employee API に含めません。

```text
Skill情報
資格
Soft Skill
メールアドレス
画像
役職
チーム
入社年月
```

EmployeeSkill は別 Resource として扱います。

---

# 3. Authorization

Employee API の Authorization は Backend で必ず実施します。

Role ごとの基本権限は以下とします。

| Role | 一覧 | 詳細 | 登録 | 更新 | 退職 |
|---|---:|---:|---:|---:|---:|
| Administrator | ○ | ○ | ○ | ○ | ○ |
| Manager | ○ | ○ | ○ | ○ | ○ |
| SubManager | 担当社員のみ | 担当社員のみ | × | 担当社員のみ | × |
| TeamLeader | 担当社員のみ | 担当社員のみ | × | × | × |

Administrator はシステム全体の管理 Role として Employee Management を操作可能とします。

SubManager / TeamLeader の「担当社員」は Assignment 情報をもとに Backend で判定します。

Frontend / BFF 側の表示制御だけを Authorization としません。

---

# 4. 社員一覧取得

## 4.1 Endpoint

```http
GET /api/v1/employees
```

社員一覧を取得します。

---

## 4.2 Authentication

必須です。

```text
401 UNAUTHENTICATED
```

---

## 4.3 Authorization

Role に応じて取得可能範囲を制御します。

```text
Administrator
→ 全社員

Manager
→ 全社員

SubManager
→ 担当社員のみ

TeamLeader
→ 担当社員のみ
```

Client から User ID 等を指定して権限範囲を変更できる仕様にはしません。

Authentication Context から取得範囲を決定します。

---

## 4.4 Query Parameters

以下を使用します。

| Parameter | Type | Required | Description |
|---|---|---:|---|
| `page` | integer | No | Page番号。1始まり |
| `perPage` | integer | No | 1 Pageあたりの件数 |
| `keyword` | string | No | Keyword Search |
| `departmentId` | integer | No | Department Filter |
| `employmentStatus` | string | No | 雇用状態Filter |
| `sort` | string | No | Sort対象 |
| `order` | string | No | `asc` / `desc` |

---

## 4.5 Pagination

Offset Pagination を使用します。

例:

```text
GET /api/v1/employees?page=2&perPage=20
```

Default:

```text
page = 1
perPage = 20
```

MVP では `perPage` の最大値を以下とします。

```text
100
```

最大値を超える Request は Validation Error とします。

---

## 4.6 Keyword Search

```text
keyword
```

を使用します。

MVP の検索対象:

```text
employeeNumber
name
```

例:

```text
GET /api/v1/employees?keyword=Yamada
```

Database Column 名を Client から直接指定する検索方式は採用しません。

---

## 4.7 Filtering

### Department

```text
departmentId
```

例:

```text
GET /api/v1/employees?departmentId=10
```

### Employment Status

```text
employmentStatus
```

MVP で許可する値は Employee Domain の Enum と OpenAPI Schema に合わせます。

例:

```text
employed
retired
```

通常画面で在籍社員のみ必要な場合は、

```text
employmentStatus=employed
```

を指定します。

---

## 4.8 Sorting

以下を許可します。

```text
sort=employeeNumber
sort=name
sort=createdAt
sort=updatedAt
```

Order:

```text
asc
desc
```

Default は以下とします。

```text
sort=employeeNumber
order=asc
```

許可されていない Sort Key は `422 VALIDATION_ERROR` とします。

---

## 4.9 Response

```http
200 OK
```

例:

```json
{
  "data": [
    {
      "id": 1,
      "employeeNumber": "EMP0001",
      "name": "Taro Yamada",
      "department": {
        "id": 10,
        "name": "Development"
      },
      "employmentStatus": "employed",
      "retirementDate": null
    }
  ],
  "pagination": {
    "page": 1,
    "perPage": 20,
    "total": 125,
    "totalPages": 7
  }
}
```

一覧 API では必要最小限の情報のみ返します。

EmployeeSkill 等の詳細情報は含めません。

---

## 4.10 Status Code

| Status | Error Code | 条件 |
|---|---|---|
| 200 | - | 成功 |
| 401 | `UNAUTHENTICATED` | 未認証 |
| 422 | `VALIDATION_ERROR` | Query Parameter不正 |
| 500 | `INTERNAL_SERVER_ERROR` | 想定外Error |

権限範囲は一覧内容を制限するため、SubManager / TeamLeader が利用しただけで `403` にはしません。

---

## 4.11 Application Layer

CQRS の Query として扱います。

```text
ListEmployeesQuery
        ↓
ListEmployeesQueryHandler
        ↓
EmployeeQueryService
        ↓
Read Model
```

Employee Aggregate を一覧件数分復元する方式は採用しません。

---

# 5. 社員詳細取得

## 5.1 Endpoint

```http
GET /api/v1/employees/{employeeId}
```

---

## 5.2 Path Parameter

| Parameter | Type | Required |
|---|---|---:|
| `employeeId` | integer | Yes |

Backend の `bigint` ID を API 上では integer として扱います。

---

## 5.3 Authentication

必須です。

---

## 5.4 Authorization

```text
Administrator
→ 全社員

Manager
→ 全社員

SubManager
→ 担当社員のみ

TeamLeader
→ 担当社員のみ
```

担当外社員へのアクセスは、

```text
403 FORBIDDEN
```

を基本とします。

---

## 5.5 Response

```http
200 OK
```

例:

```json
{
  "id": 1,
  "employeeNumber": "EMP0001",
  "name": "Taro Yamada",
  "department": {
    "id": 10,
    "name": "Development"
  },
  "employmentStatus": "employed",
  "retirementDate": null,
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-10T15:30:00+09:00"
}
```

EmployeeSkill 一覧は含めません。

必要な場合は、

```http
GET /api/v1/employees/{employeeId}/skills
```

を別途利用します。

---

## 5.6 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `EMPLOYEE_NOT_FOUND` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 5.7 Application Layer

```text
GetEmployeeQuery
        ↓
GetEmployeeQueryHandler
        ↓
EmployeeQueryService
```

Read Use Case なので、Employee Aggregate の復元を必須としません。

---

# 6. 社員登録

## 6.1 Endpoint

```http
POST /api/v1/employees
```

---

## 6.2 Authentication

必須です。

---

## 6.3 Authorization

以下のみ許可します。

```text
Administrator
Manager
```

SubManager / TeamLeader は登録できません。

権限不足:

```text
403 FORBIDDEN
```

---

## 6.4 Request

例:

```json
{
  "employeeNumber": "EMP0001",
  "name": "Taro Yamada",
  "departmentId": 10
}
```

---

## 6.5 Request Schema

| Field | Type | Required | Description |
|---|---|---:|---|
| `employeeNumber` | string | Yes | 社員番号 |
| `name` | string | Yes | 社員名 |
| `departmentId` | integer | Yes | 所属Department |

`employmentStatus` は登録時に Client から指定させません。

新規 Employee は、

```text
employed
```

として登録します。

`retirementDate` も登録 Request には含めません。

---

## 6.6 Validation

Presentation Layer で以下を確認します。

```text
employeeNumber
- required
- string
- length制約

name
- required
- string
- length制約

departmentId
- required
- integer
```

Department の存在確認は Application / Domain 側の Use Case として扱います。

---

## 6.7 Business Rule

### Employee Number

社員番号は一意とします。

Application で重複確認を行い、DB の UNIQUE Constraint でも最終防衛します。

重複時:

```text
409 EMPLOYEE_NUMBER_ALREADY_EXISTS
```

---

### Department

指定した Department が存在しない場合:

```text
404 DEPARTMENT_NOT_FOUND
```

---

## 6.8 Response

```http
201 Created
```

例:

```json
{
  "id": 1,
  "employeeNumber": "EMP0001",
  "name": "Taro Yamada",
  "department": {
    "id": 10,
    "name": "Development"
  },
  "employmentStatus": "employed",
  "retirementDate": null,
  "createdAt": "2026-09-14T10:00:00+09:00",
  "updatedAt": "2026-09-14T10:00:00+09:00"
}
```

---

## 6.9 Status Code

| Status | Error Code |
|---|---|
| 201 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `DEPARTMENT_NOT_FOUND` |
| 409 | `EMPLOYEE_NUMBER_ALREADY_EXISTS` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 6.10 Application Layer

Command として扱います。

```text
CreateEmployeeCommand
        ↓
CreateEmployeeCommandHandler
        ↓
Employee::register()
        ↓
EmployeeRepository
```

1 Use Case = 1 Transaction とします。

---

# 7. 社員更新

## 7.1 Endpoint

```http
PATCH /api/v1/employees/{employeeId}
```

部分更新を行います。

---

## 7.2 Authentication

必須です。

---

## 7.3 Authorization

```text
Administrator
→ 全社員更新可能

Manager
→ 全社員更新可能

SubManager
→ 担当社員のみ更新可能

TeamLeader
→ 更新不可
```

---

## 7.4 Request

例:

```json
{
  "name": "Taro Yamada",
  "departmentId": 20
}
```

---

## 7.5 更新可能Field

MVP では以下を更新可能とします。

```text
employeeNumber
name
departmentId
```

以下は直接更新できません。

```text
employmentStatus
retirementDate
```

退職状態への変更は必ず、

```http
POST /employees/{employeeId}/retirement
```

を使用します。

---

## 7.6 PATCH Semantics

Property が存在しない場合:

```text
変更しない
```

`null` が送信された場合:

```text
そのFieldをnullへ更新する要求
```

として区別します。

ただし MVP の Employee 更新対象 Field は原則 `null` を許可しません。

---

## 7.7 Business Rule

Employee Number を変更する場合も一意性を維持します。

重複時:

```text
409 EMPLOYEE_NUMBER_ALREADY_EXISTS
```

Department が存在しない場合:

```text
404 DEPARTMENT_NOT_FOUND
```

Employee が存在しない場合:

```text
404 EMPLOYEE_NOT_FOUND
```

---

## 7.8 Response

```http
200 OK
```

更新後の Employee を返します。

```json
{
  "id": 1,
  "employeeNumber": "EMP0001",
  "name": "Taro Yamada",
  "department": {
    "id": 20,
    "name": "Platform"
  },
  "employmentStatus": "employed",
  "retirementDate": null,
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-14T11:00:00+09:00"
}
```

---

## 7.9 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `EMPLOYEE_NOT_FOUND` |
| 404 | `DEPARTMENT_NOT_FOUND` |
| 409 | `EMPLOYEE_NUMBER_ALREADY_EXISTS` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 7.10 Application Layer

```text
UpdateEmployeeCommand
        ↓
UpdateEmployeeCommandHandler
        ↓
EmployeeRepository
        ↓
Employee Behavior
```

Generic Setter は使用しません。

概念的には、

```text
changeEmployeeNumber()
rename()
changeDepartment()
```

など、意味のある Domain Behavior を利用します。

---

# 8. 社員退職

## 8.1 Endpoint

```http
POST /api/v1/employees/{employeeId}/retirement
```

Employee を退職状態へ変更します。

---

## 8.2 Domain Operation

退職は単なる、

```text
employmentStatus = retired
```

という Property 更新ではなく Domain Operation として扱います。

そのため、

```http
PATCH /employees/{employeeId}
```

ではなく専用 Endpoint を使用します。

---

## 8.3 Authentication

必須です。

---

## 8.4 Authorization

以下のみ許可します。

```text
Administrator
Manager
```

SubManager / TeamLeader は退職処理を実行できません。

---

## 8.5 Request

```json
{
  "retirementDate": "2026-09-30"
}
```

---

## 8.6 Request Schema

| Field | Type | Required |
|---|---|---:|
| `retirementDate` | string (`date`) | Yes |

ISO 8601 の日付形式:

```text
YYYY-MM-DD
```

を使用します。

---

## 8.7 Business Rule

退職処理では以下を実施します。

```text
employmentStatus
employed → retired

retirementDate
指定値を設定
```

退職 Employee は即時削除しません。

保持期間・削除フローは別途定義した Data Retention 方針に従います。

---

## 8.8 既に退職済みの場合

既に退職済みの Employee に対して再度退職操作を行った場合は、

```text
409 EMPLOYEE_ALREADY_RETIRED
```

とします。

MVP では退職 API を Idempotent Operation として扱わず、重複した Domain Operation を明示的に Conflict とします。

---

## 8.9 Response

```http
200 OK
```

例:

```json
{
  "id": 1,
  "employeeNumber": "EMP0001",
  "name": "Taro Yamada",
  "department": {
    "id": 10,
    "name": "Development"
  },
  "employmentStatus": "retired",
  "retirementDate": "2026-09-30",
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-14T12:00:00+09:00"
}
```

---

## 8.10 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `EMPLOYEE_NOT_FOUND` |
| 409 | `EMPLOYEE_ALREADY_RETIRED` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 8.11 Application Layer

```text
RetireEmployeeCommand
        ↓
RetireEmployeeCommandHandler
        ↓
EmployeeRepository
        ↓
Employee::retire()
```

1 Use Case = 1 Transaction とします。

---

# 9. Department一覧取得

## 9.1 Endpoint

```http
GET /api/v1/departments
```

Employee 登録・更新・検索時に利用する Department の参照 API です。

---

## 9.2 Authentication

必須です。

---

## 9.3 Authorization

Application User であれば利用可能とします。

```text
Administrator
Manager
SubManager
TeamLeader
```

---

## 9.4 Query Parameters

MVP では Pagination を使用しません。

Department 数は小規模であることを前提とし、利用可能な Department をまとめて返します。

必要になった場合に Search / Pagination を追加します。

---

## 9.5 Response

```http
200 OK
```

```json
{
  "data": [
    {
      "id": 10,
      "name": "Development"
    },
    {
      "id": 20,
      "name": "Platform"
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

## 9.6 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 9.7 Application Layer

```text
ListDepartmentsQuery
        ↓
ListDepartmentsQueryHandler
        ↓
DepartmentQueryService
```

Read Model / Query Service で取得します。

---

# 10. Employee Response Schema

Employee の基本 Response Schema は以下を基準とします。

```json
{
  "id": 1,
  "employeeNumber": "EMP0001",
  "name": "Taro Yamada",
  "department": {
    "id": 10,
    "name": "Development"
  },
  "employmentStatus": "employed",
  "retirementDate": null,
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-10T15:30:00+09:00"
}
```

---

## 10.1 Naming

API:

```text
camelCase
```

Database:

```text
snake_case
```

例:

```text
employeeNumber
↕

employee_number
```

API と Database Schema を直接結合しません。

---

## 10.2 Nullable

在籍社員:

```json
{
  "employmentStatus": "employed",
  "retirementDate": null
}
```

退職社員:

```json
{
  "employmentStatus": "retired",
  "retirementDate": "2026-09-30"
}
```

---

# 11. Employee Error Code

Employee API で使用する Business 固有 Error Code は以下とします。

| Error Code | Status | Description |
|---|---:|---|
| `EMPLOYEE_NOT_FOUND` | 404 | Employee不存在 |
| `DEPARTMENT_NOT_FOUND` | 404 | Department不存在 |
| `EMPLOYEE_NUMBER_ALREADY_EXISTS` | 409 | Employee Number重複 |
| `EMPLOYEE_ALREADY_RETIRED` | 409 | Employeeが既に退職済み |

共通 Error Code:

```text
UNAUTHENTICATED
FORBIDDEN
VALIDATION_ERROR
INTERNAL_SERVER_ERROR
```

は `03_API共通仕様.md` に従います。

---

# 12. Domain / API境界

Employee API から Domain Model を直接返しません。

```text
Employee Aggregate
        ↓
Application
        ↓
Presentation
        ↓
Employee Response Schema
```

以下を API 契約へ直接公開しません。

```text
Employee Entity
Eloquent Model
Value Object
PHP Enum
Database Column
```

---

# 13. Query / Command対応

MVP の Application Use Case は以下を基本とします。

## Query

```text
GET /employees
→ ListEmployeesQuery

GET /employees/{employeeId}
→ GetEmployeeQuery

GET /departments
→ ListDepartmentsQuery
```

## Command

```text
POST /employees
→ CreateEmployeeCommand

PATCH /employees/{employeeId}
→ UpdateEmployeeCommand

POST /employees/{employeeId}/retirement
→ RetireEmployeeCommand
```

各 Command / Query に対して Handler を1つ対応させます。

---

# 14. Transaction

Read:

```text
ListEmployees
GetEmployee
ListDepartments
```

では原則 Transaction を明示的に開始しません。

Write:

```text
CreateEmployee
UpdateEmployee
RetireEmployee
```

では、

```text
1 Use Case = 1 Transaction
```

を基本とします。

Transaction Boundary は Application Handler に置きます。

---

# 15. Concurrency

Employee の通常更新では MVP として Optimistic Lock を導入しません。

```text
READ COMMITTED
+
Last Write Wins
```

を基本とします。

Employee Number の一意性については、

```text
Application Check
+
Database UNIQUE Constraint
```

の二重防御とします。

---

# 16. OpenAPI定義方針

OpenAPI 実装時には概ね以下の Schema を作成します。

```text
EmployeeSummary
EmployeeDetail
EmployeeListResponse
CreateEmployeeRequest
UpdateEmployeeRequest
RetireEmployeeRequest
DepartmentSummary
DepartmentListResponse
```

共通 Schema:

```text
Pagination
ErrorResponse
ValidationErrorResponse
```

は共通 Components を参照します。

---

# 17. MVPで採用しないAPI

MVP では以下を Employee API に含めません。

```text
DELETE /employees/{employeeId}
```

Employee を即時物理削除しません。

また、以下も作成しません。

```text
Employee一括登録
Employee一括更新
Employee一括削除
Department登録
Department更新
Department削除
Employee画像管理
Employeeメール管理
Employee資格管理
Employee役職管理
Employeeチーム管理
Employee入社年月管理
```

---

# 18. 決定事項

Employee API の MVP 仕様として以下を採用します。

```text
Employee一覧
GET /employees

Employee詳細
GET /employees/{employeeId}

Employee登録
POST /employees

Employee更新
PATCH /employees/{employeeId}

Employee退職
POST /employees/{employeeId}/retirement

Department一覧
GET /departments
```

Authorization:

```text
Administrator
全Employee操作可能

Manager
全Employee操作可能

SubManager
担当Employeeのみ閲覧・更新可能

TeamLeader
担当Employeeのみ閲覧可能
```

Employee 一覧:

```text
Pagination
Keyword Search
Department Filter
Employment Status Filter
Sorting
```

EmployeeSkill:

```text
Employee APIに含めない
別APIとして管理
```

退職:

```text
Domain Operationとして専用Endpoint
Employee物理削除はしない
```

Application:

```text
Query
ListEmployees
GetEmployee
ListDepartments

Command
CreateEmployee
UpdateEmployee
RetireEmployee
```

Read:

```text
Query Service / Read Model
```

Write:

```text
Aggregate
Repository
1 Use Case = 1 Transaction
```

この設計を `Employee API` の OpenAPI 定義および Laravel Backend 実装の基準とします。
