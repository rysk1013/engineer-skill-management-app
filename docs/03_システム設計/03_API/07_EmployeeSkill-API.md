# EmployeeSkill API

Engineer Skill Management App の EmployeeSkill に関する Backend API を定義します。

EmployeeSkill は Employee と Skill の単純な中間データではなく、社員ごとの技術経験・習熟度を表現する重要な Domain Model として扱います。

API 契約の Source of Truth は OpenAPI とし、本ドキュメントは OpenAPI 定義前の個別 API 設計として位置付けます。

---

# 1. 対象API

MVP では以下の API を提供します。

| Use Case | Method | Endpoint |
|---|---|---|
| 社員保有スキル一覧取得 | GET | `/api/v1/employees/{employeeId}/skills` |
| EmployeeSkill詳細取得 | GET | `/api/v1/employee-skills/{employeeSkillId}` |
| EmployeeSkill登録 | POST | `/api/v1/employee-skills` |
| EmployeeSkill更新 | PATCH | `/api/v1/employee-skills/{employeeSkillId}` |
| EmployeeSkill削除 | DELETE | `/api/v1/employee-skills/{employeeSkillId}` |

Skill Master の登録・変更・無効化は `06_Skill-API.md` で定義します。

---

# 2. EmployeeSkill基本方針

EmployeeSkill は以下の関係を表現します。

```text
Employee
    │
    │ employeeId
    ▼
EmployeeSkill
    ▲
    │ skillId
    │
Skill
```

EmployeeSkill は主に以下の情報を保持します。

```text
Employee
Skill
Skill Level
実務経験有無
経験期間
最終利用年月
```

EmployeeSkill は Aggregate Root として扱い、Employee / Skill Aggregate を内部に保持しません。

Aggregate 間参照は ID を利用します。

```text
EmployeeSkill
├── EmployeeId
└── SkillId
```

---

# 3. Domain Invariant

EmployeeSkill では以下の Rule を必ず維持します。

---

## 3.1 実務未経験

実務未経験の場合:

```text
workExperience = inexperienced
```

以下を必須とします。

```text
skillLevel = 1
experienceMonths = null
lastUsedYearMonth = null
```

つまり、

```text
未経験
+
Level 2〜5
```

は許可しません。

---

## 3.2 実務経験あり

実務経験ありの場合:

```text
workExperience = experienced
```

以下を必須とします。

```text
skillLevel = 1〜5
experienceMonths >= 1
lastUsedYearMonth 必須
```

経験期間 `0` は許可しません。

---

## 3.3 Employee + Skill重複禁止

同一 Employee に同一 Skill を複数登録できません。

```text
EmployeeId
+
SkillId
```

の組み合わせを一意とします。

Application で確認し、Database の UNIQUE Constraint でも最終防衛します。

---

## 3.4 inactive Skill

無効化済み Skill を新しい EmployeeSkill として登録することは禁止します。

```text
Skill.status = inactive
+
EmployeeSkill新規登録

→ 不可
```

既存 EmployeeSkill が参照している Skill が後から無効化された場合は、EmployeeSkill 自体を削除しません。

---

# 4. API上の表現

## 4.1 Skill Level

Skill Level は Integer として扱います。

```text
1
2
3
4
5
```

OpenAPI では以下に相当する制約を定義します。

```text
minimum: 1
maximum: 5
```

Domain では `SkillLevel` Value Object / Enum に変換します。

---

## 4.2 Work Experience

API 上では String Enum とします。

```text
experienced
inexperienced
```

Domain の Enum 内部表現を API へ直接公開しません。

---

## 4.3 Experience Period

API では経験期間を月数で扱います。

```text
experienceMonths
```

例:

```text
1年6か月
→ 18
```

Client 側で「年」「月」に分けて入力する場合でも、Backend API では月数へ正規化します。

これにより、

```text
experienceYears
experienceRemainingMonths
```

