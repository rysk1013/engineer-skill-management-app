# Dashboard API

Engineer Skill Management App の Dashboard に関する Backend API を定義します。

Dashboard は在籍社員の Skill 保有状況を把握するための参照専用機能です。

Domain Aggregate を大量に復元して集計するのではなく、CQRS の Read Side として Query Service / Read Model を利用し、PostgreSQL 上で効率的に集計します。

API 契約の Source of Truth は OpenAPI とし、本ドキュメントは OpenAPI 定義前の個別 API 設計として位置付けます。

---

# 1. 対象API

MVP では以下の API を提供します。

| Use Case | Method | Endpoint |
|---|---|---|
| Dashboard Summary取得 | GET | `/api/v1/dashboard/summary` |
| Skill別集計取得 | GET | `/api/v1/dashboard/skills` |
| SkillCategory別集計取得 | GET | `/api/v1/dashboard/skill-categories` |

Dashboard は参照専用とし、Command API は持ちません。

---

# 2. Dashboard基本方針

Dashboard の目的は、組織内の Skill 保有状況を俯瞰することです。

MVP では主に以下を確認できるようにします。

```text id="ydw3kn"
在籍社員数

登録Skill数

EmployeeSkill登録数

Skill保有社員数

実務経験者数

実務未経験者数

SkillCategory別の保有状況

Skill別の保有状況
```

Dashboard は詳細な BI / Analytics 基盤とはしません。

複雑な履歴分析や時系列分析は MVP 対象外とします。

---

# 3. 集計対象Employee

Dashboard のすべての集計では在籍社員のみを対象とします。

```text id="1u0b3g"
Employee.employmentStatus = employed
```

退職社員:

```text id="uj7irj"
Employee.employmentStatus = retired
```

は集計対象外です。

---

## 3.1 EmployeeSkillとの関係

退職社員の EmployeeSkill が Database に保持されていても Dashboard には含めません。

概念的には、

```text id="1jnmio"
EmployeeSkill
    ↓
Employee
    ↓
employmentStatus = employed
    ↓
Dashboard集計対象
```

とします。

---

# 4. Skill状態

Dashboard では原則として active Skill を集計対象とします。

```text id="8i2nys"
Skill.status = active
```

inactive Skill は、新しい Skill Management の対象ではないため通常の Dashboard 集計から除外します。

ただし既存 EmployeeSkill との関連自体は保持されます。

inactive Skill の履歴確認が必要な場合は EmployeeSkill API から確認します。

---

# 5. Authorization

Dashboard は以下の Role が利用できます。

| Role | Dashboard |
|---|---:|
| Administrator | ○ |
| Manager | ○ |
| SubManager | ○ |
| TeamLeader | ○ |

ただし表示対象 Employee の Scope は Role に応じて制限します。

---

## 5.1 Administrator

```text id="d4gzv7"
全在籍社員
```

を集計対象とします。

---

## 5.2 Manager

```text id="nsb01j"
全在籍社員
```

を集計対象とします。

---

## 5.3 SubManager

担当 Employee のみを集計対象とします。

```text id="n1jdns"
SubManagerAssignment
        ↓
担当Employee
        ↓
employmentStatus = employed
```

---

## 5.4 TeamLeader

担当 Employee のみを集計対象とします。

```text id="hz4c9m"
TeamLeaderAssignment
        ↓
担当Employee
        ↓
employmentStatus = employed
```

---

# 6. Authorization Scope

Dashboard API では Client から `userId` を指定して Scope を変更できません。

```text id="plbsck"
Authenticated User
        ↓
Role
        ↓
Assignment
        ↓
Dashboard Scope
```

を Backend 側で決定します。

例えば SubManager が、

```text id="6atn6b"
?userId=another-user
```

のような Query Parameter を利用して他 User の集計範囲を見ることはできません。

---

# 7. Dashboard Summary取得

## 7.1 Endpoint

