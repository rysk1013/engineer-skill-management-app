# Employee Aggregate Root 設計 決定版

## 1. 位置付け

`Employee` は社員基本情報を表すAggregate Rootとする。

Bounded Context：

    Employee Management

主な責務：

- 社員番号
- 氏名
- 所属部署
- 在籍状態
- 退職日
- 在籍状態の変更
- 所属部署の変更

`EmployeeSkill` はEmployee Aggregate内部には持たない。

EmployeeSkillはSkill Management Contextの
独立Aggregate Rootとして扱う。

---

## 2. Aggregate Root

Aggregate Root：

    Employee

識別子：

    EmployeeId

他Aggregateへの参照：

    DepartmentId

Department Entityそのものは保持せず、
DepartmentIdで参照する。

---

## 3. Property

Employeeは以下のPropertyを保持する。

    Employee
    ├── EmployeeId
    ├── EmployeeNumber
    ├── name
    ├── DepartmentId
    ├── EmploymentStatus
    └── RetirementDate?

---

## 4. Domain Type

### Value Object

- EmployeeId
- EmployeeNumber
- DepartmentId
- RetirementDate

### Enum

- EmploymentStatus

### Primitive

- name

---

## 5. EmployeeId

Employee Aggregateの識別子として扱う。

Value Object：

    EmployeeId

基本ルール：

    id > 0

生成後は変更不可とする。

---

## 6. EmployeeNumber

社員番号は業務上の識別子として扱う。

Database Primary Keyとは分離する。

Value Object：

    EmployeeNumber

最低限のRule：

- 空文字禁止
- 前後空白を許可しない、または正規化する
- 最大文字数を設定する

社員番号の詳細なFormat Ruleが決定した場合は、
EmployeeNumber Value Objectへ追加する。

---

## 7. DepartmentId

社員の所属部署はDepartment Aggregateそのものではなく、

    DepartmentId

で参照する。

    Employee
        |
        v
    DepartmentId

Department EntityをEmployee Aggregate内部へ保持しない。

---

## 8. EmploymentStatus

PHP Enumとして扱う。

概念：

    enum EmploymentStatus: string
    {
        case Active = 'ACTIVE';
        case Leave = 'LEAVE';
        case Retired = 'RETIRED';
    }

意味：

    Active
    → 在籍

    Leave
    → 休職

    Retired
    → 退職

Databaseではvarcharとして保存する。

---

## 9. RetirementDate

退職日を表すValue Object。

    RetirementDate

Database：

    date

API：

    YYYY-MM-DD

Timezoneは持たない。

---

## 10. Aggregateの不変条件

Employeeは常に以下を満たす。

### ACTIVE

    EmploymentStatus::Active

の場合：

    RetirementDate = null

---

### LEAVE

    EmploymentStatus::Leave

の場合：

    RetirementDate = null

---

### RETIRED

    EmploymentStatus::Retired

の場合：

    RetirementDate != null

---

## 11. 存在してはいけない状態

以下の状態をDomain上で作成できないようにする。

### NG

    ACTIVE
    +
    RetirementDateあり

### NG

    LEAVE
    +
    RetirementDateあり

### NG

    RETIRED
    +
    RetirementDateなし

Employee Aggregate自身がこれらを拒否する。

---

## 12. Constructor

Constructorは外部公開しない。

第一候補：

    private

外部から以下のように自由生成させない。

    new Employee(...)

Employeeの新規生成はNamed Constructor経由とする。

---

## 13. 新規社員登録

Named Constructor：

    Employee::register(...)

を採用する。

例：

    Employee::register(
        id: $employeeId,
        employeeNumber: $employeeNumber,
        name: $name,
        departmentId: $departmentId,
    );

生成時は必ず、

    EmploymentStatus::Active

    RetirementDate = null

とする。

---

## 14. register() を採用する理由

`Employee::create()` よりも、

    Employee::register()

の方が、

    社員をシステムへ登録する

という今回の業務操作を明確に表現できるため。

採用業務そのものを管理するApplicationではないため、
`hire()`ではなく`register()`を使用する。

---

## 15. Reconstitution

Databaseから既存Employeeを復元する場合：

    Employee::reconstitute(...)

を利用する。

用途：

    EloquentEmployee
        ↓
    EmployeeMapper
        ↓
    Employee::reconstitute(...)

