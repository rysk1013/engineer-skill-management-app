# Infrastructure / Persistence 設計 決定版

## 1. 基本方針

Infrastructure Layerは、
Framework・Database・外部技術の詳細を担当する。

対象：

- Laravel
- Eloquent
- PostgreSQL
- Transaction
- Database Lock
- Laravel Sanctum
- Auth.js Session Persistence
- Logging
- External API

Domain / Application Layerは、
Laravel・Eloquent・PostgreSQLへ直接依存しない。

依存方向：

    Presentation
        ↓
    Application
        ↓
      Domain
        ↑
        |
    Infrastructure

InfrastructureがDomain / Application側のInterfaceを実装する。

---

# 2. Persistence全体構成

Write：

    Application Handler
        ↓
    TransactionManager
        ↓
    Repository Interface
        ↓
    Domain Aggregate
        ↓
    Repository Implementation
        ↓
    Mapper
        ↓
    Eloquent Model
        ↓
    PostgreSQL

Read：

    Query Handler
        ↓
    Query Service Interface
        ↓
    Eloquent Query Service
        ↓
    Query Builder / SQL
        ↓
    PostgreSQL
        ↓
    Read Model

---

# 3. Eloquent Model

Eloquent ModelはInfrastructure Layerに配置する。

主な責務：

- Table Mapping
- Column Mapping
- Eloquent Relation
- Persistence Cast
- Query Builder
- Database保存

Domain Business Ruleは持たせない。

---

# 4. Eloquent Model配置

第一候補：

    app/
    └── Infrastructure/
        └── Persistence/
            └── Eloquent/
                └── Models/
                    ├── DepartmentModel.php
                    ├── EmployeeModel.php
                    ├── UserModel.php
                    ├── SkillCategoryModel.php
                    ├── SkillModel.php
                    ├── EmployeeSkillModel.php
                    ├── SubManagerAssignmentModel.php
                    └── TeamLeaderAssignmentModel.php

---

# 5. Domain Entityとの分離

以下を明確に分ける。

    Domain Employee
        ≠
    Eloquent EmployeeModel

    Domain Skill
        ≠
    Eloquent SkillModel

    Domain EmployeeSkill
        ≠
    Eloquent EmployeeSkillModel

Eloquent ModelをDomain Entityとして利用しない。

---

# 6. Eloquent Relation

Infrastructure都合のRelationは定義してよい。

例：

    EmployeeModel
        belongsTo DepartmentModel

    EmployeeSkillModel
        belongsTo EmployeeModel
        belongsTo SkillModel

ただしRelation Objectを
Domain Aggregateへそのまま渡さない。

---

# 7. Repository Interface

Repository InterfaceはDomain Layerへ配置する。

例：

    Domain/
    └── EmployeeManagement/
        └── Repositories/
            └── EmployeeRepository.php

RepositoryはAggregate単位で設計する。

---

# 8. Repository Interface候補

## Employee

    EmployeeRepository

## Department

    DepartmentRepository

## User

    UserRepository

## SkillCategory

    SkillCategoryRepository

## Skill

    SkillRepository

## EmployeeSkill

    EmployeeSkillRepository

---

# 9. Repositoryの責務

担当：

- Aggregate取得
- Aggregate保存
- Aggregate単位の存在確認
- Business Key重複確認

担当しない：

- HTTP処理
- Authorization
- Response生成
- Transaction開始
- Business Ruleそのもの
- Dashboard / 複雑検索

---

# 10. EmployeeRepository例

概念：

    interface EmployeeRepository
    {
        public function findById(
            EmployeeId $id
        ): ?Employee;

        public function findByEmployeeNumber(
            EmployeeNumber $employeeNumber
        ): ?Employee;

        public function existsByEmployeeNumber(
            EmployeeNumber $employeeNumber
        ): bool;

        public function save(
            Employee $employee
        ): void;
    }

Eloquent ModelをInterfaceへ露出しない。

---

