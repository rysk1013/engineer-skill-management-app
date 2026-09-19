# Backend 技術・Library選定 - Database・ORM

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend における Database / ORM / Persistence / Query 実装方針と、関連技術・Libraryの採用判断を定義する。

本Projectでは以下を前提とする。

- DatabaseにはPostgreSQLを採用する
- ORMにはLaravel Eloquentを採用する
- EloquentはInfrastructure Layerへ閉じ込める
- Domain ModelとEloquent Modelを分離する
- Write側はRepository + Mapperを基本とする
- Read側はQuery Service + Query Builderを基本とする
- Primary Keyはbigintを採用する
- IDはPostgreSQL Sequenceから事前取得する
- Transaction BoundaryはApplication UseCase単位とする
- Isolation LevelはREAD COMMITTEDを基本とする
- 必要箇所ではPessimistic Lockを利用する
- Database Constraintを最終的なIntegrity Defenseとして利用する

---

## 2. 基本方針

Database Accessは以下の構造を基本とする。

```text
Domain
    ↓
Repository Interface

Application
    ↓
Repository / Query Service

Infrastructure
    ├── Eloquent Model
    ├── Repository Implementation
    ├── Mapper
    ├── Query Builder
    └── PostgreSQL
```

最重要原則は以下とする。

```text
Domain Model
    ≠
Eloquent Model
```

EloquentはInfrastructure内部では積極的に利用するが、Domain Modelとしては利用しない。

---

## 3. PostgreSQL

DatabaseにはPostgreSQLを採用する。

採用Versionは以下を基本とする。

```text
PostgreSQL 18.x
```

Productionで利用するVersionは、採用Major Version内の最新Stable Minorを使用する。

環境間では可能な限りVersionを統一する。

```text
Local
CI
Staging
Production

↓
同一PostgreSQL Major Version
```

可能であればPatch Versionまで揃える。

Preview / Beta / RC Versionは利用しない。

---

## 4. PostgreSQL固有機能

PostgreSQLを明示的に採用しているため、Database Portabilityのみを目的としてPostgreSQL固有機能を避ける設計にはしない。

Requirementに応じて以下を利用できる。

```text
Sequence
RETURNING
CHECK Constraint
Partial Index
GIN / GiST
JSONB
```

ただし、

> 利用可能だから利用する

のではなく、具体的なRequirementやPerformance上の理由が存在する場合のみ採用する。

---

## 5. Eloquent ORM

ORMにはLaravel Eloquentを採用する。

```text
採用
└── Laravel Eloquent ORM
```

Eloquentの位置付けは以下とする。

```text
Infrastructure
    ↓
Persistence Model
```

Domain LayerではEloquentを使用しない。

---

## 6. Domain ModelとPersistence Model

Domain ModelとEloquent Modelは明確に分離する。

```text
Domain
└── EmployeeSkill

Infrastructure
└── EmployeeSkillModel
```

例えば以下のようなEloquent ModelはInfrastructureへ配置する。

```php
final class EmployeeSkillModel extends Model
{
    protected $table = 'employee_skills';
}
```

一方、Domain ModelはPure PHPとして実装する。

```php
final class EmployeeSkill
{
    // Domain behavior
}
```

---

## 7. Eloquent Modelの責務

Eloquent Modelは主に以下を担当する。

- Database Row Mapping
- Relationship Mapping
- Persistence
- Cast
- Infrastructure向けQuery
- Timestamp連携

Business RuleはEloquent Modelへ配置しない。

以下のような実装は原則禁止する。

```php
protected static function booted(): void
{
    static::saving(function (EmployeeSkillModel $model): void {
        // Domain Rule
    });
}
```

Model Event / ObserverへDomain Invariantを隠さない。

---

## 8. Active Recordの制限

Domain Entity自身からPersistence処理を実行しない。

以下のような設計は採用しない。

```php
$employeeSkill->save();
```

Domain ObjectからEloquent Relationshipを辿る設計も採用しない。

```php
$employeeSkill->employee;
$employeeSkill->skill;
```

PersistenceはRepository経由で行う。

```text
Domain Entity
    ↓
Repository
    ↓
Mapper
    ↓
Eloquent Model
    ↓
PostgreSQL
```

---

## 9. Repository

Write側ではRepository Patternを採用する。

Repository InterfaceはDomain Layerに配置する。

例：

```php
interface EmployeeSkillRepository
{
    public function findById(
        EmployeeSkillId $id,
    ): ?EmployeeSkill;

    public function save(
        EmployeeSkill $employeeSkill,
    ): void;
}
```

