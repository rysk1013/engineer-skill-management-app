# Infrastructure / Persistence 設計

## 1. 基本方針

Infrastructure Layerは、
外部技術・Framework・Persistenceの詳細を担当する。

対象：

- Laravel
- Eloquent
- PostgreSQL
- Laravel Sanctum
- Auth.js用Database Access
- Transaction
- Database Lock
- Logging
- External API

Domain LayerとApplication Layerから、
EloquentやPostgreSQLの詳細を直接参照しない。

依存方向：

    Presentation
        ↓
    Application
        ↓
      Domain
        ↑
        |
    Infrastructure

InfrastructureがDomain / Application側で定義された
Interfaceを実装する。

---

## 2. Persistence構成

基本構成：

    Domain Aggregate
          ↑
          |
    Repository Interface
          ↑
          |
    Repository Implementation
          |
          v
        Mapper
          |
          v
    Eloquent Model
          |
          v
      PostgreSQL

---

## 3. Eloquent Model

Eloquent ModelはInfrastructure Layerへ配置する。

役割：

- Table Mapping
- Column Mapping
- Eloquent Relation
- Cast
- Query Builder
- Database Persistence

Domain Business Ruleの中心にはしない。

---

## 4. Domain Entityとの分離

以下を明確に分ける。

    Domain Employee
        ≠
    Eloquent EmployeeModel

同様に：

    Domain Skill
        ≠
    Eloquent SkillModel

    Domain EmployeeSkill
        ≠
    Eloquent EmployeeSkillModel

とする。

---

## 5. Eloquent Model配置

第一候補：

    app/
    └── Infrastructure/
        └── Persistence/
            └── Eloquent/
                └── Models/
                    ├── EmployeeModel.php
                    ├── DepartmentModel.php
                    ├── UserModel.php
                    ├── SkillCategoryModel.php
                    ├── SkillModel.php
                    └── EmployeeSkillModel.php

Assignment用：

                    ├── SubManagerAssignmentModel.php
                    └── TeamLeaderAssignmentModel.php

---

## 6. Laravel標準Model Directoryを使わない理由

通常Laravelでは：

    app/Models/

を利用する。

今回はClean Architecture学習目的のため、

    Infrastructure/Persistence/Eloquent/Models

へ配置する。

これにより、

    Eloquent Model
    =
    Infrastructure Detail

であることを構造上も明確にする。

---

## 7. Eloquent Relation

Eloquent ModelではRelationを定義してよい。

例：

    EmployeeModel
        belongsTo DepartmentModel

    EmployeeSkillModel
        belongsTo EmployeeModel
        belongsTo SkillModel

ただしDomain Aggregateへ
そのRelation Objectをそのまま渡さない。

---

## 8. Repository Interface

Repository InterfaceはDomain側に置く。

例：

    Domain/
    └── EmployeeManagement/
        └── Repositories/
            └── EmployeeRepository.php

InterfaceはDomain用語で定義する。

---

## 9. EmployeeRepository

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

## 10. Repository Implementation

Infrastructure側：

    EloquentEmployeeRepository

を実装する。

配置：

    Infrastructure/
    └── Persistence/
        └── Eloquent/
            └── Repositories/
                └── EloquentEmployeeRepository.php

依存：

    EmployeeRepository
        ↑
    EloquentEmployeeRepository

---

## 11. Repository Implementation Flow

取得：

    EmployeeRepository::findById()
        ↓
    EmployeeModel Query
        ↓
    EmployeeMapper
        ↓
    Domain Employee

保存：

    Domain Employee
        ↓
    EmployeeMapper
        ↓
    EmployeeModel
        ↓
    save()
        ↓
    PostgreSQL

---

## 12. Mapper

Persistence表現とDomain表現を変換する。

配置：

    Infrastructure/
    └── Persistence/
        └── Eloquent/
            └── Mappers/

候補：

- EmployeeMapper
- DepartmentMapper
- UserMapper
- SkillCategoryMapper
- SkillMapper
- EmployeeSkillMapper

---

## 13. Mapperの責務

例えばEmployeeSkill：

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

この変換をMapperで行う。

---

## 14. MapperをDomainへ置かない

MapperはPersistence形式を知る必要がある。

例えば：

    2026-08-01

というDatabase表現を知るため、
Domain Layerには置かない。

Infrastructure Layerの責務とする。

---

## 15. Mapper Method候補

例：

    EmployeeMapper

    toDomain(
        EmployeeModel $model
    ): Employee

    toModel(
        Employee $employee,
        ?EmployeeModel $model = null
    ): EmployeeModel

