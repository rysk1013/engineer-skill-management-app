# Infrastructure Layer設計

## 1. 目的

Infrastructure Layerは、Application LayerおよびDomain Layerが必要とする技術的機能を具体的に実装するLayerとする。

主に以下を扱う。

- Database Access
- Eloquent ORM
- Repository Implementation
- Mapper
- Query Service Implementation
- Transaction
- ID Generation
- Authentication Adapter
- External Service Adapter
- Framework固有処理

Infrastructure Layerは、

> 技術的詳細をDomain / Applicationから隔離する場所

として設計する。

---

## 2. 基本方針

Infrastructure Layerでは以下を基本方針とする。

- Laravel / Eloquent / PostgreSQLなどの具体技術をInfrastructureへ集約する
- Domain Repository Interfaceを実装する
- Application Portを実装する
- Eloquent ModelをDomain Modelと分離する
- MapperでPersistence ModelとDomain Modelを変換する
- Read処理はQuery Service Implementationへ配置する
- Laravel Facadeの利用はInfrastructureでは許容する
- PostgreSQL固有機能もInfrastructure内に閉じ込める
- InfrastructureからDomain / Applicationへ技術詳細を漏らさない
- InfrastructureにBusiness Ruleを書かない
- Eloquent Model Event / ObserverにBusiness Ruleを書かない
- Laravel標準機能は積極的に利用する
- Clean ArchitectureのためだけにFramework機能を再実装しない
- 将来利用する可能性だけを理由として不要なAdapterやDirectoryを事前作成しない

---

## 3. Infrastructure Layerの責務

Infrastructure Layerは主に以下を担当する。

- Domain Repository Interfaceの実装
- Application Portの実装
- EloquentによるPersistence
- Database RecordとDomain Modelの変換
- Query ServiceによるRead処理
- Transactionの具体実装
- PostgreSQL Sequenceを利用したID生成
- SanctumなどのAuthentication実装
- External APIとの接続
- Cache / Queue / Storageなど技術的機能のAdapter実装
- Database Lockの具体実装
- Database Constraint Violationなど技術Exceptionの取扱い

Infrastructure Layerが担当するのは、

> どうやって技術的に実現するか

である。

一方で、

> 何が業務上正しいか

はDomain Layerが担当する。

また、

> 何をどの順番で実行するか

はApplication Layerが担当する。

---

## 4. 基本構成

Infrastructure Layerは以下を基本構成とする。

```text
Infrastructure/
├── Persistence/
│   ├── Eloquent/
│   │   └── Models/
│   ├── Repositories/
│   ├── Mappers/
│   └── QueryServices/
│
├── Authentication/
├── Transaction/
├── IdGeneration/
└── External/
```

必要になったものだけを段階的に追加する。

空のDirectoryや、用途が存在しない抽象化をArchitecture上の形式だけを理由として作成しない。

---

## 5. Persistence

Database関連の実装は `Persistence` 配下へ集約する。

```text
Infrastructure/
└── Persistence/
    ├── Eloquent/
    ├── Repositories/
    ├── Mappers/
    └── QueryServices/
```

Persistence内部でもWriteとReadの責務を分離する。

```text
Write
    ↓
Repository
    +
Mapper

Read
    ↓
Query Service
```

WriteではAggregate単位のPersistenceを重視する。

Readでは画面や検索用途に必要なData取得を重視する。

---

## 6. Eloquent Model

Eloquent ModelはPersistenceの技術詳細としてInfrastructureへ配置する。

```text
Infrastructure/
└── Persistence/
    └── Eloquent/
        └── Models/
            ├── EmployeeModel.php
            ├── DepartmentModel.php
            ├── SkillCategoryModel.php
            ├── SkillModel.php
            ├── EmployeeSkillModel.php
            └── UserModel.php
```

Domain Entityとは明確に分離する。

```text
Domain Entity
    ≠
Eloquent Model
```