Repository ImplementationはInfrastructure Layerへ配置する。

```text
Domain
└── EmployeeSkillRepository

Infrastructure
└── EloquentEmployeeSkillRepository
```

---

## 10. Repositoryの単位

RepositoryはAggregate Root単位で設計する。

```text
Repository
    ↓
Aggregate Root
```

Generic Repositoryは原則採用しない。

以下のような共通Interfaceは作成しない。

```php
interface BaseRepository
{
    public function find(int $id): ?object;

    public function save(object $entity): void;

    public function delete(object $entity): void;
}
```

各Aggregateに必要なPersistence操作のみ定義する。

---

## 11. Repository Package

Repository用External Packageは採用しない。

```text
Repository Package
    → 不採用
```

Laravel Eloquent + Project固有Repository Implementationで十分とする。

---

## 12. Mapper

Domain ModelとEloquent Modelの変換には明示的Mapperを利用する。

```text
Eloquent Model
    ↓
Mapper
    ↓
Domain Model
```

および、

```text
Domain Model
    ↓
Mapper
    ↓
Eloquent Model
```

の両方向を扱う。

例：

```php
final class EmployeeSkillMapper
{
    public function toDomain(
        EmployeeSkillModel $model,
    ): EmployeeSkill {
        return EmployeeSkill::reconstitute(
            // ...
        );
    }

    public function fillModel(
        EmployeeSkill $domain,
        EmployeeSkillModel $model,
    ): void {
        // ...
    }
}
```

---

## 13. AutoMapper

AutoMapper系Libraryは採用しない。

理由：

- Mappingを明示的に保てる
- Domain / Persistence境界が見えやすい
- Reflection依存を避けられる
- Domain Modelの変更意図を明示できる

MapperはProject固有Classとして実装する。

---

## 14. Repository保存フロー

Write側の基本フローは以下とする。

```text
Application Handler
    ↓
Repository Interface
    ↓
Eloquent Repository
    ↓
Mapper
    ↓
Eloquent Model
    ↓
PostgreSQL
```

概念例：

```php
public function save(
    EmployeeSkill $employeeSkill,
): void {
    $model = EmployeeSkillModel::query()
        ->find($employeeSkill->id()->value)
        ?? new EmployeeSkillModel();

    $this->mapper->fillModel(
        $employeeSkill,
        $model,
    );

    $model->save();
}
```

---

## 15. Migration

Schema管理にはLaravel Migrationを採用する。

```text
採用
└── Laravel Migration
```

別のMigration Frameworkは導入しない。

Migration FileをGit管理し、Database SchemaのVersion Historyとして扱う。

---

## 16. Migrationの責務

Migrationでは以下を明示的に定義する。

```text
Table
Column
Primary Key
Foreign Key
UNIQUE
CHECK
Index
Default
Nullable
```

DatabaseにもIntegrity Enforcementを持たせる。

```text
Presentation
    ↓
Input Validation

Domain
    ↓
Business Invariant

Database
    ↓
Final Integrity Defense
```

という多層防御を採用する。

---

## 17. Primary Key

Primary Keyにはbigintを採用する。

```text
Primary Key
    ↓
bigint
```

UUID / ULIDはMVPでは利用しない。

---

## 18. PostgreSQL Sequence

ID生成にはPostgreSQL Sequenceを利用する。

Aggregate生成前にIDを必要とするため、Sequenceから事前取得する。

概念例：

```sql
SELECT nextval('employees_id_seq');
```

処理フローは以下。

```text
PostgreSQL Sequence
    ↓
Typed ID
    ↓
Aggregate::register()
    ↓
Repository::save()
```

Sequenceの欠番は正常動作として許容する。

Rollback時の番号再利用を前提にしない。

---

## 19. ID Generator

Application LayerからSequenceへ直接依存しない。

Application PortとしてID Generatorを定義する。

```php
interface EmployeeIdGenerator
{
    public function generate(): EmployeeId;
}
```

Infrastructure側でPostgreSQL Sequenceを利用する。

```php
final class PostgreSqlEmployeeIdGenerator
    implements EmployeeIdGenerator
{
    public function generate(): EmployeeId
    {
        // SELECT nextval(...)
    }
}
```

---

## 20. ID Generatorの粒度

Aggregate単位で型安全なGeneratorを用意する。

例：

