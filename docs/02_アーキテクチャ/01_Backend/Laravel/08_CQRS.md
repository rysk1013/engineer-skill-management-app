# CQRS設計

## 1. 目的

CQRSは、Command Query Responsibility Segregationの略であり、

> 状態を変更する処理と、状態を取得する処理の責務を分離する

ための設計方針である。

本システムではFull CQRSではなく、Application / PersistenceレベルでWriteとReadを分離するLightweight CQRSを採用する。

基本構造は以下とする。

```text
Write
    ↓
Command
    ↓
Command Handler
    ↓
Domain Model
    ↓
Repository
```

```text
Read
    ↓
Query
    ↓
Query Handler
    ↓
Query Service
    ↓
Read Model
```

CQRSを採用する目的は以下とする。

- Domain ModelをRead都合で複雑化しない
- Repositoryを万能検索Serviceにしない
- Read処理を画面・検索用途に最適化する
- Write側ではDomain Invariantを確実に保証する
- UseCaseの意図を明確にする

---

## 2. 採用するCQRSの範囲

本システムでは以下を採用する。

- Command / Command Handler
- Query / Query Handler
- Write Repository
- Read Query Service
- Read Model / Result
- Application LayerでのWrite / Read責務分離

一方、以下はMVPでは採用しない。

- Command Bus
- Query Bus
- Message Bus
- Event Sourcing
- Write Database / Read Databaseの物理分離
- Read Replica前提設計
- Eventual Consistencyを前提としたRead Model同期
- Projection Infrastructure
- CQRS専用Framework

つまり、

```text
Logical Separation
    =
採用

Physical Separation
    =
不採用
```

とする。

---

## 3. Lightweight CQRS

本システムのCQRSは、

> 同一Application・同一Databaseを利用しながら、Write PathとRead Pathの責務をCode上で分離する

方式とする。

概念構造:

```text
                    PostgreSQL
                       ↑   ↑
                       │   │
        Write          │   │          Read
                       │   │
Command Handler        │   │     Query Handler
       ↓               │   │          ↓
Domain Model           │   │     Query Service
       ↓               │   │          ↓
Repository ────────────┘   └──── Read Model
```

Databaseを物理的に分離する必要はない。

---

## 4. Command

Commandは状態変更UseCaseへの入力を表すApplication DTOとする。

例:

```php
final readonly class RegisterEmployeeSkillCommand
{
    public function __construct(
        public int $employeeId,
        public int $skillId,
        public int $skillLevel,
        public string $workExperience,
        public ?int $experienceMonths,
        public ?string $lastUsedMonth,
    ) {}
}
```

CommandにはBusiness Logicを持たせない。

Commandは、

> 何を変更したいか

を表現する。

---

## 5. Commandの対象

以下のような処理はCommandとする。

- Employee登録
- Employee更新
- Employee退職
- Skill登録
- Skill更新
- Skill無効化
- EmployeeSkill登録
- EmployeeSkill更新
- Permission変更
- Sub Manager割当
- Team Leader割当

判断基準は、

```text
System Stateを変更する
    ↓
Command
```

とする。

---

## 6. Command Handler

Command HandlerはWrite UseCaseのオーケストレーションを担当する。

基本フロー:

```text
Command
    ↓
Command Handler
    ↓
Authorization
    ↓
RepositoryからAggregate取得
    ↓
Domain Behavior
    ↓
Repository保存
    ↓
Result
```

必要に応じて以下を利用する。

- ID Generator
- Domain Policy
- Transaction Manager
- Application Port
- 複数Repository

Business InvariantそのものはCommand Handlerへ実装しない。

---

## 7. Write処理の基本フロー

例えばEmployeeSkill登録は以下のようになる。

```text
RegisterEmployeeSkillCommand
        ↓
RegisterEmployeeSkillHandler
        ↓
Authorization
        ↓
Employee存在確認
        ↓
Skill存在確認
        ↓
重複事前確認
        ↓
ID Generator
        ↓
EmployeeSkill::register()
        ↓
EmployeeSkillRepository::save()
```

