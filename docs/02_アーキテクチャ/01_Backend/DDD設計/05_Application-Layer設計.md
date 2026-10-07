# Application Layer 設計

## 1. 役割

Application Layerは、

    「ユーザー操作を実現するために、
    Domain Objectをどう協調させるか」

を担当する。

主な責務：

- UseCaseの実行
- Command / Queryの受け取り
- Repository呼び出し
- Domain Method呼び出し
- Transaction管理
- Cross Aggregate Ruleの調整
- Domain Service呼び出し
- Application DTOの生成

Business Ruleそのものは可能な限りDomainへ置く。

---

## 2. 基本構成

    Presentation
        ↓
    Command / Query
        ↓
    Handler / UseCase
        ↓
    Domain
        ↓
    Repository Interface
        ↑
    Infrastructure

---

## 3. Command

状態を変更する操作を表す。

例：

- RegisterEmployee
- UpdateEmployee
- RetireEmployee
- RegisterSkill
- RegisterEmployeeSkill
- ChangeUserRole
- AssignSubManager

CommandはInput Dataを保持する。

---

## 4. Command例

    RegisterEmployeeCommand
    ├── employeeNumber
    ├── name
    └── departmentId

Command自身にBusiness Logicは持たせない。

---

## 5. Command Handler

Commandを受け取り、
UseCaseを実行する。

例：

    RegisterEmployeeHandler

Flow：

    RegisterEmployeeCommand
        ↓
    EmployeeNumber重複確認
        ↓
    Department確認
        ↓
    Employee::register()
        ↓
    EmployeeRepository::save()
        ↓
    Commit

---

## 6. Query

データ取得を表す。

例：

- GetEmployee
- SearchEmployees
- GetEmployeeSkills
- SearchEmployeesBySkill
- GetDashboard

Queryは状態変更を行わない。

---

## 7. Query Handler

Query処理では必ずしもAggregateを復元しない。

一覧・検索・Dashboardでは、

    Read Model

または、

    Query Service

を利用してよい。

例：

    SearchEmployeesHandler
        ↓
    EmployeeSearchQueryService
        ↓
    PostgreSQL

---

## 8. CQRSの位置付け

Full CQRSは採用しない。

ただしApplication Layerでは、

    Command
    Query

を明確に分ける。

つまり：

    Write
    → Domain Aggregate経由

    Read
    → Read Model / Query Service

という軽量CQRSを採用する。

---

## 9. UseCase命名

Write系：

    RegisterEmployee
    RetireEmployee
    RegisterEmployeeSkill
    DisableSkill

Read系：

    GetEmployee
    SearchEmployees
    GetDashboard

Handlerを付ける場合：

    RegisterEmployeeHandler
    SearchEmployeesHandler

とする。

---

## 10. DTO

Layer間のデータ受け渡しにはDTOを利用する。

主に以下を分ける。

### Input DTO

Command / Query

### Output DTO

Application Result

例：

    EmployeeResult
    EmployeeSkillResult
    DashboardResult

---

## 11. Presentationとの分離

Laravel Form Request：

    HTTP Input

Application Command：

    UseCase Input

Domain：

    Business Model

を分ける。

例：

    StoreEmployeeRequest
        ↓
    RegisterEmployeeCommand
        ↓
    RegisterEmployeeHandler
        ↓
    Employee

---

## 12. OpenAPIとの関係

OpenAPI SchemaをApplication DTOとして直接利用しない。

OpenAPI：

    External Contract

Presentation：

    HTTP Mapping

Application：

    UseCase Data

Domain：

    Business Model

として責務を分離する。

---

## 13. Transaction

Write UseCaseではApplication LayerがTransaction Boundaryを持つ。

基本：

    1 Command Handler
        =
    1 Transaction

例：

    DB::transaction(function () {
        ...
    });

ただしApplication LayerがLaravel Facadeへ直接依存しないよう、
Transaction Interfaceを定義する案を採用する。

---

## 14. Transaction Interface

Application側：

    TransactionManager

例：

    interface TransactionManager
    {
        public function run(callable $callback): mixed;
    }

Infrastructure側：

    LaravelTransactionManager

で、

    DB::transaction()

を利用する。

これによりApplication LayerからLaravel依存を外せる。

---

## 15. Repository依存

Application HandlerはRepository Interfaceへ依存する。

例：

    RegisterEmployeeHandler
        ↓
    EmployeeRepository
        ↑
    EloquentEmployeeRepository

Infrastructure実装を直接参照しない。

---

## 16. Cross Aggregate Rule

Application Layerで調整するもの：

- EmployeeNumber重複
- Skill名称重複
- Department有効確認
- SkillCategory有効確認
- Employee + Skill重複
- Permission Manager最低1人
- Assignment対象Role確認

単一Aggregateで完結するRuleはDomainへ置く。

---

## 17. Domain Service

複数Aggregateにまたがるが、
Business上明確な概念として成立する場合に利用する。

例：

    PermissionManagementPolicy

Application Handlerから呼び出す。

単なる処理置き場として使わない。

---

## 18. Application Exception

Domain Exceptionとは分ける。

候補：

    EmployeeNotFound
    DepartmentNotFound
    SkillNotFound
    DuplicateEmployeeNumber
    DuplicateSkillName
    UnauthorizedOperation

ただしNotFound等をDomain Exceptionにはしない。

---

## 19. Domain Exceptionとの違い

Domain Exception：

    Domain Modelが成立しない

例：

    InvalidEmployeeSkillState

Application Exception：

    UseCaseを実行できない

例：

    DepartmentNotFound

    EmployeeAlreadyHasSkill

---

## 20. Read Model

Read処理では専用DTOを利用する。

