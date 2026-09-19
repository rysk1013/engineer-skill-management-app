# Access Control API

Engineer Skill Management App の Access Control に関する Backend API を定義します。

本ドキュメントでは以下を扱います。

- User
- Role
- Permission管理権限
- SubManagerAssignment
- TeamLeaderAssignment

Access Control は Employee / Skill / EmployeeSkill API の Authorization の基盤となります。

API 契約の Source of Truth は OpenAPI とし、本ドキュメントは OpenAPI 定義前の個別 API 設計として位置付けます。

---

# 1. 対象API

MVP では以下の API を提供します。

## User

| Use Case | Method | Endpoint |
|---|---|---|
| User一覧取得 | GET | `/api/v1/users` |
| User詳細取得 | GET | `/api/v1/users/{userId}` |
| User登録 | POST | `/api/v1/users` |
| User更新 | PATCH | `/api/v1/users/{userId}` |

## SubManagerAssignment

| Use Case | Method | Endpoint |
|---|---|---|
| Assignment一覧取得 | GET | `/api/v1/sub-manager-assignments` |
| Assignment登録 | POST | `/api/v1/sub-manager-assignments` |
| Assignment解除 | DELETE | `/api/v1/sub-manager-assignments/{assignmentId}` |

## TeamLeaderAssignment

| Use Case | Method | Endpoint |
|---|---|---|
| Assignment一覧取得 | GET | `/api/v1/team-leader-assignments` |
| Assignment登録 | POST | `/api/v1/team-leader-assignments` |
| Assignment解除 | DELETE | `/api/v1/team-leader-assignments/{assignmentId}` |

---

# 2. Access Control基本方針

Role は以下を使用します。

```text
administrator
manager
sub_manager
team_leader
```

一般社員は Application User として扱わないため、MVP の User Role には含めません。

Employee と Application User は別概念とします。

```text
Employee
→ 社員情報

User
→ Application利用者・認証主体
```

必要に応じて User は Employee を参照しますが、User と Employee を同一 Aggregate としません。

---

# 3. Roleごとの権限

基本 Role は以下とします。

| Role | 概要 |
|---|---|
| Administrator | 全体管理 |
| Manager | 全Employee操作 |
| SubManager | 担当Employeeのみ操作 |
| TeamLeader | 担当Employeeのみ閲覧 |

Administrator の一部のみ Permission 管理を実行できます。

その能力を、

```text
canManagePermissions
```

で表現します。

---

# 4. Permission管理Administrator

Permission を管理できる User は以下を満たす必要があります。

```text
role = administrator
AND
canManagePermissions = true
```

システム全体で、この条件を満たす User を最低1人維持します。

```text
count(
  role = administrator
  AND
  canManagePermissions = true
) >= 1
```

この Rule は Access Control の重要な Domain / Application Invariant とします。

---

# 5. canManagePermissions Rule

`canManagePermissions = true` を設定できるのは Administrator のみとします。

したがって以下は無効です。

```text
role = manager
canManagePermissions = true
```

```text
role = sub_manager
canManagePermissions = true
```

```text
role = team_leader
canManagePermissions = true
```

Administrator 以外では必ず、

```text
canManagePermissions = false
```

とします。

---

# 6. Access Control APIのAuthorization

Access Control の変更系 API は Permission 管理権限を持つ Administrator のみ利用できます。

つまり、

```text
role = administrator
AND
canManagePermissions = true
```

を要求します。

基本 Authorization:

| API | Permission管理Administrator | その他 |
|---|---:|---:|
| User一覧 | ○ | × |
| User詳細 | ○ | × |
| User登録 | ○ | × |
| User更新 | ○ | × |
| Assignment一覧 | ○ | × |
| Assignment登録 | ○ | × |
| Assignment解除 | ○ | × |

MVP では Access Control 管理画面自体を管理者向け機能とします。

---

# 7. User一覧取得

## 7.1 Endpoint

```http
GET /api/v1/users
```

---

## 7.2 Authentication

必須です。

---

## 7.3 Authorization