新規登録とPersistenceからの復元を区別する。

---

## 16. Reconstitution時のValidation

`reconstitute()`でもAggregateの不変条件を確認する。

例えばDatabaseに、

    employment_status = RETIRED
    retirement_date = NULL

という不正データが存在した場合は、
Domain Exceptionを発生させる。

Database Constraintだけに依存せず、
Domainでも整合性を保証する。

---

## 17. 氏名変更

Domain Method：

    changeName(string $name)

を利用する。

汎用Setter：

    setName()

は使用しない。

MVPではEmployeeName Value Objectは作成せず、
stringとして扱う。

---

## 18. 所属部署変更

Domain Method：

    changeDepartment(
        DepartmentId $departmentId
    )

を使用する。

EmployeeはDepartmentの存在や有効状態を知らない。

Application UseCase側で以下を確認する。

- Departmentが存在する
- Departmentが有効である

確認後にDepartmentIdをEmployeeへ渡す。

---

## 19. 在籍 → 休職

Domain Method：

    takeLeave()

を採用する。

許可する状態遷移：

    ACTIVE
        ↓
    LEAVE

実行後：

    EmploymentStatus = Leave
    RetirementDate = null

---

## 20. 休職 → 在籍

Domain Method：

    returnFromLeave()

を採用する。

許可する状態遷移：

    LEAVE
        ↓
    ACTIVE

実行後：

    EmploymentStatus = Active
    RetirementDate = null

---

## 21. 退職

Domain Method：

    retire(
        RetirementDate $retirementDate
    )

を採用する。

許可する状態遷移：

    ACTIVE
        ↓
    RETIRED

または、

    LEAVE
        ↓
    RETIRED

実行後：

    EmploymentStatus = Retired
    RetirementDate = 指定値

---

## 22. 状態遷移図

許可：

    ACTIVE
       |
       | takeLeave()
       v
    LEAVE

    LEAVE
       |
       | returnFromLeave()
       v
    ACTIVE

    ACTIVE
       |
       | retire()
       v
    RETIRED

    LEAVE
       |
       | retire()
       v
    RETIRED

---

## 23. 許可しない状態遷移

以下は禁止する。

    RETIRED
        ↓
    LEAVE

    RETIRED
        ↓
    ACTIVE

    RETIRED
        ↓
    RETIRED

また、

    ACTIVE
        ↓
    returnFromLeave()

や、

    LEAVE
        ↓
    takeLeave()

など、現在状態と業務操作が一致しない場合も拒否する。

---

## 24. 汎用Status Setter

以下は作成しない。

    setEmploymentStatus()

理由：

例えば、

    setEmploymentStatus(
        EmploymentStatus::Retired
    )

だけが呼ばれると、

    status = RETIRED
    retirementDate = null

という不正状態を作れるため。

状態変更は必ず、

    takeLeave()

    returnFromLeave()

    retire()

という業務操作として表現する。

---

## 25. 退職日の未来日Validation

以下のRule：

    retirementDate <= today

は現在日時に依存する。

Employee Aggregate内部から直接、

    now()
    today()

等を利用しない。

MVPではApplication UseCase側で検証する。

責務：

### RetirementDate

- 日付として妥当である

### Application UseCase

- 未来日ではない

---

## 26. 退職取消

誤操作等による退職取消を表す、

    cancelRetirement()

はMVPでは実装しない。

通常業務として必要になった場合に、
状態遷移と権限要件を改めて設計する。

---

## 27. 退職後3年判定

以下の判定：

    retirementDate + 3 years <= today

は現在日時に依存するため、
Employee Aggregate自身の責務にはしない。

MVPではApplication Layerで扱う。

将来的に必要であれば、

    RetiredEmployeeDeletionPolicy

等のDomain Service導入を検討する。

---

## 28. Domain Exception

Aggregateの不正状態や不正状態遷移には
Domain Exceptionを利用する。

MVP第一候補：

    InvalidEmployeeState

    InvalidEmployeeStatusTransition

---

## 29. InvalidEmployeeStatusTransition

例えば、

    RETIRED
        ↓
    takeLeave()

を実行した場合に発生させる。

Domain上で許可されない状態遷移を
明示的に表現する。

---

## 30. EmployeeのBehavior

