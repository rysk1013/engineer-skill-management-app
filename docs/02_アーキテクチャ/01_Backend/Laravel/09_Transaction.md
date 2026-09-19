# Transaction設計

## 1. 目的

Transactionは、Write UseCaseにおける複数の状態変更を一貫した単位として扱い、Database上の整合性を保証するために利用する。

本システムでは、

> 1 Write UseCase = 1 Transaction

を基本方針とする。

Transaction BoundaryはApplication Layerが決定し、Laravel / PostgreSQLによる具体的なTransaction実行はInfrastructure Layerが担当する。

---

## 2. 基本方針

- Write UseCaseは原則として1 Transactionで実行する
- Transaction BoundaryはApplication Handlerに置く
- Application LayerはLaravel `DB` Facadeへ直接依存しない
- Application PortとしてTransaction Managerを利用する
- InfrastructureでLaravel `DB::transaction()` を利用する
- Repository自身はTransactionを開始しない
- Domain LayerはTransactionを知らない
- Presentation LayerはTransactionを開始しない
- PostgreSQLのIsolation Levelは原則 `READ COMMITTED` を利用する
- 必要なUseCaseのみ悲観Lockを利用する
- Optimistic LockはMVPでは採用しない
- 複数RecordをLockする場合は原則ID昇順とする
- Transactionを必要以上に長く保持しない
- External API呼び出しをDatabase Transaction内へ原則含めない
- Transaction失敗時は全体をRollbackする

---

## 3. Transactionの責務分担

Transactionに関する責務を以下のように分ける。

### Application Layer

Application Layerは、

> どこからどこまでを1つのTransactionとして扱うか

を決定する。

### Infrastructure Layer

Infrastructure Layerは、

> Laravel / PostgreSQLを利用してTransactionをどう実行するか

を担当する。

### Domain Layer

Domain Layerは、

> TransactionやDatabase Lockの存在を知らず、Business Invariantを保証する

ことに集中する。

概念:

```text
Application
    ↓
Transaction Boundary

Infrastructure
    ↓
Transaction Mechanism

Domain
    ↓
Business Consistency
```

---

## 4. 基本Transaction Flow

Write UseCaseでは以下を基本とする。

```text
Command
    ↓
Command Handler
    ↓
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

途中でExceptionが発生した場合は、

```text
Transaction Start
    ↓
処理
    ↓
Exception
    ↓
Rollback
```

とする。

---

## 5. Transaction Manager

Application LayerではTransactionを抽象化したPortを定義する。

```php
interface TransactionManager
{
    public function run(
        callable $callback,
    ): mixed;
}
```

Infrastructure LayerでLaravel実装を提供する。

```php
final class LaravelTransactionManager
    implements TransactionManager
{
    public function run(
        callable $callback,
    ): mixed {
        return DB::transaction(
            $callback,
        );
    }
}
```

Application LayerはLaravel `DB` Facadeを直接利用しない。

---

## 6. Command Handlerでの利用

Command HandlerではTransaction Managerを利用する。

```php
final readonly class UpdateEmployeeSkillHandler
{
    public function __construct(
        private TransactionManager $transactionManager,
        private EmployeeSkillRepository $repository,
    ) {}

    public function handle(
        UpdateEmployeeSkillCommand $command,
    ): UpdateEmployeeSkillResult {
        return $this->transactionManager->run(
            function () use ($command) {
                // UseCase
            },
        );
    }
}
```

Transaction BoundaryをHandlerから明確に確認できる構造とする。

---

## 7. HandlerのどこをTransactionに含めるか

Transactionには、Database整合性を保証するために必要な処理を含める。

基本:

```text
Transaction Start
    ↓
必要なRecord取得
    ↓
必要なLock取得
    ↓
Domain状態変更
    ↓
Repository保存
    ↓
Commit
```

Transaction開始前に実行しても整合性へ影響しない処理は、可能であればTransaction外で行う。

---

## 8. AuthorizationとTransaction

Authorizationは内容によってTransaction内外を判断する。

単純なRole確認などDatabase整合性と無関係なものはTransaction開始前に実行できる。

```text
Actor Role確認
    ↓
Transaction Start
    ↓
Write処理
```

一方、

```text
Permission Managerが最低1人必要
```

のように現在のDatabase状態と競合制御が関係するBusiness Ruleは、必要なLockを取得したTransaction内で確認する。

---

## 9. Domain ValidationとTransaction

Value Object生成などDatabase状態と無関係なValidationはTransaction開始前に行える。

```text
Command
    ↓
