# Transaction / Lock / Concurrency Control 設計

## 1. 基本方針

複数Aggregate・複数Rowにまたがる更新は、
Application LayerでTransaction Boundaryを管理する。

基本：

    1 Write UseCase = 1 Transaction

とする。

Transaction実装はInfrastructure Layerへ閉じ込める。

---

## 2. TransactionManager

Application LayerではLaravelの`DB` Facadeへ直接依存しない。

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

## 3. Infrastructure実装

Infrastructure側：

    LaravelTransactionManager

を実装する。

内部では、

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

---

## 4. Transaction Boundary

Transaction開始・Commit / Rollbackは
Command Handler側で管理する。

例：

    ChangeUserRoleHandler
        ↓
    TransactionManager::run()
        ↓
    Repository
        ↓
    Domain
        ↓
    Repository::save()

Repository単位でTransactionを開始しない。

---

## 5. Repository内Transactionを避ける理由

例えばRole変更では、

- User
- Assignment
- Permission Manager状態

を同時に更新する可能性がある。

各Repositoryが個別にTransactionを持つと、

    User更新成功
    Assignment削除失敗

のような中途半端な状態になり得る。

そのためUseCase単位で1つのTransactionにまとめる。

---

# 6. Permission Manager最低人数Rule

確定Rule：

    role = ADMINISTRATOR
    AND
    can_manage_permissions = true

のUserを最低1人維持する。

0人は禁止。

---

## 7. 単純countでは不十分

以下の実装だけではRace Conditionが発生する。

    countPermissionManagers()

        ↓

    if count > 1
        disable

例えば：

    Admin A
    Admin B

が同時に権限解除すると、

Transaction A：

    count = 2

Transaction B：

    count = 2

両方が解除可能と判断し、

    0人

になる可能性がある。

---

# 8. 悲観ロック

このRuleにはPostgreSQLのRow Lockを利用する。

第一候補：

    SELECT ... FOR UPDATE

Laravel / Eloquentでは：

    lockForUpdate()

をInfrastructure側で使用する。

---

# 9. Lock対象

Permission Managerの現在RowをLockする。

条件：

    role = ADMINISTRATOR

    can_manage_permissions = true

概念：

    SELECT *
    FROM users
    WHERE role = 'ADMINISTRATOR'
      AND can_manage_permissions = true
    FOR UPDATE;

---

# 10. Disable Permission Management Flow

    Transaction Start
        ↓
    Actor User取得
        ↓
    Actor権限確認
        ↓
    Permission Manager Rows
    SELECT FOR UPDATE
        ↓
    Target User取得
        ↓
    現在人数確認
        ↓
    最後の1人なら拒否
        ↓
    target.disablePermissionManagement()
        ↓
    UserRepository::save()
        ↓
    Commit

---

# 11. 同時Transaction

Transaction AがPermission Manager RowをLockすると、

Transaction Bは同じRowをLockしようとして待機する。

AがCommit：

    現在人数が1人へ減る

その後BがLockを取得し、
最新状態で再評価する。

結果：

    最後の1人

なので解除を拒否できる。

---

# 12. Lock処理の配置

Application Layerに、

    lockForUpdate()

というLaravel固有APIを露出しない。

Repository Interface側ではDomain / UseCaseの意味で表現する。

候補：

    UserRepository::findPermissionManagersForUpdate()

とする。

---

# 13. UserRepository追加候補

    interface UserRepository
    {
        public function findById(
            UserId $id
        ): ?User;

        public function save(
            User $user
        ): void;

        public function findPermissionManagersForUpdate(): array;
    }

`forUpdate`という名前はPersistence寄りではあるが、
Concurrency意図が明確なので学習目的では許容する。

---

# 14. さらに抽象化する案

よりClean Architecture寄りにするなら、

    PermissionManagerGuard

    PermissionManagerLock

等をApplication Portとして定義できる。

ただしMVPでは抽象化しすぎるため採用しない。

---

# 15. 推奨

MVPでは、

    UserRepository::findPermissionManagersForUpdate()

を採用する。

SQL / Eloquent実装はInfrastructureへ閉じ込める。

---

# 16. Infrastructure実装

概念：

    UserModel::query()
        ->where('role', 'ADMINISTRATOR')
        ->where(
            'can_manage_permissions',
            true
        )
        ->lockForUpdate()
        ->get();

取得後、

    UserMapper

でDomain Userへ変換する。

---

# 17. 最後の1人判定

Application / Domain Policy：

    PermissionManagementPolicy

で判定する。

例：

    $policy->ensureCanRemove(
        target: $target,
        permissionManagers: $permissionManagers
    );