例：

    EmployeeListItem
    EmployeeDetail
    SkillSummary
    DashboardSummary

Eloquent ModelをPresentationへ直接返さない。

---

## 21. SearchEmployees

検索条件例：

- Department
- Skill
- Skill Level
- Experience Months
- Employment Status

Query：

    SearchEmployeesQuery

Handler：

    SearchEmployeesHandler

内部：

    EmployeeSearchQueryService

を利用する。

---

## 22. Dashboard

Dashboardは複数Contextを横断するため、
Aggregateを大量に読み込まない。

    DashboardQueryService

を利用する。

例：

- 在籍社員数
- Skill保有人数
- Skill Level分布
- Category別Skill保有人数

---

## 23. Directory構成

    app/
    ├── Application/
    │   ├── EmployeeManagement/
    │   │   ├── Commands/
    │   │   │   ├── RegisterEmployee/
    │   │   │   │   ├── RegisterEmployeeCommand.php
    │   │   │   │   └── RegisterEmployeeHandler.php
    │   │   │   └── RetireEmployee/
    │   │   │
    │   │   ├── Queries/
    │   │   │   ├── GetEmployee/
    │   │   │   └── SearchEmployees/
    │   │   │
    │   │   └── DTOs/
    │   │
    │   ├── SkillManagement/
    │   └── AccessControl/
    │
    └── Domain/

---

## 24. Vertical Slice寄りの構成

Application Layerでは、
機能単位にまとめることを推奨する。

例：

    RegisterEmployee/
    ├── RegisterEmployeeCommand.php
    └── RegisterEmployeeHandler.php

以下のように巨大Directoryへ全部並べない。

    Commands/
    ├── A.php
    ├── B.php
    ├── C.php
    └── ...

Context + UseCase単位で整理する。

---

## 25. Write Flow

例：EmployeeSkill登録

    HTTP Request
        ↓
    Form Request
        ↓
    RegisterEmployeeSkillCommand
        ↓
    RegisterEmployeeSkillHandler
        ↓
    Employee Repository
    Skill Repository
    SkillCategory Repository
    EmployeeSkill Repository
        ↓
    EmployeeSkill::experienced()
        or
    EmployeeSkill::unexperienced()
        ↓
    save()
        ↓
    Commit

---

## 26. Read Flow

例：Employee詳細取得

    HTTP Request
        ↓
    GetEmployeeQuery
        ↓
    GetEmployeeHandler
        ↓
    EmployeeReadRepository
        ↓
    EmployeeDetail DTO
        ↓
    API Resource / Response

ReadではDomain Aggregateを経由しないことを許可する。

---

## 27. RepositoryをRead / Writeで分ける

Write：

    EmployeeRepository

Domain Aggregateを扱う。

Read：

    EmployeeQueryService
    EmployeeReadRepository

Read Modelを扱う。

これによりRepositoryが巨大化するのを防ぐ。

---

## 28. Handlerの責務

Handlerは、

- Input取得
- Repository利用
- Domain呼び出し
- Transaction
- Output生成

を担当する。

Handler自身に複雑なBusiness Ruleを大量に書かない。

---

## 29. Handler肥大化時

複雑になった場合は、

- Domain Entity
- Value Object
- Domain Service
- Policy

へRuleを移せないか確認する。

単純にHelper Classへ逃がさない。

---

## 30. Authentication

Login / LogoutはAuthentication Application Serviceとして
Access Controlとは分離することを第一候補とする。

例：

    Application/
    └── Authentication/
        ├── Login/
        └── Logout/

Better Auth / Laravel Sanctum / Redis / Backend Credentialなどの
技術詳細はInfrastructureへ置く。

---

## 31. Authorization

UseCase実行権限はPresentationだけでなく、
Application Boundaryでも確認することを推奨する。

つまりPolicyだけに依存しない。

例：

    ChangeUserRoleHandler

自身も、

    actor.canManagePermissions

相当の条件を確認する。

重要操作では多層防御とする。

---

## 32. Command Bus

MVPではCommand Bus Libraryは導入しない。

ControllerからHandlerをDIして直接呼ぶ。

例：

    $handler->handle($command);

理由：

- Command / Handler構造は学べる
- Magicが増えない
- Debugしやすい

---

## 33. Query Bus

同様に専用Query Busは導入しない。

    $handler->handle($query);

を利用する。

将来的に必要になった場合のみBusを検討する。

---

## 34. Handler Interface

すべてのHandlerに共通Interfaceを強制しない。

必要になった場合のみ導入する。

Interfaceを作ること自体を目的にしない。

---

## 35. Application Layer Test

Handler単位でTestする。

主な対象：

- Repository interaction
- Cross Aggregate Rule
- Transaction
- Domain Method呼び出し
- Exception

Domainの細かいInvariantはDomain Unit Testに任せる。

---

## 36. Test Double

Repository Interfaceを利用するため、
Application TestではInMemory Repository等を利用可能。

候補：

    InMemoryEmployeeRepository

ただし全RepositoryのFake実装を義務化しない。

Feature Testでは実PostgreSQLを利用する。

---

## 37. 採用方針

### Write

Command + Handler

### Read

Query + Handler

### CQRS

軽量CQRS

### Transaction

Application Layer

### Transaction Infrastructure

TransactionManager Interface経由

### DTO

Application専用DTOを利用する。

### Read Model

検索 / Dashboard等で積極的に利用する。

### Repository

Write用とRead用を分ける。

### Bus

導入しない。

---

## 38. 最終構成

    Presentation
        |
        +------------------+
        |                  |
        v                  v
     Command             Query
        |                  |
        v                  v
    CommandHandler     QueryHandler
        |                  |
        v                  v
      Domain           Read Model
        |
        v
    Repository
        ^
        |
    Infrastructure
