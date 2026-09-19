# Backend 技術・Library選定 - Domain・Application

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend における Domain Layer / Application Layer の具体的な実装方針と、関連技術・Libraryの採用判断を定義する。

本Projectでは以下を前提とする。

- Clean Architectureを採用する
- DDDを採用する
- Lightweight CQRSを採用する
- Domain LayerはPure PHPとする
- Application Layerも原則Pure PHPとする
- Laravel依存はPresentation / Infrastructureへ寄せる
- Command / Query / HandlerはProject固有Classとして実装する
- Repository InterfaceはDomain側へ配置する
- EloquentをDomainへ露出させない
- Domain ModelはBehavior経由で状態変更する
- Generic Setterを使用しない
- 外部DDD Framework / CQRS Frameworkは導入しない

基本方針は以下とする。

```text
Domain
    ↓
Pure PHP

Application
    ↓
原則Pure PHP

Presentation / Infrastructure
    ↓
Laravelを積極的に利用
```

---

## 2. 基本方針

Domain / Applicationでは、外部Libraryを増やすことよりもPHP標準機能を利用した明示的な設計を優先する。

依存関係は以下を基本とする。

```text
Presentation
    ↓
Application
    ↓
Domain

Infrastructure
    ↓
Domain / ApplicationのInterfaceを実装
```

Domain Layerから以下へ依存しない。

- Laravel
- Eloquent
- HTTP
- Database
- Cache
- Queue
- Logging Framework
- Composer Package固有Model
- Infrastructure Service

Application LayerについてもFramework依存は必要最小限とする。

---

## 3. Domain Model

Domain Modelは通常のPHP Classとして実装する。

専用DDD Frameworkは導入しない。

例：

```php
final class EmployeeSkill
{
    private function __construct(
        private EmployeeSkillId $id,
        private EmployeeId $employeeId,
        private SkillId $skillId,
        private SkillLevel $level,
        private WorkExperience $workExperience,
        private ?ExperiencePeriod $experiencePeriod,
        private ?YearMonth $lastUsedAt,
    ) {
    }

    // Domain Behavior
}
```

以下を明確に分離する。

```text
Domain Model
    ≠
Eloquent Model
```

Domain ModelはBusiness Ruleを表現する。

Eloquent ModelはInfrastructure LayerのPersistence Modelとして扱う。

---

## 4. Aggregate / Entity

Aggregate / EntityはPure PHP Classとして実装する。

主なAggregate Rootは以下とする。

```text
Department
Employee
SkillCategory
Skill
EmployeeSkill
User
```

`EmployeeSkill` は特に重要なAggregateとして扱う。

Aggregate Rootを表現するためだけの共通Base Classは原則作成しない。

以下のようなClassは採用しない。

```php
abstract class AggregateRoot
{
}
```

Aggregate Rootであることは主に以下によって表現する。

- Repository単位
- Transaction Boundary
- 外部からの変更経路
- Invariantの管理単位

継承を使う明確な理由がない限り、Marker的なBase Classを導入しない。

---

## 5. Aggregate間の参照

Aggregate間は原則IDで参照する。

例：

```text
EmployeeSkill
├── EmployeeId
└── SkillId
```

以下のような巨大なObject Graphを構築しない。

```text
EmployeeSkill
└── Employee
    └── Department
        └── Employees
            └── ...
```

Aggregate間の境界を明確に保ち、必要なAggregateはRepository等から明示的に取得する。

---

## 6. Factory / Reconstitution

Domain Modelの生成用途を明確に分離する。

新規生成には意味のあるFactory Methodを利用する。

例：

```php
EmployeeSkill::register(...);
```

Persistenceからの復元には`reconstitute()`を利用する。

```php
EmployeeSkill::reconstitute(...);
```

例：

```php
public static function register(
    EmployeeSkillId $id,
    EmployeeId $employeeId,
    SkillId $skillId,
    SkillLevel $level,
    WorkExperience $workExperience,
    ?ExperiencePeriod $experiencePeriod,
    ?YearMonth $lastUsedAt,
): self {
    // Domain invariant validation

    return new self(
        $id,
        $employeeId,
        $skillId,
        $level,
        $workExperience,
        $experiencePeriod,
        $lastUsedAt,
    );
}
```

Constructorを無制限に公開してDomain Invariantを回避できる設計にはしない。