```http id="n7f1ia"
GET /api/v1/dashboard/summary
```

Dashboard 上部などで使用する全体 Summary を取得します。

---

## 7.2 Authentication

必須です。

---

## 7.3 Authorization

すべての Application User が利用できます。

Role に応じた Employee Scope を Backend で適用します。

---

## 7.4 Query Parameters

MVP では Query Parameter を使用しません。

---

# 8. Summary Response

```http id="2e8e4b"
200 OK
```

例:

```json id="it5ntj"
{
  "employeeCount": 120,
  "skillCount": 65,
  "employeeSkillCount": 840,
  "experiencedEmployeeSkillCount": 720,
  "inexperiencedEmployeeSkillCount": 120
}
```

---

# 9. Summary Field

| Field | Type | Description |
|---|---|---|
| `employeeCount` | integer | 集計Scope内の在籍社員数 |
| `skillCount` | integer | active Skill数 |
| `employeeSkillCount` | integer | 集計対象EmployeeのEmployeeSkill数 |
| `experiencedEmployeeSkillCount` | integer | 実務経験ありEmployeeSkill数 |
| `inexperiencedEmployeeSkillCount` | integer | 実務未経験EmployeeSkill数 |

---

# 10. employeeCount

以下を数えます。

```text id="a0a2aa"
COUNT(Employee)
```

条件:

```text id="1ah2ex"
employmentStatus = employed
AND
Authorization Scope内
```

---

# 11. skillCount

active Skill 数を表します。

```text id="3c2cvb"
COUNT(Skill)
WHERE status = active
```

`skillCount` は Skill Master 自体の件数です。

Administrator / Manager / SubManager / TeamLeader で値を変えません。

つまり、

```text id="b6em0u"
組織全体のactive Skill Master数
```

を返します。

---

# 12. employeeSkillCount

集計対象 Employee が保有する active Skill の EmployeeSkill 件数を表します。

```text id="iktrmg"
Employee
    ↓
employmentStatus = employed
    ↓
Authorization Scope
    ↓
EmployeeSkill
    ↓
Skill.status = active
```

---

# 13. experiencedEmployeeSkillCount

以下を満たす EmployeeSkill の件数です。

```text id="krt27b"
Employee = 集計対象
Skill.status = active
workExperience = experienced
```

---

# 14. inexperiencedEmployeeSkillCount

以下を満たす EmployeeSkill の件数です。

```text id="6evjjv"
Employee = 集計対象
Skill.status = active
workExperience = inexperienced
```

そのため基本的に、

```text id="ghfmke"
employeeSkillCount
=
experiencedEmployeeSkillCount
+
inexperiencedEmployeeSkillCount
```

となります。

---

# 15. Summary Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 500 | `INTERNAL_SERVER_ERROR` |

通常の Application Role であれば Dashboard 自体へのアクセスは許可されるため、403 は Role / Account 状態等によって Dashboard 利用自体が許可されない場合に使用します。

---

# 16. Summary Application Layer

```text id="jny0q5"
GetDashboardSummaryQuery
        ↓
GetDashboardSummaryQueryHandler
        ↓
DashboardQueryService
        ↓
DashboardSummaryReadModel
```

Aggregate は復元しません。

---

# 17. Skill別集計取得

## 17.1 Endpoint

```http id="27hdjf"
GET /api/v1/dashboard/skills
```

Skill ごとの保有状況を取得します。

---

## 17.2 Authentication

必須です。

---

## 17.3 Authorization

すべての Application User が利用できます。

Role に応じた Employee Scope を適用します。

---

# 18. Skill別Query Parameters

| Parameter | Type | Required | Description |
|---|---|---:|---|
| `page` | integer | No | Page番号 |
| `perPage` | integer | No | 1 Page件数 |
| `skillCategoryId` | integer | No | SkillCategory Filter |
| `keyword` | string | No | Skill名検索 |
| `sort` | string | No | Sort対象 |
| `order` | string | No | `asc` / `desc` |

