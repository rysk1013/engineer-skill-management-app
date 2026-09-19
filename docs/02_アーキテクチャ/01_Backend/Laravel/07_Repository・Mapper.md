# Repository・Mapper設計

## 1. 目的

Repositoryは、Domain Aggregateの永続化に関する抽象を提供する。

Mapperは、Domain ModelとPersistence Modelの相互変換を担当する。

Repository / Mapperを利用することで、

- Domain Model
- Eloquent Model
- Database Schema

を明確に分離する。

基本方針は、

> RepositoryはAggregateの保存・復元を担当し、MapperはDomain表現とPersistence表現の変換だけを担当する

とする。

---

## 2. 基本方針

- Repository InterfaceはDomain Layerに配置する
- Repository ImplementationはInfrastructure Layerに配置する
- RepositoryはAggregate単位で設計する
- RepositoryはEloquent Modelを外部へ公開しない
- Repository InterfaceではLaravel固有型を利用しない
- 複雑なRead検索はRepositoryへ追加しない
- Read用途はQuery Serviceへ分離する
- MapperはInfrastructure Layerに配置する
- Mapperは `toDomain()` / `fillModel()` を基本とする
- Persistence復元にはDomainの `reconstitute()` を利用する
- RepositoryがTransactionを開始しない
- Business RuleをRepository / Mapperへ書かない
- Generic Repositoryは採用しない

---

## 3. Repositoryの役割

Repositoryは、

> Domainから見たAggregate Collectionのような永続化境界

として扱う。

主に以下を担当する。

- Aggregateの取得
- Aggregateの保存
- Persistence Modelの取得
- MapperによるDomain復元
- Persistenceへの状態反映
- 必要な悲観Lock付き取得

RepositoryはDatabase Table単位ではなくAggregate単位で設計する。

---

## 4. Repository Interface

Repository InterfaceはDomain Layerへ配置する。

```text
Domain/
└── SkillManagement/
    └── Repositories/
        └── EmployeeSkillRepository.php
```

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

Repository Interfaceには、Domainが必要とする操作だけを定義する。

---

## 5. Repository Interfaceで利用しない型

Repository Interfaceでは以下を利用しない。

- Eloquent Model
- Eloquent Builder
- Laravel Collection
- Query Builder
- DB Connection
- HTTP Request
- Laravel Paginator
- Infrastructure固有DTO

避ける例:

```php
public function find(
    EmployeeSkillId $id,
): ?EmployeeSkillModel;
```

推奨:

```php
public function find(
    EmployeeSkillId $id,
): ?EmployeeSkill;
```

Domain Repository InterfaceからPersistence技術を見えないようにする。

---

## 6. Repositoryの基本Method

Repositoryには必要最小限のMethodだけを定義する。

代表的なMethodは以下とする。

```text
find()
save()
```

UseCase上必要な場合のみ、

```text
remove()
exists...
findForUpdate()
```

などを追加する。

すべてのRepositoryへ形式的に同じCRUD Methodを持たせない。

AggregateごとのDomain / UseCaseに必要な操作を定義する。

---

## 7. `find()`

`find()` はIDからAggregateを取得する。

例:

```php
public function find(
    EmployeeSkillId $id,
): ?EmployeeSkill;
```

対象が存在しない場合は原則として `null` を返す。

Repository自身がUseCase固有のNot Found Exceptionを投げない。

Application Handlerで、対象が存在しないことがUseCase上の失敗であると判断する。

例:

```php
$employeeSkill = $repository->find($id);

if ($employeeSkill === null) {
    throw new EmployeeSkillNotFound(
        $id,
    );
}
```

これにより、

```text
Persistence上存在しない
```

という事実と、

```text
このUseCaseではNot Found Errorである
```

という判断を分離する。

---

## 8. `save()`

`save()` はAggregateの現在状態をPersistenceへ反映する。

```php
public function save(
    EmployeeSkill $employeeSkill,
): void;
```

新規 / 更新のどちらでも基本的に `save()` を利用する。

Application Layerは以下を知らない。

- INSERT
- UPDATE
- Eloquent `save()`
- SQL
- Database Recordの存在状態

Persistence方式の違いはInfrastructureへ閉じ込める。

---

## 9. 新規作成と更新

本システムではAggregateは生成時点からIDを持つ。

そのため、

```text
IDを持っている
    =
既存Recordである
```

とは判断できない。

新規AggregateもID Generatorから事前取得したIDを保持している。

概念的には以下となる。