Value Object生成
    ↓
Transaction Start
```

これにより、不正入力でTransactionを開始する無駄を減らせる。

ただし、Aggregateの現在状態が必要なBusiness InvariantはTransaction内で判定する。

---

## 10. Transactionを短く保つ

Transactionは可能な限り短くする。

長時間Transactionを避ける理由:

- Lock保持時間の増加
- Deadlock Risk増加
- Connection占有
- Throughput低下
- Concurrent Updateへの影響
- Database保守処理への影響

Transaction内にはDatabase整合性に必要な処理だけを含める。

---

## 11. Transaction内で避ける処理

原則として以下をTransaction内で実行しない。

- External API呼び出し
- Mail送信
- File Upload
- Object Storage通信
- 長時間CPU処理
- Sleep / Wait
- 不要なRead
- User Interaction
- 長時間のNetwork I/O

例えば、

```text
Transaction Start
    ↓
External API Request
    ↓
Response待ち
    ↓
Database Update
```

という構造は避ける。

---

## 12. External Serviceとの関係

External Serviceが必要なWrite UseCaseでは、可能であればDatabase Transactionとの順序を明確に分離する。

ただし、

```text
External API成功
+
Database Update成功
```

を完全にAtomicにすることは、通常のDatabase Transactionだけではできない。

MVPでは以下を採用しない。

- Saga
- Outbox
- Distributed Transaction

そのためExternal Serviceを伴うUseCaseは個別にFailure Strategyを設計する。

External APIをTransaction内へ入れるだけでAtomic性が得られるとは考えない。

---

## 13. RepositoryがTransactionを開始しない

Repository自身はTransaction Boundaryを持たない。

避ける例:

```php
public function save(
    EmployeeSkill $employeeSkill,
): void {
    DB::transaction(function () {
        // ...
    });
}
```

理由:

- UseCase全体を1 Transactionにできなくなる
- 複数Repository操作のAtomicityが見えなくなる
- Transaction Boundaryが分散する
- Nested Transactionへ依存しやすくなる

Repositoryは現在のTransaction Context内でPersistenceを行う。

---

## 14. PresentationでTransactionを開始しない

Controllerから `DB::transaction()` を実行しない。

避ける例:

```php
public function __invoke(
    Request $request,
): JsonResponse {
    return DB::transaction(
        function () {
            // UseCase
        },
    );
}
```

Presentation LayerはHTTP処理に集中する。

TransactionはApplication UseCaseの責務とする。

---

## 15. DomainでTransactionを扱わない

Domain Entity / Value Object / Domain Policyから以下を利用しない。

- `DB::transaction()`
- `DB::beginTransaction()`
- `DB::commit()`
- `DB::rollBack()`
- `lockForUpdate()`
- SQL
- Database Connection

DomainはPersistence Mechanismを知らない。

---

## 16. Isolation Level

PostgreSQLのTransaction Isolation Levelは原則として、

```text
READ COMMITTED
```

を利用する。

MVPでは通常これを変更しない。

必要なConcurrency ControlはIsolation Levelを全面的に引き上げるのではなく、対象UseCaseで悲観LockやDatabase Constraintを利用して対応する。

---

## 17. `READ COMMITTED` を採用する理由

本システムでは以下の理由から `READ COMMITTED` を基本とする。

- 一般的なCRUD Applicationに適している
- SERIALIZABLEよりConcurrencyを確保しやすい
- 必要な競合箇所だけ明示的にLockできる
- System全体を過剰に強いIsolationへしなくてよい
- Laravel / PostgreSQLの通常利用と相性がよい

Isolation LevelだけですべてのBusiness Race Conditionを解決しようとしない。

---

## 18. `READ COMMITTED` の注意点

`READ COMMITTED` では、同一Transaction内でもStatementごとに異なるCommitted Stateを見る場合がある。

そのため、

```text
Read
    ↓
判断
    ↓
Update
```

という処理でConcurrent Requestとの競合がBusiness Integrityに影響する場合は、悲観LockやConstraintを利用する。

---

## 19. Concurrency Control

Concurrency ControlはUseCaseごとに必要性を判断する。

基本方針:

```text
通常更新
    ↓
Last Write Wins

Business Invariantへ影響する競合
    ↓
Pessimistic Lock
    +
