# MVP API一覧

Engineer Skill Management App の MVP で必要となる Backend API を一覧化します。

本ドキュメントでは API の全体像と実装対象を整理し、Request / Response、Authorization、Error Code などの詳細仕様は各個別 API 設計で定義します。

API の Base Path は以下とします。

```text
/api/v1
```

---

## 1. 基本方針

MVP API は以下の領域に分けます。

```text
Employee Management
Skill Management
EmployeeSkill
Access Control
Dashboard
```

加えて、Employee Management から参照するための Department API を最低限用意します。

```text
Employee Management
├── Employee
└── Department（参照のみ）

Skill Management
├── SkillCategory
└── Skill

EmployeeSkill

Access Control
├── User
├── SubManagerAssignment
└── TeamLeaderAssignment

Dashboard
```

API は Use Case を基準として設計し、単に Database Table に CRUD API を1対1で作成することはしません。

---

# 2. Employee Management

## 2.1 社員一覧取得

```http
GET /api/v1/employees
```

### 用途

社員一覧を取得します。

主な利用場面:

- 社員管理画面
- 社員検索
- 担当社員選択
- EmployeeSkill 管理対象の選択

### 主な機能

- Pagination
- Keyword Search
- Department Filter
- Employment Status Filter
- Sorting

---

## 2.2 社員詳細取得

```http
GET /api/v1/employees/{employeeId}
```

### 用途

指定した社員の基本情報を取得します。

EmployeeSkill 一覧については EmployeeSkill API から取得し、Employee Aggregate と Skill 情報を巨大な Response にまとめない方針とします。

---

## 2.3 社員登録

```http
POST /api/v1/employees
```

### 用途

社員を新規登録します。

主な入力対象:

```text
社員番号
氏名
部署
雇用状態等のEmployee情報
```

MVP 要件に含まれない役職、メールアドレス、画像等は扱いません。

---

## 2.4 社員更新

```http
PATCH /api/v1/employees/{employeeId}
```

### 用途

社員の基本情報を更新します。

部分更新のため `PATCH` を使用します。

---

## 2.5 社員退職

```http
POST /api/v1/employees/{employeeId}/retirement
```

### 用途

社員を退職状態へ変更します。

単純な Property 更新ではなく、退職という Domain Operation として扱います。

退職社員は即時削除せず保持します。

---

# 3. Department

Department は MVP では独立した管理機能を提供せず、Employee の登録・更新・検索で利用する参照データとして扱います。

## 3.1 部署一覧取得

```http
GET /api/v1/departments
```

### 用途

以下の UI で部署候補を取得します。

- 社員登録
- 社員更新
- 社員検索Filter

MVP では以下の API は提供しません。

```text
POST /departments
PATCH /departments/{departmentId}
DELETE /departments/{departmentId}
```

Department の管理機能が必要になった段階で追加します。

---

# 4. Skill Management

Skill Management は Core Domain とします。

```text
SkillCategory
      │
      ▼
    Skill
```

---

## 4.1 SkillCategory一覧取得

```http
GET /api/v1/skill-categories
```

### 用途

スキルカテゴリ一覧を取得します。

主な利用場面:

- Skill 登録
- Skill 検索
- EmployeeSkill 登録
- Dashboard

---

## 4.2 SkillCategory登録

```http
POST /api/v1/skill-categories
```

### 用途

管理者が新しいスキルカテゴリを登録します。

自由入力による EmployeeSkill 登録は行わず、事前に Master として登録します。

---

## 4.3 SkillCategory更新

```http
PATCH /api/v1/skill-categories/{skillCategoryId}
```

### 用途

スキルカテゴリ情報を更新します。

---

## 4.4 Skill一覧取得

```http
GET /api/v1/skills
```

### 用途

Skill Master の一覧を取得します。

主な機能:

- Pagination
- Keyword Search
- SkillCategory Filter
- Active / Inactive Filter
- Sorting

