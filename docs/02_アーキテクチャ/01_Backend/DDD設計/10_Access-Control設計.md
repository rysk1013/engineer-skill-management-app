# Access Control Context Aggregate 設計 決定版

## 1. 位置付け

`Access Control Context` では、
Application利用者の権限・担当社員・権限管理可否を管理する。

主な責務：

- Application利用Userの管理
- Userの有効 / 無効
- Role管理
- 権限管理可能Administratorの管理
- サブマネージャー担当社員管理
- チームリーダー担当社員管理
- 社員の閲覧可否判定
- 社員の編集可否判定
- マスタ管理可否判定
- 権限管理可否判定

以下はAccess Control Domainそのものには含めない。

- Password認証
- Auth.js Session
- Laravel Sanctum Token
- Session Cookie

これらはAuthentication / Infrastructureとして扱う。

---

# 2. Role

Applicationで利用するRoleは以下とする。

- Administrator
- SubManager
- TeamLeader

一般社員はApplicationを利用しないため、
Roleとして定義しない。

管理者とマネージャーは同等の操作権限を持つため、
Domain上では `Administrator` に統合する。

---

# 3. UserRole Enum

DomainではPHP Enumを利用する。

概念：

    enum UserRole: string
    {
        case Administrator = 'ADMINISTRATOR';
        case SubManager = 'SUB_MANAGER';
        case TeamLeader = 'TEAM_LEADER';
    }

Databaseではvarcharとして保存する。

---

# 4. Roleごとの権限

## Administrator

対象：

    全社員

可能：

- 社員一覧閲覧
- 社員詳細閲覧
- 社員登録
- 社員編集
- EmployeeSkill登録
- EmployeeSkill編集
- EmployeeSkill無効化
- SkillCategory管理
- Skill管理
- Skill統合
- 社員検索
- Dashboard閲覧

ただし、

    Role付与
    Role解除
    Assignment設定

については、

    canManagePermissions = true

のAdministratorのみ可能とする。

---

## SubManager

対象：

    担当Employeeのみ

可能：

- 担当Employee閲覧
- 担当Employee編集
- 担当EmployeeSkill閲覧
- 担当EmployeeSkill登録
- 担当EmployeeSkill編集
- 担当EmployeeSkill無効化

不可：

- 担当外Employee操作
- SkillCategory管理
- Skill管理
- Role管理
- Assignment管理

---

## TeamLeader

対象：

    担当Employeeのみ

可能：

- 担当Employee閲覧
- 担当EmployeeSkill閲覧

不可：

- Employee編集
- EmployeeSkill編集
- SkillCategory管理
- Skill管理
- Role管理
- Assignment管理

---

# 5. User Aggregate Root

Aggregate Root：

    User

Bounded Context：

    Access Control

Property：

    User
    ├── UserId
    ├── EmployeeId
    ├── LoginId
    ├── UserRole
    ├── canManagePermissions
    └── isActive

Password / Session / TokenはDomain Entityへ持ち込まない。

---

# 6. Domain Type

## Value Object

- UserId
- EmployeeId
- LoginId

## Enum

- UserRole

## Primitive

- canManagePermissions
- isActive

---

# 7. UserとEmployee

UserはApplication利用者。

Employeeは管理対象社員。

Relation：

    Employee 1
        |
        | 0..1
        v
       User

User Aggregateでは、

    EmployeeId

のみ保持する。

Employee Domain Entityそのものは保持しない。

---

# 8. User生成

Named Constructor：

    User::register(...)

を利用する。

概念：

    User::register(
        id: $userId,
        employeeId: $employeeId,
        loginId: $loginId,
        role: $role,
    );

生成時：

    isActive = true

とする。

`canManagePermissions` の初期値はRole付与UseCase側で決定する。

---

# 9. Constructor

Constructorは、

    private

とする。

外部から、

    new User(...)

による自由生成を許可しない。

---

# 10. Reconstitution

Persistenceから復元する場合：

    User::reconstitute(...)

を利用する。

Flow：

    EloquentUser
        ↓
    UserMapper
        ↓
    User::reconstitute()

復元時もDomain Invariantを確認する。

---

# 11. User Aggregate Invariant

常に以下を保証する。

    canManagePermissions = true

の場合：

    role = Administrator

でなければならない。

つまり以下は禁止する。

    SubManager
    +
    canManagePermissions = true

    TeamLeader
    +
    canManagePermissions = true

---

# 12. Administratorと権限管理可否