Database Constraint
```

すべての更新へLockを追加しない。

---

## 20. Last Write Wins

一般的なEmployee情報やSkill情報の同時更新では、MVPではLast Write Winsを許容する。

例えば2人がほぼ同時に同じSkill情報を編集した場合、後からCommitされた更新が最終状態になることを許容する。

これらにVersion Columnを利用したOptimistic Lockは導入しない。

---

## 21. Optimistic Lock

MVPではOptimistic Lockを採用しない。

以下のようなColumnは標準では導入しない。

```text
version
lock_version
row_version
```

および、

```sql
UPDATE ...
WHERE id = ?
AND version = ?
```

による一般的なVersion Checkも採用しない。

Concurrent EditによるLost Updateが実際のRequirement上問題になった場合に再検討する。

---

## 22. Pessimistic Lock

Business InvariantがConcurrent Requestによって破壊される可能性がある場合は悲観Lockを利用する。

代表例:

> Permission管理可能なAdministratorを最低1人維持する

複数Requestが同時にPermission管理権限を解除すると、

```text
Request A
    ↓
現在2人いる
    ↓
1人解除可能

Request B
    ↓
現在2人いる
    ↓
1人解除可能
```

と双方が判断し、最終的に0人になるRace Conditionが発生し得る。

このような処理ではLockを利用する。

---

## 23. Permission Manager更新

Permission Manager変更UseCaseでは、Invariant評価に必要な対象RecordをTransaction内でLockする。

概念:

```text
Transaction Start
    ↓
必要なPermission Manager RecordをLock
    ↓
現在状態確認
    ↓
Domain Policy
    ↓
Permission変更
    ↓
Repository保存
    ↓
Commit
```

同時RequestはLock解除まで待機するため、最新の整合した状態を基にInvariantを評価できる。

---

## 24. `SELECT FOR UPDATE`

PostgreSQLの悲観Lockには、

```sql
SELECT ... FOR UPDATE
```

を利用する。

LaravelではInfrastructure側で、

```php
->lockForUpdate()
```

を利用できる。

Application / DomainはPostgreSQL構文やLaravel Query Builderを知らない。

---

## 25. Lock付きRepository Method

必要に応じてRepositoryへLock付き取得Methodを定義する。

例:

```php
public function findForUpdate(
    UserId $id,
): ?User;
```

Infrastructure Implementation:

```php
$model =
    UserModel::query()
        ->whereKey($id->value())
        ->lockForUpdate()
        ->first();
```

Repository InterfaceではEloquent Builderを公開しない。

---

## 26. LockはTransaction内で取得する

`SELECT FOR UPDATE` はTransaction内で使用する。

基本:

```text
Transaction Start
    ↓
SELECT FOR UPDATE
    ↓
Business Rule確認
    ↓
Update
    ↓
Commit
```

Transaction外でLockを取得する設計にはしない。

---

## 27. Lock順序

複数RecordをLockする場合は、原則としてID昇順でLockする。

例:

```php
UserModel::query()
    ->whereIn('id', $ids)
    ->orderBy('id')
    ->lockForUpdate()
    ->get();
```

複数UseCaseで同じRecord群をLockする場合も、可能な限り同じ順序を維持する。

---

## 28. Lock順序を統一する理由

例えば、

```text
Transaction A
User 1
    ↓
User 2
```

と、

```text
Transaction B
User 2
    ↓
User 1
```

のように異なる順序でLockするとDeadlockが起こりやすくなる。

そのため、

> Lock対象を安定した順序で取得する

ことをConcurrency設計の基本とする。

ID昇順をDefault Ruleとする。

---

## 29. Deadlock

悲観Lockを利用していてもDeadlockを完全には防げない。

PostgreSQLがDeadlockを検知した場合、Transactionの一方が失敗する。

Risk低減のため以下を行う。

- Lock順序を統一する
- Transactionを短くする
- 必要以上のRecordをLockしない
- Lock取得前後に長時間処理を行わない
- External I/OをTransaction内へ入れない

---

## 30. Deadlock Retry

MVPではApplication全体に汎用的なAutomatic Deadlock Retry機構を事前導入しない。

実運用でDeadlockが確認され、Retryが安全かつ有効なUseCaseについてのみ導入を検討する。

Retry機構を利用する場合も、

- 同一処理の再実行が安全か
- External Side Effectがないか
- Idempotencyを確保できるか

を確認する。

無条件Retryは行わない。

---

## 31. Lock範囲

LockはBusiness Invariantを保証するために必要な最小範囲とする。

避ける例:

```text
User Table全件Lock
```

必要な、

```text
Invariant評価に関係するRecord
```

のみをLockする。

Over-lockingによってConcurrencyを不必要に低下させない。

---

## 32. Read Queryでは原則Lockしない

CQRSのRead Queryでは原則としてRow Lockを取得しない。

```text
Query Handler
    ↓