Write処理ではDomain Modelを通すことを基本とする。

---

## 8. WriteではDomain Modelを利用する

状態変更ではAggregate / Entity / Value Object / Domain Policyを利用してBusiness Invariantを保証する。

例えば、

```text
実務未経験
    +
Skill Level 3
```

を登録しようとした場合、

```text
Command Handler
    ↓
EmployeeSkill::register()
    ↓
Domain Exception
```

となる。

Command HandlerやRepositoryだけでBusiness Ruleを保証しない。

---

## 9. Write Repository

Write側のPersistenceにはDomain Repositoryを利用する。

```text
Command Handler
    ↓
Repository Interface
    ↓
Aggregate
```

RepositoryはAggregate Persistenceに集中する。

例:

```php
interface EmployeeSkillRepository
{
    public function find(
        EmployeeSkillId $id,
    ): ?EmployeeSkill;

    public function save(
        EmployeeSkill $employeeSkill,
    ): void;
}
```

検索画面やDashboardなどのRead用途はRepositoryへ追加しない。

---

## 10. WriteとTransaction

Write UseCaseは原則として、

```text
1 Command Handler
    =
1 Transaction
```

とする。

例:

```text
Transaction Start
    ↓
Aggregate取得
    ↓
Domain Behavior
    ↓
Repository保存
    ↓
Transaction Commit
```

具体的なTransaction設計は `09_Transaction.md` で定義する。

---

## 11. Command Result

Commandは必要に応じてApplication Resultを返す。

例えば新規登録時は、

```php
final readonly class RegisterEmployeeSkillResult
{
    public function __construct(
        public int $id,
        public int $employeeId,
        public int $skillId,
    ) {}
}
```

などを返す。

Command HandlerからEloquent ModelやDomain EntityをPresentationへ直接返さない。

---

## 12. Commandは必ずResultを返す必要はない

状態変更後にResponse Bodyが不要なUseCaseではResultを返さなくてもよい。

例えば、

```text
Skill無効化
Employee削除
Assignment解除
```

などでHTTP `204 No Content` を採用する場合は、

```php
public function handle(
    DeactivateSkillCommand $command,
): void
```

も許容する。

意味のないResult DTOを形式上作らない。

---

## 13. Query

Queryは状態を変更せず、Data取得UseCaseへの入力を表すApplication DTOとする。

例:

```php
final readonly class SearchEmployeeSkillsQuery
{
    public function __construct(
        public ?string $keyword,
        public ?int $skillId,
        public int $page,
        public int $perPage,
    ) {}
}
```

Queryは、

> 何を知りたいか

を表現する。

---

## 14. Queryの対象

以下のような処理はQueryとする。

- Employee詳細取得
- Employee一覧
- Employee検索
- Skill一覧
- Skill検索
- EmployeeSkill詳細
- EmployeeSkill一覧
- Dashboard集計
- Skill保有人数集計
- 経験年数Filter
- Permission状態取得

判断基準は、

```text
System Stateを変更しない
    ↓
Query
```

とする。

---

## 15. Query Handler

Query HandlerはRead UseCaseのオーケストレーションを担当する。

基本:

```text
Query
    ↓
Query Handler
    ↓
Authorization
    ↓
Query Service
    ↓
Read Model / Result
```

Read処理では原則としてDomain Aggregateを復元しない。

---

## 16. Query Service

Read処理のData AccessはQuery Serviceを利用する。

Application LayerでInterfaceを定義し、Infrastructure Layerで実装する。

概念:

```text
Application
EmployeeSearchQueryService
        ↑
        │ implements
        │
Infrastructure
EloquentEmployeeSearchQueryService
```

Query ServiceはRead用途に最適化する。

---

## 17. Query Serviceで利用可能な技術

Infrastructure側のQuery Serviceでは必要に応じて以下を利用できる。