```text
ID Generator
    ↓
ID取得
    ↓
Aggregate::register()
    ↓
Repository::save()
```

Repository Implementationは、新規Recordか既存RecordかをPersistence側で判断する。

---

## 10. `save()` の基本実装

MVPではRepository Implementation側で対象Modelを検索し、存在しない場合は新規Modelを生成する方式を基本とする。

例:

```php
public function save(
    EmployeeSkill $employeeSkill,
): void {
    $model = EmployeeSkillModel::query()
        ->find(
            $employeeSkill
                ->id()
                ->value(),
        );

    if ($model === null) {
        $model =
            new EmployeeSkillModel();

        $model->id =
            $employeeSkill
                ->id()
                ->value();
    }

    $this->mapper->fillModel(
        $employeeSkill,
        $model,
    );

    $model->save();
}
```

Application LayerへINSERT / UPDATEの区別を持ち込まない。

---

## 11. `updateOrCreate()` を基本としない

Laravelの `updateOrCreate()` は便利だが、Aggregate Repositoryの標準実装とはしない。

理由:

- MappingがArray中心になりやすい
- Mapperの責務が曖昧になりやすい
- Domain ModelとPersistence Modelの境界が弱くなる
- 新規 / 更新のPersistence Flowが見えにくくなる

基本形は、

```text
Model取得
    ↓
存在しない場合Model生成
    ↓
Mapper::fillModel()
    ↓
Model::save()
```

とする。

明確な理由がある場合に `updateOrCreate()` の利用そのものを禁止するわけではない。

---

## 12. Repository Implementation

Repository ImplementationはInfrastructure Layerへ配置する。

```text
Infrastructure/
└── Persistence/
    └── Repositories/
        └── EloquentEmployeeSkillRepository.php
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
        $model =
            EmployeeSkillModel::query()
                ->find($id->value());

        if ($model === null) {
            return null;
        }

        return $this->mapper
            ->toDomain($model);
    }

    public function save(
        EmployeeSkill $employeeSkill,
    ): void {
        $model =
            EmployeeSkillModel::query()
                ->find(
                    $employeeSkill
                        ->id()
                        ->value(),
                );

        if ($model === null) {
            $model =
                new EmployeeSkillModel();

            $model->id =
                $employeeSkill
                    ->id()
                    ->value();
        }

        $this->mapper->fillModel(
            $employeeSkill,
            $model,
        );

        $model->save();
    }
}
```

EloquentやDatabaseに関する処理はInfrastructure Implementation内へ閉じ込める。

---

## 13. RepositoryでBusiness Ruleを書かない

Repository ImplementationにはBusiness Ruleを書かない。

避ける例:

```php
if (
    $employeeSkill->workExperience()
        === WorkExperience::NONE
    && $employeeSkill->skillLevel()
        !== SkillLevel::LEVEL_1
) {
    throw new InvalidSkillLevel(...);
}
```

このような状態はDomain側で成立できないようにする。

Repositoryは、

> 正しいDomain AggregateをPersistenceへ保存する

ことに集中する。

---

## 14. Repositoryと重複確認

Write UseCase上、保存前の存在確認が必要な場合は、Domain上意味のあるMethodをRepositoryへ追加できる。

例えばEmployeeSkillでは、

```text
employee_id
+
skill_id
```

が一意である。

この場合、

```php
public function existsByEmployeeAndSkill(
    EmployeeId $employeeId,
    SkillId $skillId,
): bool;
```

のようなMethodを定義できる。

Applicationでは、

```text
事前存在確認
    ↓
Aggregate生成
    ↓
save()
```

を行える。

ただし、Concurrent Requestによる競合を完全には防げないため、Databaseの `UNIQUE` Constraintも必ず維持する。

---

## 15. Repositoryを検索Serviceにしない

以下のようなRead用途のMethodをAggregate Repositoryへ増やさない。

```php
searchEmployees(...);

paginateSkills(...);

getDashboardStatistics(...);

findSkillsByKeyword(...);

getEmployeeSkillSummary(...);
```

Repositoryの責務が、

```text
Aggregate Persistence
```

から、

```text
あらゆるDatabase Access
```

へ拡大することを防ぐ。

---

## 16. Query Serviceとの分離

RepositoryとQuery Serviceを以下のように分離する。

```text
Write
    ↓
Repository
    ↓
Aggregate
```

```text
Read
    ↓
Query Service
    ↓
Read Model / Result
```

Repositoryは主にCQRSのWrite側で利用する。