# 11. Repository Implementation

Infrastructure側で実装する。

例：

    EmployeeRepository
        ↑
    EloquentEmployeeRepository

配置：

    Infrastructure/
    └── Persistence/
        └── Eloquent/
            └── Repositories/

---

# 12. Repository Implementation候補

    EloquentDepartmentRepository

    EloquentEmployeeRepository

    EloquentUserRepository

    EloquentSkillCategoryRepository

    EloquentSkillRepository

    EloquentEmployeeSkillRepository

    EloquentSubManagerAssignmentRepository

    EloquentTeamLeaderAssignmentRepository

---

# 13. Mapper

Mapperは、

    Eloquent Model
        ↔
    Domain Aggregate

の変換を担当する。

配置：

    Infrastructure/
    └── Persistence/
        └── Eloquent/
            └── Mappers/

---

# 14. Mapper候補

- DepartmentMapper
- EmployeeMapper
- UserMapper
- SkillCategoryMapper
- SkillMapper
- EmployeeSkillMapper

AssignmentはDomain Modelが軽量なため、
専用Mapperを必須にはしない。

---

# 15. Mapperの責務

Persistence表現とDomain表現を変換する。

例：EmployeeSkill

Database：

    has_work_experience = true
    experience_months = 42
    skill_level = 3
    last_used_date = 2026-08-01

Domain：

    WorkExperience::Experienced
    ExperienceMonths(42)
    SkillLevel::Level3
    LastUsedMonth(2026, 8)

---

# 16. Mapper Method

第一候補：

    toDomain()

    fillModel()

例：

    final class EmployeeMapper
    {
        public function toDomain(
            EmployeeModel $model
        ): Employee {
            // ...
        }

        public function fillModel(
            Employee $employee,
            EmployeeModel $model
        ): void {
            // ...
        }
    }

---

# 17. MapperにQueryを書かない

Mapperは変換だけを担当する。

以下は禁止する。

    Mapper
        ↓
    Department Query

    Mapper
        ↓
    Repository呼び出し

MapperからDatabaseへ追加アクセスしない。

---

# 18. Domain Getter

MapperがPersistenceへ変換するため、
Aggregateに読み取り専用Getterを持たせてよい。

例：

    id()

    employeeNumber()

    departmentId()

    employmentStatus()

    retirementDate()

Setterは公開しない。

---

# 19. Save Strategy

Repositoryの、

    save()

でINSERT / UPDATEを抽象化する。

Flow：

    Domain Aggregate
        ↓
    Primary KeyでModel検索
        ↓
    存在
        → UPDATE

    不存在
        → INSERT

Application Layerは新規・更新Persistenceの違いを意識しない。

---

# 20. Sequence先取りID

Domain Aggregateは保存前にIDを持つ。

ID生成：

    PostgreSQL Sequence
        ↓
    ID Generator
        ↓
    Domain ID Value Object

Repository保存時には取得済みIDを明示的に設定する。

---

# 21. ID Generator Interface

Aggregateごとに型安全なPortを利用する。

例：

    EmployeeIdGenerator

    DepartmentIdGenerator

    UserIdGenerator

    SkillCategoryIdGenerator

    SkillIdGenerator

    EmployeeSkillIdGenerator

Interface：

    Application Layer

Implementation：

    Infrastructure Layer

---

# 22. ID Generator Implementation

配置：

    Infrastructure/
    └── Persistence/
        └── IdGenerators/

候補：

    PostgreSqlEmployeeIdGenerator.php

    PostgreSqlDepartmentIdGenerator.php

    PostgreSqlUserIdGenerator.php

    PostgreSqlSkillCategoryIdGenerator.php

    PostgreSqlSkillIdGenerator.php

    PostgreSqlEmployeeSkillIdGenerator.php

---

# 23. Sequence Detail

Application / Domainは以下を知らない。

    nextval()

    employees_id_seq

Sequence NameなどのPostgreSQL固有情報は
Infrastructureへ閉じ込める。