---

# 19. Pagination

Offset Pagination を使用します。

Default:

```text id="oh8w3s"
page = 1
perPage = 20
```

Maximum:

```text id="d5jzy7"
perPage = 100
```

---

# 20. Filtering

SkillCategory:

```text id="g9gzbn"
skillCategoryId
```

例:

```text id="fgqkfr"
GET /api/v1/dashboard/skills?skillCategoryId=2
```

---

# 21. Keyword Search

Skill 名を対象とします。

```text id="9twxyj"
keyword=Laravel
```

---

# 22. Sorting

MVP では以下を許可します。

```text id="thd88z"
sort=skillName
sort=employeeCount
sort=experiencedEmployeeCount
sort=inexperiencedEmployeeCount
```

Default:

```text id="y0t1pn"
sort=employeeCount
order=desc
```

同値の場合は安定した結果を返すため、Skill ID 昇順を Secondary Sort とします。

---

# 23. Skill別Response

```http id="ysnpdl"
200 OK
```

例:

```json id="fcd27d"
{
  "data": [
    {
      "skill": {
        "id": 10,
        "name": "Laravel",
        "category": {
          "id": 2,
          "name": "Framework"
        }
      },
      "employeeCount": 40,
      "experiencedEmployeeCount": 35,
      "inexperiencedEmployeeCount": 5
    },
    {
      "skill": {
        "id": 20,
        "name": "TypeScript",
        "category": {
          "id": 1,
          "name": "Language"
        }
      },
      "employeeCount": 32,
      "experiencedEmployeeCount": 28,
      "inexperiencedEmployeeCount": 4
    }
  ],
  "pagination": {
    "page": 1,
    "perPage": 20,
    "total": 65,
    "totalPages": 4
  }
}
```

---

# 24. Skill別集計Field

| Field | Description |
|---|---|
| `employeeCount` | Skillを登録している対象Employee数 |
| `experiencedEmployeeCount` | Skillを実務経験ありで登録している対象Employee数 |
| `inexperiencedEmployeeCount` | Skillを実務未経験で登録している対象Employee数 |

Employee + Skill は EmployeeSkill の UNIQUE Constraint により一意であるため、

```text id="h9wsxi"
EmployeeSkill件数
=
Skillを保有するEmployee数
```

として扱えます。

---

# 25. Skill別集計対象

以下のみ対象とします。

```text id="wgykmm"
Employee.employmentStatus = employed
AND
Employee = Authorization Scope内
AND
Skill.status = active
```

active Skill で EmployeeSkill が0件の場合も Skill 一覧には含めます。

例:

```json id="jps7dk"
{
  "skill": {
    "id": 99,
    "name": "Rust",
    "category": {
      "id": 1,
      "name": "Language"
    }
  },
  "employeeCount": 0,
  "experiencedEmployeeCount": 0,
  "inexperiencedEmployeeCount": 0
}
```

これにより Skill Master と実際の保有状況を比較できます。

---

# 26. Skill別Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 422 | `VALIDATION_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

# 27. Skill別Application Layer

```text id="8p0t95"
ListDashboardSkillsQuery
        ↓
ListDashboardSkillsQueryHandler
        ↓
DashboardQueryService
        ↓
DashboardSkillReadModel
```

---

# 28. SkillCategory別集計取得

## 28.1 Endpoint

```http id="zzxmmw"
GET /api/v1/dashboard/skill-categories
```

SkillCategory 単位で Skill 保有状況を集計します。

---

## 28.2 Authentication

必須です。

---

## 28.3 Authorization

すべての Application User が利用できます。

Role に応じた Employee Scope を適用します。

---

# 29. SkillCategory別Query Parameters

MVP では Query Parameter を使用しません。

SkillCategory は少数の Master Data であるため Pagination も使用しません。

---

# 30. SkillCategory別Response