主要なDomain API：

    Employee::register()

    Employee::reconstitute()

    changeName()

    changeDepartment()

    takeLeave()

    returnFromLeave()

    retire()

必要に応じて状態確認Method：

    isActive()

    isOnLeave()

    isRetired()

を追加できる。

---

## 31. Identity

生成後変更不可：

- EmployeeId
- EmployeeNumber

EmployeeNumberを後から変更する業務要件が発生した場合は、
その時点で専用Domain Operationを設計する。

MVPでは変更不可を基本とする。

---

## 32. EmployeeSkillとの関係

Employee AggregateはEmployeeSkill Collectionを保持しない。

以下のような巨大Aggregateにはしない。

    Employee
    └── EmployeeSkills[]

EmployeeSkillはSkill Management Contextの
独立Aggregate Rootとする。

Relation：

    EmployeeSkill
        ↓
    EmployeeId

で表現する。

---

## 33. Userとの関係

Employee Aggregate内にUser Entityを保持しない。

UserはAccess Control ContextのAggregate Rootとする。

Relation：

    User
      ↓
    EmployeeId

EmployeeはUserが存在するかどうかを知らなくてもよい。

---

## 34. Repository

Employee Aggregate専用Repository Interface：

    EmployeeRepository

主なOperation候補：

    findById()

    findByEmployeeNumber()

    existsByEmployeeNumber()

    save()

必要なUseCaseが発生した場合のみ追加する。

---

## 35. Repositoryの基本方針

RepositoryはAggregate単位で扱う。

以下のような部分更新Methodを大量に作らない。

    updateName()

    updateDepartment()

    updateStatus()

基本フロー：

    Aggregate取得
        ↓
    Domain Method
        ↓
    Repository::save()

とする。

---

## 36. EmployeeNumber重複

EmployeeNumberの一意性は、
Employee Aggregate単体では判断できない。

Application Layer：

    EmployeeRepository
        ->existsByEmployeeNumber()

で確認する。

Database：

    UNIQUE(employee_number)

でも最終保証する。

---

## 37. Department存在確認

Employee AggregateはDepartment Aggregateを直接参照しない。

Application UseCase：

    DepartmentRepository

で以下を確認する。

- Department存在
- Department有効

その後、

    DepartmentId

のみEmployeeへ渡す。

---

## 38. RegisterEmployee UseCase

基本Flow：

    EmployeeNumber重複確認
        ↓
    Department存在確認
        ↓
    Department有効確認
        ↓
    Employee::register()
        ↓
    EmployeeRepository::save()
        ↓
    Commit

---

## 39. UpdateEmployee UseCase

氏名・部署変更例：

    Employee取得
        ↓
    Department存在・有効確認
        ↓
    employee->changeName()
        ↓
    employee->changeDepartment()
        ↓
    EmployeeRepository::save()
        ↓
    Commit

変更内容に応じて不要な操作は行わない。

---

## 40. TakeLeaveEmployee UseCase

Flow：

    Employee取得
        ↓
    employee->takeLeave()
        ↓
    EmployeeRepository::save()
        ↓
    Commit

状態遷移自体はEmployee Aggregateが保証する。

---

## 41. ReturnEmployeeFromLeave UseCase

Flow：

    Employee取得
        ↓
    employee->returnFromLeave()
        ↓
    EmployeeRepository::save()
        ↓
    Commit

---

## 42. RetireEmployee UseCase

Flow：

    Employee取得
        ↓
    RetirementDate Input変換
        ↓
    未来日でないことを確認
        ↓
    employee->retire(
        RetirementDate
    )
        ↓
    EmployeeRepository::save()
        ↓
    Commit

---

## 43. Transaction Boundary

基本：

    1 UseCase = 1 Transaction

Transaction管理はApplication Layerの責務とする。

Employee AggregateはTransactionを意識しない。

---

## 44. Mapper

Eloquent ModelとDomain Aggregateを分離する。

取得：

    EloquentEmployee
        ↓
    EmployeeMapper
        ↓
    Employee

保存：

    Employee
        ↓
    EmployeeMapper
        ↓
    EloquentEmployee

---

## 45. Persistence変換

### employment_status

Database：

    varchar

Domain：

    EmploymentStatus

---

### retirement_date

Database：

    date / null

Domain：

    RetirementDate / null

Mapperが変換を担当する。