Eloquent Modelは主に以下を担当する。

- Table Mapping
- Column Mapping
- Cast
- Eloquent Relation
- Primary Key設定
- Timestamp設定
- Persistence上必要なORM設定

Business Ruleは持たせない。

---

## 7. `app/Models` を利用しない方針

Domain Persistenceに利用するEloquent Modelは原則としてLaravel標準の `app/Models` ではなく、

```text
Infrastructure/Persistence/Eloquent/Models/
```

へ配置する。

これにより、

```text
Domain Model
```

と

```text
Persistence Model
```

の違いをCode Structure上でも明確にする。

ただし、Laravel PackageやFramework Conventionとの互換性上、標準配置が明確に有利なものまで無理に移動しない。

Architecture上の見た目よりも実運用上の合理性を優先する。

---

## 8. Eloquent Modelで避けるもの

Eloquent Modelへ以下を実装しない。

- Business Invariant
- Domain Policy
- UseCase Logic
- Authorization Logic
- 複雑な状態遷移
- Domain Behaviorの代替
- Business Ruleを伴うModel Event
- Business Ruleを伴うObserver

例えば以下のような実装は行わない。

```php
protected static function booted(): void
{
    static::saving(function (EmployeeSkillModel $model) {
        if (
            $model->work_experience === 'none'
            && $model->skill_level > 1
        ) {
            throw new ...
        }
    });
}
```

以下のBusiness RuleはDomainで保証する。

```text
実務未経験
    ↓
Skill Level 1のみ
```

Eloquent ModelはPersistence Mappingへ集中させる。

---

## 9. Eloquent Relation

Eloquent RelationはInfrastructure内部では利用できる。

例:

```php
public function skill(): BelongsTo
{
    return $this->belongsTo(
        SkillModel::class,
        'skill_id',
    );
}
```

ただし、Eloquent RelationをそのままDomain AggregateのRelationとして扱わない。

```text
Eloquent Relation
    ≠
Domain Aggregate Relation
```

Domain上のAggregate Referenceは原則としてID参照を維持する。

---

## 10. Repository Implementation

Repository ImplementationはDomainで定義されたRepository Interfaceを実装する。

```text
Domain
EmployeeSkillRepository
        ↑
        │ implements
        │
Infrastructure
EloquentEmployeeSkillRepository
```

例:

```php
final class EloquentEmployeeSkillRepository
    implements EmployeeSkillRepository
{
    public function __construct(
        private EmployeeSkillMapper $mapper,
    ) {}

    public function find(
        EmployeeSkillId $id,
    ): ?EmployeeSkill {
        $model = EmployeeSkillModel::query()
            ->find($id->value());

        return $model === null
            ? null
            : $this->mapper->toDomain($model);
    }

    public function save(
        EmployeeSkill $employeeSkill,
    ): void {
        // Persistence処理
    }
}
```

Repository Implementation内部ではEloquentやLaravel Database機能を利用できる。

---

## 11. Repositoryの責務

Repository Implementationは主に以下を担当する。

- Aggregateの取得
- Aggregateの保存
- Persistence Modelとの橋渡し
- Mapperの利用
- 必要なPersistence Lock
- Persistence Errorの適切な変換

RepositoryはAggregate単位で設計する。

以下のようなRead用途の複雑な検索処理をRepositoryへ集約しない。

- Employee一覧
- 複雑なFilter
- Dashboard
- 集計
- Report
- Search Suggestion

これらはQuery Serviceへ分離する。

---

## 12. RepositoryがTransactionを開始しない

Repository Implementationは独自にTransactionを開始しない。

避ける例:

```php
public function save(
    EmployeeSkill $employeeSkill,
): void {
    DB::transaction(function () use ($employeeSkill) {
        // ...
    });
}
```

Transaction BoundaryはApplication Handlerが決定する。