Query Service
    ↓
SELECT
```

を基本とする。

Lock付きReadはWrite UseCaseのConsistency Controlとして利用する。

---

## 33. Database Constraintとの組み合わせ

Concurrency Controlでは悲観LockだけでなくDatabase Constraintも利用する。

例えばEmployeeSkill重複登録では、

```text
Application
    ↓
exists確認
```

だけではConcurrent Requestを完全には防げない。

そのため、

```text
Application事前確認
    +
UNIQUE Constraint
```

を利用する。

---

## 34. EmployeeSkill重複登録

例えば以下の一意性を持つ。

```text
employee_id
+
skill_id
```

2つのRequestが同時に、

```text
存在しない
```

と判断してInsertしようとしても、Databaseの `UNIQUE` Constraintによって片方を失敗させる。

このケースでは、無理に事前Row Lockを導入せずDatabase Constraintによる競合解決を利用する。

---

## 35. LockとConstraintの使い分け

基本判断:

```text
既存Recordの状態を見て
Business Ruleを判断する必要がある
    ↓
Pessimistic Lockを検討
```

```text
一意性や参照整合性を
Databaseで表現できる
    ↓
Constraintを利用
```

必要に応じて両方を利用する。

---

## 36. Transaction中のException

Transaction内でExceptionが発生した場合はRollbackする。

LaravelのTransaction Mechanismを利用し、CallbackからExceptionがThrowされた場合はTransaction全体を失敗させる。

概念:

```text
Transaction
    ↓
Domain Exception
        or
Application Exception
        or
Infrastructure Exception
    ↓
Rollback
    ↓
Exception伝播
```

Exceptionを握り潰してCommitしない。

---

## 37. Domain ExceptionとRollback

Domain Exceptionが発生した場合も、そのWrite UseCaseのTransactionはRollbackする。

```text
Transaction Start
    ↓
Aggregate取得
    ↓
Domain Behavior
    ↓
Domain Exception
    ↓
Rollback
```

Application HandlerがBusiness Errorとして扱う場合でも、Database変更はCommitしない。

---

## 38. Constraint ViolationとRollback

Repository保存時に、

```text
UNIQUE Violation
CHECK Violation
Foreign Key Violation
```

などが発生した場合もTransactionはRollbackする。

InfrastructureでMeaningful Exceptionへ変換する場合でも、Transactionを成功扱いにはしない。

---

## 39. ExceptionをCatchする場合

Transaction Callback内でExceptionをCatchする場合は注意する。

避ける例:

```php
$this->transactionManager->run(
    function () {
        try {
            $repository->save(...);
        } catch (\Throwable $e) {
            // logging only
        }
    },
);
```

RollbackすべきExceptionを握り潰すと、Transactionが成功扱いとなる可能性がある。

RollbackすべきExceptionは再Throwする。

---

## 40. Rollback後のDomain Object

Transaction Rollback後、Memory上のDomain Objectは変更済み状態のまま残っている場合がある。

そのObjectは再利用しない。

Write HandlerがExceptionで終了した場合は、そのUseCase内で生成・変更したAggregateを破棄する前提とする。

Rollback後に同じDomain Objectを利用して処理を継続しない。

---

## 41. Nested Transaction

MVPではNested Transactionへ依存する設計をしない。

基本:

```text
Command Handler
    ↓
Transaction
    ↓
Repository A
    ↓
Repository B
```

とする。

以下のようにRepository単位でTransaction Boundaryを重ねない。

```text
Repository A
    ↓
Transaction

Repository B
    ↓
Transaction
```

Transaction BoundaryはUseCase単位に集約する。

---

## 42. 複数Repository

1 Write UseCaseで複数Repositoryを利用することは許容する。

```text
Transaction
    ↓
EmployeeRepository
    ↓
SkillRepository
    ↓
EmployeeSkillRepository
```

すべて同一Transaction Context内で実行する。

Repositoryごとに独立Commitしない。

---

## 43. 複数Aggregate

複数Aggregateを1 Transactionで扱うことは可能だが、安易に増やさない。

複数Aggregate間に強い整合性Requirementがある場合のみ同一Transactionで扱う。

毎回大量のAggregateを1 Transactionで更新する構造になっている場合は、Aggregate Boundaryそのものを再確認する。

---

## 44. ID GenerationとTransaction

PostgreSQL SequenceによるID生成はAggregate生成前に行う。

```text
ID Generator
    ↓