Administratorには2種類の状態が存在する。

    Administrator
    ├── canManagePermissions = true
    └── canManagePermissions = false

つまり、

    Administrator

だからといって、
必ず権限管理できるわけではない。

---

# 13. 権限管理可能化

Domain Method：

    enablePermissionManagement()

を利用する。

実行条件：

    role = Administrator

それ以外のRoleではDomain Exceptionを発生させる。

結果：

    canManagePermissions = true

---

# 14. 権限管理可能解除

Domain Method：

    disablePermissionManagement()

を利用する。

ただし、

    権限管理可能Administratorを0人にしてはいけない

というルールはUser Aggregate単体では判断できない。

そのため、

    最後の1人かどうか

の判定はApplication / Domain Policy側で行う。

---

# 15. 権限管理可能Administrator最低人数

確定Rule：

    canManagePermissions = true

のAdministratorは、

    最低1人

必須。

複数人存在してよい。

0人は禁止。

---

# 16. Permission Management Policy

複数UserにまたがるBusiness Ruleを扱うため、

    PermissionManagementPolicy

を利用する。

主な責務：

- Administrator以外への権限管理権限付与を禁止
- 最後の権限管理可能Administratorの解除を禁止
- 最後の権限管理可能Administratorの降格を禁止
- 最後の権限管理可能Administratorの無効化を禁止

---

# 17. 最後の1人の解除

例えば：

    Admin A
    canManagePermissions = true

のみの場合、

    Admin A
        ↓
    disablePermissionManagement()

は禁止する。

---

# 18. 複数人いる場合

例えば：

    Admin A
    canManagePermissions = true

    Admin B
    canManagePermissions = true

の場合、

Admin Aの権限管理権限解除は可能。

結果：

    Admin B

が残るため。

---

# 19. Role変更

Role変更にはDomain Method：

    changeRole(
        UserRole $role
    )

を利用する。

ただし変更を実行できるかどうかは
Application UseCaseで確認する。

---

# 20. Permission ManagerのRole変更

例えば：

    Administrator
    canManagePermissions = true

から、

    SubManager

へ変更する場合、

    canManagePermissions = true

のままでは不正状態になる。

そのためRole変更UseCaseで、

1. Permission Manager人数確認
2. 最後の1人なら変更禁止
3. canManagePermissions解除
4. Role変更

の順で処理する。

---

# 21. User無効化

Domain Method：

    disable()

結果：

    isActive = false

Application Layerではさらに、

- Auth.js Session失効
- Laravel Sanctum Token失効

を行う。

---

# 22. User再有効化

Domain Method：

    activate()

結果：

    isActive = true

ただし既存Sessionは復活させない。

再Loginを必要とする。

---

# 23. 最後のPermission Managerの無効化

以下の場合：

    canManagePermissions = true

かつ、

    他にPermission Managerが存在しない

なら、

    disable()

をApplication UseCase側で禁止する。

これにより権限管理可能Userを0人にしない。

---

# 24. SubManager Assignment

サブマネージャーと担当Employeeは多対多Relationとする。

    SubManager User
          |
          | N:M
          v
       Employee

1人のSubManager：

    複数Employeeを担当可能

1人のEmployee：

    複数SubManagerを割当可能

---

# 25. SubManagerAssignment

独立したRelation Entityとして扱う。

    SubManagerAssignment
    ├── UserId
    └── EmployeeId

Database Table：

    sub_manager_assignments

---

# 26. SubManagerAssignment Constraint

同じ担当Relationを重複登録しない。

    UNIQUE(
        user_id,
        employee_id
    )

---

# 27. SubManager Assignment Rule

Assignment対象Userは、

    UserRole::SubManager

でなければならない。

Application Layerで確認する。

---

# 28. SubManager Assignment設定権限

Assignmentを設定・解除できるのは、

    UserRole::Administrator
    +
    canManagePermissions = true

のUserのみとする。

---

# 29. TeamLeader Assignment

TeamLeaderとEmployeeも多対多Relationとする。

    TeamLeader User
          |
          | N:M
          v
       Employee

1人のTeamLeader：

    複数Employeeを担当可能

1人のEmployee：

    複数TeamLeaderを割当可能

---

# 30. TeamLeaderAssignment

独立したRelation Entityとして扱う。

    TeamLeaderAssignment
    ├── UserId
    └── EmployeeId

Database Table：

    team_leader_assignments

---