```text
Application
    ↓
Transaction Boundary決定

Infrastructure
    ↓
Transaction実行

Repository
    ↓
同一Transaction内でPersistence
```

これによりUseCase全体を1つのTransactionとして扱えるようにする。

---

## 13. Mapper

MapperはEloquent ModelとDomain Modelの相互変換を担当する。

PersistenceからDomainへの変換:

```text
Eloquent Model
    ↓
toDomain()
    ↓
Domain Model
```

DomainからPersistenceへの反映:

```text
Domain Model
    ↓
fillModel()
    ↓
Eloquent Model
```

例:

```php
final class EmployeeSkillMapper
{
    public function toDomain(
        EmployeeSkillModel $model,
    ): EmployeeSkill {
        return EmployeeSkill::reconstitute(
            new EmployeeSkillId($model->id),
            new EmployeeId($model->employee_id),
            new SkillId($model->skill_id),
            SkillLevel::from($model->skill_level),
            WorkExperience::from(
                $model->work_experience,
            ),
            // ...
        );
    }
}
```

MapperはInfrastructure Layerへ配置する。

---

## 14. `toDomain()`

`toDomain()` はPersistence上のRecordからDomain Objectを復元する。

基本的にDomain側の、

```php
reconstitute()
```

を利用する。

```text
Database
    ↓
Eloquent Model
    ↓
Mapper::toDomain()
    ↓
Aggregate::reconstitute()
```

新規登録用の、

```php
register()
```

をPersistence復元へ利用しない。

新規登録時の意味とPersistenceからの復元を明確に分離する。

---

## 15. `fillModel()`

Domain Aggregateの現在状態をEloquent Modelへ反映する場合は `fillModel()` を利用する。

概念例:

```php
public function fillModel(
    EmployeeSkill $employeeSkill,
    EmployeeSkillModel $model,
): EmployeeSkillModel {
    $model->employee_id =
        $employeeSkill->employeeId()->value();

    $model->skill_id =
        $employeeSkill->skillId()->value();

    $model->skill_level =
        $employeeSkill->skillLevel()->value;

    return $model;
}
```

新規作成 / 更新のPersistence手順については `07_Repository・Mapper.md` で詳細を定義する。

---

## 16. Mapperの責務

MapperはData Representationの変換へ集中する。

以下を原則として行わない。

- UseCase実行
- Authorization
- Business Invariantの判断
- Transaction制御
- External API呼び出し
- Query実行
- Repository相当の処理
- HTTP Response変換

Mapperは、

> Database表現とDomain表現の差異を吸収するAdapter

として扱う。

---

## 17. Query Service Implementation

Read処理の具体実装はInfrastructure Layerへ配置する。

```text
Application
EmployeeSkillQueryService
        ↑
        │ implements
        │
Infrastructure
EloquentEmployeeSkillQueryService
```

Infrastructure側のQuery Serviceでは必要に応じて以下を利用できる。

- Eloquent Query Builder
- Laravel Query Builder
- Raw SQL
- PostgreSQL固有機能

Read処理ではDomain Aggregateの復元を必須としない。

---

## 18. Query Serviceの責務

Query ServiceはRead用途に最適化したData Accessを担当する。

主な例:

- Employee一覧
- Employee詳細表示
- Employee Skill一覧
- Skill検索
- Dashboard集計
- Filter
- Sort
- Pagination
- Search
- Statistics

Query ServiceはApplication側で定義されたRead Model / Resultへ必要な形でDataをMappingする。

```text
Database
    ↓
Query Service
    ↓
Read Model / Result
```

Write RepositoryとRead Query Serviceを役割分担する。

---

## 19. ReadでEloquentを直接利用できる範囲

InfrastructureのQuery Serviceでは、Read用途であればDomain Aggregateへ変換せずEloquent Query BuilderなどからRead Modelを直接生成できる。

例えば、