```text
EmployeeIdGenerator
EmployeeSkillIdGenerator
SkillIdGenerator
SkillCategoryIdGenerator
DepartmentIdGenerator
UserIdGenerator
```

以下のような汎用Generatorだけで全IDを扱わない。

```php
interface IdGenerator
{
    public function generate(): int;
}
```

Infrastructure内部で共通処理を再利用することは許可する。

---

## 21. Foreign Key

Relationには原則Foreign Key Constraintを設定する。

例：

```text
employee_skills.employee_id
    ↓
employees.id

employee_skills.skill_id
    ↓
skills.id
```

ApplicationだけでReferential Integrityを保証しない。

Delete / Update ActionはDomain Lifecycleに合わせて個別に定義する。

機械的な`CASCADE DELETE`は避ける。

---

## 22. UNIQUE Constraint

Business上重複してはいけない組み合わせにはUNIQUE Constraintを設定する。

EmployeeSkillでは以下を基本とする。

```text
UNIQUE (
    employee_id,
    skill_id
)
```

重複チェックはApplicationでも行う。

```text
Application
    ↓
事前チェック

Database
    ↓
UNIQUE Constraint
```

ConcurrencyによるRace Conditionの最終防衛はDatabase Constraintが担当する。

---

## 23. CHECK Constraint

単純なData IntegrityにはCHECK Constraintを利用する。

例：

```text
skill_level BETWEEN 1 AND 5
experience_months >= 0
```

ただし複雑なDomain BehaviorをすべてCHECKへ移さない。

判断基準は以下。

```text
Simple Data Integrity
    ↓
CHECK Constraint

Business Invariant / Behavior
    ↓
Domain
```

Domain RuleとDatabase Integrityの責務を分離する。

---

## 24. Transaction

Database TransactionにはLaravel標準機能を利用する。

Infrastructure側で、

```php
DB::transaction(...);
```

を利用できる。

ただしApplication HandlerからLaravel Facadeを直接利用する設計にはしない。

```text
Application
    ↓
Transaction Port
    ↓
Infrastructure
    ↓
Laravel Database Transaction
```

とする。

---

## 25. Transaction Boundary

Transaction BoundaryはApplication UseCase単位とする。

```text
1 Handler
    ≒
1 UseCase
    ≒
1 Transaction
```

Controller単位やRepository Method単位でTransactionを乱立させない。

詳細はBackend Architectureの`09_Transaction.md`に従う。

---

## 26. Isolation Level

基本Isolation Levelには、

```text
READ COMMITTED
```

を採用する。

MVPではSERIALIZABLEを標準にしない。

Concurrency Problemは以下を組み合わせて対処する。

```text
READ COMMITTED
+
Pessimistic Lock
+
UNIQUE / CHECK Constraint
```

---

## 27. Pessimistic Lock

Concurrency Controlが必要なUseCaseではPessimistic Lockを採用する。

PostgreSQLの、

```sql
SELECT ... FOR UPDATE
```

を利用する。

Laravelでは以下を利用できる。

```php
$query->lockForUpdate();
```

Lockは必ずTransaction内で利用する。

---

## 28. Lock順序

複数RowをLockする場合は、Deadlock Riskを下げるためLock順序を統一する。

基本は、

```text
ID昇順
```

とする。

```text
ID 10
    ↓
ID 20
    ↓
ID 30
```

UseCaseごとにLock順序を変えない。

---

## 29. Permission管理とLock

以下のInvariantをConcurrency下でも維持する。

```text
Administrator
+
can_manage_permissions = true

↓
最低1人
```

処理は以下を基本とする。

```text
Transaction開始
    ↓
必要なRowをFOR UPDATE
    ↓
現在状態確認
    ↓
変更後も最低1人残るか検証
    ↓
変更
    ↓
Commit
```

単純な事前SELECTだけで保証しない。

---

## 30. Read Query

CQRSのRead側ではRepositoryを必須としない。

基本構成は以下。

```text
Query
    ↓
Query Handler / Query Service
    ↓
Laravel Query Builder
    ↓
PostgreSQL
    ↓
Read Model
```

Read UseCaseのためだけにDomain Aggregateを復元しない。

---

## 31. Write / Read DB Access

WriteとReadではDB Access方法を分ける。

```text
Write
    ↓
Aggregate
    ↓
Repository
    ↓
Mapper
    ↓
Eloquent
```

```text
Read
    ↓
Query Service
    ↓
Query Builder
    ↓
Read Model
```

これをLightweight CQRSの基本とする。

---

## 32. Laravel Query Builder