---

## 7. Domain Behavior

Domain Modelの状態変更はBehavior Method経由で行う。

Generic Setterは採用しない。

以下のような実装は避ける。

```php
$employeeSkill->setLevel($level);
$employeeSkill->setExperiencePeriod($period);
$employeeSkill->setLastUsedAt($lastUsedAt);
```

代わりにDomain上の意味を表すMethodを利用する。

```php
$employeeSkill->changeLevel($level);
$employeeSkill->recordWorkExperience(...);
$employeeSkill->markAsUnexperienced();
```

Domain Invariantは可能な限りAggregate内部で守る。

---

## 8. EmployeeSkill Invariant

EmployeeSkillでは以下をDomain Ruleとして保証する。

```text
実務未経験
    ↓
Skill Level 1のみ
Experience Periodなし
Last Usedなし


実務経験あり
    ↓
Experience Period 1か月以上
Last Used必須
Skill Level 1〜5
```

このRuleをForm RequestやEloquent Modelだけに依存させない。

```text
HTTP Validation
    ↓
入力形式

Domain
    ↓
Business Invariant

Database
    ↓
最終的な整合性
```

という多層防御とする。

---

## 9. Value Object

Value ObjectはPure PHPで実装する。

専用Value Object Libraryは採用しない。

基本的には`final readonly class`を利用する。

例：

```php
final readonly class EmployeeId
{
    public function __construct(
        public int $value,
    ) {
        if ($value <= 0) {
            throw new InvalidEmployeeId($value);
        }
    }
}
```

主な候補：

```text
EmployeeId
EmployeeSkillId
SkillId
SkillCategoryId
DepartmentId
UserId
ExperiencePeriod
YearMonth
```

---

## 10. Value Object化の基準

DDDを理由にすべてのPrimitive ValueをValue Object化しない。

以下を基準とする。

> 独自の意味・制約・操作を持つ値か

例えば、

```text
EmployeeId
```

は通常の`int`と区別する意味が強いためValue Object化する。

一方、単純な表示用文字列まで機械的にValue Object化しない。

例：

```text
EmployeeName
SkillName
DepartmentName
```

などは独自Behaviorや強いInvariantが必要になった場合にValue Object化を再検討する。

Primitive Obsessionと過剰なClass化のバランスを取る。

---

## 11. Enum

EnumにはPHP Native Enumを採用する。

外部Enum Libraryは利用しない。

例：

```php
enum SkillLevel: int
{
    case Level1 = 1;
    case Level2 = 2;
    case Level3 = 3;
    case Level4 = 4;
    case Level5 = 5;
}
```

主なEnumは以下とする。

```text
EmploymentStatus
SkillLevel
WorkExperience
UserRole
```

Enumにその値自身に自然に属する小さなBehaviorを持たせることは許可する。

例：

```php
public function isLevelOne(): bool
{
    return $this === self::Level1;
}
```

---

## 12. Domain Service

Domain Serviceは以下の場合のみ導入する。

> Entity / Aggregate / Value Objectのいずれにも自然に属さないDomain Logicが存在する場合

まず以下の順番で配置先を検討する。

```text
Aggregate Behavior
    ↓
Value Object
    ↓
Domain Service
```

何でもDomain Serviceへ移動する設計にはしない。

Domain Serviceは原則としてStatelessに保つ。

---

## 13. Domain Exception

Domain Rule違反は必要に応じてDomain Exceptionとして表現する。

専用Exception Libraryは利用しない。

例：

```php
final class InvalidSkillLevelForUnexperiencedEmployee
    extends DomainException
{
}
```

Domain ExceptionにはHTTP固有情報を持たせない。

以下をDomainへ持ち込まない。

```text
HTTP Status Code
JsonResponse
Error Response Schema
Laravel Exception Handler
```

変換は外側のLayerで行う。

```text
Domain Exception
    ↓
Application / Presentation
    ↓
HTTP Error Response
```

---

## 14. Repository Interface

Repository Interfaceは原則Domain Layerに配置する。

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

Repository実装はInfrastructure Layerへ配置する。

```text
Domain
└── EmployeeSkillRepository

Infrastructure
└── EloquentEmployeeSkillRepository
```

Repository専用Libraryは導入しない。

---

## 15. Repository設計

RepositoryはAggregate単位で設計する。