のような複数 Field を Domain/API に持ち込まない設計とします。

---

## 4.4 Last Used Year Month

最終利用年月は以下の形式とします。

```text
YYYY-MM
```

例:

```text
2026-08
```

実務未経験の場合は `null` とします。

---

# 5. Authorization

Role ごとの基本権限は以下とします。

| Role | 一覧・詳細 | 登録 | 更新 | 削除 |
|---|---:|---:|---:|---:|
| Administrator | ○ | ○ | ○ | ○ |
| Manager | ○ | ○ | ○ | ○ |
| SubManager | 担当社員のみ | 担当社員のみ | 担当社員のみ | 担当社員のみ |
| TeamLeader | 担当社員のみ | × | × | × |

Authorization は EmployeeSkill ID だけではなく、その EmployeeSkill が属する Employee まで確認して判定します。

Frontend / BFF の表示制御だけを Authorization としません。

---

# 6. 社員保有スキル一覧取得

## 6.1 Endpoint

```http
GET /api/v1/employees/{employeeId}/skills
```

指定 Employee の EmployeeSkill 一覧を取得します。

---

## 6.2 Path Parameter

| Parameter | Type | Required |
|---|---|---:|
| `employeeId` | integer | Yes |

---

## 6.3 Authentication

必須です。

---

## 6.4 Authorization

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

担当外 Employee の場合:

```text
403 FORBIDDEN
```

とします。

---

## 6.5 Query Parameters

MVP では以下を利用できます。

| Parameter | Type | Required | Description |
|---|---|---:|---|
| `skillCategoryId` | integer | No | SkillCategory Filter |
| `workExperience` | string | No | 実務経験Filter |
| `skillLevel` | integer | No | Skill Level Filter |
| `sort` | string | No | Sort対象 |
| `order` | string | No | `asc` / `desc` |

Employee 1人あたりの Skill 数は限定的と想定し、MVP では Pagination を使用しません。

---

## 6.6 Filtering

### SkillCategory

```text
skillCategoryId
```

例:

```text
GET /employees/1/skills?skillCategoryId=2
```

### Work Experience

```text
experienced
inexperienced
```

### Skill Level

```text
1〜5
```

---

## 6.7 Sorting

MVP では以下を許可します。

```text
sort=skillName
sort=skillCategory
sort=skillLevel
sort=lastUsedYearMonth
```

Order:

```text
asc
desc
```

Default:

```text
sort=skillName
order=asc
```

---

## 6.8 Response

```http
200 OK
```

例:

```json
{
  "data": [
    {
      "id": 101,
      "skill": {
        "id": 10,
        "name": "Laravel",
        "category": {
          "id": 2,
          "name": "Framework"
        },
        "status": "active"
      },
      "skillLevel": 4,
      "workExperience": "experienced",
      "experienceMonths": 36,
      "lastUsedYearMonth": "2026-08"
    },
    {
      "id": 102,
      "skill": {
        "id": 20,
        "name": "Go",
        "category": {
          "id": 1,
          "name": "Language"
        },
        "status": "active"
      },
      "skillLevel": 1,
      "workExperience": "inexperienced",
      "experienceMonths": null,
      "lastUsedYearMonth": null
    }
  ]
}
```

Skill が inactive の場合も、既存 EmployeeSkill では状態を含めて返します。

---

## 6.9 Employee不存在

指定 Employee が存在しない場合:

```text
404 EMPLOYEE_NOT_FOUND
```

---

## 6.10 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `EMPLOYEE_NOT_FOUND` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 6.11 Application Layer

```text
ListEmployeeSkillsQuery
        ↓
ListEmployeeSkillsQueryHandler
        ↓
EmployeeSkillQueryService
        ↓
Read Model
```

一覧取得では EmployeeSkill Aggregate を1件ずつ復元しません。

---

# 7. EmployeeSkill詳細取得

