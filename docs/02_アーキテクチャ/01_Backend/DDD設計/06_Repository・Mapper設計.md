# Repository + Mapper 具体設計

## 1. 基本方針

RepositoryはDomain Aggregateの保存・取得を担当する。

Mapperは、

    Eloquent Model
        ↔
    Domain Aggregate

の変換を担当する。

Eloquent ModelをDomain / Application Layerへ直接返さない。

---

## 2. 全体構成

    Application
        ↓
    EmployeeRepository Interface
        ↑
    EloquentEmployeeRepository
        ↓
    EmployeeMapper
        ↓
    EmployeeModel
        ↓
    PostgreSQL

---

## 3. EmployeeRepository Interface

配置：

    Domain/
    └── EmployeeManagement/
        └── Repositories/
            └── EmployeeRepository.php

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

Repository InterfaceはEloquentを知らない。

---

## 4. Repositoryの責務

EmployeeRepositoryが担当する。

- Employee Aggregate取得
- Employee Aggregate保存
- EmployeeNumber重複確認

担当しない。

- HTTP
- Validation
- Authorization
- Transaction開始
- Response生成
- Business Ruleそのもの

---

## 5. findById

Input：

    EmployeeId

Output：

    Employee|null

内部Flow：

    EmployeeId
        ↓
    EmployeeModel Query
        ↓
    EmployeeModel|null
        ↓
    EmployeeMapper
        ↓
    Employee|null

---

## 6. findByEmployeeNumber

Input：

    EmployeeNumber

Output：

    Employee|null

EmployeeNumber Value ObjectからPrimitiveを取り出してQueryする。

---

## 7. existsByEmployeeNumber

重複確認用。

    existsByEmployeeNumber(
        EmployeeNumber $employeeNumber
    ): bool

Aggregateを復元せず、

    EXISTS

Queryだけで判定してよい。

---

## 8. save

Input：

    Employee

Output：

    void

Domain AggregateをPersistenceへ保存する。

新規・更新の両方を扱う。

---

## 9. 新規 / 更新判定

今回のDomain Aggregateは保存前からIDを持つ。

そのため、

    id

で既存Recordを確認できる。

概念：

    EmployeeModel::query()
        ->find($employee->id()->value())

存在：

    UPDATE

不存在：

    INSERT

とする。

---

## 10. Mapper

配置：

    Infrastructure/
    └── Persistence/
        └── Eloquent/
            └── Mappers/
                └── EmployeeMapper.php

責務：

    EmployeeModel
        ↓
    Employee

および、

    Employee
        ↓
    EmployeeModel

の変換。

---

## 11. EmployeeMapper toDomain

概念：

    public function toDomain(
        EmployeeModel $model
    ): Employee

変換：

    id
        ↓
    EmployeeId

    employee_number
        ↓
    EmployeeNumber

    department_id
        ↓
    DepartmentId

    employment_status
        ↓
    EmploymentStatus

    retirement_date
        ↓
    RetirementDate|null

---

## 12. Domain復元

Mapperでは、

    Employee::reconstitute()

を利用する。

概念：

    return Employee::reconstitute(
        id: new EmployeeId($model->id),
        employeeNumber: new EmployeeNumber(
            $model->employee_number
        ),
        name: $model->name,
        departmentId: new DepartmentId(
            $model->department_id
        ),
        employmentStatus: EmploymentStatus::from(
            $model->employment_status
        ),
        retirementDate:
            $model->retirement_date !== null
                ? RetirementDate::fromDate(...)
                : null,
    );

---

## 13. EmployeeMapper toModel

Domain AggregateからEloquent Modelへ変換する。

候補：

    public function toModel(
        Employee $employee,
        ?EmployeeModel $model = null
    ): EmployeeModel

既存Modelが渡された場合：

    UPDATE用

nullの場合：

    INSERT用

---

## 14. fill方式

別案：

    public function fillModel(
        Employee $employee,
        EmployeeModel $model
    ): void

を利用する。

今回はこちらを第一候補とする。

理由：

- Model生成と値設定を分離できる
- Repositoryが新規 / 更新を判断できる
- Mapperの責務が明確

---

## 15. EmployeeMapper

候補構成：

    final class EmployeeMapper
    {
        public function toDomain(
            EmployeeModel $model
        ): Employee {
            // ...
        }

        public function fillModel(
            Employee $employee,
            EmployeeModel $model
        ): void {
            // ...
        }
    }

---

## 16. fillModel変換

例えば：

    $model->id =
        $employee->id()->value();

    $model->employee_number =
        $employee->employeeNumber()->value();

    $model->name =
        $employee->name();

    $model->department_id =
        $employee->departmentId()->value();

    $model->employment_status =
        $employee->employmentStatus()->value;

    $model->retirement_date =
        $employee->retirementDate()?->toDateString();