または：

    fillModel(
        Employee $employee,
        EmployeeModel $model
    ): void

---

## 16. Domain Getter

MapperがAggregate内部状態を取得する必要がある。

ただしDDDだからといってGetterを完全禁止しない。

読み取り専用Method：

    id()
    employeeNumber()
    name()
    departmentId()
    employmentStatus()
    retirementDate()

等を用意してよい。

Setterは作らない。

---

## 17. Save Strategy

Repository `save()` は、

    新規作成
    更新

の両方を扱う。

例：

    if model exists
        update

    else
        insert

ただしDomain側でPersistence状態を意識させない。

---

## 18. ID生成

現在Database Primary KeyはAuto Increment bigintを採用している。

ここでDDD上の論点がある。

新規Domain Entity生成時：

    Employee::register(
        id: ???
    )

となる。

Auto Incrementの場合、
DB保存前にはIDが存在しない。

---

## 19. ID生成方式候補

### 案A

Domain IDをNullableにする。

    ?EmployeeId

新規：

    null

保存後：

    DB generated ID

---

### 案B

Repositoryで先にIDを発行する。

PostgreSQL Sequenceから、

    nextval(...)

を取得してからDomain Entityを作る。

---

### 案C

Domain IDをULID / UUIDへ変更する。

Application側で保存前に生成できる。

---

## 20. 今回の推奨

現在のDatabase設計ではbigint Auto Incrementを採用済みなので、

**Repository / ID GeneratorでDB SequenceからIDを先に取得する方式**

を学習候補として推奨する。

つまり：

    EmployeeIdGenerator
        ↓
    PostgreSQL Sequence
        ↓
    EmployeeId
        ↓
    Employee::register()

とする。

---

## 21. Sequence利用

PostgreSQLではIdentity / Sequenceを利用しているため、
保存前に次のIDを取得できる。

概念：

    nextval(...)

ただしSequence名への直接依存は
Infrastructureへ閉じ込める。

---

## 22. ID Generator Interface

Domain / Application側：

    EmployeeIdGenerator

または共通：

    IdGenerator

を定義する案がある。

学習目的ではAggregateごとの型安全性を優先し、

    EmployeeIdGenerator
    SkillIdGenerator
    EmployeeSkillIdGenerator

等を検討する。

ただし大量に増えるため、
最終的には共通Infrastructure実装でもよい。

---

## 23. Alternative

ID生成問題が設計上かなり煩雑になる場合は、
将来的にULID採用を再検討してよい。

ただし現時点では、

    bigint Auto Increment

の決定を維持する。

---

## 24. Transaction Manager

Application LayerをLaravel Facadeへ依存させないため、
Transaction Interfaceを利用する。

Application側：

    interface TransactionManager
    {
        public function run(
            callable $callback
        ): mixed;
    }

Infrastructure：

    LaravelTransactionManager

---

## 25. LaravelTransactionManager

内部：

    DB::transaction(...)

を利用する。

概念：

    final class LaravelTransactionManager
        implements TransactionManager
    {
        public function run(
            callable $callback
        ): mixed {
            return DB::transaction($callback);
        }
    }

Laravel依存をInfrastructureへ閉じ込める。

---

## 26. Transaction Boundary

Transaction開始・終了の判断はApplication Handlerが行う。

例：

    RegisterEmployeeSkillHandler
        ↓
    TransactionManager::run()
        ↓
    Repository
        ↓
    Domain
        ↓
    save()

Repositoryごとに勝手にTransactionを開始しない。

---

## 27. Repository内Transaction

原則禁止する。

理由：

複数RepositoryをまたぐUseCaseで、
Transaction Boundaryが分断されるため。

例：

    EmployeeRepository
    SkillRepository
    EmployeeSkillRepository

を1UseCaseで使う場合でも、
Handler側の1 Transactionにまとめる。

---

## 28. Permission Manager Concurrency

確定Rule：

    can_manage_permissions = true

のAdministratorを最低1人残す。

単純な、

    count()
        ↓
    update

ではRace Conditionが発生する。

---

## 29. Race Condition例

初期：

    Admin A = true
    Admin B = true

Transaction A：

    count = 2
    ↓
    Admin A false

Transaction B：

    count = 2
    ↓
    Admin B false

結果：

    0人

になる可能性がある。

---

## 30. Concurrency Control

この処理ではDatabase Lockを利用する。

第一候補：

    SELECT ... FOR UPDATE

を採用する。

---

## 31. Permission Manager Lock Flow