- Eloquent Query Builder
- Laravel Query Builder
- JOIN
- Subquery
- Aggregate Function
- Raw SQL
- PostgreSQL固有SQL
- Pagination
- CTE
- Window Function

Read処理をDomain Aggregateの形へ無理に合わせない。

---

## 18. Read Model

Query Serviceは画面・API用途に適したRead Modelを返す。

例えばEmployee Skill一覧で必要なのが、

```text
EmployeeSkill ID
Employee Name
Skill Name
Skill Category
Skill Level
Experience Months
Last Used Month
```

であれば、その用途に適したRead Modelを作る。

例:

```php
final readonly class EmployeeSkillListItem
{
    public function __construct(
        public int $id,
        public string $employeeName,
        public string $skillName,
        public string $categoryName,
        public int $skillLevel,
        public ?int $experienceMonths,
        public ?string $lastUsedMonth,
    ) {}
}
```

Aggregate構造へ合わせる必要はない。

---

## 19. Read ModelとDomain Model

Read ModelはDomain Entityではない。

```text
Domain Model
    ↓
Business Behavior
Business Invariant
Consistency

Read Model
    ↓
Display
Search
Filter
Aggregation
```

目的が異なるため分離する。

Read ModelへDomain Behaviorを実装しない。

---

## 20. ReadでAggregateを復元しない理由

単純な一覧取得で、

```text
EmployeeSkill
    ↓
Employee
    ↓
Skill
    ↓
SkillCategory
```

のAggregateを順番に復元すると、

- Query数増加
- N+1 Risk
- 不要なObject生成
- Mapping処理増加
- Read要件とDomain構造の不一致

が発生しやすい。

Readでは必要なDataを直接取得する。

---

## 21. Read Queryの最適化

Read側では画面やAPI Requirementに合わせてQueryを最適化できる。

例えば、

```sql
SELECT
    es.id,
    e.name,
    s.name AS skill_name,
    sc.name AS category_name,
    es.skill_level
FROM employee_skills es
JOIN employees e ...
JOIN skills s ...
JOIN skill_categories sc ...
```

のようなQueryを利用できる。

Domain Aggregateの境界がRead SQLのJOINを制限するわけではない。

Aggregate BoundaryはWrite Consistencyのための境界である。

---

## 22. Aggregate BoundaryとRead

WriteではAggregate Boundaryを守る。

```text
Aggregate A
    ↔ ID
Aggregate B
```

Readでは複数Table / Aggregateを跨いだJOINを許容する。

```text
Employee
    +
EmployeeSkill
    +
Skill
    +
SkillCategory
        ↓
Read Model
```

これはAggregate Boundary違反とはみなさない。

---

## 23. QueryとBusiness Logic

Query Handler / Query ServiceへBusiness State変更Logicを書かない。

また、重要なBusiness判断をRead SQLだけで再実装しない。

ただし表示・検索のための以下はRead処理として扱う。

- Filter
- Sort
- Count
- Grouping
- Aggregation
- 表示に必要なData整形

---

## 24. ReadでDomain Value Objectを利用するか

Read ModelではDomain Value Objectの利用を必須としない。

例えば、

```text
LastUsedMonth
```

についてQuery Serviceから、

```php
public ?string $lastUsedMonth
```

として `YYYY-MM` を返してよい。

Read ModelはDomain Modelとは異なるため、

> DomainにValue ObjectがあるからReadでも必ず利用する

とはしない。

ただし、Application内部でValue Objectを利用した方が責務や意味が明確になる場合は禁止しない。

---

## 25. Query Result

Query HandlerはApplication用Result / Read Modelを返す。

Presentation LayerはそれをAPI Resourceへ変換する。

```text
Query Service
    ↓
Read Model
    ↓
Query Handler
    ↓
Application Result
    ↓
API Resource
    ↓
HTTP Response
```

Read ModelとResultが完全に同一の意味を持つ場合は、形式上別Classへ分けなくてもよい。

不要なDTO変換Layerを増やさない。

---

## 26. Query Service Interfaceの配置