---

## 17. Timestamp

`created_at` / `updated_at` はDomain Aggregateへ持ち込まないことを第一候補とする。

理由：

今回のEmployee Domain Ruleでは
作成日時・更新日時がBusiness Behaviorに関係しないため。

TimestampはPersistence / API表示用Metadataとして扱う。

---

## 18. Timestampが必要になった場合

例えば将来、

    Employeeがいつ登録されたか

がDomain Ruleに必要になった場合のみ、
Domainへ導入を検討する。

今はMapper / Eloquent側で扱う。

---

## 19. EmployeeModel

配置：

    Infrastructure/
    └── Persistence/
        └── Eloquent/
            └── Models/
                └── EmployeeModel.php

概念：

    final class EmployeeModel extends Model
    {
        protected $table = 'employees';

        public $incrementing = true;

        protected $keyType = 'int';

        protected function casts(): array
        {
            return [
                'retirement_date' => 'date',
            ];
        }
    }

Domain Behaviorは持たせない。

---

## 20. Eloquent Relation

EmployeeModelではInfrastructure都合でRelationを定義してよい。

例：

    department()

ただし、

    $employeeModel->department

をDomain Aggregate内部へそのまま渡さない。

---

## 21. save新規時

Flow：

    Employee Aggregate
        ↓
    find existing model by id
        ↓
    not found
        ↓
    new EmployeeModel()
        ↓
    EmployeeMapper::fillModel()
        ↓
    save()

Sequence先取り済みのIDを明示的に設定する。

---

## 22. save更新時

Flow：

    Employee Aggregate
        ↓
    EmployeeModel取得
        ↓
    Mapper::fillModel()
        ↓
    save()

---

## 23. 更新対象が存在しない場合

Domain Aggregateとして既存Employeeを更新しようとしているのに
DB Recordが存在しない場合は異常。

候補：

    PersistenceException

等を発生させる。

ただしRepository `save()` をUpsert的に使うなら
新規扱いになる。

---

## 24. 推奨

新規 / 更新の意図をRepositoryで区別しない。

    save()

は、

    idが存在しなければINSERT
    存在すればUPDATE

として扱う。

Application側はPersistence状態を意識しない。

---

## 25. Optimistic Lock

MVPではVersion ColumnによるOptimistic Lockは導入しない。

必要になった場合：

    version

Columnを追加して再検討する。

今回の重要な競合制御はPermission Manager Ruleの
悲観Lockを優先する。

---

## 26. MapperにQueryを書かない

Mapperは変換だけを担当する。

禁止例：

    EmployeeMapper::toDomain()

内部でDepartment Queryを実行する。

MapperからRepositoryやDatabaseへアクセスしない。

---

## 27. RepositoryにBusiness Ruleを書かない

禁止例：

    if status == RETIRED ...

のようなBusiness Ruleを
EloquentEmployeeRepositoryへ置かない。

状態RuleはEmployee Aggregateで保証する。

---

## 28. Repository Implementation例

概念：

    final class EloquentEmployeeRepository
        implements EmployeeRepository
    {
        public function __construct(
            private EmployeeMapper $mapper,
        ) {
        }

        public function findById(
            EmployeeId $id
        ): ?Employee {
            $model = EmployeeModel::query()
                ->find($id->value());

            return $model
                ? $this->mapper->toDomain($model)
                : null;
        }

        public function save(
            Employee $employee
        ): void {
            $model = EmployeeModel::query()
                ->find($employee->id()->value());

            $model ??= new EmployeeModel();

            $this->mapper->fillModel(
                $employee,
                $model
            );

            $model->save();
        }
    }

---

## 29. Application Flow

RegisterEmployeeの場合：

    RegisterEmployeeHandler
        ↓
    EmployeeRepository::existsByEmployeeNumber()
        ↓
    EmployeeIdGenerator::next()
        ↓
    Employee::register()
        ↓
    EmployeeRepository::save()
        ↓
    Infrastructure
        ↓
    Mapper
        ↓
    Eloquent
        ↓
    PostgreSQL

---

## 30. 他Aggregateへの横展開

同じPatternを利用する。

### Department

    DepartmentRepository
    EloquentDepartmentRepository
    DepartmentMapper
    DepartmentModel

### SkillCategory

    SkillCategoryRepository
    EloquentSkillCategoryRepository
    SkillCategoryMapper
    SkillCategoryModel

### Skill

    SkillRepository
    EloquentSkillRepository
    SkillMapper
    SkillModel

### EmployeeSkill

    EmployeeSkillRepository
    EloquentEmployeeSkillRepository
    EmployeeSkillMapper
    EmployeeSkillModel

### User

    UserRepository
    EloquentUserRepository
    UserMapper
    UserModel

---

## 31. Assignment

