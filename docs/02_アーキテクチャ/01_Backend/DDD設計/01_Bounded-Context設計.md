# Bounded Context 設計

## 1. 基本方針

DDDの学習目的として、
Application全体を業務上の意味ごとにBounded Contextへ分割する。

ただしMVPではContextを細かく分けすぎない。

第一候補：

- Employee Management Context
- Skill Management Context
- Access Control Context

---

# 2. Employee Management Context

社員情報を管理するContext。

主なEntity：

- Employee
- Department
- Userとの対応情報

主な責務：

- 社員登録
- 社員編集
- 所属部署
- 在籍状態
- 退職日
- 退職社員の保持
- 社員検索の基本情報

主なDomain Rule：

- Employee Numberは一意
- Employeeは必ずDepartmentに所属する
- RETIREDの場合はretirement_date必須
- ACTIVE / LEAVEの場合はretirement_dateを持たない

---

# 3. Skill Management Context

社員の保有Skillを管理するContext。

今回のApplicationのCore Domain候補。

主なEntity：

- SkillCategory
- Skill
- EmployeeSkill

主なValue Object候補：

- SkillLevel
- ExperienceMonths
- LastUsedMonth

主な責務：

- SkillCategory管理
- Skill Master管理
- EmployeeへのSkill登録
- EmployeeSkill編集
- EmployeeSkill無効化
- 経験年数管理
- Skill Level管理
- 最終利用年月管理
- Skill検索
- Skill別Employee検索

主なDomain Rule：

    実務経験なし
        ↓
    ExperienceMonths = 0
    SkillLevel = Level 1
    LastUsedMonth = null

    実務経験あり
        ↓
    ExperienceMonths >= 1
    SkillLevel = Level 1〜5
    LastUsedMonth required

---

# 4. Access Control Context

Application利用者と権限を管理するContext。

主なEntity候補：

- User
- Role
- Assignment

主な概念：

- 管理ユーザー
- 権限管理可能な管理ユーザー
- サブマネージャー
- チームリーダー

主な責務：

- Login可能Userの管理
- Role付与
- Role解除
- 担当社員設定
- 閲覧可能範囲判定
- 編集可能範囲判定

主なDomain Rule：

- 権限管理可能な管理ユーザーを0人にできない
- サブマネージャーは担当Employeeのみ編集可能
- チームリーダーは担当Employeeのみ閲覧可能
- 1 Employeeに複数サブマネージャーを割り当て可能
- 1 Employeeに複数チームリーダーを割り当て可能

---

# 5. Context Map

概念：

    Employee Management
          |
          | Employee ID
          v
    Skill Management

    Employee Management
          |
          | Employee / User relation
          v
    Access Control

    Access Control
          |
          | Authorization
          v
    Employee Management
          +
    Skill Management

---

# 6. Employee Management → Skill Management

Skill Managementでは、

    Employee

そのものの詳細情報を
独自に管理しない。

必要なのは基本的に、

    EmployeeId

である。

例えばEmployeeSkill：

    EmployeeSkill
    ├── EmployeeId
    ├── SkillId
    ├── ExperienceMonths
    └── SkillLevel

とする。

Skill Domain Entityが
Employee Domain Entity全体を直接保持しないことを第一候補とする。

---

# 7. Context間のID参照

Contextをまたぐ場合は、
Domain EntityそのものではなくIDで参照する。

例：

    EmployeeId

    UserId

    SkillId

これによりContext間の結合を弱くする。

---

# 8. Shared Kernel

MVPではShared Kernelを最小限にする。

候補：

    Domain/Shared/
    ├── ValueObjects/
    │   └── IDs
    └── Exceptions/

ただし何でもSharedへ置かない。

「どこに置けばよいか分からないもの」を
Sharedへ逃がさない。

---

# 9. Core Domain

今回のApplicationで最も重要なDomain：

**Skill Management**

とする。

理由：

Applicationの主目的が、

    社員の保有技術・能力を把握する

ことだから。

特に、

    EmployeeSkill

周辺のBusiness Ruleを
最も丁寧にDomain Model化する。

---

# 10. Supporting Domain

以下をSupporting Domainとして扱う。

## Employee Management

Skill Managementを成立させるために必要。

## Access Control

Application利用・権限制御に必要。

重要ではあるが、
Application固有の競争優位の中心ではない。

---

# 11. Generic Subdomain

Authentication自体はGeneric Subdomainとして扱う。

対象：