```http id="45m7a1"
200 OK
```

例:

```json id="5eh04j"
{
  "data": [
    {
      "category": {
        "id": 1,
        "name": "Language"
      },
      "skillCount": 15,
      "employeeCount": 90,
      "employeeSkillCount": 300
    },
    {
      "category": {
        "id": 2,
        "name": "Framework"
      },
      "skillCount": 20,
      "employeeCount": 85,
      "employeeSkillCount": 250
    }
  ]
}
```

---

# 31. SkillCategory別Field

## skillCount

Category に所属する active Skill 数です。

```text id="mmztnd"
COUNT(active Skill)
```

---

## employeeCount

Category 内のいずれかの active Skill を1つ以上登録している対象 Employee 数です。

Employee が同じ Category 内で複数 Skill を保有していても1人として数えます。

概念的には、

```text id="an9qzu"
COUNT(DISTINCT employee_id)
```

です。

---

## employeeSkillCount

Category 内の active Skill に紐づく EmployeeSkill の総件数です。

例えば、

```text id="i04w20"
Employee A

PHP
Go
TypeScript
```

を保有しており、すべて Language Category の場合、

```text id="q05ejd"
employeeCount = 1
employeeSkillCount = 3
```

となります。

---

# 32. SkillCategory 0件Data

Category に active Skill または EmployeeSkill が存在しない場合も Category 自体は返します。

例:

```json id="q0zntq"
{
  "category": {
    "id": 7,
    "name": "Database"
  },
  "skillCount": 0,
  "employeeCount": 0,
  "employeeSkillCount": 0
}
```

これにより Dashboard の Category 表示を Master Data と一致させます。

---

# 33. SkillCategory Sort

MVP では Category 名昇順とします。

```text id="og4uqy"
category.name ASC
```

Client から Sort 条件は指定しません。

---

# 34. SkillCategory Status Code

| Status | Error Code |
|---|---|
| 200 | - |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 500 | `INTERNAL_SERVER_ERROR` |

---

# 35. SkillCategory Application Layer

```text id="7g48bj"
ListDashboardSkillCategoriesQuery
        ↓
ListDashboardSkillCategoriesQueryHandler
        ↓
DashboardQueryService
        ↓
DashboardSkillCategoryReadModel
```

---

# 36. Dashboard Query Service

Dashboard 専用 Query Service を Infrastructure Layer に実装します。

概念的には、

```text id="h1gckg"
Application
DashboardQueryService Interface
        ↑
        │ implements
        │
Infrastructure
PostgreSQLDashboardQueryService
```

とします。

Application Layer は Eloquent / SQL に依存しません。

---

# 37. Read Model

Dashboard では専用 Read Model を利用します。

概念例:

```text id="16rr8h"
DashboardSummaryReadModel

DashboardSkillReadModel

DashboardSkillCategoryReadModel
```

これらは Domain Entity ではありません。

Business Behavior を持たず、Query 結果を Application / Presentation に渡すための Read Model とします。

---

# 38. Aggregateを利用した集計を行わない

以下の実装は避けます。

```text id="rrz6cr"
EmployeeRepository
    ↓
全Employee Aggregate復元
    ↓
EmployeeSkill Aggregate復元
    ↓
PHPでcount()
```

Dashboard は大量データを扱う可能性があるため、Database に集計を任せます。

推奨:

```text id="4z15j5"
PostgreSQL
    ↓
JOIN
WHERE
COUNT
COUNT DISTINCT
GROUP BY
    ↓
Read Model
```

---

# 39. Query例

実際の SQL は Infrastructure 実装時に決定しますが、概念的には以下のような処理を利用します。

```text id="uw7g3c"
employees
    ↓
employee_skills
    ↓
skills
    ↓
skill_categories
```

条件:

```text id="z51rnk"
employees.employment_status = employed
skills.status = active
```

さらに Authorization Scope を適用します。