Query Service InterfaceはApplication Layerへ配置する。

理由は、

> Read UseCaseがどのDataを必要とするか

をApplication側が定義するためである。

UseCase固有である場合は、例えば以下のように配置できる。

```text
Application/
└── SkillManagement/
    └── Queries/
        └── SearchEmployeeSkills/
            ├── SearchEmployeeSkillsQuery.php
            ├── SearchEmployeeSkillsHandler.php
            ├── EmployeeSkillSearchQueryService.php
            └── SearchEmployeeSkillsResult.php
```

複数UseCaseで自然に共有される場合は、

```text
Application/
└── SkillManagement/
    └── QueryServices/
        └── EmployeeSkillQueryService.php
```

のような配置も許容する。

---

## 27. Query Serviceの粒度

Query Serviceは万能な、

```text
EmployeeQueryService
SkillQueryService
```

へすべてのRead処理を無制限に集約しない。

UseCaseやRead Modelの関連性を見て適切な粒度に分割する。

候補例:

```text
EmployeeSearchQueryService
EmployeeDetailQueryService
DashboardSkillStatisticsQueryService
```

ただし、

```text
1 Query
    =
1 Query Service
```

を形式的には強制しない。

関連するQueryで自然に共有できる場合は共有してよい。

---

## 28. Query HandlerとQuery Serviceの違い

Query Handlerは、

> UseCaseを実行する

責務を持つ。

Query Serviceは、

> Read Dataを取得する

責務を持つ。

例えば、

```text
SearchEmployeeSkillsHandler
    ↓
Authorization
    ↓
検索条件のUseCase上の整理
    ↓
EmployeeSkillSearchQueryService
```

となる。

Query ServiceへAuthorizationやUseCase Flowを持ち込まない。

---

## 29. Command HandlerとQuery HandlerのDI

Command Bus / Query Busは採用しないため、PresentationからHandlerを直接DIする。

Write:

```text
Controller
    ↓
RegisterEmployeeSkillHandler
```

Read:

```text
Controller
    ↓
SearchEmployeeSkillsHandler
```

Laravel Service Containerによる通常のConstructor Injectionを利用する。

---

## 30. Command Busを採用しない

MVPではCommand Busを採用しない。

以下のような構造は導入しない。

```text
Controller
    ↓
Command Bus
    ↓
Handler Resolver
    ↓
Command Handler
```

現時点では、

```text
Controller
    ↓
Command Handler
```

で十分とする。

---

## 31. Query Busを採用しない

Queryについても同様に、

```text
Controller
    ↓
Query Handler
```

とする。

Query Busを導入しない。

Busが必要になる明確なCross-cutting Requirementが発生した場合のみ再検討する。

---

## 32. Bus導入を再検討する条件

将来的に以下の要求が強くなった場合はCommand / Query Busを再検討できる。

- Handler実行前後の共通Pipeline
- UseCase共通Metrics
- 共通Tracing
- 共通Retry
- Middleware形式の横断処理
- 非同期Command Dispatch

ただし、

> CQRSだからBusが必要

とは考えない。

---

## 33. Event Sourcingを採用しない

本システムではEvent Sourcingを採用しない。

Aggregateの現在状態は通常のRelational Database Tableへ保存する。

```text
Aggregate
    ↓
Current State
    ↓
PostgreSQL
```

Event Historyから現在状態を再構築する方式は利用しない。

---

## 34. Domain Eventとの関係

将来的にDomain Eventを利用する場合でも、

```text
Domain Event
    ≠
Event Sourcing
```

である。

Domain Eventを採用することとEvent Sourcingを採用することは別判断とする。

MVPでは明確な必要性がない限りDomain Event Infrastructureも事前導入しない。

---

## 35. Read Databaseを分離しない

MVPではWrite DatabaseとRead Databaseを物理的に分離しない。

```text
Write
    ↓
PostgreSQL

Read
    ↓
同じPostgreSQL
```

Logical CQRSのみを採用する。

これにより以下の複雑性を増やさない。