EmployeeSkill 登録 UI では、原則として有効な Skill のみ選択可能とします。

---

## 4.5 Skill詳細取得

```http
GET /api/v1/skills/{skillId}
```

### 用途

指定した Skill の詳細を取得します。

---

## 4.6 Skill登録

```http
POST /api/v1/skills
```

### 用途

新しい Skill を Master に登録します。

例:

```text
Laravel
PHP
PostgreSQL
Docker
AWS
```

EmployeeSkill へ自由入力で Skill 名を登録することはできません。

---

## 4.7 Skill更新

```http
PATCH /api/v1/skills/{skillId}
```

### 用途

Skill 名や Category 等を更新します。

---

## 4.8 Skill無効化

```http
POST /api/v1/skills/{skillId}/deactivation
```

### 用途

Skill を無効化します。

Skill は完全削除しません。

既存の EmployeeSkill との関連を保持したまま、新規選択対象から除外します。

---

# 5. EmployeeSkill

EmployeeSkill は Employee と Skill の単なる中間 Table ではなく、MVP の重要な Domain Model として扱います。

主な情報:

```text
Employee
Skill
Skill Level
実務経験有無
経験期間
最終利用年月
```

---

## 5.1 社員保有スキル一覧取得

```http
GET /api/v1/employees/{employeeId}/skills
```

### 用途

指定した社員が保有する Skill 一覧を取得します。

主な利用場面:

- 社員詳細
- スキル管理
- 社員スキル編集

---

## 5.2 EmployeeSkill詳細取得

```http
GET /api/v1/employee-skills/{employeeSkillId}
```

### 用途

EmployeeSkill の詳細を取得します。

更新画面等で使用します。

---

## 5.3 EmployeeSkill登録

```http
POST /api/v1/employee-skills
```

### 用途

社員に Skill を登録します。

主な Domain Rule:

```text
同一Employee + Skillの重複禁止

実務未経験
→ Level 1のみ
→ 最終利用年月なし

実務経験あり
→ 経験期間1か月以上
→ 最終利用年月必須
```

---

## 5.4 EmployeeSkill更新

```http
PATCH /api/v1/employee-skills/{employeeSkillId}
```

### 用途

以下の情報を更新します。

```text
Skill Level
実務経験有無
経験期間
最終利用年月
```

更新後も EmployeeSkill の Domain Invariant を満たす必要があります。

---

## 5.5 EmployeeSkill削除

```http
DELETE /api/v1/employee-skills/{employeeSkillId}
```

### 用途

Employee から Skill 登録を解除します。

Skill Master 自体は削除しません。

---

# 6. Access Control

Access Control では、アプリケーションを利用する管理系 User と担当社員 Assignment を管理します。

MVP の Role:

```text
Administrator
Manager
SubManager
TeamLeader
```

一般社員は Application User として利用しません。

---

# 7. User

## 7.1 User一覧取得

```http
GET /api/v1/users
```

### 用途

Application User の一覧を取得します。

主な利用場面:

- User 管理
- Role 管理
- Assignment 設定

---

## 7.2 User詳細取得

```http
GET /api/v1/users/{userId}
```

### 用途

指定した User の Role・権限情報を取得します。

---

## 7.3 User登録

```http
POST /api/v1/users
```

### 用途

Application を利用する User を登録します。

Role:

```text
Administrator
Manager
SubManager
TeamLeader
```

を設定します。

---

## 7.4 User更新

```http
PATCH /api/v1/users/{userId}
```

### 用途

User の Role や権限情報を更新します。

Administrator については、

```text
canManagePermissions
```

の変更を含む場合があります。

以下の Invariant を必ず維持します。

```text
Administrator
AND
canManagePermissions = true

のUserを最低1人維持する
```

必要箇所では Transaction と悲観ロックを利用します。

---

# 8. SubManager Assignment