---

# 40. SubManager Scope

SubManager の場合、概念的には、

```text id="sp18ow"
sub_manager_assignments
        ↓
employee_id
        ↓
employees
        ↓
employee_skills
```

で集計対象を限定します。

---

# 41. TeamLeader Scope

TeamLeader の場合も同様に、

```text id="dk1ylo"
team_leader_assignments
        ↓
employee_id
        ↓
employees
        ↓
employee_skills
```

で Scope を限定します。

---

# 42. Scope重複

同一 Employee に対して Assignment が重複しない Database Constraint を設定しています。

ただし JOIN により将来的に重複 Row が発生する可能性を考慮し、Employee 数を数える場合は必要に応じて、

```text id="p7o9pq"
COUNT(DISTINCT employee_id)
```

を使用します。

---

# 43. Dashboard ResponseとDomain Model

Dashboard API では Domain Entity を Response として返しません。

```text id="um41cd"
PostgreSQL
    ↓
Query Service
    ↓
Read Model
    ↓
Response Schema
```

とします。

以下は直接公開しません。

```text id="npum1d"
Employee Aggregate
EmployeeSkill Aggregate
Skill Aggregate
Eloquent Model
Database Row
SQL Query
```

---

# 44. Transaction

Dashboard API は Read Only のため、原則として明示的な Transaction を開始しません。

```text id="9hh1j6"
GET Dashboard
→ No explicit transaction
```

複数 Query を1回の Dashboard API 内で実行する場合、MVP では Snapshot の完全一致を保証しません。

READ COMMITTED の通常 Read とします。

---

# 45. Consistency

Dashboard は管理・分析用途の Read Model であり、金融処理のような厳密な Snapshot Consistency は要求しません。

同時に EmployeeSkill が更新された場合、

```text id="prpnbm"
Summary取得時点
Skill集計取得時点
```

で一時的に値が異なる可能性を許容します。

Frontend も複数 Dashboard API 間の完全な Atomic Consistency を前提としません。

---

# 46. Cache

MVP では Backend 独自の Dashboard Cache を導入しません。

```text id="55aprr"
Request
    ↓
Query Service
    ↓
PostgreSQL
```

を基本とします。

性能測定後に必要性が確認された場合のみ、

```text id="rj1cbi"
Application Cache
Redis
Precomputed Read Model
Materialized View
```

等を検討します。

先に Cache を導入しません。

---

# 47. Performance

Dashboard Query では以下を重視します。

```text id="pcmxzc"
必要ColumnのみSELECT

N+1を発生させない

Database側で集計

適切なIndex

不要なAggregate復元をしない
```

Index は Database 設計および実際の `EXPLAIN` 結果を基に調整します。

---

# 48. Error Response

Dashboard 固有の Business Error Code は原則として持ちません。

Dashboard は Read API であり、通常は以下の共通 Error を利用します。

```text id="fm7q35"
UNAUTHENTICATED
FORBIDDEN
VALIDATION_ERROR
INTERNAL_SERVER_ERROR
```

Filter Parameter 等が不正な場合:

```text id="9ibvrx"
422 VALIDATION_ERROR
```

とします。

---

# 49. Empty Data

集計対象が存在しない場合も `404` にはしません。

Summary:

```json id="ml5czb"
{
  "employeeCount": 0,
  "skillCount": 65,
  "employeeSkillCount": 0,
  "experiencedEmployeeSkillCount": 0,
  "inexperiencedEmployeeSkillCount": 0
}
```

Skill:

```json id="zef3nh"
{
  "data": [],
  "pagination": {
    "page": 1,
    "perPage": 20,
    "total": 0,
    "totalPages": 0
  }
}
```

Category は Master が存在する限り0件集計として返します。

---

# 50. Query / Handler対応

```text id="j54mq8"
GET /dashboard/summary
→ GetDashboardSummaryQuery
→ GetDashboardSummaryQueryHandler
```