概念：

    Transaction Start
        ↓
    Permission Manager Rowを
    SELECT FOR UPDATE
        ↓
    件数確認
        ↓
    最後の1人なら拒否
        ↓
    Update
        ↓
    Commit

同時TransactionはLock解除まで待機する。

---

## 32. Repository / Lock Interface

Application LayerへSQLを露出しない。

例えば：

    PermissionManagerRepository

または、

    PermissionManagerLock

Interfaceを定義する。

候補：

    lockPermissionManagers(): PermissionManagerCollection

ただし専用抽象化が過剰なら、

    UserRepository::lockPermissionManagers()

でもよい。

---

## 33. 推奨

学習目的として、

    PermissionManagerLock

のような専用Interfaceを作るより、
まずは、

    UserRepository::findPermissionManagersForUpdate()

などRepositoryへ明示する案を第一候補とする。

SQL詳細はInfrastructure Implementationへ閉じ込める。

---

## 34. Eloquent Lock

InfrastructureではEloquent / Query Builderの、

    lockForUpdate()

を利用できる。

Application / Domainは、

    lockForUpdate()

というLaravel固有APIを知らない。

---

## 35. Advisory Lock

PostgreSQL Advisory Lockも候補ではある。

ただし今回のRuleは、

    User rows

に明確に紐付くため、
まずRow Lockを採用する。

Advisory Lockは必要性が出た場合に学習対象として追加する。

---

## 36. Query Service

Read系ではRepository Aggregateを経由せず、
Query ServiceからEloquent / Query Builderを利用してよい。

例：

    EloquentEmployeeSearchQueryService

配置：

    Infrastructure/
    └── Persistence/
        └── Queries/

---

## 37. Query Service例

    EmployeeSearchQueryService
        ↑
    EloquentEmployeeSearchQueryService

Application Query Handler：

    SearchEmployeesHandler
        ↓
    EmployeeSearchQueryService

Infrastructure：

    PostgreSQL JOIN / EXISTS
        ↓
    EmployeeListItem DTO

---

## 38. Read ModelではMapper不要の場合もある

例えばEmployee一覧：

    employees
    JOIN departments
    JOIN employee_skills

から直接、

    EmployeeListItem

を作ってよい。

Domain Aggregateを復元する必要はない。

---

## 39. Dashboard Query

同様に：

    DashboardQueryService

Infrastructureで、

- COUNT
- GROUP BY
- JOIN

を利用する。

Domain Repositoryを経由して
大量のAggregateをロードしない。

---

## 40. Eloquent Mass Assignment

Infrastructure Modelでは、

    fillable
    guarded

等を利用できる。

ただしHTTP Requestをそのまま、

    Model::create($request->all())

する設計にはしない。

必ずApplication / Domainを経由する。

---

## 41. Model Events

Eloquent Model Event：

- creating
- updating
- deleting

へBusiness Ruleを書かない。

理由：

処理経路が隠れるため。

Domain RuleはDomain Aggregate、
UseCase FlowはApplication Layerへ置く。

---

## 42. Observer

Laravel Observerも、
Business Ruleの中心には利用しない。

Infrastructure側の技術的処理：

- Audit
- Cache invalidation

などで必要になった場合のみ検討する。

---

## 43. Cast

Eloquent ModelではPersistence向けCastを利用する。

例：

    is_active
        → boolean

    retirement_date
        → date

    last_used_date
        → date

ただしDomain Enum / Value Objectへの変換はMapperで行う。

---

## 44. Domain Event

今回DDDを採用するが、
MVPではDomain Eventを必須にしない。

候補：

    EmployeeRetired
    SkillDisabled
    UserDisabled

必要な副作用が明確になった段階で導入する。

---

## 45. Domain Eventを今すぐ使わない理由

現時点では多くの処理が、

    1 Transaction
    +
    同期処理

で十分だから。

Eventを使うこと自体を目的にしない。

---

## 46. Infrastructure Exception

PostgreSQL / Eloquent固有Exceptionを
上位Layerへそのまま漏らさないことを検討する。

例：

    UniqueConstraintViolation

を、

    DuplicateEmployeeNumber

等へ変換する。

ただしすべてのExceptionを独自Wrapする必要はない。

---

## 47. UNIQUE Race Condition

Applicationで、

    existsByEmployeeNumber()

を確認しても、

同時RequestによってUNIQUE Constraint違反は発生し得る。

そのためDatabase UNIQUEを最終保証として残す。

必要に応じてInfrastructureでConstraint Nameを確認し、
Application Exceptionへ変換する。