以下のみ許可します。

```text
Administrator
AND
canManagePermissions = true
```

その他:

```text
403 FORBIDDEN
```

---

## 7.4 Query Parameters

| Parameter | Type | Required | Description |
|---|---|---:|---|
| `page` | integer | No | Page番号 |
| `perPage` | integer | No | 1 Page件数 |
| `keyword` | string | No | User検索 |
| `role` | string | No | Role Filter |
| `canManagePermissions` | boolean | No | Permission管理可否 |
| `sort` | string | No | Sort対象 |
| `order` | string | No | `asc` / `desc` |

---

## 7.5 Pagination

Offset Pagination を使用します。

```text
page = 1
perPage = 20
```

最大:

```text
perPage = 100
```

---

## 7.6 Keyword Search

MVP では User を識別する表示名を検索対象とします。

```text
keyword
```

認証情報や秘密情報を検索・返却対象にはしません。

---

## 7.7 Filter

Role:

```text
administrator
manager
sub_manager
team_leader
```

Permission管理:

```text
canManagePermissions=true
canManagePermissions=false
```

---

## 7.8 Sorting

MVP では以下を許可します。

```text
sort=name
sort=role
sort=createdAt
sort=updatedAt
```

Default:

```text
sort=name
order=asc
```

---

## 7.9 Response

```http
200 OK
```

例:

```json
{
  "data": [
    {
      "id": 1,
      "name": "Admin User",
      "role": "administrator",
      "canManagePermissions": true
    },
    {
      "id": 2,
      "name": "Manager User",
      "role": "manager",
      "canManagePermissions": false
    }
  ],
  "pagination": {
    "page": 1,
    "perPage": 20,
    "total": 10,
    "totalPages": 1
  }
}
```

---

## 7.10 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 7.11 Application Layer

```text
ListUsersQuery
    ↓
ListUsersQueryHandler
    ↓
UserQueryService
    ↓
Read Model
```

---

# 8. User詳細取得

## 8.1 Endpoint

```http
GET /api/v1/users/{userId}
```

---

## 8.2 Authentication / Authorization

Permission管理Administrator のみ許可します。

---

## 8.3 Path Parameter

| Parameter | Type | Required |
|---|---|---:|
| `userId` | integer | Yes |

---

## 8.4 Response

```http
200 OK
```

```json
{
  "id": 1,
  "name": "Admin User",
  "role": "administrator",
  "canManagePermissions": true,
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-10T15:30:00+09:00"
}
```

---

## 8.5 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `USER_NOT_FOUND` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 8.6 Application Layer

```text
GetUserQuery
    ↓
GetUserQueryHandler
    ↓
UserQueryService
```

---

# 9. User登録

## 9.1 Endpoint

```http
POST /api/v1/users
```

---

## 9.2 Authentication / Authorization

Permission管理Administrator のみ許可します。

---

## 9.3 Request

例:

```json
{
  "name": "Manager User",
  "role": "manager",
  "canManagePermissions": false
}
```

Administrator:

```json
{
  "name": "Admin User",
  "role": "administrator",
  "canManagePermissions": true
}
```

---

## 9.4 Request Schema

| Field | Type | Required | Description |
|---|---|---:|---|
| `name` | string | Yes | 表示名 |
| `role` | string | Yes | User Role |
| `canManagePermissions` | boolean | Yes | Permission管理権限 |

認証プロバイダとの紐付けに必要な内部情報は別途 Authentication 設計に従います。

本 API では Auth.js の Session 情報や Credential を直接管理しません。

---

# 10. User登録Rule

Role が Administrator 以外の場合:

```text
canManagePermissions = false
```

でなければなりません。

違反:

```text
409 USER_PERMISSION_RULE_VIOLATION
```

---

## 10.1 Response

```http
201 Created
```

```json
{
  "id": 2,
  "name": "Manager User",
  "role": "manager",
  "canManagePermissions": false,
  "createdAt": "2026-09-15T00:00:00+09:00",
  "updatedAt": "2026-09-15T00:00:00+09:00"
}
```