# 31. TeamLeaderAssignment Constraint

    UNIQUE(
        user_id,
        employee_id
    )

とする。

---

# 32. TeamLeader Assignment Rule

Assignment対象Userは、

    UserRole::TeamLeader

でなければならない。

Assignment設定・解除は、

    Administrator
    +
    canManagePermissions = true

のUserのみ可能。

---

# 33. AssignmentをUser Aggregate内部に持たせない

以下の構成にはしない。

    User
    └── assignedEmployees[]

理由：

- 担当Employee数が増える可能性がある
- 1 Employeeへ複数Userを割り当てる
- Assignment単位で検索したい
- User Aggregateを大きくしたくない

Assignmentは独立Relationとして扱う。

---

# 34. AssignmentのDomain Model

`SubManagerAssignment` と `TeamLeaderAssignment` は
非常に小さなDomain Modelとして扱う。

DDD学習目的でも、
複雑なBehaviorを無理に持たせない。

主なIdentity：

    UserId
    +
    EmployeeId

とする。

---

# 35. Role変更時のAssignment

Role変更時は旧RoleのAssignmentを整理する。

---

## SubManager → Administrator

    sub_manager_assignments

を削除する。

Administratorは全Employeeを操作できるため、
担当Employee Relationを保持しない。

---

## TeamLeader → Administrator

    team_leader_assignments

を削除する。

---

## SubManager → TeamLeader

既存、

    sub_manager_assignments

を、

    team_leader_assignments

へ自動変換しない。

理由：

編集担当と閲覧担当は別の業務Assignmentだから。

Flow：

    SubManager Assignment削除
        ↓
    Role変更
        ↓
    TeamLeader Assignmentを明示設定

---

## TeamLeader → SubManager

同様に自動変換しない。

---

# 36. ChangeUserRole UseCase

基本Flow：

    実行User取得
        ↓
    実行Userの権限管理可否確認
        ↓
    Target User取得
        ↓
    Permission Manager Rule確認
        ↓
    旧Role Assignment整理
        ↓
    必要ならPermission Management解除
        ↓
    target->changeRole()
        ↓
    UserRepository::save()
        ↓
    Commit

1 UseCase = 1 Transactionを基本とする。

---

# 37. Authorization最終判定

Backend APIのAuthorization最終判定はLaravelで行う。

ただしLaravel Policyへ複雑なBusiness Ruleを
直接詰め込みすぎない。

構成：

    Laravel Policy
        ↓
    Access Control Application / Domain
        ↓
    Assignment Repository

とする。

---

# 38. Employee閲覧権限

## Administrator

    全Employee
    → 閲覧可能

## SubManager

    担当Employee
    → 閲覧可能

    担当外Employee
    → 閲覧不可

## TeamLeader

    担当Employee
    → 閲覧可能

    担当外Employee
    → 閲覧不可

---

# 39. Employee編集権限

## Administrator

    全Employee
    → 編集可能

## SubManager

    担当Employee
    → 編集可能

    担当外Employee
    → 編集不可

## TeamLeader

    すべて編集不可

---

# 40. EmployeeSkill閲覧権限

## Administrator

    全EmployeeSkill
    → 閲覧可能

## SubManager

    担当EmployeeのEmployeeSkill
    → 閲覧可能

## TeamLeader

    担当EmployeeのEmployeeSkill
    → 閲覧可能

---

# 41. EmployeeSkill編集権限

## Administrator

    全EmployeeSkill
    → 編集可能

## SubManager

    担当EmployeeのEmployeeSkill
    → 編集可能

## TeamLeader

    編集不可

---

# 42. Skill Master管理

## Administrator

    可能

## SubManager

    不可

## TeamLeader

    不可

---

# 43. Permission管理

可能：

    Administrator
    +
    canManagePermissions = true

のみ。

対象：

- Role付与
- Role解除
- SubManager Assignment
- TeamLeader Assignment
- Permission Manager付与
- Permission Manager解除

---

# 44. AccessControlService

複雑なAuthorization判定には、

    AccessControlService

を利用することを第一候補とする。

Operation候補：

    canViewEmployee(
        User $user,
        EmployeeId $employeeId
    )

    canEditEmployee(
        User $user,
        EmployeeId $employeeId
    )

    canManageSkillMaster(
        User $user
    )

    canManagePermissions(
        User $user
    )

単純なRole GetterだけのServiceにはしない。

---

# 45. Laravel Policy