SubManagerAssignment / TeamLeaderAssignmentは
Domain Modelが軽量なため、
Mapperを必須にしない案もある。

ただし設計の一貫性を優先するならMapperを置いてもよい。

第一候補：

    Repository Implementation
        ↓
    Query Builder / Eloquent

で直接Relation Objectを復元する。

過度なMapper追加はしない。

---

## 32. EmployeeSkill Mapper

EmployeeSkillは変換が最も重要。

Database：

    boolean
    integer
    smallint
    date

Domain：

    WorkExperience
    ExperienceMonths
    SkillLevel
    LastUsedMonth

となる。

このAggregateではMapperを必須とする。

---

## 33. LastUsedMonth変換

Database：

    2026-08-01

Mapper：

    year = 2026
    month = 8

Domain：

    LastUsedMonth(2026, 8)

保存時は逆変換する。

---

## 34. WorkExperience変換

Database：

    true

Domain：

    WorkExperience::Experienced

Database：

    false

Domain：

    WorkExperience::Unexperienced

---

## 35. SkillLevel変換

Database：

    3

Domain：

    SkillLevel::Level3

PHP：

    SkillLevel::from($model->skill_level)

で変換できる。

---

## 36. User Mapper

Database：

    role = 'SUB_MANAGER'

Domain：

    UserRole::SubManager

Database：

    can_manage_permissions = false

Domain：

    bool

として復元する。

---

## 37. Exception変換

Repository保存時にPostgreSQL UNIQUE Constraint違反が発生する可能性がある。

例：

    uq_employees_employee_number

InfrastructureでConstraintを識別し、

    DuplicateEmployeeNumber

等のApplication Exceptionへ変換することを検討する。

---

## 38. Application事前確認との併用

Application：

    existsByEmployeeNumber()

でUX向上・明示的Rule確認。

Database：

    UNIQUE

でRace Conditionを含む最終保証。

両方利用する。

---

## 39. Constraint Name

例：

    uq_employees_employee_number

    uq_users_login_id

    uq_skills_name

    uq_employee_skills_employee_skill

明示名を付ける。

InfrastructureでError Mappingしやすくする。

---

## 40. Read処理との分離

一覧・検索ではRepositoryを使わない場合がある。

例えば：

    EmployeeRepository

はAggregate取得・保存用。

一覧：

    EmployeeSearchQueryService

詳細表示：

    EmployeeDetailQueryService

を利用できる。

---

## 41. Repository肥大化を防ぐ

避ける例：

    EmployeeRepository
    ├── searchBySkill()
    ├── searchByDepartment()
    ├── dashboardCount()
    ├── exportCsv()
    └── ...

Write Aggregate RepositoryとRead Queryを分ける。

---

## 42. Read側

概念：

    interface EmployeeSearchQueryService
    {
        public function search(
            SearchEmployeesQuery $query
        ): EmployeeSearchResult;
    }

Infrastructure：

    EloquentEmployeeSearchQueryService

がJOIN等を実装する。

---

## 43. Testing

### Mapper Unit Test

確認：

- Eloquent → Domain
- Domain → Eloquent
- Enum変換
- Value Object変換
- nullable Date変換

### Repository Integration Test

実PostgreSQLで確認：

- save insert
- save update
- findById
- findByEmployeeNumber
- exists
- Constraint violation

---

## 44. Domain Testとの分離

Domain TestではEloquent / Mapperを使用しない。

    Employee::register()
    employee->retire()

等だけを確認する。

Persistence TestとDomain Testを分離する。

---

## 45. Service Container Binding

Service ProviderでBindingする。

概念：

    EmployeeRepository::class
        →
    EloquentEmployeeRepository::class

他Repositoryも同様。

---

## 46. Directory構成

    app/
    ├── Domain/
    │   └── EmployeeManagement/
    │       └── Repositories/
    │           └── EmployeeRepository.php
    │
    └── Infrastructure/
        └── Persistence/
            └── Eloquent/
                ├── Models/
                │   └── EmployeeModel.php
                │
                ├── Mappers/
                │   └── EmployeeMapper.php
                │
                └── Repositories/
                    └── EloquentEmployeeRepository.php

---

## 47. 決定候補

### Repository Interface

Domain Layer。

### Repository Implementation

Infrastructure Layer。

### Eloquent Model

Infrastructure Layer。

### Mapper

Infrastructure Layer。

### Domain Aggregate

Eloquentとは分離。

### Mapper責務

Persistence ↔ Domain変換のみ。

### Repository責務

Aggregate取得 / 保存。

### Read Query

専用Query Service。

### save()

Insert / Updateを抽象化する。

### Timestamp

Domainには持たせない。

### Eloquent Relation

Infrastructure内部で利用可能。

### Business Rule

Repository / Mapperへ置かない。