```text
Repository
    ↓
Aggregate Root
```

汎用Base Repositoryは原則作成しない。

以下のようなInterfaceは避ける。

```php
interface BaseRepository
{
    public function find(int $id): ?object;

    public function save(object $entity): void;

    public function delete(object $entity): void;
}
```

各Aggregateで必要な操作のみ明示的に定義する。

Eloquent固有型をRepository Interfaceへ露出させない。

---

## 16. Command

状態を変更するUseCaseの入力にはCommandを利用する。

CommandはPure PHP `final readonly class`とする。

例：

```php
final readonly class CreateEmployeeCommand
{
    public function __construct(
        public string $name,
        public DepartmentId $departmentId,
    ) {
    }
}
```

Commandに以下を含めない。

- HTTP Request
- FormRequest
- JsonResponse
- Eloquent Model
- Laravel固有Object

Command Busは導入しない。

---

## 17. Query

Read UseCaseの入力にはQueryを利用する。

QueryもPure PHP `final readonly class`とする。

例：

```php
final readonly class ListEmployeesQuery
{
    public function __construct(
        public ?DepartmentId $departmentId,
        public ?string $keyword,
        public int $page,
        public int $perPage,
    ) {
    }
}
```

QueryはRead Model取得に必要な条件を明示的に表現する。

---

## 18. Lightweight CQRS

WriteとReadを論理的に分離する。

```text
Write

Command
    ↓
Command Handler
    ↓
Domain Aggregate
    ↓
Repository


Read

Query
    ↓
Query Handler / Query Service
    ↓
Read Model
```

採用するのはLightweight CQRSであり、Infrastructure自体を完全分離するFull CQRSではない。

以下はMVPでは採用しない。

- Command Bus
- Query Bus
- Event Store
- Event Sourcing
- Separate Write Database
- Separate Read Database

---

## 19. Handler

Command / QueryとHandlerは原則1:1で対応させる。

例：

```text
CreateEmployeeCommand
    ↓
CreateEmployeeHandler

UpdateEmployeeSkillCommand
    ↓
UpdateEmployeeSkillHandler

ListEmployeesQuery
    ↓
ListEmployeesHandler
```

HandlerはController等からDIして直接呼び出す。

```php
$result = $handler->handle($command);
```

Command Bus等による自動Dispatchは行わない。

---

## 20. Application Handlerの責務

HandlerはUseCase Orchestratorとして扱う。

主な責務は以下。

```text
Input受け取り
    ↓
必要なRepositoryから取得
    ↓
Domain Behavior呼び出し
    ↓
必要なDomain Service呼び出し
    ↓
Repository保存
    ↓
Result返却
```

Handler自体へ複雑なBusiness Ruleを集中させない。

Business Ruleは可能な限りDomainへ配置する。

一方で、

- Transaction Coordination
- 複数Aggregateの調整
- External Service呼び出し
- Authorization済みUseCaseの進行

などはApplication Layerの責務となる。

---

## 21. Transaction Boundary

Transaction BoundaryはApplication UseCase単位とする。

```text
1 Handler
    ≒
1 UseCase
    ≒
1 Transaction
```

Application LayerからTransaction Portを利用し、実装はInfrastructure Layerへ配置する。

Laravel FacadeをDomainから直接利用しない。

具体的なTransaction設計はBackend Architectureの`09_Transaction.md`に従う。

---

## 22. DTO

汎用DTO Libraryは採用しない。

基本的にPHPの`final readonly class`を利用する。

例えば、

```php
final readonly class EmployeeDetail
{
    public function __construct(
        public int $id,
        public string $name,
        public string $departmentName,
    ) {
    }
}
```

以下は現時点では採用しない。

```text
spatie/laravel-data
その他DTO Framework
```

外部Libraryによる自動Mappingよりも、明示的な型と変換を優先する。

---

## 23. DTOという名前の乱用を避ける

役割ごとに名前を明確に分ける。

```text
Command
    → Write UseCase Input

Query
    → Read UseCase Input

Read Model
    → Read UseCase Output

Result
    → Write UseCase Output

API Resource
    → HTTP Output
```

すべてを単に`DTO`と呼ばない。

Architecture上の責務がClass名から分かる状態を維持する。

---

## 24. Read Model

Read側はDomain Aggregateを復元する必要はない。