Read側はApplication Query HandlerからQuery Serviceを利用する。

---

## 17. Pagination

Paginationを伴うRead処理はQuery Serviceで実装する。

Repository InterfaceからLaravel Paginatorを返さない。

避ける例:

```php
public function paginate(
    int $page,
): LengthAwarePaginator;
```

Query Serviceでは必要に応じてLaravel Paginationを内部利用できるが、Application LayerへはApplication固有のResultとして返す。

概念例:

```text
Laravel Pagination
        ↓
Infrastructure
        ↓
Application Pagination Result
```

---

## 18. Mapperの役割

Mapperは、

```text
Persistence Representation
        ↕
Domain Representation
```

の変換を担当する。

基本Methodは以下とする。

```text
toDomain()
fillModel()
```

MapperはInfrastructure Layerへ配置する。

---

## 19. `toDomain()`

`toDomain()` はEloquent ModelからDomain Aggregateを復元する。

例:

```php
public function toDomain(
    EmployeeSkillModel $model,
): EmployeeSkill {
    return EmployeeSkill::reconstitute(
        new EmployeeSkillId(
            $model->id,
        ),
        new EmployeeId(
            $model->employee_id,
        ),
        new SkillId(
            $model->skill_id,
        ),
        SkillLevel::from(
            $model->skill_level,
        ),
        WorkExperience::from(
            $model->work_experience,
        ),
        $model->experience_months === null
            ? null
            : ExperiencePeriod::fromMonths(
                $model->experience_months,
            ),
        $model->last_used_month === null
            ? null
            : LastUsedMonth::fromString(
                $model->last_used_month,
            ),
    );
}
```

Persistenceからの復元にはDomainの `reconstitute()` を利用する。

---

## 20. `register()` と `reconstitute()` の分離

Domain Objectには、新規生成用とPersistence復元用で異なる入口を持たせる。

```text
新規生成
    ↓
register()
```

```text
Persistence復元
    ↓
reconstitute()
```

Mapperは `reconstitute()` を利用する。

Persistence復元時に `register()` を利用しない。

これにより、

- 新規登録固有処理
- Creation Event
- 新規登録時のみ必要な処理

などを復元時に誤って実行することを防ぐ。

---

## 21. `fillModel()`

`fillModel()` はDomain Aggregateの現在状態をEloquent Modelへ反映する。

例:

```php
public function fillModel(
    EmployeeSkill $employeeSkill,
    EmployeeSkillModel $model,
): EmployeeSkillModel {
    $model->employee_id =
        $employeeSkill
            ->employeeId()
            ->value();

    $model->skill_id =
        $employeeSkill
            ->skillId()
            ->value();

    $model->skill_level =
        $employeeSkill
            ->skillLevel()
            ->value;

    $model->work_experience =
        $employeeSkill
            ->workExperience()
            ->value;

    $model->experience_months =
        $employeeSkill
            ->experiencePeriod()
            ?->totalMonths();

    $model->last_used_month =
        $employeeSkill
            ->lastUsedMonth()
            ?->toString();

    return $model;
}
```

Mapper自身はPersistenceを実行しない。

---

## 22. Mapperが `save()` を呼ばない

Mapperの責務はData Representationの変換だけとする。

以下のような実装は避ける。

```php
public function persist(
    EmployeeSkill $employeeSkill,
): void {
    $model =
        new EmployeeSkillModel();

    // Mapping...

    $model->save();
}
```

基本フローは以下とする。

```text
Repository
    ↓
Model取得 / Model生成
    ↓
Mapper::fillModel()
    ↓
Repository
    ↓
Model::save()
```

RepositoryがPersistence Operationを担当し、MapperはMappingだけを担当する。

---

## 23. MapperでQueryを実行しない

MapperはDatabase Queryを実行しない。

避ける例:

```php
public function toDomain(
    EmployeeSkillModel $model,
): EmployeeSkill {
    $skill =
        SkillModel::query()
            ->find($model->skill_id);

    // ...
}
```

必要なPersistence Dataの取得はRepositoryが担当する。

Mapperから暗黙的にQueryが発行される設計を避ける。

---

## 24. Lazy Loadingへ依存しない

MapperではEloquent Lazy Loadingへ依存しない。

例えば、

```php
$model->skill->name
```

のようなRelation Accessによって暗黙的に追加Queryが発行される状態でDomain Aggregateを復元しない。

Aggregate復元にRelationが必要であれば、Repository側で必要なRelationを明示的に取得する。