PolicyはSQLを知らない。

---

# 18. Policyの責務

`PermissionManagementPolicy` は、

    現在のPermission Manager集合

を受け取り、

    Targetを外しても1人以上残るか

を判断する。

Infrastructureへの依存は持たない。

---

# 19. Domain Policy例

概念：

    final class PermissionManagementPolicy
    {
        public function ensureCanRemove(
            User $target,
            array $permissionManagers,
        ): void {
            // business invariant
        }
    }

---

# 20. ActorとTarget

以下を分ける。

    Actor
    → 操作を実行するUser

    Target
    → 権限変更されるUser

Actorについて：

    canManagePermissions = true

である必要がある。

Targetについて：

    最後のPermission Managerか

を判定する。

---

# 21. Role変更

Permission Managerを、

    Administrator
        ↓
    SubManager

等へ変更する場合も同じLockが必要。

理由：

Role変更によって、

    can_manage_permissions = true

を維持できなくなるため。

Flow：

    Lock Permission Managers
        ↓
    最後の1人か判定
        ↓
    Permission Management解除
        ↓
    Role変更

とする。

---

# 22. User無効化

Permission Manager Userを無効化する場合も同様。

    User.disable()

するとApplicationを利用できなくなるため、
実質的にPermission Manager人数が減る。

そのため：

    DisableUserHandler

でもPermission Manager Row Lockが必要。

---

# 23. User削除

Userを完全削除する場合も同じ。

TargetがPermission Managerの場合：

    Lock
        ↓
    最低人数確認
        ↓
    Delete

とする。

---

# 24. Lock対象UseCase

最低限以下で利用する。

- DisablePermissionManagement
- ChangeUserRole
- DisableUser
- DeleteUser

将来：

- Permission Manager関連のBulk Update

でも利用する。

---

# 25. LockしなくてよいUseCase

例えば、

    enablePermissionManagement()

はPermission Manager人数を減らさない。

そのため最低人数Ruleだけを見るならLock不要。

ただしRole整合性は確認する。

---

# 26. Assignment Concurrency

SubManagerAssignment / TeamLeaderAssignmentでは、

    UNIQUE(user_id, employee_id)

をDatabaseで保証する。

同時に同じAssignmentを登録した場合は、
UNIQUE Constraintを最終防衛線とする。

通常はSELECT FOR UPDATEまで利用しない。

---

# 27. EmployeeSkill重複

同様に、

    UNIQUE(employee_id, skill_id)

があるため、
同時登録競合はDatabaseで拒否する。

Application側でも事前確認する。

---

# 28. Optimistic Lock

MVPでは、

    version

ColumnによるOptimistic Lockは導入しない。

理由：

現時点で、

    同じEmployeeを複数人が頻繁に同時編集

する強い要件がないため。

必要になった場合に検討する。

---

# 29. Lost Update

Optimistic Lockを採用しないため、

同一Recordへの同時更新では
Last Write Winsになる可能性がある。

MVPでは許容する。

ただし、

    Permission Manager最低人数

のように壊してはいけないRuleについては
明示的に悲観Lockする。

---

# 30. Isolation Level

PostgreSQL標準の、

    READ COMMITTED

を基本とする。

MVPではApplication全体を、

    SERIALIZABLE

へ変更しない。

必要な箇所だけRow Lockを利用する。

---

# 31. READ COMMITTEDを採用する理由

- PostgreSQL標準
- 一般的なCRUDに十分
- Lock範囲を限定できる
- SERIALIZABLEのRetry設計を避けられる

重要なInvariantだけ明示Lockする。

---

# 32. Deadlock

複数RowをLockする場合、
Lock順序を一定にする。

例えばPermission Manager Rowは、

    ORDER BY id

してからLockすることを検討する。

これによりDeadlock Riskを下げる。

---

# 33. Lock順序

第一候補：

    ORDER BY id ASC
    FOR UPDATE

とする。

同じUseCase群でLock順序を統一する。

---

# 34. Transaction時間

Lockを取得したTransaction内で、
外部HTTP Requestを行わない。

禁止例：

    Lock取得
        ↓
    Laravel API以外の外部Service呼び出し
        ↓
    待機
        ↓
    Commit

Lock保持時間を短くする。

---

# 35. Authentication Token失効との関係

User無効化UseCaseでは、

    DB User更新

と、

    Auth.js Session削除
    Sanctum Token失効

が関係する。

ただしNext.js側Session削除は別Applicationへの通信になる可能性がある。

Database Transactionに外部Network Callを含めない設計を第一候補とする。