```text
Eloquent Query Builder
        ↓
JOIN / Filter / Aggregate
        ↓
Read Model
```

という構成を許容する。

これはLightweight CQRSのRead側として扱う。

ただし、Eloquent Model自体をApplication / Presentationへ返さない。

---

## 20. Transaction Implementation

Transactionの具体実装はInfrastructureへ配置する。

```text
Infrastructure/
└── Transaction/
    └── LaravelTransactionManager.php
```

Application Layerで定義されたPortを実装する。

```php
final class LaravelTransactionManager
    implements TransactionManager
{
    public function run(
        callable $callback,
    ): mixed {
        return DB::transaction($callback);
    }
}
```

Application LayerからLaravel `DB` Facadeを直接利用しない。

---

## 21. Transaction責務

Transactionに関する責務を以下のように分離する。

### Application

```text
どこからどこまでを
1 Transactionにするか
```

を決定する。

### Infrastructure

```text
Laravel / PostgreSQLを使って
どうTransactionを実行するか
```

を担当する。

原則として、

```text
1 Write UseCase
    =
1 Transaction
```

を維持する。

詳細は `09_Transaction.md` で定義する。

---

## 22. Database Lock

PostgreSQLのRow Lockなどの具体的処理はInfrastructureへ配置する。

Permission Manager更新など、悲観Lockが必要なUseCaseではRepository Implementationなどから、

```sql
SELECT ... FOR UPDATE
```

相当の処理を行う。

Laravelでは必要に応じて、

```php
->lockForUpdate()
```

などを利用できる。

Application / Domain LayerはPostgreSQL固有構文を知らない。

---

## 23. Lockの責務分離

Lockについては以下の責務分担とする。

```text
なぜ同時更新を防ぐ必要があるか
        ↓
Business Requirement
Domain / Application

どのObjectを
どの順番で扱うか
        ↓
Application

SELECT FOR UPDATEなど
どうLockするか
        ↓
Infrastructure
```

複数RecordをLockする場合は、Deadlock Riskを抑えるため原則としてID昇順で取得する。

具体的なConcurrency設計は `09_Transaction.md` で定義する。

---

## 24. ID Generation

PostgreSQL Sequenceを利用したID生成ImplementationはInfrastructureへ配置する。

```text
Infrastructure/
└── IdGeneration/
    ├── PostgreSqlEmployeeIdGenerator.php
    ├── PostgreSqlSkillIdGenerator.php
    └── PostgreSqlEmployeeSkillIdGenerator.php
```

Application側のID Generator Portを実装する。

例:

```php
final class PostgreSqlEmployeeSkillIdGenerator
    implements EmployeeSkillIdGenerator
{
    public function generate(): EmployeeSkillId
    {
        // PostgreSQL SequenceからIDを取得
    }
}
```

Domain / Applicationは以下を知らない。

- Sequence名
- SQL
- PostgreSQL Driver
- `nextval()`
- Database Connection

ID Generationの技術詳細をInfrastructureへ閉じ込める。

---

## 25. IDはAggregate生成前に取得する

本システムではDomain Objectは生成時点からIDを持つ設計とする。

そのためApplication Handlerでは、

```text
ID Generator
    ↓
ID取得
    ↓
Aggregate::register()
```

の順序を基本とする。

Infrastructure側のID GeneratorがPostgreSQL SequenceからIDを取得する。

Sequenceの欠番は許容する。

---

## 26. PostgreSQL固有機能

PostgreSQL固有機能はInfrastructure内で積極的に利用できる。

主な例:

- Sequence
- `SELECT FOR UPDATE`
- `timestamptz`
- PostgreSQL固有SQL
- Index
- Constraint
- PostgreSQL固有Operator
- Query Optimization
- Execution Planを考慮したQuery

ただし、PostgreSQL固有型やSQL表現をDomain / Application Layerへ漏らさない。

---

## 27. Database Constraint