ただし本システムではAggregate間参照はIDを基本とするため、Aggregate復元時に不要なRelationをLoadしない。

---

## 25. Aggregate ReferenceとMapper

本システムではAggregate間の参照を原則としてIDで保持する。

例えばEmployeeSkillは、

```text
EmployeeId
SkillId
```

を保持する。

そのためMapperで、

```text
Employee Aggregate
Skill Aggregate
```

まで復元してEmployeeSkillへ組み込むことはしない。

概念的には、

```text
employee_id
    ↓
EmployeeId

skill_id
    ↓
SkillId
```

の変換だけを行う。

これにより巨大なObject Graphを防ぐ。

---

## 26. Eloquent CastとMapper

Eloquent CastはPersistence上便利な範囲で利用できる。

ただし、

```text
Eloquent Cast
    =
Domain Value Object
```

とは考えない。

Domain Value ObjectはMapperから明示的に生成する。

例:

```text
Database
VARCHAR / INTEGER
    ↓
Eloquent Primitive
    ↓
Mapper
    ↓
Domain Value Object
```

Business RuleをEloquent Custom Castへ移動しない。

---

## 27. EnumのMapping

Database表現とDomain Enumの変換はMapperで明示する。

PersistenceからDomain:

```php
$skillLevel =
    SkillLevel::from(
        $model->skill_level,
    );
```

DomainからPersistence:

```php
$model->skill_level =
    $employeeSkill
        ->skillLevel()
        ->value;
```

Eloquent Enum Castを利用する場合でも、Domain EnumとPersistence Representationの境界を明確にする。

---

## 28. Nullable Value ObjectのMapping

Nullable ColumnをValue Objectへ変換する場合は `null` を明示的に扱う。

例:

```php
$lastUsedMonth =
    $model->last_used_month === null
        ? null
        : LastUsedMonth::fromString(
            $model->last_used_month,
        );
```

Domain側で、

```text
実務未経験
    ↓
LastUsedMonth = null
```

などのBusiness Invariantを保証する。

Mapper自身がそのBusiness Ruleを判断しない。

---

## 29. Date / Time Mapping

Date / TimeもPersistence表現とDomain表現を明示的に変換する。

概念例:

```text
PostgreSQL timestamptz
        ↓
Eloquent / Carbon
        ↓
Mapper
        ↓
Domain DateTime表現
```

Domain LayerへCarbonを持ち込まない。

年月を扱う `LastUsedMonth` についても、Persistence表現からDomain Value ObjectへMapperで変換する。

---

## 30. MapperとDomain Invariant

`toDomain()` から `reconstitute()` した結果がDomain Invariantに反する場合は、

```text
Persistence Dataに不整合が存在している
```

とみなす。

Mapperが不正な値を勝手に補正しない。

避ける例:

```text
DatabaseではLevel 3だが
実務未経験だから
MapperでLevel 1へ書き換える
```

このようなSilent Correctionは行わない。

不整合は検知可能な状態にする。

---

## 31. Lock付き取得

悲観Lockが必要なUseCaseでは、Repositoryへ明示的なLock付き取得Methodを定義できる。

例:

```php
public function findForUpdate(
    UserId $id,
): ?User;
```

Implementation:

```php
$model =
    UserModel::query()
        ->whereKey(
            $id->value(),
        )
        ->lockForUpdate()
        ->first();
```

Repository InterfaceへLaravel Query Builderそのものは公開しない。

---

## 32. Lock用Methodの命名

Infrastructure Implementationでは `lockForUpdate()` を利用できる。

一方、Repository InterfaceではPersistence技術を直接表現する命名を必要以上に持ち込まない。

ただし、

```text
findForUpdate()
```

のような名前は、

```text
更新処理のため排他的に取得する
```

というUseCase上の意味も明確であるため採用可能とする。

よりDomain上自然な名称が存在する場合はそちらを優先する。

---

## 33. 複数RecordのLock

複数RecordをLockする場合はDeadlock Riskを抑えるため、原則としてID昇順でLockする。

概念例:

```php
$models =
    UserModel::query()
        ->whereIn(
            'id',
            $ids,
        )
        ->orderBy('id')
        ->lockForUpdate()
        ->get();
```

Permission Manager更新など、複数Userを同時に扱う処理ではこの原則を適用する。

詳細は `09_Transaction.md` で定義する。

---

## 34. RepositoryとLockの責務

Repositoryは、

```text
どうDatabase Lockを取得するか
```