Read側ではLaravel Query Builderを積極的に利用する。

特に以下で利用する。

- JOIN
- Filter
- Sort
- Search
- Aggregate
- Count
- Dashboard Query
- Report Query

Query BuilderをDomain Layerへ露出させない。

---

## 33. EloquentとQuery Builderの使い分け

以下を基本とする。

| 用途 | 推奨 |
|---|---|
| Aggregate Persistence | Eloquent |
| 単純Read | Eloquent / Query Builder |
| JOINの多いRead | Query Builder |
| 集計 | Query Builder |
| Dashboard | Query Builder |
| Complex Search | Query Builder |
| Domain Aggregate復元 | Repository + Eloquent |

一律にどちらかへ統一しない。

---

## 34. Sort Column

Clientから受け取った文字列をそのままORDER BY Columnとして利用しない。

以下のような方式を採用する。

```text
API sort key
    ↓
Allow List
    ↓
Database Column
```

例：

```php
$sortColumns = [
    'name' => 'employees.name',
    'createdAt' => 'employees.created_at',
];
```

Column NameはParameter Bindingできないため、Allow Listで制御する。

---

## 35. Raw SQL

Raw SQLは禁止しない。

以下の場合のみ利用を検討する。

- Query Builderでは不自然になる
- PostgreSQL固有機能を利用する
- Performance改善が必要
- 複雑なAggregate Query
- Query Planを明示的に最適化したい

Raw SQLを利用する場合も値は必ずBindingする。

以下は禁止する。

```php
$sql = "SELECT * FROM employees WHERE name = '$name'";
```

---

## 36. N+1 Query

Eloquent利用時はN+1 Queryを防止する。

必要なRelationは明示的にEager Loadする。

```php
EmployeeModel::query()
    ->with(['department'])
    ->get();
```

ただし、複雑な一覧表示を巨大なEloquent Object Graphとして取得しない。

複雑なReadはQuery Serviceへ切り出す。

---

## 37. Pagination

Paginationは`02_HTTP・API.md`の決定に従う。

MVPではOffset Paginationを採用する。

```text
?page=1
&per_page=20
```

Infrastructure内部ではLaravel Paginatorを利用できる。

ただし、

```text
LengthAwarePaginator
```

などのLaravel固有型をApplication Boundaryへそのまま露出させないことを推奨する。

必要に応じて独自Page Resultへ変換する。

---

## 38. Soft Delete

Laravel `SoftDeletes`を全Entityへ標準採用しない。

```text
SoftDeletes
    → 必要なEntityだけ検討
```

今回の主要LifecycleはDomain上の意味を持つため、

```text
is_active
employment_status
retired_at
```

等で明示的に表現する。

---

## 39. Skillの無効化

Skillは完全削除せず無効化保持する。

Laravel Soft Deleteではなく、Domain上の状態として表現する。

例：

```text
skills.is_active
```

または同等のStatus表現とする。

```text
Active
    ↓
Inactive
```

というDomain Lifecycleとして扱う。

---

## 40. Retired Employee

退職Employeeは以下のLifecycleを持つ。

```text
Active
    ↓
Retired
    ↓
3年間保持
    ↓
Administrator確認
    ↓
Hard Delete
```

このLifecycleを単純な`deleted_at`だけで表現しない。

退職状態とDeletionを明確に区別する。

---

## 41. Hard Delete

Business Requirement上、最終的に削除するEntityについてはHard Deleteを許可する。

ただし以下を確認してから実行する。

- 保持期間
- Administrator確認
- Related Data
- Audit Requirement
- Referential Integrity

不用意なCascade Deleteは避ける。

---

## 42. Timestamp

基本TimestampとしてLaravel標準の以下を利用する。

```text
created_at
updated_at
```

ただしBusiness上意味のある日時は専用Columnとして持つ。

例：

```text
retired_at
last_used_at
permission_changed_at
```

`updated_at`をBusiness Event日時の代用にしない。

---

## 43. Date / Time Column

時点を表す日時はPostgreSQLのTimezone-aware Timestampを基本候補とする。

ApplicationではUTCを基準とする。

```text
Database
    ↓
UTC

Application
    ↓
UTC

Presentation
    ↓
必要に応じてTimezone変換
```

年月のみを意味する値はTimestampに変換しない。

例：

```text
2026-09
```

は`YearMonth`として別途設計する。

詳細は`08_Serialization・Date・ID.md`で定義する。

---

## 44. Index

IndexはQuery Patternに基づいて設計する。

主な対象：