SubManager は担当社員のみ操作できます。

1人の社員に複数の SubManager を割り当てることを許可します。

---

## 8.1 SubManager Assignment一覧取得

```http
GET /api/v1/sub-manager-assignments
```

### 用途

SubManager と担当 Employee の Assignment を取得します。

必要に応じて以下で Filter します。

```text
userId
employeeId
```

---

## 8.2 SubManager Assignment登録

```http
POST /api/v1/sub-manager-assignments
```

### 用途

SubManager に Employee を割り当てます。

---

## 8.3 SubManager Assignment解除

```http
DELETE /api/v1/sub-manager-assignments/{assignmentId}
```

### 用途

SubManager と Employee の担当関係を解除します。

---

# 9. TeamLeader Assignment

TeamLeader は担当社員を閲覧できますが、編集はできません。

1人の社員に複数の TeamLeader を割り当てることを許可します。

---

## 9.1 TeamLeader Assignment一覧取得

```http
GET /api/v1/team-leader-assignments
```

### 用途

TeamLeader と担当 Employee の Assignment を取得します。

---

## 9.2 TeamLeader Assignment登録

```http
POST /api/v1/team-leader-assignments
```

### 用途

TeamLeader に Employee を割り当てます。

---

## 9.3 TeamLeader Assignment解除

```http
DELETE /api/v1/team-leader-assignments/{assignmentId}
```

### 用途

TeamLeader と Employee の担当関係を解除します。

---

# 10. Dashboard

Dashboard は CQRS の Read Side として扱います。

Aggregate を大量に復元して集計するのではなく、Query Service / Read Model を利用します。

集計対象は在籍社員のみです。

---

## 10.1 Dashboard Summary取得

```http
GET /api/v1/dashboard/summary
```

### 用途

Dashboard の基本指標を取得します。

例:

```text
在籍社員数
登録Skill数
EmployeeSkill登録数
その他MVPで必要なSummary
```

詳細な Response 項目は Dashboard API 設計で確定します。

---

## 10.2 Skill集計取得

```http
GET /api/v1/dashboard/skills
```

### 用途

Skill 単位の保有状況を集計します。

例:

```text
Laravelを保有する社員数
PHPを保有する社員数
AWSを保有する社員数
```

必要に応じて Skill Level や実務経験有無による集計を行います。

---

## 10.3 SkillCategory集計取得

```http
GET /api/v1/dashboard/skill-categories
```

### 用途

SkillCategory 単位で社員の Skill 保有状況を集計します。

例:

```text
言語
Framework
OS
Middleware
Cloud
Development Tool
```

---

# 11. MVP API一覧

MVP で実装する API は以下とします。