を実装する。

Applicationは、

```text
このUseCaseでLock付き取得が必要である
```

ことを判断する。

Domainは、

```text
Lock
SELECT FOR UPDATE
Database Transaction
```

を知らない。

---

## 35. Delete

物理削除がDomain上許可されているAggregateについては、必要に応じてRepositoryへ `remove()` を定義する。

例:

```php
public function remove(
    SomeAggregate $aggregate,
): void;
```

ただし、本システムではBusiness Stateとして保持するEntityも多い。

例えば、

```text
Skill
    ↓
無効化

Employee
    ↓
退職状態
```

については、物理削除Methodを利用せずDomain Behaviorによる状態変更を行う。

---

## 36. Business State変更

Business State変更をRepository固有Methodとして実装しない。

避ける例:

```php
$skillRepository
    ->deactivate($skillId);
```

基本:

```text
Repository::find()
    ↓
Skill Aggregate
    ↓
deactivate()
    ↓
Repository::save()
```

とする。

状態遷移そのものはDomain Behaviorで表現する。

---

## 37. Soft Delete

MVPではLaravel `SoftDeletes` を一般的なPersistence Strategyとして採用しない。

Business上保持が必要な状態は明示的なDomain Stateで管理する。

例:

```text
is_active
employment_status
retired_at
```

Soft Deleteを、

```text
とりあえず削除履歴を残すため
```

という理由だけで利用しない。

物理削除とBusiness上の無効化を区別する。

---

## 38. Database Constraint Violation

Repositoryの `save()` ではDatabase Constraint Violationが発生する場合がある。

例えばEmployeeSkillでは、

```text
UNIQUE (
    employee_id,
    skill_id
)
```

によって重複を防御する。

概念的には、

```text
Repository::save()
    ↓
PostgreSQL
    ↓
Unique Violation
    ↓
Infrastructure
```

となる。

---

## 39. Constraint Violationの変換

Business Conflictとして意味のあるConstraint Violationについては、InfrastructureでConstraint Nameを判定してMeaningful Exceptionへ変換する。

例:

```text
PostgreSQL
Unique Violation
        ↓
Constraint Name判定
        ↓
DuplicateEmployeeSkill
```

Domain / Application / PresentationへPostgreSQL Driver固有Exceptionをそのまま露出しない。

HTTP StatusへのMappingはPresentation Layerで行う。

詳細は `10_Exception設計.md` で定義する。

---

## 40. ConstraintをRepositoryの代わりにしない

Database Constraintは最終防衛として重要だが、Application / Domainの代替とはしない。

EmployeeSkill重複であれば、

```text
Application
事前存在確認
        +
Database
UNIQUE Constraint
```

を基本とする。

Domain InvariantについてはDomainでも保証する。

多層防御によってApplication Race ConditionやImplementation Bugに対しても整合性を維持する。

---

## 41. RepositoryとTransaction

Repositoryは現在のTransaction Context内でPersistenceを行う。

Repository自身はTransaction Boundaryを開始・終了しない。

基本フロー:

```text
Application Handler
    ↓
TransactionManager::run()
    ↓
Repository::find()
    ↓
Domain Behavior
    ↓
Repository::save()
```

複数Repositoryを利用する場合も同一UseCase Transaction内で実行する。

---

## 42. Repository間呼び出し

Repository Implementationから別Repositoryを呼び出す構造は原則として避ける。

避ける:

```text
EmployeeSkillRepository
    ↓
EmployeeRepository
    ↓
SkillRepository
```

複数Aggregateが必要な場合はApplication Handlerが各Repositoryを利用して処理をオーケストレーションする。

```text
Application Handler
    ├── EmployeeRepository
    ├── SkillRepository
    └── EmployeeSkillRepository
```

Repository同士を隠れたDependency Chainにしない。

---

## 43. Generic Repositoryを採用しない

以下のようなGeneric Repositoryは採用しない。

```php
interface Repository
{
    public function find(
        int $id,
    ): mixed;

    public function save(
        object $entity,
    ): void;

    public function delete(
        object $entity,
    ): void;
}
```

理由:

- Aggregate固有の意図が失われる
- Ubiquitous Languageが弱くなる
- 不要なMethodを各Repositoryへ強制する
- Type Safetyが低下する
- Infrastructure抽象化が目的化しやすい

RepositoryはAggregateごとに定義する。

---

## 44. Base Repositoryを事前作成しない

以下のようなBase ClassをMVP開始時から作成しない。