DomainがBusiness Invariantを保証している場合でも、Database Constraintを最終防衛として利用する。

基本的には、

```text
Applicationで必要な事前確認
        +
DomainでInvariant保証
        +
Database Constraint
```

の多層防御とする。

例えばEmployeeSkillの重複登録については、

```text
Application
    ↓
事前存在確認

Database
    ↓
UNIQUE Constraint
```

の両方で防御できるようにする。

---

## 28. Constraint Name

Database Constraintには原則として明示的な名前を付与する。

対象:

- UNIQUE
- CHECK
- Foreign Key
- その他Business上重要なConstraint

これによりConstraint Violation発生時に、

```text
どのBusiness Conflictが発生したか
```

をInfrastructure側で判定しやすくする。

具体的なError Mappingは `10_Exception設計.md` で定義する。

---

## 29. Authentication

Laravel Sanctumなど認証技術に依存する処理はInfrastructureへ配置する。

```text
Infrastructure/
└── Authentication/
```

主に以下を扱う。

- Sanctum Token
- Authenticated User取得Adapter
- Token関連処理
- ActorContext Implementation
- Authentication Infrastructureとの橋渡し

Application / DomainへSanctum Tokenそのものを渡さない。

---

## 30. ActorContext Implementation

Application側で定義したActorContext PortをInfrastructure側で実装する。

概念的には以下とする。

```text
Laravel Auth / Sanctum
        ↓
LaravelActorContext
        ↓
Application ActorContext
```

Application側は以下のようなUseCaseに必要な情報だけを利用する。

- UserId
- UserRole
- Permission管理可否
- 必要に応じたActor情報

Laravel Authentication ObjectそのものはApplicationへ公開しない。

---

## 31. AuthenticationとDomain Userの分離

Authentication CredentialとDomain上のUserを同一概念として扱わない。

例えば以下はAuthentication Infrastructureの関心事とする。

```text
Sanctum Token
Auth.js Session
Token Hash
Session Identifier
Authentication Credential
```

一方、Domain上では業務上必要な、

```text
UserId
UserRole
Permission管理状態
```

などを扱う。

Authentication技術の変更がDomain Modelへ影響しないようにする。

---

## 32. External Service Adapter

外部サービスとの通信ImplementationはInfrastructureへ配置する。

```text
Infrastructure/
└── External/
    └── SomeService/
        └── SomeServiceClient.php
```

Application側でGateway / Portを定義し、Infrastructure側で具体実装を提供する。

```text
Application Port
        ↑
        │ implements
        │
Infrastructure Adapter
        ↓
External Service
```

Infrastructure ImplementationではLaravel HTTP Clientなどを利用できる。

---

## 33. External APIとの境界

External APIのRequest / Response形式をDomainへ直接持ち込まない。

例えば、

```text
External JSON
    ↓
Infrastructure Adapter
    ↓
Applicationが理解できるDTO / Result
```

へ変換する。

External Service固有のField NameやStatus CodeによってDomain Modelが汚染されないようにする。

---

## 34. Laravel Facade

Infrastructure Layerでは必要に応じてLaravel Facadeを利用できる。

例:

- `DB`
- `Cache`
- `Http`
- `Storage`
- `Log`

ただし、

> Facadeを利用している処理はすべてInfrastructureである

とは考えない。

処理の責務そのものによってLayerを決定する。

Business RuleはDomainへ、UseCase LogicはApplicationへ配置し、Infrastructureでは技術的実現のためにFacadeを利用する。

---

## 35. Logging

Loggingの具体実装ではLaravel Loggingを利用できる。

Infrastructure内部の技術ログについてはLaravel Loggerを直接利用してよい。

例:

- External API Error
- Database接続問題
- Retry情報
- Adapter内部の技術情報

Domain LayerへLoggerを持ち込まない。

Application Layerから明示的なAudit / Logging機能が必要になった場合は、その目的に応じてPort導入を検討する。