```text
Foreign Key
JOIN Column
Search Condition
Sort Condition
UNIQUE Constraint
Frequently Filtered Column
```

必要性のないIndexを大量に作成しない。

---

## 45. Foreign Key Index

PostgreSQLではForeign Keyを定義しても、参照元Column側のIndexが自動的に作成されるわけではない。

そのため、以下を個別に検討する。

```text
employee_skills.employee_id
employee_skills.skill_id
sub_manager_assignments.employee_id
team_leader_assignments.employee_id
```

JOIN / Delete / Update Patternを踏まえてIndexを定義する。

---

## 46. Composite Index

複数Columnを組み合わせて頻繁に検索する場合はComposite Indexを検討する。

例：

```text
(employment_status, department_id)
```

ただし実際のQuery Patternを確認して決定する。

Column順序もQuery Patternに基づいて選択する。

---

## 47. Partial Index

PostgreSQL Partial Indexは必要に応じて利用できる。

例えば、

```text
Active Employeeのみ頻繁に検索
```

する場合、

```sql
WHERE employment_status = 'active'
```

に限定したIndexを将来的に検討できる。

MVP開始時から不要に導入しない。

---

## 48. EXPLAIN

Performance Issueや重要QueryではPostgreSQLの以下を利用する。

```text
EXPLAIN
EXPLAIN ANALYZE
```

Index追加は推測だけで行わずQuery Planを確認する。

Performance監視の詳細は`10_Observability.md`で定義する。

---

## 49. Seeder

Initial / Development DataにはLaravel Seederを利用する。

主な用途：

- Master Data
- Development Data
- Local Environment Initial Data

Migration内へ大量のApplication Data投入処理を混在させない。

Schema変更とData Seedを可能な限り分離する。

---

## 50. Model Factory

Feature / Infrastructure Test用Data作成にはLaravel Model Factoryを利用する。

```text
Feature Test
Infrastructure Test
    ↓
Laravel Model Factory
```

Domain Unit TestではLaravel Model Factoryへ依存しない。

Domain Testでは必要に応じてTest Builder / Object Mother等をProject内で用意する。

---

## 51. Stored Procedure

Stored ProcedureはMVPでは採用しない。

```text
Stored Procedure
    → 不採用
```

Business LogicをDatabase側へ分散させない。

Application / DomainをBusiness Logicの中心とする。

---

## 52. Database Trigger

Database Triggerは原則採用しない。

```text
Database Trigger
    → 原則不採用
```

以下をTriggerへ隠さない。

- Business Rule
- Domain State Transition
- Audit Logic
- Application Workflow

DB Layerでしか適切に保証できないRequirementが将来発生した場合のみ再検討する。

---

## 53. Audit

Audit LogをDatabase Triggerだけで実装しない。

Auditの責務はApplication / Infrastructure側で明示的に扱う。

詳細は`09_Log・Audit.md`で決定する。

---

## 54. Doctrine

Doctrine ORMは採用しない。

```text
Doctrine ORM
    → 不採用
```

Laravel EloquentとDomain Model分離で必要なArchitectureを実現できるため、2つ目のORMを導入しない。

---

## 55. Doctrine DBAL

Doctrine DBALをDatabase Access Layerとして常用しない。

Laravel Schema Builder / Query Builder / Eloquentを基本とする。

Migration上の特定機能等でLaravel内部依存として利用される場合まで禁止するものではないが、Projectの主要Database APIとしては採用しない。

---

## 56. Database Abstraction

複数Database製品への切替を目的とした独自Abstraction Layerは作らない。

本ProjectではPostgreSQLを明確に選択している。

```text
MySQL
PostgreSQL
SQLite
SQL Server

すべて切替可能
```

を目標にしない。

ただしDomain LayerがDatabaseへ直接依存しないArchitectureは維持する。

---

## 57. Library採用判断

| Library / 技術 | 判断 |
|---|---|
| PostgreSQL | 採用 |
| PostgreSQL 18.x | 採用 |
| Laravel Eloquent | 採用 |
| Laravel Query Builder | 採用 |
| Laravel Migration | 採用 |
| Laravel Seeder | 採用 |
| Laravel Model Factory | 採用 |
| Laravel Database Transaction | Infrastructureで採用 |
| Repository Pattern | 採用 |
| Repository Package | 不採用 |
| Mapper | 自前実装 |
| AutoMapper Package | 不採用 |
| PostgreSQL Sequence | 採用 |
| UUID / ULID | 不採用 |
| Foreign Key | 採用 |
| UNIQUE Constraint | 採用 |
| CHECK Constraint | 採用 |
| Pessimistic Lock | 必要箇所で採用 |
| Optimistic Lock | MVPでは不採用 |
| READ COMMITTED | 採用 |
| Raw SQL | 必要時のみ |
| PostgreSQL固有機能 | 必要時に採用 |
| SoftDeletes | 標準採用しない |
| Stored Procedure | 不採用 |
| Database Trigger | 原則不採用 |
| Doctrine ORM | 不採用 |
| Doctrine DBAL | 常用しない |