```text
BaseRepository
AbstractRepository
EloquentRepository
```

共通化のための共通化を避ける。

複数Repositoryで明確な重複が実際に発生し、

- 保守性が上がる
- Domain固有の意味を損なわない
- Generic Repository化しない

ことを確認できた場合のみ共通化を検討する。

---

## 45. Repository Interfaceの配置

Repository InterfaceはDomain Layerへ配置する。

例:

```text
Domain/
└── SkillManagement/
    └── Repositories/
        ├── EmployeeSkillRepository.php
        ├── SkillRepository.php
        └── SkillCategoryRepository.php
```

Repository InterfaceがDomain Languageの一部として自然に理解できる構成を維持する。

---

## 46. Repository Implementationの配置

Repository ImplementationはInfrastructureへ配置する。

```text
Infrastructure/
└── Persistence/
    └── Repositories/
        ├── EloquentEmployeeSkillRepository.php
        ├── EloquentSkillRepository.php
        └── EloquentSkillCategoryRepository.php
```

InterfaceとImplementationを同一Directoryへ混在させない。

---

## 47. Mapperの配置

MapperはInfrastructureへ配置する。

```text
Infrastructure/
└── Persistence/
    └── Mappers/
        ├── EmployeeSkillMapper.php
        ├── SkillMapper.php
        └── SkillCategoryMapper.php
```

Domain LayerへPersistence Mapperを配置しない。

---

## 48. Repository Test

Repository ImplementationはPostgreSQLを利用したIntegration Testで確認する。

主なTest対象:

- 新規Aggregateを保存できる
- Aggregateを取得できる
- Aggregate更新を保存できる
- 保存したAggregateを正しく復元できる
- IDが正しくMappingされる
- Enumが正しくMappingされる
- Value Objectが正しくMappingされる
- Nullable Fieldが正しく扱われる
- UNIQUE Constraint Violationを扱える
- Lock付き取得が機能する

PostgreSQL固有BehaviorをSQLiteで代替しない。

---

## 49. Mapper Test

Mapperは必要に応じてUnit TestまたはInfrastructure Integration Testで確認する。

主な対象は以下とする。

```text
Eloquent Model
    ↓
Mapper
    ↓
Domain Aggregate
```

および、

```text
Domain Aggregate
    ↓
Mapper
    ↓
Eloquent Model
```

特に以下を重点的に確認する。

- ID
- Enum
- Value Object
- Nullable Field
- ExperiencePeriod
- LastUsedMonth
- Timestamp / Date

Mapperの変換BugによってPersistence DataとDomain Modelが乖離しないことを確認する。

---

## 50. Repository設計原則

Repositoryについて以下の流れを基本とする。

```text
Aggregate取得
    ↓
Repository::find()

Aggregate状態変更
    ↓
Domain Behavior

Aggregate保存
    ↓
Repository::save()
```

Repositoryは、

> Aggregateの永続化境界

として設計する。

検索画面、Dashboard、Report、集計などのRead Model取得機構として利用しない。

---

## 51. Mapper設計原則

PersistenceからDomain:

```text
Database
    ↓
Eloquent Model
    ↓
Mapper::toDomain()
    ↓
Aggregate::reconstitute()
```

DomainからPersistence:

```text
Domain Aggregate
    ↓
Mapper::fillModel()
    ↓
Eloquent Model
    ↓
Repository
    ↓
Persistence
```

Mapperは、

> Domain ModelとPersistence Modelの表現差を吸収する変換専用Adapter

として扱う。

---

## 52. Repository・Mapper全体原則

Repository / Mapper全体では以下の責務分担を維持する。

```text
Business Rule
        ↓
Domain

UseCase
Transaction Boundary
        ↓
Application

Aggregate Persistence
        ↓
Repository

Domain ↔ Persistence変換
        ↓
Mapper

ORM / Database
        ↓
Eloquent / PostgreSQL

複雑なRead
        ↓
Query Service
```

RepositoryとMapperを設ける目的は、

> Eloquentを隠すことそのものではなく、Domain Modelの設計をPersistence都合から守ること

とする。

Laravel / Eloquentの便利さはInfrastructure内部では積極的に利用する。

一方で、RepositoryやMapperへBusiness Logicを移動し、

```text
Domainが薄い
    ↓
InfrastructureがBusiness Ruleを持つ
```

という構造にならないようにする。

RepositoryはAggregate Persistence、MapperはRepresentation変換という責務を維持する。