Query ServiceからRead専用Modelを返す。

例：

```php
final readonly class EmployeeListItem
{
    public function __construct(
        public int $id,
        public string $name,
        public string $departmentName,
    ) {
    }
}
```

流れは以下。

```text
Query
    ↓
Query Handler / Query Service
    ↓
Database
    ↓
Read Model
```

Eloquent ModelをPresentation Layerへ直接返さない。

---

## 25. Result Object

Write UseCaseの戻り値は必要に応じてResult Objectを利用する。

例：

```php
final readonly class CreateEmployeeResult
{
    public function __construct(
        public EmployeeId $employeeId,
    ) {
    }
}
```

ただし単一Value Objectを返すだけで十分な場合は専用Result Objectを作らない。

基準は以下。

```text
単一値で意味が明確
    ↓
その型を直接返す

複数の関連値を返す
    ↓
Result Object
```

不要なClass増加を避ける。

---

## 26. Application Service

汎用的な`ApplicationService` Base Classは採用しない。

基本的にはHandler自体がApplication Serviceの役割を担う。

```text
Application Service
    ≒
Command / Query Handler
```

複数UseCaseで共通となるApplication Logicが明確に存在する場合のみ、専用Application Serviceを作成する。

単なるCode重複回避だけを目的とした安易な共通化は避ける。

---

## 27. ID Generator Port

ID生成はApplication Portとして抽象化する。

Primary KeyにはPostgreSQL bigint / Sequenceを利用するが、Application / DomainからPostgreSQLへ直接依存しない。

例：

```php
interface EmployeeIdGenerator
{
    public function generate(): EmployeeId;
}
```

Infrastructure側でPostgreSQL Sequenceを利用する。

```text
Application
    ↓
EmployeeIdGenerator

Infrastructure
    ↓
PostgreSQL Sequence
```

これによりAggregate生成前にIDを取得できる。

```text
ID生成
    ↓
Aggregate::register()
    ↓
Repository::save()
```

IDの欠番は許容する。

---

## 28. ID Generatorの粒度

Aggregateごとに型安全なGenerator Interfaceを持つ方式を基本とする。

例：

```text
EmployeeIdGenerator
EmployeeSkillIdGenerator
SkillIdGenerator
DepartmentIdGenerator
```

汎用的な、

```php
interface IdGenerator
{
    public function generate(): int;
}
```

のみで全Aggregateを扱う方式は、型安全性が低下するため原則採用しない。

共通実装の内部では再利用してよい。

---

## 29. Clock Port

現在時刻をApplication / Domainから直接取得しない。

Clock InterfaceをApplication Portとして採用する。

```php
interface Clock
{
    public function now(): DateTimeImmutable;
}
```

ProductionではInfrastructure実装を利用する。

```php
final class SystemClock implements Clock
{
    public function now(): DateTimeImmutable
    {
        return new DateTimeImmutable();
    }
}
```

TestではFake Clockを利用できる。

```text
Production
    ↓
SystemClock

Test
    ↓
FakeClock
```

これにより時間依存UseCaseのTestを決定的にできる。

---

## 30. Date / Time

Domain / ApplicationではPHP標準の`DateTimeImmutable`を基本とする。

```text
Domain / Application
    ↓
DateTimeImmutable

Presentation / Infrastructure
    ↓
必要に応じてCarbon利用可
```

DomainへCarbon依存を持ち込まない。

`YearMonth`のようにDomain上固有の意味を持つ日時はValue Objectとして表現する。

詳細は`08_Serialization・Date・ID.md`で定義する。

---

## 31. Domain Event

MVPでは本格的なDomain Event基盤を導入しない。

以下は現時点では採用しない。

```text
Domain Event Bus
Message Bus
Event Store
Async Domain Event
Event Sourcing
```

具体的なNeedが発生した場合のみ再検討する。

Domain Eventを導入するとしても、Domain LayerをLaravel Eventへ依存させない。

---

## 32. Laravel Event

Laravel EventはDomain Event Frameworkとして利用しない。

将来的に必要となった場合は、

```text
Application / Infrastructure
    ↓
Integration Event
```

として利用することを検討できる。

例えば、

```text
EmployeeCreated
    ↓
External Notification
```

のような外部連携用途は将来の検討対象とする。

MVPでは不要なEvent Driven Architectureを導入しない。