## 7.1 Endpoint

```http
GET /api/v1/employee-skills/{employeeSkillId}
```

---

## 7.2 Path Parameter

| Parameter | Type | Required |
|---|---|---:|
| `employeeSkillId` | integer | Yes |

---

## 7.3 Authentication

必須です。

---

## 7.4 Authorization

EmployeeSkill が所属する Employee に対して以下を適用します。

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

---

## 7.5 Response

```http
200 OK
```

例:

```json
{
  "id": 101,
  "employee": {
    "id": 1,
    "employeeNumber": "EMP0001",
    "name": "Taro Yamada"
  },
  "skill": {
    "id": 10,
    "name": "Laravel",
    "category": {
      "id": 2,
      "name": "Framework"
    },
    "status": "active"
  },
  "skillLevel": 4,
  "workExperience": "experienced",
  "experienceMonths": 36,
  "lastUsedYearMonth": "2026-08",
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-10T15:30:00+09:00"
}
```

---

## 7.6 Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `EMPLOYEE_SKILL_NOT_FOUND` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 7.7 Application Layer

```text
GetEmployeeSkillQuery
        ↓
GetEmployeeSkillQueryHandler
        ↓
EmployeeSkillQueryService
```

Read Use Case のため Aggregate 復元は必須としません。

---

# 8. EmployeeSkill登録

## 8.1 Endpoint

```http
POST /api/v1/employee-skills
```

---

## 8.2 Authentication

必須です。

---

## 8.3 Authorization

```text
Administrator
→ 全社員

Manager
→ 全社員

SubManager
→ 担当社員のみ

TeamLeader
→ 登録不可
```

---

## 8.4 Request

### 実務経験あり

```json
{
  "employeeId": 1,
  "skillId": 10,
  "skillLevel": 4,
  "workExperience": "experienced",
  "experienceMonths": 36,
  "lastUsedYearMonth": "2026-08"
}
```

### 実務未経験

```json
{
  "employeeId": 1,
  "skillId": 20,
  "skillLevel": 1,
  "workExperience": "inexperienced",
  "experienceMonths": null,
  "lastUsedYearMonth": null
}
```

---

## 8.5 Request Schema

| Field | Type | Required | Description |
|---|---|---:|---|
| `employeeId` | integer | Yes | Employee ID |
| `skillId` | integer | Yes | Skill ID |
| `skillLevel` | integer | Yes | 1〜5 |
| `workExperience` | string | Yes | `experienced` / `inexperienced` |
| `experienceMonths` | integer / null | Conditional | 経験月数 |
| `lastUsedYearMonth` | string / null | Conditional | 最終利用年月 |

---

# 9. Presentation Validation

Presentation Layer では基本的な入力形式を検証します。

```text
employeeId
- required
- integer

skillId
- required
- integer

skillLevel
- required
- integer
- 1〜5

workExperience
- required
- enum

experienceMonths
- integer
- minimum 1 when supplied

lastUsedYearMonth
- YYYY-MM format
```

以下のような業務 Rule は HTTP Validation だけに閉じ込めません。

```text
未経験ならLevel1のみ
経験ありならexperienceMonths必須
経験ありならlastUsedYearMonth必須
```

これらは Domain Invariant としても必ず検証します。

---

# 10. 登録時Domain Rule

## 10.1 Employee存在確認

Employee が存在しない場合:

```text
404 EMPLOYEE_NOT_FOUND
```

---

## 10.2 Skill存在確認

Skill が存在しない場合:

```text
404 SKILL_NOT_FOUND
```

---

## 10.3 inactive Skill

指定 Skill が inactive の場合:

```text
409 SKILL_INACTIVE
```

新規 EmployeeSkill 登録はできません。

---

## 10.4 重複登録

同一 Employee + Skill が既に存在する場合:

```text
409 EMPLOYEE_SKILL_ALREADY_EXISTS
```