Laravel PolicyはInfrastructure / Presentation側のAdapterとして扱う。

例：

    EmployeePolicy::view()

        ↓

    AccessControlService
        ->canViewEmployee(...)

Laravel固有のPolicyと
Domain Authorization Logicを分離する。

---

# 46. User Repository

Repository Interface：

    UserRepository

Operation候補：

    findById()

    findByEmployeeId()

    findByLoginId()

    save()

Permission Manager人数取得は、

    countPermissionManagers()

でも実装可能だが、
Query専用Interfaceへ分離することも許可する。

---

# 47. Assignment Repository

## SubManager

    SubManagerAssignmentRepository

Operation候補：

    exists(
        UserId,
        EmployeeId
    )

    assign()

    remove()

    removeAllForUser()

---

## TeamLeader

    TeamLeaderAssignmentRepository

同様のOperationを持つ。

---

# 48. Domain Exception

MVP候補：

- InvalidUserState
- InvalidRoleTransition
- LastPermissionManagerCannotBeRemoved
- InvalidAssignment
- PermissionDenied

Business Errorとして意味があるものをDomain Exceptionで表現する。

---

# 49. User Class概念

    final class User
    {
        private function __construct(
            private readonly UserId $id,
            private readonly EmployeeId $employeeId,
            private readonly LoginId $loginId,
            private UserRole $role,
            private bool $canManagePermissions,
            private bool $isActive,
        ) {
        }

        public static function register(...): self
        {
            // isActive = true
        }

        public static function reconstitute(...): self
        {
            // invariant validation
        }

        public function changeRole(
            UserRole $role
        ): void {
            // change role
        }

        public function enablePermissionManagement(): void
        {
            // Administrator only
        }

        public function disablePermissionManagement(): void
        {
            // 最低人数確認は外部で実施
            $this->canManagePermissions = false;
        }

        public function disable(): void
        {
            $this->isActive = false;
        }

        public function activate(): void
        {
            $this->isActive = true;
        }
    }

---

# 50. User Aggregate Invariant

常に：

    canManagePermissions = true

なら、

    role = Administrator

でなければならない。

逆方向は必須ではない。

つまり：

    Administrator
    +
    canManagePermissions = false

は正常状態。

---

# 51. Database users変更

`users` Tableへ以下を追加する。

    role

    can_manage_permissions

修正版概念：

    users
    ├── id
    ├── employee_id
    ├── login_id
    ├── password
    ├── name
    ├── role
    ├── can_manage_permissions
    ├── is_active
    ├── created_at
    └── updated_at

---

# 52. users.role

Database Type：

    varchar

許可値：

    ADMINISTRATOR
    SUB_MANAGER
    TEAM_LEADER

PostgreSQL CHECK Constraintを利用する。

概念：

    CHECK (
        role IN (
            'ADMINISTRATOR',
            'SUB_MANAGER',
            'TEAM_LEADER'
        )
    )

---

# 53. users.can_manage_permissions

Type：

    boolean

Default：

    false

ただし初期のAdministrator作成時には、
最低1人を、

    true

として登録する必要がある。

---

# 54. users CHECK Constraint

Databaseでも以下を保証する。

    CHECK (
        can_manage_permissions = false
        OR role = 'ADMINISTRATOR'
    )

これにより、

    SUB_MANAGER
    +
    can_manage_permissions = true

等を拒否する。

---

# 55. Permission Manager最低人数

以下：

    can_manage_permissions = true

のUserが最低1人存在することは、
通常のRow単位CHECK Constraintでは保証できない。

そのため、

    Application / Domain Policy
    +
    Transaction
    +
    Concurrency Control

で保証する。

---

# 56. SubManager Assignment Table

追加Table：

    sub_manager_assignments

Columns候補：

    user_id
    employee_id
    created_at
    updated_at

Constraint：

    UNIQUE(
        user_id,
        employee_id
    )

Foreign Key：

    user_id
        ↓
    users.id

    employee_id
        ↓
    employees.id

---

# 57. TeamLeader Assignment Table

追加Table：

    team_leader_assignments

Columns候補：

    user_id
    employee_id
    created_at
    updated_at

Constraint：

    UNIQUE(
        user_id,
        employee_id
    )

Foreign Key：

    user_id
        ↓
    users.id

    employee_id
        ↓
    employees.id

---

# 58. Assignment Foreign Key削除方針

AssignmentはUser / EmployeeとのRelationデータなので、
親削除時の扱いは業務Tableとは分けて検討する。