---

# 36. DB Transactionと外部副作用

基本：

    DB Transaction
        ↓
    Commit
        ↓
    External Side Effect

とする。

ただし外部処理失敗時の整合性については
Authentication詳細設計で再検討する。

---

# 37. Outbox Pattern

学習目的として候補にはなるが、
MVPでは導入しない。

理由：

- 実装量が増える
- Message Broker等へ発展しやすい
- 現時点では必要性が低い

必要になった段階で再検討する。

---

# 38. Transaction内で行うもの

例：

- User更新
- Assignment削除
- Permission Manager確認
- Employee更新
- EmployeeSkill更新
- Repository save

---

# 39. Transaction外で行う候補

例：

- External Notification
- 外部API
- Auth.jsへのHTTP Request
- 非同期処理

ただし具体的な認証連携方式によって変わる。

---

# 40. Exception時

Transaction内でExceptionが発生した場合はRollbackする。

Domain Exception：

    LastPermissionManagerCannotBeRemoved

等もRollback対象。

TransactionManagerに任せる。

---

# 41. Retry

Deadlock等が発生した場合のRetryは
Laravel TransactionのRetry機能を利用することを検討する。

ただしMVPでは必要性を確認して設定する。

無条件の大量Retryは行わない。

---

# 42. Integration Test

Transaction / LockはUnit Testだけでは不十分。

実PostgreSQLを利用したIntegration Testを作成する。

確認：

- 最後のPermission Managerを解除できない
- 2人いれば1人解除できる
- Role降格時にも最低1人Ruleが効く
- User無効化時にも効く

---

# 43. Concurrency Test

可能であれば、

    2 Transaction

を並行実行して、
両方が最後のPermission Managerを消せないことをTestする。

これは学習目的として非常に価値が高い。

---

# 44. Assignment Test

同時に同じAssignmentを作成した場合、

    UNIQUE Constraint

によって重複が残らないことをIntegration Testする。

---

# 45. EmployeeSkill Test

同時Skill登録でも、

    UNIQUE(employee_id, skill_id)

が最終保証として機能することを確認する。

---

# 46. Directory構成

第一候補：

    app/
    ├── Application/
    │   └── Shared/
    │       └── Transactions/
    │           └── TransactionManager.php
    │
    ├── Domain/
    │   └── AccessControl/
    │       └── Policies/
    │           └── PermissionManagementPolicy.php
    │
    └── Infrastructure/
        └── Persistence/
            └── Transactions/
                └── LaravelTransactionManager.php

Repository Lock実装：

    Infrastructure/
    └── Persistence/
        └── Eloquent/
            └── Repositories/
                └── EloquentUserRepository.php

---

# 47. ChangeUserRole Flow

全体：

    Controller
        ↓
    ChangeUserRoleCommand
        ↓
    ChangeUserRoleHandler
        ↓
    TransactionManager::run()
        ↓
    Actor取得
        ↓
    Actor権限確認
        ↓
    Target取得
        ↓
    必要ならPermission Manager Rows Lock
        ↓
    PermissionManagementPolicy
        ↓
    Assignment整理
        ↓
    Target.changeRole()
        ↓
    UserRepository::save()
        ↓
    Commit

---

# 48. DisablePermissionManagement Flow

    Command
        ↓
    Handler
        ↓
    Transaction
        ↓
    Actor確認
        ↓
    Permission Managers Lock
        ↓
    Target確認
        ↓
    Policy
        ↓
    target.disablePermissionManagement()
        ↓
    save()
        ↓
    Commit

---

# 49. Database Constraintとの役割分担

Database：

- UNIQUE
- CHECK
- FK

でRow単位 / Relation単位を保証する。

Application + Lock：

- Permission Manager最低1人

のような複数Row Invariantを保証する。

---

# 50. 決定候補

### Transaction Boundary

1 Write UseCase = 1 Transaction。

### Transaction Interface

Application Layer。

### Transaction Implementation

Infrastructure Layer。

### Isolation Level

READ COMMITTED。

### Permission Manager Rule

SELECT FOR UPDATEによる悲観Lock。

### Lock API

Infrastructureで`lockForUpdate()`。

### Repository

`findPermissionManagersForUpdate()`等で抽象化。

### Lock順序

ID昇順を第一候補とする。

### Optimistic Lock

MVPでは導入しない。

### Assignment重複

UNIQUE Constraint。

### EmployeeSkill重複

UNIQUE Constraint。

### External Call

DB Transaction内で行わないことを基本とする。

### Test

実PostgreSQLによるConcurrency Integration Testを行う。