Database の UNIQUE Constraint でも防御します。

---

## 10.5 実務未経験Rule

以下の場合は Domain Rule 違反です。

```text
workExperience = inexperienced
skillLevel != 1
```

Error:

```text
409 EMPLOYEE_SKILL_RULE_VIOLATION
```

同様に、

```text
workExperience = inexperienced
experienceMonths != null
```

または、

```text
lastUsedYearMonth != null
```

も許可しません。

---

## 10.6 実務経験ありRule

以下を満たす必要があります。

```text
workExperience = experienced
experienceMonths >= 1
lastUsedYearMonth != null
```

満たさない場合:

```text
409 EMPLOYEE_SKILL_RULE_VIOLATION
```

---

# 11. 登録Response

```http
201 Created
```

例:

```json
{
  "id": 101,
  "employee": {
    "id": 1,
    "employeeNumber": "EMP0001",
    "name": "Taro Yamada"
  },
  "skill": {
    "id": 10,
    "name": "Laravel",
    "category": {
      "id": 2,
      "name": "Framework"
    },
    "status": "active"
  },
  "skillLevel": 4,
  "workExperience": "experienced",
  "experienceMonths": 36,
  "lastUsedYearMonth": "2026-08",
  "createdAt": "2026-09-15T00:00:00+09:00",
  "updatedAt": "2026-09-15T00:00:00+09:00"
}
```

---

# 12. 登録Status Code

| Status | Error Code |
|---|---|
| 201 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `EMPLOYEE_NOT_FOUND` |
| 404 | `SKILL_NOT_FOUND` |
| 409 | `SKILL_INACTIVE` |
| 409 | `EMPLOYEE_SKILL_ALREADY_EXISTS` |
| 409 | `EMPLOYEE_SKILL_RULE_VIOLATION` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

# 13. 登録Application Layer

```text
CreateEmployeeSkillCommand
        ↓
CreateEmployeeSkillCommandHandler
        ↓
Employee / Skill存在・状態確認
        ↓
EmployeeSkill::register()
        ↓
EmployeeSkillRepository
```

1 Use Case = 1 Transaction とします。

---

# 14. EmployeeSkill更新

## 14.1 Endpoint

```http
PATCH /api/v1/employee-skills/{employeeSkillId}
```

---

## 14.2 Authentication

必須です。

---

## 14.3 Authorization

```text
Administrator
→ 全社員

Manager
→ 全社員

SubManager
→ 担当社員のみ

TeamLeader
→ 更新不可
```

対象 EmployeeSkill の Employee をもとに判定します。

---

## 14.4 Request

例:

```json
{
  "skillLevel": 5,
  "workExperience": "experienced",
  "experienceMonths": 48,
  "lastUsedYearMonth": "2026-09"
}
```

---

## 14.5 更新可能Field

MVP では以下を更新可能とします。

```text
skillLevel
workExperience
experienceMonths
lastUsedYearMonth
```

以下は更新できません。

```text
employeeId
skillId
```

Employee または Skill を変更したい場合は、

```text
既存EmployeeSkill削除
        ↓
新しいEmployeeSkill登録
```

とします。

これにより EmployeeSkill の Identity を明確に保ちます。

---

# 15. PATCH Semantics

Request に存在しない Property は変更しません。

```text
Propertyなし
→ 既存値を維持
```

`null` は明示的な値として扱います。

例えば実務経験ありから未経験へ変更する場合:

```json
{
  "skillLevel": 1,
  "workExperience": "inexperienced",
  "experienceMonths": null,
  "lastUsedYearMonth": null
}
```

のように明示します。

---

# 16. Partial UpdateとInvariant

PATCH では Request Field だけを個別に検証して終わりにしません。

既存状態と Request を組み合わせた更新後状態に対して、EmployeeSkill 全体の Invariant を再検証します。

例:

現在:

```text
workExperience = experienced
skillLevel = 4
experienceMonths = 24
lastUsedYearMonth = 2026-08
```

Request:

```json
{
  "workExperience": "inexperienced"
}
```

このまま適用すると、

```text
inexperienced
+
skillLevel = 4
```

となるため無効です。

したがって、

```text
409 EMPLOYEE_SKILL_RULE_VIOLATION
```

とします。

---

# 17. 更新時Skill状態

既存 EmployeeSkill が参照する Skill が inactive であっても、EmployeeSkill の経験情報更新は許可します。

```text
既存EmployeeSkill
+
inactive Skill

→ 更新可能
```

Skill 無効化は「新規選択禁止」であり、既存の経験情報を編集不能にするものではありません。

---

# 18. 更新Response

```http
200 OK
```

更新後の EmployeeSkill を返します。

```json
{
  "id": 101,
  "employee": {
    "id": 1,
    "employeeNumber": "EMP0001",
    "name": "Taro Yamada"
  },
  "skill": {
    "id": 10,
    "name": "Laravel",
    "category": {
      "id": 2,
      "name": "Framework"
    },
    "status": "active"
  },
  "skillLevel": 5,
  "workExperience": "experienced",
  "experienceMonths": 48,
  "lastUsedYearMonth": "2026-09",
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-15T00:10:00+09:00"
}
```

---

# 19. 更新Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `EMPLOYEE_SKILL_NOT_FOUND` |
| 409 | `EMPLOYEE_SKILL_RULE_VIOLATION` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

# 20. 更新Application Layer

```text
UpdateEmployeeSkillCommand
        ↓
UpdateEmployeeSkillCommandHandler
        ↓
EmployeeSkillRepository
        ↓
EmployeeSkill Behavior
```

Generic Setter は利用しません。

概念的には以下のような Domain Behavior を利用します。

```text
changeSkillLevel()
recordExperience()
markAsInexperienced()
updateLastUsedYearMonth()
```

実際のメソッド分割は Domain Layer 実装時に最終決定します。

---

# 21. EmployeeSkill削除

## 21.1 Endpoint

```http
DELETE /api/v1/employee-skills/{employeeSkillId}
```

社員から Skill 登録を解除します。

Skill Master 自体は削除しません。

---

## 21.2 Authentication

必須です。

---

## 21.3 Authorization

```text
Administrator
→ 全社員

Manager
→ 全社員

SubManager
→ 担当社員のみ

TeamLeader
→ 削除不可
```

---

## 21.4 Request

Request Body は不要です。

---

## 21.5 Response

成功時:

```http
204 No Content
```

Response Body は返しません。

---

## 21.6 Status Code

| Status | Error Code |
|---|---|
| 204 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `EMPLOYEE_SKILL_NOT_FOUND` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

## 21.7 Application Layer

```text
DeleteEmployeeSkillCommand
        ↓
DeleteEmployeeSkillCommandHandler
        ↓
EmployeeSkillRepository
```

1 Use Case = 1 Transaction とします。

EmployeeSkill は現在値のみ保持する MVP 方針のため、削除履歴自体は保持しません。

---

# 22. EmployeeSkill Response Schema

基本 Response は以下とします。

```json
{
  "id": 101,
  "employee": {
    "id": 1,
    "employeeNumber": "EMP0001",
    "name": "Taro Yamada"
  },
  "skill": {
    "id": 10,
    "name": "Laravel",
    "category": {
      "id": 2,
      "name": "Framework"
    },
    "status": "active"
  },
  "skillLevel": 4,
  "workExperience": "experienced",
  "experienceMonths": 36,
  "lastUsedYearMonth": "2026-08",
  "createdAt": "2026-09-01T10:00:00+09:00",
  "updatedAt": "2026-09-10T15:30:00+09:00"
}
```

---

# 23. 一覧Response Schema

社員保有 Skill 一覧では Employee 情報を各行に重複して含めません。