```text id="00xnrw"
GET /dashboard/skills
→ ListDashboardSkillsQuery
→ ListDashboardSkillsQueryHandler
```

```text id="rfp9cq"
GET /dashboard/skill-categories
→ ListDashboardSkillCategoriesQuery
→ ListDashboardSkillCategoriesQueryHandler
```

すべて Query Side とします。

Command はありません。

---

# 51. OpenAPI定義方針

OpenAPI 実装時には概ね以下の Schema を作成します。

```text id="wskefn"
DashboardSummary

DashboardSkill
DashboardSkillListResponse

DashboardSkillCategory
DashboardSkillCategoryListResponse
```

既存 Schema:

```text id="5x3qgf"
SkillCategorySummary
Pagination
ErrorResponse
ValidationErrorResponse
```

は可能な範囲で共通 Components として再利用します。

---

# 52. MVPで採用しない機能

MVP では以下を Dashboard API に含めません。

```text id="hr0jvz"
時系列推移
Skill増減履歴
Skill Level推移
EmployeeSkill更新履歴
退職社員分析
期間比較
Department別高度分析
ランキング専用API
グラフ専用API
CSV Export
Excel Export
Custom Dashboard
Dashboard Widget設定
Real-time更新
WebSocket
```

必要になったものを将来個別 Use Case として追加します。

---

# 53. Dashboardと履歴

EmployeeSkill は現在値のみ保持するため、

```text id="1n0n09"
先月
↓
今月
```

のような Skill 状況の時系列比較は現状の Data Model では行いません。

将来必要になった場合は、

```text id="t9j15w"
Snapshot
History Table
Event
Analytics Store
```

等を別途検討します。

Dashboard のためだけに MVP で履歴機構を追加しません。

---

# 54. 決定事項

Dashboard API の MVP 仕様として以下を採用します。

```text id="pkolgu"
GET
/dashboard/summary

GET
/dashboard/skills

GET
/dashboard/skill-categories
```

---

## 集計対象

```text id="n6u9bf"
在籍Employeeのみ

AND

active Skillのみ
```

退職 Employee と inactive Skill は通常の Dashboard 集計から除外します。

---

## Authorization Scope

```text id="5s7g7v"
Administrator
→ 全在籍Employee

Manager
→ 全在籍Employee

SubManager
→ 担当在籍Employee

TeamLeader
→ 担当在籍Employee
```

Scope は Backend で決定し、Client から変更できません。

---

## Summary

```text id="u6fb18"
employeeCount

skillCount

employeeSkillCount

experiencedEmployeeSkillCount

inexperiencedEmployeeSkillCount
```

を返します。

---

## Skill別集計

```text id="ocgh8r"
Skill

employeeCount

experiencedEmployeeCount

inexperiencedEmployeeCount
```

を返します。

active Skill で EmployeeSkill が0件の場合も集計結果へ含めます。

---

## SkillCategory別集計

```text id="fpx43d"
SkillCategory

skillCount

employeeCount

employeeSkillCount
```

を返します。

---

## CQRS

Dashboard は完全に Read Side とします。

```text id="rrb4g8"
Query
    ↓
Query Handler
    ↓
DashboardQueryService
    ↓
Read Model
```

Command は持ちません。

---

## Database集計

```text id="ntg6ad"
JOIN
WHERE
COUNT
COUNT DISTINCT
GROUP BY
```

等を PostgreSQL 側で実行します。

Aggregate を大量復元して Application 側で集計しません。

---

## Transaction

```text id="2ffol4"
Read Only

原則明示Transactionなし
```

複数 Dashboard API 間の Snapshot Consistency は保証しません。

---

## Cache

```text id="2fj6qd"
MVPではCacheなし
```

Performance Measurement 後に必要な場合のみ導入します。

---

この設計を `Dashboard API` の OpenAPI 定義および Laravel Backend 実装の基準とします。