---

# 24. Sequence欠番

Sequenceの欠番は許容する。

    ID取得
        ↓
    Transaction Rollback
        ↓
    次のIDへ進む

Database PKに連続性を要求しない。

---

# 25. TransactionManager

Transaction BoundaryはApplication Layerが決定する。

Interface：

    TransactionManager

概念：

    interface TransactionManager
    {
        public function run(
            callable $callback
        ): mixed;
    }

---

# 26. LaravelTransactionManager

Infrastructure側で実装する。

内部：

    DB::transaction(...)

を利用する。

Application LayerへLaravel Facadeを露出しない。

---

# 27. Transaction Boundary

基本：

    1 Write UseCase
        =
    1 Transaction

とする。

Transaction開始 / Commit / RollbackはHandlerが管理する。

---

# 28. Repository内Transaction

Repositoryが独自にTransactionを開始しない。

理由：

複数Repositoryを使うUseCaseを
1 Transactionとして扱えなくなるため。

---

# 29. Permission Manager Rule

確定Rule：

    ADMINISTRATOR
    AND
    can_manage_permissions = true

のUserを最低1人維持する。

このRuleは複数Rowにまたがるため、
通常のCHECK Constraintだけでは保証できない。

---

# 30. Permission Manager Concurrency

単純な、

    count
        ↓
    update

ではRace Conditionが発生する。

そのため悲観Lockを利用する。

採用：

    SELECT ... FOR UPDATE

Laravel Infrastructureでは：

    lockForUpdate()

を利用する。

---

# 31. Lock対象

現在のPermission Manager User RowをLockする。

条件：

    role = 'ADMINISTRATOR'

    can_manage_permissions = true

さらにLock順序を安定させるため、

    ORDER BY id ASC

を第一候補とする。

---

# 32. UserRepository Lock Method

MVP第一候補：

    findPermissionManagersForUpdate()

をUserRepositoryへ追加する。

概念：

    public function findPermissionManagersForUpdate(): array;

Infrastructure実装：

    UserModel::query()
        ->where(...)
        ->orderBy('id')
        ->lockForUpdate()
        ->get();

---

# 33. PermissionManagementPolicy

取得したPermission Manager集合を使い、
Domain Policyで最低人数Ruleを判定する。

PolicyはSQLやEloquentを知らない。

概念：

    PermissionManagementPolicy
        ↓
    最後の1人を解除できない

---

# 34. Lock対象UseCase

最低限以下で利用する。

- DisablePermissionManagement
- ChangeUserRole
- DisableUser
- DeleteUser

Target UserがPermission Managerの場合に適用する。

---

# 35. Lockしなくてよい操作

Permission Manager人数を増やすだけの、

    enablePermissionManagement()

については最低人数Ruleだけを見るならLock不要。

Role整合性はDomainで確認する。

---

# 36. Isolation Level

PostgreSQL標準：

    READ COMMITTED

を利用する。

Application全体をSERIALIZABLEにはしない。

重要なInvariantだけ明示的にRow Lockする。

---

# 37. Optimistic Lock

MVPでは導入しない。

以下のような、

    version

Columnは現時点では追加しない。

一般的な同時編集については
Last Write Winsを許容する。

重要なInvariantのみ悲観Lockで守る。

---

# 38. Assignment Concurrency

以下はDatabase UNIQUE Constraintを最終保証とする。

    UNIQUE(
        user_id,
        employee_id
    )

同一Assignmentの同時登録時に
SELECT FOR UPDATEまでは行わない。

---

# 39. EmployeeSkill Concurrency

同様に、

    UNIQUE(
        employee_id,
        skill_id
    )

で同時重複登録を防ぐ。

Application側でも事前存在確認する。

---

# 40. UNIQUE Race Condition

Applicationで、

    exists()

を確認しても、
同時Requestでは競合が起こり得る。

そのため、

    Application事前確認
        +
    Database UNIQUE

を併用する。