---

## 10.2 Status Code

| Status | Error Code |
|---|---|
| 201 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 409 | `USER_PERMISSION_RULE_VIOLATION` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 10.3 Application Layer

```text
CreateUserCommand
    ↓
CreateUserCommandHandler
    ↓
User::register()
    ↓
UserRepository
```

1 Use Case = 1 Transaction とします。

---

# 11. User更新

## 11.1 Endpoint

```http
PATCH /api/v1/users/{userId}
```

---

## 11.2 Authentication / Authorization

Permission管理Administrator のみ許可します。

---

## 11.3 Request

例:

```json
{
  "role": "administrator",
  "canManagePermissions": true
}
```

または:

```json
{
  "name": "Updated User"
}
```

---

## 11.4 更新可能Field

```text
name
role
canManagePermissions
```

---

## 11.5 PATCH Semantics

Property が存在しない場合は変更しません。

変更後の User 全体に対して Rule を再評価します。

例えば現在:

```text
role = administrator
canManagePermissions = true
```

に対し、

```json
{
  "role": "manager"
}
```

だけを指定した場合、更新後は:

```text
role = manager
canManagePermissions = true
```

となり Rule 違反です。

そのため Role 変更時には整合する状態への変更が必要です。

---

# 12. 最後のPermission管理Administrator

以下の変更は禁止します。

```text
Permission管理Administratorが1人だけ存在

そのUserを

administrator → manager
```

または、

```text
canManagePermissions
true → false
```

に変更すること。

---

## 12.1 Error

```text
409 LAST_PERMISSION_ADMIN_REQUIRED
```

とします。

---

# 13. User更新時の悲観ロック

Permission管理Administrator 数の確認は、単純な事前 SELECT だけでは Race Condition を防げません。

例:

```text
Permission管理Administrator = A, B
```

同時に:

```text
Request 1
A.canManagePermissions = false

Request 2
B.canManagePermissions = false
```

を処理すると、両 Request が「もう1人いる」と判断する可能性があります。

これを防ぐため、該当 Use Case では悲観ロックを利用します。

---

## 13.1 Transaction

概念的には以下とします。

```text
BEGIN

Permission管理に関係するUserを
ID昇順で SELECT ... FOR UPDATE

↓
変更後のPermission管理Administrator数を評価

↓
1人以上なら更新

COMMIT
```

Lock 順序は ID 昇順で統一します。

---

## 13.2 Isolation Level

```text
READ COMMITTED
```

を維持します。

Serializable Isolation への引き上げは MVP では行いません。

---

# 14. User更新Response

```http
200 OK
```

```json
{
  "id": 1,
  "name": "Admin User",
  "role": "administrator",
  "canManagePermissions": true,
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-15T00:30:00+09:00"
}
```

---

## 14.1 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `USER_NOT_FOUND` |
| 409 | `USER_PERMISSION_RULE_VIOLATION` |
| 409 | `LAST_PERMISSION_ADMIN_REQUIRED` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 14.2 Application Layer

```text
UpdateUserCommand
    ↓
UpdateUserCommandHandler
    ↓
Transaction
    ↓
UserRepository
    ↓
Pessimistic Lock
    ↓
User Behavior
```

---

# 15. User Domain Behavior

Generic Setter は使用しません。

概念的には以下の Behavior を利用します。

```text
rename()
changeRole()
grantPermissionManagement()
revokePermissionManagement()
```

Role と Permission 管理権限の整合性は Domain / Application Rule として維持します。

---

# 16. SubManagerAssignment基本方針

SubManagerAssignment は以下を表します。

```text
SubManager User
       │
       ▼
SubManagerAssignment
       │
       ▼
Employee
```

1 SubManager は複数 Employee を担当できます。

1 Employee に複数 SubManager を割り当てられます。

---

# 17. SubManagerAssignment Rule

Assignment 可能な User は、

```text
role = sub_manager
```

のみです。

例えば Manager を SubManagerAssignment に登録することはできません。

---

## 17.1 Duplicate

同一:

```text
userId
+
employeeId
```

の Assignment は重複不可とします。

---

# 18. SubManagerAssignment一覧取得

## 18.1 Endpoint

```http
GET /api/v1/sub-manager-assignments
```

---

## 18.2 Authentication / Authorization

Permission管理Administrator のみ許可します。

---

## 18.3 Query Parameters

| Parameter | Type | Required |
|---|---|---:|
| `userId` | integer | No |
| `employeeId` | integer | No |
| `page` | integer | No |
| `perPage` | integer | No |

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

## 18.4 Response

```json
{
  "data": [
    {
      "id": 1001,
      "user": {
        "id": 20,
        "name": "Sub Manager User",
        "role": "sub_manager"
      },
      "employee": {
        "id": 1,
        "employeeNumber": "EMP0001",
        "name": "Taro Yamada"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "perPage": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

---

## 18.5 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 18.6 Application Layer

```text
ListSubManagerAssignmentsQuery
    ↓
ListSubManagerAssignmentsQueryHandler
    ↓
SubManagerAssignmentQueryService
```

---

# 19. SubManagerAssignment登録

## 19.1 Endpoint

```http
POST /api/v1/sub-manager-assignments
```

---

## 19.2 Authentication / Authorization

Permission管理Administrator のみ許可します。

---

## 19.3 Request

```json
{
  "userId": 20,
  "employeeId": 1
}
```

---

## 19.4 Rule

User が存在しない:

```text
404 USER_NOT_FOUND
```

Employee が存在しない:

```text
404 EMPLOYEE_NOT_FOUND
```

User Role が `sub_manager` ではない:

```text
409 USER_ROLE_MISMATCH
```

既に同一 Assignment が存在:

```text
409 SUB_MANAGER_ASSIGNMENT_ALREADY_EXISTS
```

---

## 19.5 Response

```http
201 Created
```

```json
{
  "id": 1001,
  "user": {
    "id": 20,
    "name": "Sub Manager User",
    "role": "sub_manager"
  },
  "employee": {
    "id": 1,
    "employeeNumber": "EMP0001",
    "name": "Taro Yamada"
  },
  "createdAt": "2026-09-15T00:35:00+09:00"
}
```

---

## 19.6 Status Code

| Status | Error Code |
|---|---|
| 201 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `USER_NOT_FOUND` |
| 404 | `EMPLOYEE_NOT_FOUND` |
| 409 | `USER_ROLE_MISMATCH` |
| 409 | `SUB_MANAGER_ASSIGNMENT_ALREADY_EXISTS` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 19.7 Application Layer

```text
CreateSubManagerAssignmentCommand
    ↓
CreateSubManagerAssignmentCommandHandler
    ↓
User / Employee確認
    ↓
SubManagerAssignmentRepository
```

---

# 20. SubManagerAssignment解除

## 20.1 Endpoint

```http
DELETE /api/v1/sub-manager-assignments/{assignmentId}
```

---

## 20.2 Authentication / Authorization

Permission管理Administrator のみ許可します。

---

## 20.3 Response

```http
204 No Content
```

Response Body は返しません。

---

## 20.4 Status Code

| Status | Error Code |
|---|---|
| 204 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `SUB_MANAGER_ASSIGNMENT_NOT_FOUND` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 20.5 Application Layer

```text
DeleteSubManagerAssignmentCommand
    ↓
DeleteSubManagerAssignmentCommandHandler
    ↓
SubManagerAssignmentRepository
```

---

# 21. TeamLeaderAssignment基本方針

TeamLeaderAssignment は以下を表します。

```text
TeamLeader User
       │
       ▼
TeamLeaderAssignment
       │
       ▼