---

## 48. Constraint Name

Migrationで明示的なConstraint Nameを付ける。

例：

    uq_employees_employee_number

    uq_employee_skills_employee_skill

    chk_employee_skills_work_experience

これによりInfrastructure Exception変換もしやすくなる。

---

## 49. Repository Binding

Laravel Service Containerを利用して、
InterfaceとImplementationをBindingする。

例：

    EmployeeRepository
        →
    EloquentEmployeeRepository

BindingはService Providerで行う。

---

## 50. Service Provider

候補：

    PersistenceServiceProvider

配置例：

    Infrastructure/
    └── Providers/
        └── PersistenceServiceProvider.php

Binding：

- EmployeeRepository
- DepartmentRepository
- SkillRepository
- EmployeeSkillRepository
- UserRepository
- TransactionManager
- Query Services

---

## 51. DomainからService Containerを使わない

以下は禁止する。

    app(EmployeeRepository::class)

をDomain Entity内で利用する。

DependencyはConstructor Injectionで受け取る。

Laravel Service ContainerはComposition Rootとして利用する。

---

## 52. Composition Root

LaravelのService Providerを、
Infrastructure構成の組み立て場所として利用する。

概念：

    Interface
        ↓
    Service Provider
        ↓
    Implementation

Domain / Applicationは具体クラスを知らない。

---

## 53. Directory構成

第一候補：

    app/
    ├── Domain/
    │
    ├── Application/
    │
    ├── Infrastructure/
    │   ├── Persistence/
    │   │   ├── Eloquent/
    │   │   │   ├── Models/
    │   │   │   ├── Repositories/
    │   │   │   └── Mappers/
    │   │   │
    │   │   ├── Queries/
    │   │   └── Transactions/
    │   │
    │   ├── Authentication/
    │   ├── Logging/
    │   └── Providers/
    │
    └── Http/

---

## 54. Persistence Directory詳細

    Infrastructure/
    └── Persistence/
        ├── Eloquent/
        │   ├── Models/
        │   │   ├── EmployeeModel.php
        │   │   ├── DepartmentModel.php
        │   │   ├── UserModel.php
        │   │   ├── SkillModel.php
        │   │   ├── SkillCategoryModel.php
        │   │   └── EmployeeSkillModel.php
        │   │
        │   ├── Repositories/
        │   │   ├── EloquentEmployeeRepository.php
        │   │   ├── EloquentDepartmentRepository.php
        │   │   ├── EloquentUserRepository.php
        │   │   ├── EloquentSkillRepository.php
        │   │   └── EloquentEmployeeSkillRepository.php
        │   │
        │   └── Mappers/
        │       ├── EmployeeMapper.php
        │       ├── DepartmentMapper.php
        │       ├── UserMapper.php
        │       ├── SkillMapper.php
        │       └── EmployeeSkillMapper.php
        │
        ├── Queries/
        │   ├── EloquentEmployeeSearchQueryService.php
        │   └── EloquentDashboardQueryService.php
        │
        └── Transactions/
            └── LaravelTransactionManager.php

---

## 55. Write Architecture

    Command Handler
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

---

## 56. Read Architecture

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

Read処理ではDomain Aggregateを経由することを必須としない。

---

## 57. Unit Test

Domain TestではInfrastructureを利用しない。

Application Testでは、

- InMemory Repository
- Fake TransactionManager

等を必要に応じて利用できる。

---

## 58. Integration Test

Infrastructure Repositoryは、
実際のPostgreSQLを利用してTestする。

対象：

- Mapper
- Repository
- Constraint
- Transaction
- Lock
- Query Service

SQLiteで代替せず、
PostgreSQL固有機能を実PostgreSQLで確認する。

---

## 59. Lock Test

Permission Manager最低1人Ruleについては、
Concurrency Testも検討する。

少なくとも、

    SELECT FOR UPDATE

が正しく使用されていることを
Integration Test対象とする。

---

## 60. 採用方針

### Eloquent Model

Infrastructure Layer。

### Domain Entity

Eloquentとは分離する。

### Repository Interface

Domain Layer。

### Repository Implementation

Infrastructure Layer。

### Mapper

Infrastructure Layer。

### Transaction

Application Layerで境界を決定。

### Transaction実装

Infrastructure Layer。

### Read Query

Query Serviceを利用する。

### Lock

PostgreSQL Row Lockを第一候補とする。

### Business Logic

Eloquent Model Eventへ置かない。

### DI

Laravel Service ContainerをComposition Rootとして利用する。