```json
{
  "data": [
    {
      "id": 101,
      "skill": {
        "id": 10,
        "name": "Laravel",
        "category": {
          "id": 2,
          "name": "Framework"
        },
        "status": "active"
      },
      "skillLevel": 4,
      "workExperience": "experienced",
      "experienceMonths": 36,
      "lastUsedYearMonth": "2026-08"
    }
  ]
}
```

---

# 24. Error Code

EmployeeSkill API 固有 Error Code は以下とします。

| Error Code | Status | Description |
|---|---:|---|
| `EMPLOYEE_SKILL_NOT_FOUND` | 404 | EmployeeSkill不存在 |
| `EMPLOYEE_SKILL_ALREADY_EXISTS` | 409 | Employee + Skill重複 |
| `EMPLOYEE_SKILL_RULE_VIOLATION` | 409 | Domain Invariant違反 |
| `SKILL_INACTIVE` | 409 | inactive Skillへの新規登録 |

他 Resource 由来:

```text
EMPLOYEE_NOT_FOUND
SKILL_NOT_FOUND
```

共通:

```text
UNAUTHENTICATED
FORBIDDEN
VALIDATION_ERROR
INTERNAL_SERVER_ERROR
```

---

# 25. Validation ErrorとDomain Error

形式的な入力不正:

```text
skillLevel = 10
experienceMonths = "abc"
lastUsedYearMonth = "2026/09"
```

は、

```text
422 VALIDATION_ERROR
```

とします。

一方、

```text
inexperienced + Level 3

experienced + experienceMonthsなし

experienced + lastUsedYearMonthなし
```

のように形式自体は正しいが Domain Rule に違反する場合は、

```text
409 EMPLOYEE_SKILL_RULE_VIOLATION
```

とします。

これにより、

```text
HTTP Input Validation
```

と、

```text
Domain Invariant
```

を区別します。

---

# 26. Database Constraint

Database では少なくとも以下を設定します。

```text
PRIMARY KEY
employee_skills.id
```

```text
FOREIGN KEY
employee_id → employees.id

skill_id → skills.id
```

```text
UNIQUE
(employee_id, skill_id)
```

可能な Rule は CHECK Constraint も利用します。

ただし Business Rule の Source of Truth を Database のみに置きません。

```text
Domain Rule
+
Application Check
+
Database Constraint
```

の多層防御とします。

---

# 27. Duplicate Race Condition

以下の競合を考慮します。

```text
Request A
Employee 1 + Skill 10 登録

Request B
Employee 1 + Skill 10 登録
```

Application で事前確認しても同時実行 Race は完全には防げません。

そのため Database UNIQUE Constraint を最終防衛とします。

Constraint 違反を Infrastructure Exception のまま返さず、

```text
409 EMPLOYEE_SKILL_ALREADY_EXISTS
```

へ変換します。

---

# 28. Transaction

Read:

```text
ListEmployeeSkills
GetEmployeeSkill
```

では原則として明示 Transaction を開始しません。

Write:

```text
CreateEmployeeSkill
UpdateEmployeeSkill
DeleteEmployeeSkill
```

では、

```text
1 Use Case = 1 Transaction
```

とします。

Transaction Boundary は Application Handler に置きます。

---

# 29. Concurrency

MVP では Optimistic Lock を導入しません。

```text
READ COMMITTED
+
Last Write Wins
```

を基本とします。

ただし Employee + Skill 重複については UNIQUE Constraint により整合性を保証します。

---

# 30. Domain / API境界

Domain Model を直接 API Response として返しません。

```text
EmployeeSkill Aggregate
        ↓
Application
        ↓
Presentation
        ↓
EmployeeSkill Response Schema
```

以下は API 契約へ直接公開しません。

```text
EmployeeSkill Entity
EmployeeId Value Object
SkillId Value Object
SkillLevel Value Object / Enum
WorkExperience Enum
Eloquent Model
Database Column
```