Employee
```

1 TeamLeader は複数 Employee を担当できます。

1 Employee に複数 TeamLeader を割り当てることも可能とします。

---

# 22. TeamLeaderAssignment Rule

Assignment 可能な User は、

```text
role = team_leader
```

のみです。

同一:

```text
userId
+
employeeId
```

の重複 Assignment は禁止します。

---

# 23. TeamLeaderAssignment一覧取得

## 23.1 Endpoint

```http
GET /api/v1/team-leader-assignments
```

---

## 23.2 Authentication / Authorization

Permission管理Administrator のみ許可します。

---

## 23.3 Query Parameters

| Parameter | Type | Required |
|---|---|---:|
| `userId` | integer | No |
| `employeeId` | integer | No |
| `page` | integer | No |
| `perPage` | integer | No |

Offset Pagination を使用します。

---

## 23.4 Response

```json
{
  "data": [
    {
      "id": 2001,
      "user": {
        "id": 30,
        "name": "Team Leader User",
        "role": "team_leader"
      },
      "employee": {
        "id": 1,
        "employeeNumber": "EMP0001",
        "name": "Taro Yamada"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "perPage": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

---

## 23.5 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 23.6 Application Layer

```text
ListTeamLeaderAssignmentsQuery
    ↓
ListTeamLeaderAssignmentsQueryHandler
    ↓
TeamLeaderAssignmentQueryService
```

---

# 24. TeamLeaderAssignment登録

## 24.1 Endpoint

```http
POST /api/v1/team-leader-assignments
```

---

## 24.2 Request

```json
{
  "userId": 30,
  "employeeId": 1
}
```

---

## 24.3 Rule

User が存在しない:

```text
404 USER_NOT_FOUND
```

Employee が存在しない:

```text
404 EMPLOYEE_NOT_FOUND
```

User Role が `team_leader` ではない:

```text
409 USER_ROLE_MISMATCH
```

重複:

```text
409 TEAM_LEADER_ASSIGNMENT_ALREADY_EXISTS
```

---

## 24.4 Response

```http
201 Created
```

```json
{
  "id": 2001,
  "user": {
    "id": 30,
    "name": "Team Leader User",
    "role": "team_leader"
  },
  "employee": {
    "id": 1,
    "employeeNumber": "EMP0001",
    "name": "Taro Yamada"
  },
  "createdAt": "2026-09-15T00:35:00+09:00"
}
```

---

## 24.5 Status Code

| Status | Error Code |
|---|---|
| 201 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `USER_NOT_FOUND` |
| 404 | `EMPLOYEE_NOT_FOUND` |
| 409 | `USER_ROLE_MISMATCH` |
| 409 | `TEAM_LEADER_ASSIGNMENT_ALREADY_EXISTS` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 24.6 Application Layer

```text
CreateTeamLeaderAssignmentCommand
    ↓
CreateTeamLeaderAssignmentCommandHandler
    ↓
User / Employee確認
    ↓
TeamLeaderAssignmentRepository
```

---

# 25. TeamLeaderAssignment解除

## 25.1 Endpoint

```http
DELETE /api/v1/team-leader-assignments/{assignmentId}
```

---

## 25.2 Authentication / Authorization

Permission管理Administrator のみ許可します。

---

## 25.3 Response

```http
204 No Content
```

---

## 25.4 Status Code

| Status | Error Code |
|---|---|
| 204 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `TEAM_LEADER_ASSIGNMENT_NOT_FOUND` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

# 26. Role変更とAssignment

User Role を変更した場合、既存 Assignment との整合性を維持する必要があります。

例えば、

```text
role = sub_manager
```

の User が SubManagerAssignment を持つ状態から、

```text
role = manager
```

へ変更すると、

```text
SubManagerAssignment
+
Manager User
```

という不整合が発生します。

MVP では Role 変更時に、このような不整合状態を許可しません。

---

# 27. Role変更時Rule

Role 変更対象 User が、変更後 Role と整合しない Assignment を持つ場合:

```text
409 USER_ROLE_ASSIGNMENT_CONFLICT
```

とします。

例:

```text
SubManagerAssignmentあり
sub_manager → manager
```

はそのままでは変更できません。

先に Assignment を解除してから Role を変更します。

---

## 27.1 理由

Role 更新と Assignment 自動削除を同時に行うと、

```text
Role変更
+
暗黙的Assignment削除
```

という複数の業務操作が1 API に混在します。

MVP では明示的な操作を優先し、自動削除しません。

---

# 28. Assignment Database Constraint

SubManagerAssignment:

```text
UNIQUE(user_id, employee_id)
```

TeamLeaderAssignment:

```text
UNIQUE(user_id, employee_id)
```

Foreign Key:

```text
user_id → users.id
employee_id → employees.id
```

Database Constraint は Application Rule の最終防衛とします。

---

# 29. Assignment Race Condition

同じ Assignment を同時に登録した場合でも、

```text
Application Check
+
Database UNIQUE Constraint
```

により重複を防ぎます。

Database Constraint 違反は Infrastructure Exception のまま返さず、

```text
SUB_MANAGER_ASSIGNMENT_ALREADY_EXISTS
```

または、

```text
TEAM_LEADER_ASSIGNMENT_ALREADY_EXISTS
```

へ変換します。

---

# 30. Transaction

Read API では原則として明示 Transaction を開始しません。

Write API:

```text
CreateUser
UpdateUser

CreateSubManagerAssignment
DeleteSubManagerAssignment

CreateTeamLeaderAssignment
DeleteTeamLeaderAssignment
```

では、

```text
1 Use Case = 1 Transaction
```

とします。

特に User Role / Permission 更新では悲観ロックを使用します。

---

# 31. Lock Policy

Permission 管理 Invariant を扱う場合:

```text
SELECT ... FOR UPDATE
```

を使用します。

複数 User を Lock する場合:

```text
ID昇順
```

で Lock します。

これにより Deadlock Risk を低減します。

---

# 32. Authorization実装

Presentation Layer では Policy 等を利用して Authorization を実行します。

概念的には:

```text
Authenticated User
    ↓
role確認
    ↓
canManagePermissions確認
    ↓
Use Case実行
```

ただし、

```text
最低1人Permission管理Administratorを維持する
```

といった整合性 Rule は Policy ではなく Application / Domain 側で扱います。

---

# 33. Error Code

Access Control API 固有 Error Code は以下とします。

| Error Code | Status | Description |
|---|---:|---|
| `USER_NOT_FOUND` | 404 | User不存在 |
| `USER_PERMISSION_RULE_VIOLATION` | 409 | RoleとPermission管理権限の不整合 |
| `LAST_PERMISSION_ADMIN_REQUIRED` | 409 | 最後のPermission管理Administratorを失う変更 |
| `USER_ROLE_MISMATCH` | 409 | Assignment種別とUser Role不一致 |
| `USER_ROLE_ASSIGNMENT_CONFLICT` | 409 | Role変更後に既存Assignmentと不整合 |
| `SUB_MANAGER_ASSIGNMENT_NOT_FOUND` | 404 | SubManagerAssignment不存在 |
| `SUB_MANAGER_ASSIGNMENT_ALREADY_EXISTS` | 409 | SubManagerAssignment重複 |
| `TEAM_LEADER_ASSIGNMENT_NOT_FOUND` | 404 | TeamLeaderAssignment不存在 |
| `TEAM_LEADER_ASSIGNMENT_ALREADY_EXISTS` | 409 | TeamLeaderAssignment重複 |

他 Resource:

```text
EMPLOYEE_NOT_FOUND
```

共通:

```text
UNAUTHENTICATED
FORBIDDEN
VALIDATION_ERROR
INTERNAL_SERVER_ERROR
```

---

# 34. User Response Schema

基本 User Response:

```json
{
  "id": 1,
  "name": "Admin User",
  "role": "administrator",
  "canManagePermissions": true,
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-10T15:30:00+09:00"
}
```

以下の内部情報は返しません。

```text
Auth.js Session
Sanctum Token
Password
Credential
Internal Provider Identifier
Database内部状態
```

---

# 35. Assignment Response Schema

SubManagerAssignment / TeamLeaderAssignment は基本的に以下を返します。

```json
{
  "id": 1001,
  "user": {
    "id": 20,
    "name": "Sub Manager User",
    "role": "sub_manager"
  },
  "employee": {
    "id": 1,
    "employeeNumber": "EMP0001",
    "name": "Taro Yamada"
  },
  "createdAt": "2026-09-15T00:35:00+09:00"
}
```

---

# 36. Domain / API境界

以下を直接 API Response として公開しません。

```text
User Aggregate
UserRole PHP Enum
Eloquent Model
Permission内部実装
SubManagerAssignment Model
TeamLeaderAssignment Model
Database Column
Lock実装
```

API 用 Schema へ変換します。

---

# 37. Query / Command対応

## Query

```text
GET /users
→ ListUsersQuery

GET /users/{userId}
→ GetUserQuery

GET /sub-manager-assignments
→ ListSubManagerAssignmentsQuery

GET /team-leader-assignments
→ ListTeamLeaderAssignmentsQuery
```

## Command

```text
POST /users
→ CreateUserCommand

PATCH /users/{userId}
→ UpdateUserCommand

POST /sub-manager-assignments
→ CreateSubManagerAssignmentCommand

DELETE /sub-manager-assignments/{assignmentId}
→ DeleteSubManagerAssignmentCommand

POST /team-leader-assignments
→ CreateTeamLeaderAssignmentCommand

DELETE /team-leader-assignments/{assignmentId}
→ DeleteTeamLeaderAssignmentCommand
```

Command / Query ごとに Handler を1つ対応させます。

---

# 38. OpenAPI定義方針

OpenAPI 実装時には概ね以下の Schema を作成します。

```text
UserSummary
UserDetail
UserListResponse

CreateUserRequest
UpdateUserRequest

UserRole

SubManagerAssignment
SubManagerAssignmentListResponse
CreateSubManagerAssignmentRequest

TeamLeaderAssignment
TeamLeaderAssignmentListResponse
CreateTeamLeaderAssignmentRequest
```

共通:

```text
Pagination
ErrorResponse
ValidationErrorResponse
```

を再利用します。

---

# 39. MVPで採用しないAPI

MVP では以下を作成しません。

```text
DELETE /users/{userId}
```

User 削除は認証ライフサイクルや監査との関係があるため別途設計します。

また、

```text
Role一括変更
Assignment一括登録
Assignment一括削除
Permission一括変更
Custom Role
Custom Permission
RBAC Policy Editor
```

も採用しません。

---

# 40. 決定事項

Access Control API の MVP 仕様として以下を採用します。

```text
User

GET
/users

GET
/users/{userId}

POST
/users

PATCH
/users/{userId}
```

```text
SubManagerAssignment

GET
/sub-manager-assignments

POST
/sub-manager-assignments

DELETE
/sub-manager-assignments/{assignmentId}
```

```text
TeamLeaderAssignment

GET
/team-leader-assignments

POST
/team-leader-assignments

DELETE
/team-leader-assignments/{assignmentId}
```

---

## Permission管理

```text
role = administrator
AND
canManagePermissions = true
```

のみ Access Control を変更可能とします。

---

## 最低1人制約

```text
Administrator
AND
canManagePermissions = true
```

を最低1人維持します。

```text
Transaction
+
SELECT ... FOR UPDATE
+
ID昇順Lock
```

で同時更新にも対応します。

---

## Assignment

```text
SubManagerAssignment
→ sub_manager Userのみ

TeamLeaderAssignment
→ team_leader Userのみ
```

同一:

```text
userId + employeeId
```

を重複不可とします。

---

## Role変更

変更後 Role と既存 Assignment が不整合になる場合:

```text
409 USER_ROLE_ASSIGNMENT_CONFLICT
```

とします。

Assignment を暗黙削除せず、先に明示的に解除します。

---

## Read

```text
Query Service
Read Model
```

を利用します。

---

## Write

```text
Command
Handler
Repository
Domain Behavior
1 Use Case = 1 Transaction
```

を基本とします。

Permission 管理 Invariant を伴う更新のみ悲観ロックを適用します。

この設計を `Access Control API` の OpenAPI 定義および Laravel Backend 実装の基準とします。