---

## 46. Database Constraint

Domainで不変条件を保証していても、
PostgreSQL CHECK Constraintを維持する。

Databaseでも、

    ACTIVE / LEAVE
        ↓
    retirement_date IS NULL

    RETIRED
        ↓
    retirement_date IS NOT NULL

を保証する。

Domain + Databaseの二重防御とする。

---

## 47. Form Requestとの責務分離

### Form Request

API Inputとして成立するかを確認する。

例：

- employeeNumberが必須
- nameが必須
- departmentIdがinteger
- retirementDateがYYYY-MM-DD

### Domain

Businessとして成立するかを保証する。

例：

- RETIREDならRetirementDate必須
- 不正な状態遷移は禁止

---

## 48. APIとの関係

OpenAPIではPrimitiveとして表現する。

例：

    {
      "id": 100,
      "employeeNumber": "EMP0001",
      "name": "Example User",
      "departmentId": 1,
      "employmentStatus": "ACTIVE",
      "retirementDate": null
    }

Presentation / Application LayerでDomain Typeへ変換する。

OpenAPI SchemaをDomain Entityそのものとして扱わない。

---

## 49. Unit Test

Employee Aggregateは重点的にUnit Testする。

### Register

- 新規EmployeeはACTIVEになる
- RetirementDateはnullになる

### Name

- 氏名を変更できる

### Department

- DepartmentIdを変更できる

### Leave

- ACTIVE → LEAVE
- LEAVE → ACTIVE

### Retirement

- ACTIVE → RETIRED
- LEAVE → RETIRED
- RetirementDateが設定される

### Invalid Transition

- RETIRED → LEAVEを拒否
- RETIRED → ACTIVEを拒否
- RETIRED → RETIREDを拒否
- ACTIVEでreturnFromLeave()を拒否
- LEAVEでtakeLeave()を拒否

### Reconstitution

- 正常状態を復元できる
- 不正なstatus / retirementDateを拒否する

---

## 50. Employee Class 概念

    final class Employee
    {
        private function __construct(
            private readonly EmployeeId $id,
            private readonly EmployeeNumber $employeeNumber,
            private string $name,
            private DepartmentId $departmentId,
            private EmploymentStatus $employmentStatus,
            private ?RetirementDate $retirementDate,
        ) {
        }

        public static function register(...): self
        {
            // ACTIVE
            // retirementDate = null
        }

        public static function reconstitute(...): self
        {
            // invariant validation
        }

        public function changeName(
            string $name
        ): void {
            // change name
        }

        public function changeDepartment(
            DepartmentId $departmentId
        ): void {
            // change department
        }

        public function takeLeave(): void
        {
            // ACTIVE -> LEAVE
        }

        public function returnFromLeave(): void
        {
            // LEAVE -> ACTIVE
        }

        public function retire(
            RetirementDate $retirementDate
        ): void {
            // ACTIVE / LEAVE -> RETIRED
        }

        public function isActive(): bool
        {
            // ...
        }

        public function isOnLeave(): bool
        {
            // ...
        }

        public function isRetired(): bool
        {
            // ...
        }
    }

---

## 51. 決定事項

### Aggregate Root

`Employee`

### Bounded Context

Employee Management

### Constructor

`private`

### 新規生成

`Employee::register()`

### Persistenceからの復元

`Employee::reconstitute()`

### Domain Type

Value Object：

- EmployeeId
- EmployeeNumber
- DepartmentId
- RetirementDate

Enum：

- EmploymentStatus

### 状態変更

以下のDomain Methodを使用する。

- `takeLeave()`
- `returnFromLeave()`
- `retire()`

### 汎用Status Setter

作成しない。

### 氏名変更

`changeName()`

### Department変更

`changeDepartment()`

### 退職取消

MVPでは実装しない。

### 未来退職日Validation

Application Layerで行う。

### 退職後3年判定

Application Layerで行う。

### EmployeeSkill

Aggregate内部へ保持しない。

### User

Aggregate内部へ保持しない。

### Repository

`EmployeeRepository`

### Transaction

Application UseCaseで管理する。

### Persistence

Eloquent Modelとは分離し、
Mapper経由で変換する。

### Database Constraint

Domain Ruleと併用して維持する。

### Test

Employee Aggregateの状態遷移を重点的にUnit Testする。