ID取得
    ↓
Aggregate::register()
```

PostgreSQL SequenceはTransaction Rollbackによって値が戻ることを前提にしない。

そのため、

```text
ID 100取得
    ↓
Transaction Rollback
    ↓
次のID 101
```

のような欠番を許容する。

---

## 45. Sequenceの欠番

Primary Keyの連続性をBusiness Requirementとしない。

IDは、

> 一意な識別子

として扱う。

Transaction RollbackやSequenceの動作によって欠番が発生しても問題としない。

---

## 46. Timestamp

Persistence TimestampはDatabase Transaction内で保存する。

Domain上「現在時刻」がBusiness Ruleに必要な場合はApplication PortとしてClockを利用することを検討する。

Domainから直接、

```text
Laravel now()
Carbon
```

へ依存しない。

単なる `created_at` / `updated_at` はPersistence ConcernとしてEloquentへ任せてよい。

---

## 47. Read UseCaseのTransaction

通常のRead Queryでは明示的なTransactionを利用しない。

```text
Query Handler
    ↓
Query Service
    ↓
SELECT
```

を基本とする。

複数Query間で厳密に同一Snapshotが必要になるRequirementが発生した場合のみ、Read Transactionを個別に検討する。

---

## 48. DashboardとTransaction

Dashboardや一覧検索などのRead UseCaseでは原則としてTransactionを開始しない。

Read中にDataが更新され、複数項目の値がわずかに異なる時点を表す可能性は通常許容する。

完全なSnapshot ConsistencyがRequirementになった場合のみ別途設計する。

---

## 49. Long-running Batch

大量Batch処理では、

```text
Batch全体
    =
1 Transaction
```

としない。

大量件数を1 Transactionにすると以下の問題が発生する。

- Lock時間増加
- WAL増加
- Rollback Cost増加
- Connection占有
- Failure時の再実行Cost増加
- Transaction長期化

Batchが必要になった場合はChunk単位Transactionなどを個別設計する。

---

## 50. Migrationとの違い

Application TransactionとDatabase Migration Transactionを混同しない。

```text
Application Transaction
    ↓
Business UseCase Consistency
```

```text
Migration Transaction
    ↓
Schema Change Consistency
```

は別の責務とする。

MigrationのTransaction設計はDatabase Migration方針として別途扱う。

---

## 51. Transaction Logging

必要に応じて以下をObservability対象とする。

- Transaction Error
- Deadlock
- Lock Timeout
- Database Timeout
- Constraint Violation
- Slow Transaction

ただしBusiness DataやCredentialをLogへ不用意に出力しない。

Logging詳細は非機能要件・Observability方針に従う。

---

## 52. Transaction Timeout

MVPではApplication固有のTransaction Timeout機構を事前実装しない。

Long-running Transactionが問題になった場合は以下を検討する。

- PostgreSQL `statement_timeout`
- PostgreSQL `lock_timeout`
- Infrastructure設定
- Monitoring
- Slow Transaction検知

Timeout値をDomain / Application CodeへHard-codeしない。

---

## 53. Lock Timeout

悲観Lockで長時間待機する問題が発生した場合はPostgreSQL `lock_timeout` の利用を検討する。

ただしMVP開始時点から複雑なTimeout / Retry Policyを導入しない。

まずは以下を優先する。

- Transactionを短くする
- Lock順序を統一する
- Lock範囲を最小化する

---

## 54. Transaction失敗時のHTTP Response

Transaction Layer自身はHTTP Statusを決定しない。

```text
Database / Domain Error
    ↓
Rollback
    ↓
Application / Infrastructure Exception
    ↓
Presentation Exception Mapping
    ↓
HTTP Response
```

Business ConflictであればPresentationで `409 Conflict` などへMappingする。

詳細は `10_Exception設計.md` で定義する。

---

## 55. RetryとIdempotency

Transaction RetryとHTTP RequestのIdempotencyは別問題として扱う。

Retryを導入する場合は、

```text
同じUseCaseを再実行して安全か
```

を確認する。

特に以下の副作用を伴う場合は注意する。

- External API
- Notification
- Queue Dispatch
- File操作
- Mail送信

Transaction Retryだけを機械的に導入しない。

---

## 56. Commit後の副作用

将来的にMail / Notification / Queueなどを利用する場合、Database Commit前に実行すると、

```text
Notification成功
    ↓