単純に「Loggerを抽象化するため」だけのInterfaceは作成しない。

---

## 36. Cache

Cacheを利用する場合、RedisやLaravel Cacheなどの具体技術はInfrastructureへ配置する。

Application / Domainは以下へ直接依存しない。

```text
Redis
Laravel Cache Store
Cache Facade
```

ただしMVPでは、明確な性能上の必要性がない限りCacheを事前導入しない。

CacheをArchitecture上の必須Layerとはしない。

---

## 37. Queue

Queueを利用する場合、Laravel Queueの具体的なImplementationはInfrastructureまたはFramework Boundaryへ配置する。

Domain EntityからLaravel Jobを直接Dispatchしない。

避ける例:

```php
dispatch(
    new SomeLaravelJob(...)
);
```

をDomain Behavior内部から実行すること。

非同期処理が必要になった場合は、

```text
Application UseCase
    ↓
Port / Dispatch境界
    ↓
Laravel Queue
```

のように責務を分離する。

MVPで必要がなければ事前に抽象化しない。

---

## 38. Infrastructure Exception

DatabaseやExternal Serviceなど技術的要因によるExceptionはInfrastructure内で発生する。

主な例:

- Database Connection Error
- Unique Constraint Violation
- Foreign Key Violation
- Lock Error
- Deadlock
- External API Error
- Timeout
- Authentication Infrastructure Error

必要に応じて、ApplicationまたはPresentationが理解できるExceptionへ変換する。

Database Driver固有ExceptionをそのままPresentation Layerまで露出しない。

---

## 39. Constraint Violationの変換

Database Constraintは最終防衛として利用するため、Constraint ViolationをBusiness Conflictへ変換する必要がある場合がある。

例:

```text
PostgreSQL
UNIQUE Constraint Violation
        ↓
Infrastructure
Constraint判定
        ↓
Meaningful Exception
        ↓
Presentation
409 Conflict
```

ただしHTTP Statusへの変換そのものはInfrastructureでは行わない。

InfrastructureはHTTPを知らない。

具体的なException変換は `10_Exception設計.md` で定義する。

---

## 40. Migration

MigrationはLaravel標準の、

```text
database/migrations/
```

を利用する。

Infrastructure Layer配下へ移動しない。

```text
database/
├── factories/
├── migrations/
└── seeders/
```

Laravel標準運用との親和性を優先する。

Migrationでは主に以下を定義する。

- Table
- Column
- Primary Key
- Foreign Key
- UNIQUE Constraint
- CHECK Constraint
- Index
- Constraint Name
- Sequence関連設定

Database SchemaそのものはArchitecture Directoryへ無理に移動しない。

---

## 41. Service Providerとの関係

InterfaceとInfrastructure ImplementationのBindingはLaravel Service Providerで行う。

例:

```php
$this->app->bind(
    EmployeeSkillRepository::class,
    EloquentEmployeeSkillRepository::class,
);
```

```php
$this->app->bind(
    TransactionManager::class,
    LaravelTransactionManager::class,
);
```

```php
$this->app->bind(
    EmployeeSkillIdGenerator::class,
    PostgreSqlEmployeeSkillIdGenerator::class,
);
```

Application Handler側でInfrastructure Implementationを直接生成しない。

避ける例:

```php
new EloquentEmployeeSkillRepository(...);
```

Dependency ResolutionはComposition Rootへ集約する。

詳細は `11_Laravel Service Container・DI.md` で定義する。

---

## 42. InfrastructureからApplicationへの依存

InfrastructureはApplicationで定義されたPortを実装するため、ApplicationのInterfaceやDTOへ依存する場合がある。

例えば、

```text
Application
TransactionManager Interface
        ↑
        │
Infrastructure
LaravelTransactionManager
```

という依存は許容する。

同様に、

```text
Application
EmployeeSkillQueryService Interface
        ↑
        │
Infrastructure
EloquentEmployeeSkillQueryService
```