- Infrastructure Complexity
- Synchronization
- Eventual Consistency
- Operational Cost
- Data Replication管理

---

## 36. Read Modelを永続化しない

MVPではCQRS専用のRead Model Tableを原則として作成しない。

Read Modelは通常、

```text
Database
    ↓
Query
    ↓
Runtime Read Model
```

として生成する。

Performance Requirement上必要になった場合のみ以下を検討する。

- Materialized View
- Denormalized Table
- Cache
- Read Projection

---

## 37. CQRSを適用しすぎない

すべての処理を無理に複雑なCQRS Patternへ落とし込まない。

例えば非常に単純なQueryでも、

```text
Query
    ↓
Query Handler
    ↓
Query Service
```

という責務分離は維持する。

一方で、以下のような追加要素を形式だけで導入しない。

```text
Specification
Projection
Query Bus
Query Pipeline
Read Repository
```

CQRSによるClass数増加そのものを目的としない。

---

## 38. Command / Queryの判断基準

基本判断は以下とする。

```text
状態を変更する
    ↓
Command

状態を変更しない
    ↓
Query
```

同一UseCase内で、

```text
Dataを取得
    ↓
状態変更
```

を行う場合でも、そのUseCase全体が状態変更を目的としていればCommandとする。

例えば、

```text
EmployeeSkillを取得
    ↓
変更
    ↓
保存
```

はCommandである。

---

## 39. Queryから状態を変更しない

Query Handler / Query ServiceからBusiness Stateを変更しない。

以下を行わない。

- `save()`
- `update()`
- `delete()`
- Domain Behaviorによる状態変更
- Business Stateを変更する副作用

QueryはObservableなBusiness Stateを変更しない。

---

## 40. Readに伴う技術的副作用

Query実行に伴う以下のような技術的副作用は、Business State変更とは区別する。

例:

- Access Log
- Metrics
- Trace
- Cache Hit / Miss記録

ただし、Read UseCase実行によってDomain上意味のある状態が変更される場合はQueryとは扱わない。

例えば、

```text
閲覧したことで既読状態を変更する
```

ような処理が将来存在する場合、その状態変更部分はCommandとして扱うことを検討する。

---

## 41. CommandからQuery Serviceを使う場合

原則としてWrite UseCaseではRepositoryを利用する。

Aggregateを変更するためのDataはAggregate Repositoryから取得する。

一方で、Business State変更に直接関係しない補助的な参照情報について、Read-oriented Portを利用することを完全には禁止しない。

ただし、

> Writeなのに必要なDataをすべてQuery Serviceで取得する

設計にはしない。

変更対象AggregateをRead Modelとして取得して直接更新する構造を避ける。

---

## 42. Commandで直接SQLを利用しない

Command HandlerはEloquent / Query Builder / Raw SQLを直接利用しない。

避ける例:

```php
DB::table('employee_skills')
    ->where(...)
    ->update(...);
```

通常のBusiness Writeは、

```text
Repository
    ↓
Domain Aggregate
    ↓
Domain Behavior
    ↓
Repository::save()
```

を基本とする。

---

## 43. 一括更新

大量更新など、Aggregateを1件ずつ復元すると非現実的なUseCaseが将来発生した場合は個別に設計判断する。

例えば、

```text
数十万件の一括Migration
Bulk Maintenance
Administrative Batch
```

などまで通常のCQRS Write Ruleを機械的に適用しない。

ただし、通常のBusiness UseCaseではDomain Model経由を基本とする。

大量更新という技術要件を理由に通常のDomain Write Pathを崩さない。

---

## 44. Dashboard

DashboardはRead UseCaseとして扱う。

```text
DashboardQuery
    ↓
DashboardQueryHandler
    ↓
DashboardQueryService
    ↓
DashboardReadModel
```

Dashboard集計のためにAggregateを大量に復元しない。

以下を利用してよい。

- SQL Aggregate Function
- JOIN
- GROUP BY
- PostgreSQL固有のRead最適化