---

## 33. DDD Framework

DDD専用Frameworkは採用しない。

以下はPure PHPとして実装する。

```text
Aggregate
Entity
Value Object
Domain Service
Domain Exception
Repository Interface
```

DDDはLibraryではなく設計・Modelingの方針として扱う。

---

## 34. CQRS Framework

CQRS Frameworkは採用しない。

以下を導入しない。

```text
Command Bus Framework
Query Bus Framework
Mediator Framework
Message Bus Framework
CQRS Toolkit
```

Command / Query / Handlerは通常のPHP Classとして明示的に実装する。

---

## 35. `spatie/laravel-data`

`spatie/laravel-data`は現時点では採用しない。

理由：

- Pure PHP `readonly class`で十分
- Application LayerをLaravel Packageへ依存させたくない
- Mapping処理を明示的に保ちたい
- OpenAPI Firstを採用しており、CodeからSchema生成する必要がない
- DTO数が現時点では管理可能

Presentation LayerのData Mappingが将来的に大規模化した場合のみ再検討する。

---

## 36. UUID / ULID Library

Primary Keyにはbigint + PostgreSQL Sequenceを利用するため、UUID / ULID Libraryは採用しない。

```text
ramsey/uuid
    → 不採用
```

Primary Key戦略を変更した場合のみ再検討する。

---

## 37. Date Library

Domain向けの追加Date Libraryは採用しない。

基本は以下。

```text
DateTimeImmutable
+
Project固有Value Object
```

`YearMonth`等は必要に応じて自前の小さなValue Objectとして実装する。

---

## 38. Validation Library

Domain Validation専用Frameworkは導入しない。

Domain Invariantは以下で表現する。

- Constructor / Factory
- Behavior Method
- Value Object
- Enum
- Domain Exception

Annotation / Attributeによる自動Domain Validationは採用しない。

---

## 39. Attribute / Reflection中心の設計

Domain / Application ClassへArchitecture表現用Attributeを大量に付ける設計は採用しない。

例えば、

```php
#[AggregateRoot]
#[ValueObject]
#[Command]
#[CommandHandler]
```

のようなMetadataは不要とする。

Architectureは以下で明示する。

- Namespace
- Directory
- Class
- Interface
- Dependency Direction
- Naming

Reflectionによる過剰な自動化を避ける。

---

## 40. Laravel Service Container

Dependency InjectionのComposition RootとしてLaravel Service Containerを利用する。

例：

```php
$this->app->bind(
    EmployeeRepository::class,
    EloquentEmployeeRepository::class,
);
```

これはDomainがLaravelへ依存することを意味しない。

```text
Domain Interface
        ↑
        │ bind
Laravel Service Container
        │
        ↓
Infrastructure Implementation
```

Laravel Service Containerは外側の組み立て役として使用する。

---

## 41. Framework Dependency Rule

Layerごとの依存方針は以下とする。

| Layer | Laravel依存 |
|---|---|
| Domain | 禁止 |
| Application | 原則避ける |
| Presentation | 許可 |
| Infrastructure | 許可 |

Domain / ApplicationでLaravel Helperを安易に使用しない。

例えば以下をDomainから利用しない。

```php
now();
collect();
app();
config();
DB::transaction(...);
Log::info(...);
```

必要な機能はPort / Interface越しに利用する。

---

## 42. Application Port

ApplicationからInfrastructure機能を利用する必要がある場合はPortを定義する。

主な例：

```text
Clock
ID Generator
Transaction Manager
External Service Client
```

ただし全てのInfrastructure機能を機械的にInterface化しない。

以下の基準で導入する。

- Applicationから必要
- Infrastructure詳細を隠したい
- Test Doubleへ差し替える価値がある
- 複数実装の可能性がある
- Architecture Boundaryとして意味がある

Interface Explosionを避ける。

---

## 43. DomainとApplicationの最終構成

Write UseCaseは以下とする。

```text
Presentation
    ↓
Command
    ↓
Command Handler
    ↓
Repository / Application Port
    ↓
Aggregate
    ↓
Domain Behavior
    ↓
Repository Save
```

Read UseCaseは以下とする。

```text
Presentation
    ↓
Query
    ↓
Query Handler / Query Service
    ↓
Infrastructure Query
    ↓
Read Model
```