---

## 58. 採用技術・方針一覧

| 項目 | 決定 |
|---|---|
| Database | PostgreSQL |
| Version | 18.x Latest Stable Minor |
| ORM | Laravel Eloquent |
| Eloquent Layer | Infrastructure |
| Domain = Eloquent Model | 禁止 |
| Persistence Model | Eloquent Model |
| Repository Interface | Domain |
| Repository Implementation | Infrastructure |
| Repository単位 | Aggregate Root |
| Generic Repository | 原則不採用 |
| Mapper | 明示的Mapper |
| AutoMapper | 不採用 |
| Migration | Laravel Migration |
| Primary Key | bigint |
| ID Generation | PostgreSQL Sequence |
| ID事前取得 | 採用 |
| Sequence欠番 | 許容 |
| ID Generator | Application Port |
| Foreign Key | 原則設定 |
| UNIQUE | 積極利用 |
| CHECK | Simple Integrityに利用 |
| Transaction | UseCase単位 |
| Transaction実装 | Laravel |
| Isolation Level | READ COMMITTED |
| Pessimistic Lock | `FOR UPDATE` |
| Laravel Lock API | `lockForUpdate()` |
| Lock順序 | ID昇順 |
| Optimistic Lock | 不採用 |
| Write Access | Repository + Mapper + Eloquent |
| Read Access | Query Service + Query Builder |
| Raw SQL | 必要時のみ |
| PostgreSQL-specific Feature | Requirementに応じ利用 |
| N+1対策 | Eager Load / Query Service |
| Pagination | Offset Pagination |
| Soft Delete | Defaultでは不採用 |
| Skill削除 | 無効化 |
| Retired Employee | 3年保持後確認削除 |
| Timestamp | `created_at` / `updated_at` + Domain固有日時 |
| Timezone | UTC基準 |
| Index | Query Patternベース |
| Seeder | Laravel Seeder |
| Factory | Laravel Model Factory |
| Stored Procedure | 不採用 |
| Trigger | 原則不採用 |
| Doctrine ORM | 不採用 |

---

## 59. 最終Architecture

Write Sideは以下とする。

```text
Command
    ↓
Command Handler
    ↓
Repository Interface
    ↓
Eloquent Repository
    ↓
Mapper
    ↓
Eloquent Model
    ↓
PostgreSQL
```

Read Sideは以下とする。

```text
Query
    ↓
Query Handler / Query Service
    ↓
Laravel Query Builder
    ↓
PostgreSQL
    ↓
Read Model
```

ID生成は以下。

```text
Application
    ↓
ID Generator Port
    ↓
PostgreSQL Sequence
    ↓
Typed ID
    ↓
Aggregate::register()
```

Concurrency Controlは以下とする。

```text
Application UseCase
    ↓
Transaction
    ↓
READ COMMITTED
    ↓
必要に応じてFOR UPDATE
    ↓
Domain Invariant
    ↓
Database Constraint
```

---

## 60. 最終方針

Database Layerでは、

> PostgreSQLの機能を適切に利用しながら、EloquentをInfrastructure詳細として閉じ込める

ことを基本方針とする。

Write側では、

```text
Aggregate
+
Repository
+
Mapper
+
Eloquent
```

を利用し、Domain ModelとPersistence Modelを明確に分離する。

Read側では、

```text
Query Service
+
Laravel Query Builder
+
Read Model
```

を利用し、一覧・検索・集計のためだけにAggregateを復元しない。

Database Integrityについては、

```text
Application Check
+
Domain Invariant
+
Database Constraint
```

という多層防御を採用する。

Concurrencyについては、

```text
READ COMMITTED
+
Pessimistic Lock
+
Database Constraint
```

を基本とする。

不要なORM / Repository / Mapping Packageを追加せず、

> PostgreSQL + Laravel Eloquent + Laravel Query Builder + 明示的Repository / Mapper

という構成を採用する。