- Better Auth
- Laravel Sanctum
- Password Authentication
- Session
- Backend Credential

独自の認証アルゴリズムをDomainとして作らない。

既存Framework / Libraryを利用する。

Application User AuthenticationはLaravelが担当し、
Browser Session ManagementはBetter Authが担当する。

---

# 12. ContextとInfrastructure

Bounded Contextは、
Database TableやStorage単位では決めない。

例えば：

    users
    personal_access_tokens

がPostgreSQLに存在し、

    Better Auth Session
    Backend Credential

がRedisに存在していても、

    Better Auth Session
    Sanctum Token
    Backend Credential

はInfrastructure / Generic Authentication寄り。

一方、

    User Role
    Assignment
    Permission Rule

はAccess Control Domain。

Storage方式や技術的なTableとDomain Boundaryを混同しない。

Better Auth SessionやBackend Credentialを
Access Control DomainのEntityとして扱わない。

Application User、Role、Assignmentなどの
業務上の概念とAuthentication Infrastructureを分離する。

---

# 13. Directory構成案

    app/
    ├── Domain/
    │   ├── EmployeeManagement/
    │   │   ├── Entities/
    │   │   ├── ValueObjects/
    │   │   ├── Repositories/
    │   │   └── Exceptions/
    │   │
    │   ├── SkillManagement/
    │   │   ├── Entities/
    │   │   ├── ValueObjects/
    │   │   ├── Repositories/
    │   │   ├── Services/
    │   │   └── Exceptions/
    │   │
    │   ├── AccessControl/
    │   │   ├── Entities/
    │   │   ├── ValueObjects/
    │   │   ├── Repositories/
    │   │   └── Services/
    │   │
    │   └── Shared/
    │
    ├── Application/
    │   ├── EmployeeManagement/
    │   ├── SkillManagement/
    │   └── AccessControl/
    │
    └── Infrastructure/
        ├── Persistence/
        ├── Auth/
        └── Logging/

---

# 14. Application LayerもContext単位で分ける

例：

    Application/
    ├── EmployeeManagement/
    │   ├── Commands/
    │   └── Queries/
    │
    ├── SkillManagement/
    │   ├── Commands/
    │   └── Queries/
    │
    └── AccessControl/
        ├── Commands/
        └── Queries/

これにより、

    Domain
    Application

双方で同じ業務境界を維持する。

---

# 15. User Storyとの対応

例えば：

    社員を登録する
        ↓
    Employee Management

    社員にPHP Skillを登録する
        ↓
    Skill Management

    サブマネージャーを設定する
        ↓
    Access Control

となる。

User StoryがどのContextに属するかを
明確にできる。

---

# 16. Contextを分けすぎない

MVPでは例えば以下を独立Contextにしない。

- Department Management
- SkillCategory Management
- Authentication
- Reporting
- Search

理由：

現在の規模では境界が細かすぎるため。

例えばDepartmentは、

    Employee Management

の一部として扱う。

SkillCategoryは、

    Skill Management

の一部として扱う。

---

# 17. Search

社員検索は複数Contextを横断する可能性がある。

例：

    Department
      +
    Employee
      +
    Skill
      +
    ExperienceMonths

このようなQueryは、
Domain Entityを無理に組み合わせるより、

    Application Query Service
    Query Object
    Read Model

を利用することを検討する。

特に検索系はDDDのAggregate境界に無理に合わせない。

---

# 18. Dashboard

Dashboardも複数Contextを横断する。

例：

    在籍Employee
        +
    Skill
        ↓
    Skill保有人数

これはDomain Entityの操作ではなく、
Read Model / Query側で実装することを第一候補とする。

---

# 19. Aggregate候補

現時点の第一候補：

## Employee Management

Aggregate Root：

    Employee

DepartmentはMaster Entityとして扱う。

---

## Skill Management

Aggregate Root候補：

    Skill

    EmployeeSkill

ただしEmployeeSkillを独立Aggregateとするかは
次のAggregate設計で検討する。

---

## Access Control

Aggregate Root候補：

    User

担当社員Assignmentの扱いは
権限Domain設計時に決定する。

---

# 20. 決定候補

### Bounded Context

- Employee Management
- Skill Management
- Access Control

### Core Domain

Skill Management

### Supporting Domain

- Employee Management
- Access Control

### Generic Subdomain

Authentication

### Context間参照

Domain EntityではなくIDを基本とする。

### Shared Kernel

最小限にする。

### Search / Dashboard

必要に応じてRead Model / Query Serviceを利用する。