---

# 41. Constraint Name

MigrationではConstraintへ明示名を付ける。

例：

    uq_employees_employee_number

    uq_users_login_id

    uq_skills_name

    uq_employee_skills_employee_skill

    chk_employee_skills_work_experience

InfrastructureでDatabase Errorを判別しやすくする。

---

# 42. Exception Mapping

Database UNIQUE Constraint違反を
必要に応じてApplication Exceptionへ変換する。

例：

    PostgreSQL UniqueViolation
        ↓
    DuplicateEmployeeNumber

すべてのDB Exceptionを独自Wrapする必要はない。

意味のあるBusiness Errorだけ変換する。

---

# 43. Read Query

一覧 / 検索 / Dashboardは、
Domain Repositoryへ詰め込まない。

専用Query Serviceを利用する。

候補：

    EmployeeSearchQueryService

    EmployeeDetailQueryService

    DashboardQueryService

---

# 44. Query Service Interface

Application側でInterfaceを定義する。

Infrastructure：

    EloquentEmployeeSearchQueryService

等が実装する。

ReadではDomain Aggregateの復元を必須としない。

---

# 45. Read Model

Query Serviceは専用DTO / Read Modelを返す。

候補：

    EmployeeListItem

    EmployeeDetail

    SkillSummary

    DashboardSummary

Eloquent ModelをPresentationへ直接返さない。

---

# 46. Dashboard

Dashboardは、

    COUNT
    GROUP BY
    JOIN

等を直接利用してよい。

大量AggregateをRepository経由で復元しない。

---

# 47. Eloquent Cast

Persistence向けCastは利用する。

例：

    retirement_date
        → date

    last_used_date
        → date

    is_active
        → boolean

Domain Value Object / Enumへの変換はMapperが担当する。

---

# 48. Eloquent Model Events

以下へBusiness Ruleを書かない。

- creating
- updating
- deleting

Domain RuleはDomain Aggregateへ置く。

UseCase FlowはApplication Layerへ置く。

---

# 49. Laravel Observer

Business Ruleには使用しない。

必要になった場合、

- Audit
- Cache invalidation

などInfrastructure都合の副作用で検討する。

---

# 50. External Side Effect

Database Transaction内で
外部Network Requestを行わないことを基本とする。

避ける：

    Lock
        ↓
    External HTTP
        ↓
    Long Wait
        ↓
    Commit

Lock保持時間を短くする。

---

# 51. User無効化と認証

User無効化時には、

- User DB更新
- Auth.js Session失効
- Sanctum Token失効

が必要になる。

DB Transactionと外部副作用の境界は分離する。

第一候補：

    DB Transaction
        ↓
    Commit
        ↓
    Authentication Side Effect

具体的な失敗時RecoveryはAuthentication詳細設計で扱う。

---

# 52. Outbox Pattern

MVPでは導入しない。

将来的に、

- 確実な外部通知
- 非同期処理
- Event連携

が必要になった段階で再検討する。

---

# 53. Domain Event

DDDを採用するが、
MVPではDomain Eventを必須にしない。

必要な副作用が明確になった段階で導入する。

候補：

    EmployeeRetired

    UserDisabled

    SkillDisabled

---

# 54. Service Container Binding

Laravel Service Containerで、

    Interface
        ↓
    Implementation

をBindingする。

例：

    EmployeeRepository
        ↓
    EloquentEmployeeRepository

    TransactionManager
        ↓
    LaravelTransactionManager

---

# 55. Service Provider

第一候補：

    PersistenceServiceProvider

でPersistence関連Bindingを行う。

候補：

- Repository
- TransactionManager
- ID Generator
- Query Service

---

# 56. Composition Root

Laravel Service Providerを
Infrastructure構成のComposition Rootとして利用する。

Domain / Applicationから、

    app(...)

等でService Containerを直接参照しない。

DependencyはConstructor Injectionを利用する。

---

# 57. Directory構成