---

# 31. Query / Command対応

## Query

```text
GET /employees/{employeeId}/skills
→ ListEmployeeSkillsQuery

GET /employee-skills/{employeeSkillId}
→ GetEmployeeSkillQuery
```

## Command

```text
POST /employee-skills
→ CreateEmployeeSkillCommand

PATCH /employee-skills/{employeeSkillId}
→ UpdateEmployeeSkillCommand

DELETE /employee-skills/{employeeSkillId}
→ DeleteEmployeeSkillCommand
```

各 Command / Query に Handler を1つ対応させます。

---

# 32. Authorization判定

Authorization は以下の流れを基本とします。

```text
Authenticated User
        ↓
Role確認
        ↓
対象Employee確認
        ↓
Assignment確認
        ↓
許可 / 拒否
```

SubManager:

```text
SubManagerAssignment
```

TeamLeader:

```text
TeamLeaderAssignment
```

を参照します。

EmployeeSkill ID を直接指定した場合でも対象 Employee まで辿って判定します。

---

# 33. OpenAPI定義方針

OpenAPI 実装時には概ね以下の Schema を作成します。

```text
EmployeeSkillSummary
EmployeeSkillDetail
EmployeeSkillListResponse

CreateEmployeeSkillRequest
UpdateEmployeeSkillRequest

SkillLevel
WorkExperience
YearMonth
```

共通 Schema:

```text
ErrorResponse
ValidationErrorResponse
```

を再利用します。

---

# 34. MVPで採用しないAPI

MVP では以下を作成しません。

```text
EmployeeSkill一括登録
EmployeeSkill一括更新
EmployeeSkill一括削除
EmployeeSkill履歴取得
EmployeeSkill変更履歴
Skill経験Timeline
Skill Level履歴
CSV Import
CSV Export
```

また、

```text
PATCH /employee-skills/{id}
```

で `employeeId` や `skillId` を変更することも許可しません。

---

# 35. 決定事項

EmployeeSkill API の MVP 仕様として以下を採用します。

```text
GET
/employees/{employeeId}/skills

GET
/employee-skills/{employeeSkillId}

POST
/employee-skills

PATCH
/employee-skills/{employeeSkillId}

DELETE
/employee-skills/{employeeSkillId}
```

EmployeeSkill は単なる中間 Table ではなく Domain Model とします。

---

## Domain Invariant

```text
実務未経験

workExperience = inexperienced
skillLevel = 1
experienceMonths = null
lastUsedYearMonth = null
```

```text
実務経験あり

workExperience = experienced
skillLevel = 1〜5
experienceMonths >= 1
lastUsedYearMonth 必須
```

---

## 重複

```text
EmployeeId + SkillId
```

を一意とします。

```text
Application Check
+
Database UNIQUE Constraint
```

の二重防御を行います。

---

## inactive Skill

```text
新規EmployeeSkill登録
→ 禁止

既存EmployeeSkill参照
→ 許可

既存EmployeeSkill更新
→ 許可
```

---

## Authorization

```text
Administrator
全社員の閲覧・登録・更新・削除

Manager
全社員の閲覧・登録・更新・削除

SubManager
担当社員のみ閲覧・登録・更新・削除

TeamLeader
担当社員のみ閲覧
```

---

## Experience Period

API では、

```text
experienceMonths
```

による総月数で管理します。

---

## Update

```text
employeeId
skillId
```

は変更不可とします。

Skill を変更する場合は、

```text
削除
↓
再登録
```

とします。

---

## Read

```text
Query Service
Read Model
```

を使用します。

---

## Write

```text
EmployeeSkill Aggregate
Repository
Domain Behavior
1 Use Case = 1 Transaction
```

を基本とします。

この設計を `EmployeeSkill API` の OpenAPI 定義および Laravel Backend 実装の基準とします。