とする。

重要なのはApplicationがInfrastructureの具体実装へ依存しないことである。

---

## 43. InfrastructureからDomainへの依存

InfrastructureはRepository ImplementationやMapperを実装するためDomainへ依存する。

```text
Infrastructure
    ↓
Domain
```

例えば以下を利用する。

- Aggregate
- Entity
- Value Object
- Domain Enum
- Repository Interface

DomainからInfrastructureへの逆依存は作らない。

---

## 44. Infrastructureで避けるもの

Infrastructure Layerへ以下を実装しない。

- Business Invariantそのもの
- UseCaseの処理順序
- HTTP Response生成
- HTTP Status決定
- Controller
- Form Request
- API Resource
- Domain Policyの代替
- Application Authorizationの代替
- Business Ruleを含むEloquent Observer
- Domain Behaviorの代替となるRepository Logic

Infrastructureは技術的詳細へ集中する。

---

## 45. ディレクトリ構成

Infrastructure Layerは以下を基本とする。

```text
Infrastructure/
├── Persistence/
│   ├── Eloquent/
│   │   └── Models/
│   │       ├── EmployeeModel.php
│   │       ├── DepartmentModel.php
│   │       ├── SkillCategoryModel.php
│   │       ├── SkillModel.php
│   │       ├── EmployeeSkillModel.php
│   │       └── UserModel.php
│   │
│   ├── Repositories/
│   │   ├── EloquentEmployeeRepository.php
│   │   ├── EloquentSkillRepository.php
│   │   └── EloquentEmployeeSkillRepository.php
│   │
│   ├── Mappers/
│   │   ├── EmployeeMapper.php
│   │   ├── SkillMapper.php
│   │   └── EmployeeSkillMapper.php
│   │
│   └── QueryServices/
│       ├── EmployeeManagement/
│       ├── SkillManagement/
│       └── AccessControl/
│
├── Authentication/
│   └── LaravelActorContext.php
│
├── Transaction/
│   └── LaravelTransactionManager.php
│
├── IdGeneration/
│   ├── PostgreSqlEmployeeIdGenerator.php
│   ├── PostgreSqlSkillIdGenerator.php
│   └── PostgreSqlEmployeeSkillIdGenerator.php
│
└── External/
```

実際に利用しないDirectoryは事前に作成しない。

`External/` についても外部Integrationが発生した時点で具体的なSubdirectoryを追加する。

---

## 46. Infrastructure Layer設計原則

Infrastructure Layer全体では以下を維持する。

```text
Domain Repository Interface
        ↓
Repository Implementation

Domain Entity
        ↕
Mapper
        ↕
Eloquent Model

Application Query Service
        ↓
Query Service Implementation

Application Transaction Port
        ↓
Laravel Transaction

Application ID Generator Port
        ↓
PostgreSQL Sequence

Application ActorContext
        ↓
Laravel Auth / Sanctum

Application External Gateway
        ↓
External Service Adapter
```

責務は以下のように分離する。

```text
何が業務上正しいか
        ↓
Domain

何をどの順番で実行するか
        ↓
Application

HTTPとしてどう扱うか
        ↓
Presentation

技術的にどう実現するか
        ↓
Infrastructure
```

Infrastructure Layerは、

> Laravel・Eloquent・PostgreSQLなどの具体技術を最大限活用しながら、それらの技術的詳細をApplication / Domainへ漏らさないAdapter Layer

として設計する。

Clean Architectureを採用していてもLaravelの便利な機能を避ける必要はない。

一方で、

```text
Laravel / Eloquent / PostgreSQLの都合
        ↓
Business Ruleの設計
```

という依存関係は作らない。

FrameworkやDatabaseは交換可能性そのものを目的として抽象化するのではなく、Core DomainとUseCaseを技術的詳細から守るために境界を設ける。