第一候補：

    app/
    ├── Domain/
    │
    ├── Application/
    │   └── Shared/
    │       └── Transactions/
    │           └── TransactionManager.php
    │
    ├── Infrastructure/
    │   ├── Persistence/
    │   │   ├── Eloquent/
    │   │   │   ├── Models/
    │   │   │   ├── Repositories/
    │   │   │   └── Mappers/
    │   │   │
    │   │   ├── IdGenerators/
    │   │   ├── Queries/
    │   │   └── Transactions/
    │   │
    │   ├── Authentication/
    │   ├── Logging/
    │   └── Providers/
    │
    └── Http/

---

# 58. Persistence詳細構成

    Infrastructure/
    └── Persistence/
        ├── Eloquent/
        │   ├── Models/
        │   │   ├── DepartmentModel.php
        │   │   ├── EmployeeModel.php
        │   │   ├── UserModel.php
        │   │   ├── SkillCategoryModel.php
        │   │   ├── SkillModel.php
        │   │   ├── EmployeeSkillModel.php
        │   │   ├── SubManagerAssignmentModel.php
        │   │   └── TeamLeaderAssignmentModel.php
        │   │
        │   ├── Repositories/
        │   └── Mappers/
        │
        ├── IdGenerators/
        │
        ├── Queries/
        │
        └── Transactions/
            └── LaravelTransactionManager.php

---

# 59. Testing Strategy

## Domain Unit Test

Infrastructureを利用しない。

対象：

- Aggregate Invariant
- Value Object
- Domain Policy

## Application Test

Repository Fake / InMemory実装を必要に応じて使用する。

対象：

- Handler
- Cross Aggregate Flow
- Exception

## Infrastructure Integration Test

実PostgreSQLを利用する。

対象：

- Repository
- Mapper
- Sequence
- Transaction
- Lock
- Constraint
- Query Service

SQLiteでは代替しない。

---

# 60. Concurrency Integration Test

Permission Manager最低人数Ruleでは、
並行Transaction Testを作成することを推奨する。

確認：

- 2人から同時解除して0人にならない
- 最後の1人を解除できない
- Role降格でもRuleが有効
- User無効化でもRuleが有効

---

# 61. Repository決定事項

Repository Interface：

    Domain Layer

Repository Implementation：

    Infrastructure Layer

Write Aggregate単位で利用する。

複雑検索をRepositoryへ詰め込まない。

---

# 62. Mapper決定事項

Mapper：

    Infrastructure Layer

責務：

    Persistence
        ↔
    Domain

の変換のみ。

Database QueryやBusiness Ruleを持たない。

---

# 63. Transaction決定事項

Transaction Boundary：

    Application Handler

基本：

    1 Write UseCase
        =
    1 Transaction

Implementation：

    LaravelTransactionManager

---

# 64. Lock決定事項

Permission Manager最低人数Rule：

    SELECT FOR UPDATE

を利用する。

Infrastructure：

    lockForUpdate()

Application / DomainへLaravel APIを露出しない。

Isolation Level：

    READ COMMITTED

---

# 65. ID決定事項

Domain Aggregate：

    bigint
    +
    PostgreSQL Sequence先取り

Application Port：

    Aggregate別ID Generator

Infrastructure：

    PostgreSQL Sequence Implementation

---

# 66. Read決定事項

一覧・検索・Dashboard：

    Query Service
        +
    Read Model

を利用する。

Domain Aggregate復元を必須としない。

---

# 67. Infrastructure最終構成

    Domain
      ↑
      |
    Application
      |
      | Interfaces / Ports
      v
    Infrastructure
      |
      ├── Repository Implementation
      ├── Mapper
      ├── Eloquent Model
      ├── ID Generator
      ├── TransactionManager
      ├── Query Service
      └── Database Lock
      |
      v
    PostgreSQL

Infrastructureは技術詳細を外側へ閉じ込め、
Domain ModelをLaravel / Eloquent / PostgreSQLから独立させる。