Database Rollback
```

という不整合が発生し得る。

そのためCommit後に実行すべき副作用については個別設計する。

MVPではOutbox Patternを採用しない。

必要性が発生した時点で、LaravelのAfter Commit系機能なども含めて検討する。

---

## 57. Transaction Scopeの判断基準

Transactionへ処理を含めるかは、

> その処理が失敗したとき、Database上の変更をまとめて取り消す必要があるか

を判断基準とする。

必要なら同一Transactionへ含める。

不要ならTransaction外へ出すことを検討する。

ただしNetwork ServiceとのAtomicityはDatabase Transactionだけでは保証できない。

---

## 58. Transaction設計で避けるもの

以下を避ける。

- ControllerからTransaction開始
- RepositoryごとのTransaction
- DomainからTransaction操作
- すべてのReadでTransaction開始
- すべてのUpdateで悲観Lock
- 不要なSerializable Isolation
- 長時間Transaction
- Transaction内External API
- Lock順序の不統一
- ConstraintをApplication Checkだけで代替
- Exceptionを握り潰したままCommit
- Nested Transaction前提Architecture
- 無条件Deadlock Retry
- ApplicationからLaravel DB Facadeを直接利用
- Transaction機構をBusiness Ruleとして扱う

---

## 59. ディレクトリ構成

Application側:

```text
Application/
└── Shared/
    └── Ports/
        └── TransactionManager.php
```

Infrastructure側:

```text
Infrastructure/
└── Transaction/
    └── LaravelTransactionManager.php
```

Transaction関連Classを各Bounded Contextへ重複して作成しない。

Transaction機構そのものはShared Application Port / Infrastructure Implementationとして扱う。

---

## 60. Transaction Test

Application Handler Testでは主に以下を確認する。

- Transaction Managerを通してWrite UseCaseが実行される
- Exception発生時にUseCaseが失敗する
- Repository操作のUseCase Flowが正しい

PostgreSQL Integration Testでは以下を確認する。

- Commit
- Rollback
- UNIQUE Constraint
- Row Lock
- Concurrent Transaction
- Permission Manager Invariant
- Lock順序
- Constraint競合

Concurrency TestはSQLiteではなくPostgreSQLを利用する。

---

## 61. Permission Manager Concurrency Test

重要なConcurrency Testとして、

```text
Permission Managerが2人存在
```

する状態から、2つのTransactionが同時に権限解除を試みるScenarioをTestする。

期待する結果:

```text
Transaction A
    ↓
Lock取得
    ↓
解除成功
    ↓
Commit

Transaction B
    ↓
Lock待機
    ↓
最新状態を確認
    ↓
最後のPermission Managerを消せない
    ↓
失敗
```

最終的に、

```text
Permission Manager >= 1
```

が必ず維持されることを確認する。

---

## 62. Transaction設計原則

Write UseCase:

```text
Controller
    ↓
Command Handler
    ↓
TransactionManager
    ↓
Repository
    ↓
Domain
    ↓
Repository
    ↓
Commit
```

責務:

```text
Business Invariant
        ↓
Domain

Transaction Boundary
        ↓
Application

Transaction / Lock実装
        ↓
Infrastructure

HTTP Error変換
        ↓
Presentation
```

とする。

---

## 63. 最終方針

本システムのTransactionは、

> 1 Write UseCaseを1つの整合性単位としてApplication HandlerでTransaction Boundaryを定義し、Laravel / PostgreSQLによる具体的なTransaction・Lock処理をInfrastructureへ隔離する

方針とする。

Isolation Levelは原則として、

```text
READ COMMITTED
```

を利用する。

通常の同時編集では、

```text
Last Write Wins
```

を許容する。

一方、

```text
Permission Managerを最低1人維持する
```

などConcurrent RequestによってBusiness Invariantが破壊される可能性があるUseCaseでは、

```text
Transaction
    +
Pessimistic Lock
    +
Domain Policy
```

によって整合性を保証する。

一意性などDatabaseで強制できる条件については、

```text
Application事前確認
    +
Database Constraint
```

による多層防御を利用する。

TransactionをArchitecture上の形式として増やすのではなく、

> Business上同時に成功・失敗すべきDatabase変更を、安全かつ最小限の範囲でAtomicに扱うこと

を最終的な設計基準とする。