| Domain | Use Case | Method | Endpoint |
|---|---|---|---|
| Employee | 社員一覧取得 | GET | `/employees` |
| Employee | 社員詳細取得 | GET | `/employees/{employeeId}` |
| Employee | 社員登録 | POST | `/employees` |
| Employee | 社員更新 | PATCH | `/employees/{employeeId}` |
| Employee | 社員退職 | POST | `/employees/{employeeId}/retirement` |
| Department | 部署一覧取得 | GET | `/departments` |
| SkillCategory | 一覧取得 | GET | `/skill-categories` |
| SkillCategory | 登録 | POST | `/skill-categories` |
| SkillCategory | 更新 | PATCH | `/skill-categories/{skillCategoryId}` |
| Skill | 一覧取得 | GET | `/skills` |
| Skill | 詳細取得 | GET | `/skills/{skillId}` |
| Skill | 登録 | POST | `/skills` |
| Skill | 更新 | PATCH | `/skills/{skillId}` |
| Skill | 無効化 | POST | `/skills/{skillId}/deactivation` |
| EmployeeSkill | 社員保有スキル一覧取得 | GET | `/employees/{employeeId}/skills` |
| EmployeeSkill | 詳細取得 | GET | `/employee-skills/{employeeSkillId}` |
| EmployeeSkill | 登録 | POST | `/employee-skills` |
| EmployeeSkill | 更新 | PATCH | `/employee-skills/{employeeSkillId}` |
| EmployeeSkill | 削除 | DELETE | `/employee-skills/{employeeSkillId}` |
| User | 一覧取得 | GET | `/users` |
| User | 詳細取得 | GET | `/users/{userId}` |
| User | 登録 | POST | `/users` |
| User | 更新 | PATCH | `/users/{userId}` |
| SubManagerAssignment | 一覧取得 | GET | `/sub-manager-assignments` |
| SubManagerAssignment | 登録 | POST | `/sub-manager-assignments` |
| SubManagerAssignment | 解除 | DELETE | `/sub-manager-assignments/{assignmentId}` |
| TeamLeaderAssignment | 一覧取得 | GET | `/team-leader-assignments` |
| TeamLeaderAssignment | 登録 | POST | `/team-leader-assignments` |
| TeamLeaderAssignment | 解除 | DELETE | `/team-leader-assignments/{assignmentId}` |
| Dashboard | Summary取得 | GET | `/dashboard/summary` |
| Dashboard | Skill集計取得 | GET | `/dashboard/skills` |
| Dashboard | SkillCategory集計取得 | GET | `/dashboard/skill-categories` |

Base Path:

```text
/api/v1
```

をすべての Endpoint に付与します。

---

# 12. MVPでは作成しないAPI

MVP では以下を対象外とします。

```text
Department管理API
資格管理API
Soft Skill API
Position管理API
Team管理API
Employee画像API
Employee Email管理API
Audit Log閲覧API
退職社員物理削除API
Skill物理削除API
Bulk Import API
Bulk Update API
Public API
GraphQL API
```

必要になった段階で別途設計します。

---

# 13. 個別API設計との対応

MVP API は以下のファイルで詳細設計します。

```text
03_システム設計/03_API/
├── README.md
├── 01_API仕様管理.md
├── 02_OpenAPI運用方式.md
├── 03_API共通仕様.md
├── 04_Employee-API.md
├── 05_Skill-API.md
├── 06_EmployeeSkill-API.md
├── 07_Access-Control-API.md
└── 08_Dashboard-API.md
```

Department API は `04_Employee-API.md` に含めます。

SkillCategory API は `05_Skill-API.md` に含めます。

User / SubManagerAssignment / TeamLeaderAssignment は `07_Access-Control-API.md` に含めます。

---

# 14. 個別APIで決定する項目

各 API の詳細設計では以下を決定します。

```text
Use Case
Endpoint
HTTP Method
Authentication
Authorization
Path Parameter
Query Parameter
Request Schema
Response Schema
HTTP Status
Error Code
Pagination
Filtering
Search
Sorting
Domain Rule
Application Use Caseとの対応
```

この段階では Endpoint の全体像を固定し、Schema の詳細は個別 API 設計で確定します。

---

# 15. 決定事項

Engineer Skill Management App の MVP API は以下の構成とします。

```text
Employee Management
├── Employee CRUD相当
├── Retirement
└── Department参照

Skill Management
├── SkillCategory
├── Skill
└── Skill Deactivation

EmployeeSkill
├── List
├── Detail
├── Create
├── Update
└── Delete

Access Control
├── User
├── SubManager Assignment
└── TeamLeader Assignment

Dashboard
├── Summary
├── Skill Aggregation
└── SkillCategory Aggregation
```

MVP API の洗い出し完了後は、以下の順番で個別 API 設計を行います。

```text
04_Employee-API.md
        ↓
05_Skill-API.md
        ↓
06_EmployeeSkill-API.md
        ↓
07_Access-Control-API.md
        ↓
08_Dashboard-API.md
```

個別 API 設計完了後、OpenAPI の実ファイル作成へ進みます。