第一候補：

    users
        ↓
    assignments

    ON DELETE CASCADE

Userが正式に削除された場合、
Assignmentは意味を失うため。

Employee削除時も同様に、

    ON DELETE CASCADE

を第一候補とする。

ただしEmployee削除自体は、
退職後3年 + 管理ユーザー確認という
Application Ruleを通した場合のみ実行する。

---

# 59. Concurrency Control

「Permission Managerを最低1人残す」Ruleでは
同時更新競合を考慮する。

問題例：

    Permission Manager A
    Permission Manager B

が同時に互いの権限を解除する。

両Transactionが、

    現在2人いる

と判断すると、
最終的に0人になる可能性がある。

---

# 60. Concurrency Control候補

Persistence設計時に以下を比較する。

- PostgreSQL Row Lock
- SELECT ... FOR UPDATE
- Transaction Isolation
- PostgreSQL Advisory Lock

MVPでも最低人数Ruleについては
競合を無視しない。

---

# 61. Access Control Context構成

    Access Control Context
    │
    ├── User Aggregate
    │   ├── UserId
    │   ├── EmployeeId
    │   ├── LoginId
    │   ├── UserRole
    │   ├── canManagePermissions
    │   └── isActive
    │
    ├── SubManagerAssignment
    │   ├── UserId
    │   └── EmployeeId
    │
    ├── TeamLeaderAssignment
    │   ├── UserId
    │   └── EmployeeId
    │
    ├── PermissionManagementPolicy
    │
    └── AccessControlService

---

# 62. Databaseへの追加・変更

既存MVP DB設計へ以下を反映する。

## users変更

追加：

- role
- can_manage_permissions

## Table追加

- sub_manager_assignments
- team_leader_assignments

これによりAccess Control要件を
初期リリースから実現する。

---

# 63. Aggregate Root 決定事項

## User

独立Aggregate Root。

## SubManagerAssignment

独立した軽量Relation Entity / Aggregateとして扱う。

## TeamLeaderAssignment

独立した軽量Relation Entity / Aggregateとして扱う。

---

# 64. Role 決定事項

Role：

- Administrator
- SubManager
- TeamLeader

管理者とマネージャーは、
Application権限上同一のAdministratorとして扱う。

一般社員Roleは作成しない。

---

# 65. Permission Manager 決定事項

Administratorのうち、

    canManagePermissions = true

のUserだけが権限設定を変更できる。

複数人設定可能。

最低1人必須。

0人は禁止。

---

# 66. Assignment 決定事項

## SubManager

- 担当Employeeのみ閲覧・編集可能
- 1 Employeeへ複数SubManager設定可能
- 1 SubManagerへ複数Employee設定可能

## TeamLeader

- 担当Employeeのみ閲覧可能
- 1 Employeeへ複数TeamLeader設定可能
- 1 TeamLeaderへ複数Employee設定可能

---

# 67. Role変更 決定事項

Role変更時に旧RoleのAssignmentを整理する。

Assignmentを別Roleへ自動変換しない。

Role変更はApplication UseCaseで
Transactionとして実行する。

---

# 68. Authorization 決定事項

Laravel Backend APIを
Authorizationの最終判断地点とする。

Laravel Policyを入口とし、

    AccessControlService
    PermissionManagementPolicy
    Assignment Repository

等を利用してBusiness Ruleを判定する。

---

# 69. Authenticationとの分離

以下はAccess Control Domainへ持ち込まない。

- Auth.js Session
- Session Cookie
- Sanctum Token
- Token Encryption
- Password Hash

これらはAuthentication / Infrastructure側の責務とする。

User Domainは、

    誰がApplicationを利用できるか
    どのRoleを持つか
    何を操作できるか

を担当する。

---

# 70. 最終決定

Access Control Contextでは以下を採用する。

### User

Behavior RichなAggregate Rootとして扱う。

### UserRole

PHP Enum：

- Administrator
- SubManager
- TeamLeader

### Permission Manager

`canManagePermissions` で表現する。

### Minimum Rule

権限管理可能Administratorを最低1人維持する。

### Assignment

- SubManagerAssignment
- TeamLeaderAssignment

を独立Relationとして管理する。

### Authorization

Laravel Policy + Access Control Domain/Application Logic。

### Persistence

EloquentとはDomain Modelを分離する。

### Concurrency

Permission Manager最低人数Ruleでは
同時更新対策をPersistence設計で必ず行う。