Infrastructureは以下を担当する。

```text
Infrastructure
├── Eloquent Model
├── Repository Implementation
├── Mapper
├── Query Service Implementation
├── PostgreSQL Sequence
├── Transaction Implementation
└── SystemClock
```

---

## 44. Library採用判断

| Library / 技術 | 判断 |
|---|---|
| PHP Native Class | 採用 |
| `final readonly class` | 積極利用 |
| PHP Native Enum | 採用 |
| `DateTimeImmutable` | 採用 |
| Laravel Service Container | Composition Rootで採用 |
| Laravel Event | Domain Event用途では不採用 |
| DDD Framework | 不採用 |
| CQRS Framework | 不採用 |
| Command Bus | 不採用 |
| Query Bus | 不採用 |
| Repository Package | 不採用 |
| Mapper Package | 不採用 |
| Value Object Package | 不採用 |
| Enum Package | 不採用 |
| DTO Package | 不採用 |
| `spatie/laravel-data` | 不採用 |
| `ramsey/uuid` | 不採用 |
| Domain Date Library | 不採用 |
| Event Sourcing Framework | 不採用 |
| Reflection-based Domain Framework | 不採用 |

---

## 45. 採用技術・方針一覧

| 項目 | 決定 |
|---|---|
| Domain | Pure PHP |
| Application | 原則Pure PHP |
| Domain Model | 独立PHP Class |
| Eloquentとの分離 | 必須 |
| Aggregate Base Class | 不採用 |
| Aggregate参照 | ID参照 |
| Generic Setter | 不採用 |
| 新規生成 | `register()`等 |
| Persistence復元 | `reconstitute()` |
| Value Object | `final readonly class` |
| VO Library | 不採用 |
| Enum | PHP Native Enum |
| Enum Library | 不採用 |
| Domain Service | 必要時のみ |
| Domain Exception | Pure PHP |
| Repository Interface | Domain |
| Repository実装 | Infrastructure |
| Generic Repository | 原則不採用 |
| Command | `final readonly class` |
| Query | `final readonly class` |
| Handler | Command / Queryと原則1:1 |
| Command Bus | 不採用 |
| Query Bus | 不採用 |
| DTO Library | 不採用 |
| Read Model | Pure PHP |
| Result Object | 必要時のみ |
| Application Service Base Class | 不採用 |
| ID Generator | Application Port |
| ID Strategy | bigint + PostgreSQL Sequence |
| Clock | Application Port |
| Domain Date | `DateTimeImmutable` |
| Carbon Domain依存 | 禁止 |
| Transaction | UseCase単位 |
| Domain Event基盤 | MVPでは不採用 |
| Event Sourcing | 不採用 |
| DDD Framework | 不採用 |
| CQRS Framework | 不採用 |
| Service Container | Laravel標準 |
| Reflection中心設計 | 不採用 |

---

## 46. 最終方針

Domain / Applicationでは、

> FrameworkやLibraryでDDD / CQRSを実現するのではなく、PHPの型・Class・Interface・Dependency DirectionによってArchitectureを表現する

ことを基本方針とする。

最終的なWrite Architectureは以下とする。

```text
HTTP Request
    ↓
Presentation
    ↓
Command
    ↓
Command Handler
    ↓
Application Port / Repository
    ↓
Domain Aggregate
    ↓
Domain Behavior
    ↓
Repository Implementation
    ↓
Database
```

Read Architectureは以下とする。

```text
HTTP Request
    ↓
Presentation
    ↓
Query
    ↓
Query Handler / Query Service
    ↓
Read Query
    ↓
Read Model
    ↓
API Resource
```

Domain Layerには、

```text
Aggregate
Entity
Value Object
Enum
Domain Service
Domain Exception
Repository Interface
```

のみを中心として配置し、Laravel / Eloquent / HTTP / Databaseの詳細を持ち込まない。

Application Layerでは、

```text
Command
Query
Handler
Read Model
Result
Application Port
```

によってUseCaseを明示する。

特にInfrastructure依存となる、

```text
ID Generation
Current Time
Transaction
```

については必要に応じてApplication Portを設け、PostgreSQLやLaravelの詳細を内側へ漏らさない。

外部DDD / CQRS / DTO Frameworkを導入せず、

> Pure PHP + Laravelを外側で活用する

構成を採用する。