在籍社員のみを集計するRequirementもQuery Serviceの取得条件へ反映する。

---

## 45. Search

検索はRead UseCaseとして扱う。

例えば、

```text
EmployeeSearchQuery
    ↓
EmployeeSearchHandler
    ↓
EmployeeSearchQueryService
```

とする。

Query Serviceでは以下を効率的に処理する。

- Keyword
- Filter
- Sort
- Pagination

Aggregate Repositoryへ検索機能を集約しない。

---

## 46. Authorization

Command / Queryの双方でAuthorizationが必要になる。

Write:

```text
Command Handler
    ↓
UseCase Authorization
    ↓
Write処理
```

Read:

```text
Query Handler
    ↓
UseCase Authorization
    ↓
Read処理
```

特にSub Manager / Team Leaderの担当社員ScopeはRead側にも影響する。

Query ServiceそのものをSecurity Boundaryの唯一の保証地点にはしない。

---

## 47. Team LeaderのRead

Team Leaderは担当社員の閲覧のみ可能であるため、

```text
Query Handler
    ↓
ActorContext
    ↓
担当範囲Authorization
    ↓
Query Service
```

とする。

Query ServiceへLaravel User ObjectやSanctum Tokenを直接渡さない。

ApplicationでRead可能Scopeを明確にしたうえでQuery Serviceを利用する。

---

## 48. Sub ManagerのRead

Sub Managerについても、担当社員のみを対象とする。

Read UseCaseではApplication LayerがActorのAccess Scopeを判断し、Query Serviceへ必要な検索条件として渡す。

概念:

```text
ActorContext
    ↓
Application Authorization
    ↓
Accessible Employee Scope
    ↓
Query Service
```

Infrastructure側がRole Definitionの唯一の責任者にならないようにする。

---

## 49. Read Performance

Read側ではDomain ModelよりRead Performanceを優先したQuery設計が可能である。

例えば以下を利用できる。

- 必要ColumnだけSELECT
- JOIN
- Aggregate Function
- Pagination
- Indexを意識したFilter
- PostgreSQL固有機能
- CTE
- Window Function

これがWrite / Readを分離する主な利点の一つである。

---

## 50. Write Performance

WriteではRead PerformanceのためにDomain Modelを歪めない。

Write側で重要なのは以下とする。

- Business Invariant
- Aggregate Consistency
- Transaction
- Concurrency Control
- Correct State Transition

Read用JOINのしやすさだけを理由にAggregate Boundaryを変更しない。

---

## 51. CQRSとDatabase Schema

Lightweight CQRSを採用しても、Write用TableとRead用Tableを分離する必要はない。

同じSchemaを、

```text
Write
    ↓
Repository
```

と、

```text
Read
    ↓
Query Service
```

から異なる方法で利用できる。

CQRS上の責務分離とDatabase Schemaの物理分離を混同しない。

---

## 52. Query ServiceとDatabase Schema

Query ServiceはRead用途のため、複数TableをJOINしてよい。

例えば、

```text
employees
employee_skills
skills
skill_categories
```

を跨いだQueryも許容する。

Infrastructure側では必要に応じてDatabase Schemaを直接意識した最適化を行える。

ただし、そのSchema構造をApplication / Presentationへ漏らさない。

---

## 53. Read Modelの命名

Read Modelは用途が分かる名前を付ける。

例:

```text
EmployeeDetailResult
EmployeeListItem
EmployeeSkillListItem
SkillStatisticsResult
DashboardSummary
```

避ける例:

```text
EmployeeDto
DataDto
ResponseData
ItemData
```

どのRead UseCaseのためのDataかが分かる名称を優先する。

---

## 54. Command / Queryの命名

Command / QueryはUseCaseを明確に表す動詞を利用する。

Command例:

```text
RegisterEmployeeSkillCommand
UpdateEmployeeSkillCommand
DeactivateSkillCommand
RetireEmployeeCommand
ChangeUserPermissionCommand
```

Query例:

```text
GetEmployeeSkillQuery
SearchEmployeesQuery
ListSkillsQuery
GetDashboardQuery
```

技術的なCRUD名だけでなく、業務上の意味がある場合はその名称を優先する。

---

## 55. Handlerの1:1対応

Command / QueryとHandlerは原則として1:1とする。

```text
RegisterEmployeeSkillCommand
        ↓
RegisterEmployeeSkillHandler
```

```text
GetEmployeeSkillQuery
        ↓
GetEmployeeSkillHandler
```

1つの巨大Handlerで複数UseCaseをswitchする構造は採用しない。

---

## 56. Test方針

Command側では主に以下をTestする。

- Handler Flow
- Authorization
- Domain Behavior呼び出し
- Repository保存
- Transaction
- Domain Exception伝播
- Conflict処理

Query側では主に以下をTestする。

- Filter
- Search
- Sort
- Pagination
- Authorization Scope
- Read Model Mapping
- PostgreSQL Query

詳細は `12_テスト戦略.md` で定義する。

---

## 57. ディレクトリ構成

Application Layerでは以下を基本とする。

```text
Application/
└── SkillManagement/
    ├── Commands/
    │   ├── RegisterEmployeeSkill/
    │   │   ├── RegisterEmployeeSkillCommand.php
    │   │   ├── RegisterEmployeeSkillHandler.php
    │   │   └── RegisterEmployeeSkillResult.php
    │   │
    │   └── UpdateEmployeeSkill/
    │       ├── UpdateEmployeeSkillCommand.php
    │       ├── UpdateEmployeeSkillHandler.php
    │       └── UpdateEmployeeSkillResult.php
    │
    └── Queries/
        ├── GetEmployeeSkill/
        │   ├── GetEmployeeSkillQuery.php
        │   ├── GetEmployeeSkillHandler.php
        │   └── GetEmployeeSkillResult.php
        │
        └── SearchEmployeeSkills/
            ├── SearchEmployeeSkillsQuery.php
            ├── SearchEmployeeSkillsHandler.php
            └── SearchEmployeeSkillsResult.php
```

Query Service InterfaceはUseCase固有または共有範囲に応じてApplication Layerへ配置する。

Infrastructure Implementation:

```text
Infrastructure/
└── Persistence/
    └── QueryServices/
        └── SkillManagement/
            ├── EmployeeSkillQueryService.php
            └── EmployeeSearchQueryService.php
```

---

## 58. CQRS設計原則

Write側:

```text
HTTP
    ↓
Command
    ↓
Command Handler
    ↓
Domain Aggregate
    ↓
Repository
    ↓
Database
```

Read側:

```text
HTTP
    ↓
Query
    ↓
Query Handler
    ↓
Query Service
    ↓
Database
    ↓
Read Model
```

Writeでは、

> Business Consistencyを守ること

を重視する。

Readでは、

> 必要なDataを分かりやすく効率的に取得すること

を重視する。

---

## 59. 最終方針

本システムのCQRSは、

> Write処理ではDDDのAggregateとRepositoryを利用してBusiness Invariantを保証し、Read処理ではDomain Aggregateの復元に拘束されずQuery Serviceによって用途に最適化したRead Modelを取得するLightweight CQRS

とする。

CQRSはArchitectureを複雑化するために採用するものではない。

以下を目的として利用する。

- Write ModelをRead都合から守る
- Read QueryをDomain Model都合から解放する
- Repositoryの責務を明確にする
- UseCaseの意図を明示する
- Business ConsistencyとRead Performanceをそれぞれ適切に設計する

MVPではLogicalなWrite / Read分離に留める。

以下は導入しない。

```text
Command Bus
Query Bus
Event Sourcing
Read Database分離
Projection Infrastructure
CQRS専用Framework
```

必要性が具体的に発生した時点で段階的に拡張する。

CQRSの採用自体を目的化せず、

> WriteとReadで異なる要求を、それぞれ最も自然なModelと実装方法で扱えること

を最終的な設計基準とする。
