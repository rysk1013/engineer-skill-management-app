# Domain Layer設計

## 1. 目的

Domain Layerは、Engineer Skill Management Appの業務概念・業務ルール・制約を表現する中核Layerとする。

Framework、Database、HTTPなどの技術的詳細から独立させ、業務上重要なルールをDomain Model自身が保証する。

Domain Layerは、

> 技術的な都合ではなく、業務上の概念・ルール・制約を表現する場所

として設計する。

---

## 2. 基本方針

Domain Layerでは以下を基本方針とする。

- Laravel非依存とする
- Eloquent非依存とする
- HTTP非依存とする
- Database非依存とする
- 業務ルールをDomain Modelへ集約する
- Aggregate単位で整合性を管理する
- Aggregate間はID参照を基本とする
- Aggregateを過度に大きくしない
- 状態変更は業務上意味のあるBehavior経由で行う
- Generic Setterは原則として作らない
- 新規生成は `register()` を基本とする
- 永続化データからの復元は `reconstitute()` を基本とする
- 業務上意味のある値にはValue Objectを積極的に利用する
- 有限の状態や分類にはPHP Enumを利用する
- 単一Aggregateだけでは判断できない業務ルールにはDomain Policyを利用する
- Domain Serviceは必要な場合のみ利用する
- Repository InterfaceはDomain Layerへ配置する
- Domain ExceptionはHTTPなどのPresentation上の情報を持たない

---

## 3. Bounded Context

本システムでは以下を主要なBounded Contextとする。

```text
Employee Management
Skill Management
Access Control
Authentication
```

### 3.1 Employee Management

社員に関する業務概念を扱う。

主に以下を対象とする。

- Employee
- Department
- Employment Status
- 退職に関する状態

---

### 3.2 Skill Management

社員の保有スキルおよびスキルマスタに関する業務概念を扱う。

主に以下を対象とする。

- SkillCategory
- Skill
- EmployeeSkill
- SkillLevel
- WorkExperience
- ExperiencePeriod
- LastUsedMonth

本システムのCore Domainとする。

---

### 3.3 Access Control

Application上のRole、Permissionおよび担当社員との関係に関する業務概念を扱う。

主に以下を対象とする。

- User Role
- Permission Manager
- SubManagerAssignment
- TeamLeaderAssignment
- 担当社員に対するアクセス範囲

---

### 3.4 Authentication

認証ユーザーに関するDomain上の概念を扱う。

Better Auth、Laravel Sanctum、Session、Backend Credential、Tokenなどの具体的な認証技術はDomainには含めず、Infrastructure Detailとして扱う。

---

## 4. Core Domain

本システムのCore Domainは `Skill Management` とする。

本システムの主目的である、

> 社員の保有技術・能力を把握する

というBusiness Valueに最も直接関係するためである。

Employee ManagementおよびAccess ControlはCore Domainを支える重要なSupporting Domainとして扱う。

Authenticationは主に技術基盤との境界を持つDomainとして扱う。

---

## 5. Aggregate Root

MVPでは主に以下をAggregate Rootとして扱う。

| Bounded Context | Aggregate Root |
|---|---|
| Employee Management | Department |
| Employee Management | Employee |
| Skill Management | SkillCategory |
| Skill Management | Skill |
| Skill Management | EmployeeSkill |
| Access Control / Authentication | User |

特に `EmployeeSkill` は、Skill Managementにおける重要Aggregateとして扱う。

`SubManagerAssignment` および `TeamLeaderAssignment` は独立した重量級Aggregateとはせず、担当関係を表現する軽量なRelationとして扱う。

---

## 6. Aggregate設計原則

Aggregateは、

> 同一Transaction内で強い整合性を保証する必要があるDomain Objectの単位

として設計する。

Aggregateを必要以上に大きくしない。

例えばEmployee Aggregateが以下をすべてObjectとして保持する設計は採用しない。

```text
Employee
├── Department
├── EmployeeSkill[]
│   └── Skill
├── SubManagerAssignment[]
└── TeamLeaderAssignment[]
```

このような巨大なObject Graphを作ると、

- 不要なData Load
- Aggregate境界の曖昧化
- Transaction範囲の肥大化
- 更新責務の混在

につながるため避ける。

---

## 7. Aggregate間参照

Aggregate間の参照はID参照を基本とする。

例えば `EmployeeSkill` はEmployeeおよびSkillそのものを保持せず、それぞれのIDを保持する。

```php
final class EmployeeSkill
{
    private EmployeeId $employeeId;

    private SkillId $skillId;
}
```

原則として以下のような参照は行わない。

```php
final class EmployeeSkill
{
    private Employee $employee;

    private Skill $skill;
}
```

基本形を以下とする。

```text
EmployeeSkill
├── EmployeeId
└── SkillId
```

これによりAggregate同士を疎結合に保ち、巨大なObject Graphの生成を防ぐ。

---

## 8. Entity

Entityは識別子を持ち、ライフサイクルを通して同一性を維持するDomain Objectとする。

Entityの同一性は、属性値全体ではなくIDによって判断する。

Domain EntityとEloquent Modelは明確に分離する。

```text
Domain Entity
    ≠
Eloquent Model
```

Domain EntityへPersistence都合のBehaviorやORM Relationを持ち込まない。

---

## 9. Value Object

業務上意味のある値は、Primitive型のまま扱うよりもDomain上の概念として表現することに価値がある場合、Value Objectを利用する。

例:

```text
EmployeeId
SkillId
EmployeeSkillId
ExperiencePeriod
LastUsedMonth
```

Value Objectは原則として以下の性質を持つ。

- Immutable
- 値による等価性
- 生成時に自身のInvariantを保証する
- 不正な状態を生成できない
- Domain上意味のあるBehaviorを持てる

ただし、単純な値をすべてValue Object化することはしない。

Value Object化によって、

- 業務上の意味が明確になる
- Validationを一箇所へ集約できる
- Primitive Obsessionを防げる
- 型によって誤用を防げる

場合に利用する。

---

## 10. ID Value Object

Aggregate / EntityのIDはValue Objectとして扱う。

例:

```text
EmployeeId
SkillId
SkillCategoryId
EmployeeSkillId
UserId
DepartmentId
```

Domain内で単なる `int` として扱わず、異なる種類のIDを型によって区別する。

これにより、例えばEmployee IDをSkill IDとして誤って渡すような実装を防止する。

Database PKの具体的な型やSequenceによる生成方法などはDomainの責務としない。

---

## 11. Domain Enum

有限の状態・分類を表現する場合はPHP Enumを利用する。

MVPでは主に以下をDomain Enumとして扱う。

```text
EmploymentStatus
SkillLevel
WorkExperience
UserRole
```

EnumはDomain Layerへ配置する。

Database上の値やAPI上の文字列表現とDomain Enumを完全に同一視せず、必要に応じて境界で変換する。

Domain EnumへHTTPやDatabase固有の責務を持たせない。

---

## 12. Behaviorによる状態変更

Domain Entityの状態変更は、業務上意味のあるBehaviorを通して行う。

Generic Setterは原則として作らない。

避ける例:

```php
$employeeSkill->setLevel($level);
$employeeSkill->setExperienceMonths($months);
$employeeSkill->setLastUsedMonth($month);
```

推奨例:

```php
$employeeSkill->changeLevel($level);

$employeeSkill->recordWorkExperience(
    $experiencePeriod,
    $lastUsedMonth,
);
```

Behavior内で必要なInvariantを確認する。

これにより、

```text
状態変更
    +
業務ルール
```

を同じ場所で管理する。

---

## 13. 新規生成

Aggregate / Entityの新規生成にはNamed Constructorとして `register()` を基本的に利用する。

例:

```php
$employeeSkill = EmployeeSkill::register(
    $employeeSkillId,
    $employeeId,
    $skillId,
    $skillLevel,
    $workExperience,
    $experiencePeriod,
    $lastUsedMonth,
);
```

`register()` は新規登録時に必要なInvariantを保証する。

Constructorを無制限に公開し、Application Layerなどから任意の状態のDomain Objectを生成できる設計は避ける。

ただし、Domain Objectの意味として `create()` など別の名前の方が自然な場合は、Domain Languageを優先する。

`register()` という名前を機械的にすべてのEntityへ適用すること自体を目的としない。

---

## 14. 永続化データからの復元

Databaseなどから既存のDomain Objectを復元する場合は `reconstitute()` を基本とする。

例:

```php
EmployeeSkill::reconstitute(
    $employeeSkillId,
    $employeeId,
    $skillId,
    $skillLevel,
    $workExperience,
    $experiencePeriod,
    $lastUsedMonth,
);
```

`register()` と `reconstitute()` の責務を明確に分離する。

```text
register()
    ↓
新しいDomain Objectを生成する

reconstitute()
    ↓
既に存在していたDomain Objectを復元する
```

Persistenceからの復元時に「新規登録」というDomain Eventや新規作成固有の処理が誤って発生しないようにする。

`reconstitute()` はInfrastructure側のMapperなどから利用する。

---

## 15. EmployeeSkill

`EmployeeSkill` はSkill Managementにおける重要Aggregateとして扱う。

EmployeeとSkillの単なる中間データではなく、

> 社員が特定のSkillについてどのような経験・能力を持っているか

を表現するDomain Modelとする。

主に以下の情報を扱う。

- EmployeeId
- SkillId
- SkillLevel
- WorkExperience
- ExperiencePeriod
- LastUsedMonth

EmployeeSkill自身が、これらの値の組み合わせに関するInvariantを保証する。

---

## 16. EmployeeSkill Invariant

### 16.1 実務未経験

実務未経験の場合、Skill LevelはLevel 1のみ選択可能とする。

```text
WorkExperience = NONE
        ↓
SkillLevel = LEVEL_1
```

Level 2以上の状態を生成・変更できないようDomainで保証する。

---

### 16.2 実務経験あり

実務経験ありの場合、経験期間は1か月以上必須とする。

```text
WorkExperience = EXPERIENCED
        ↓
ExperiencePeriod >= 1 month
```

`0年0か月` は実務経験ありとして扱わない。

---

### 16.3 最終利用年月

実務経験ありの場合、最終利用年月を必須とする。

```text
WorkExperience = EXPERIENCED
        ↓
LastUsedMonth is required
```

実務未経験の場合は最終利用年月を設定しない。

---

### 16.4 Invariantの保証

これらのInvariantは、

- 新規登録
- Skill Level変更
- 実務経験変更
- 経験期間変更

など、どの経路から状態が変更された場合でも破られないようDomain Modelで保証する。

Form Requestなど外側のLayerでも同様のValidationを行うことはできるが、Domainを最終的なInvariantの保証地点とする。

---

## 17. Domain Policy

単一Aggregateだけでは判断できない業務ルールはDomain Policyとして表現する。

代表例として、

> Permission Managerを最低1人維持する

というInvariantがある。

この判断には複数Userの状態を考慮する必要があるため、単一User Aggregateだけの責務とはしない。

Domain Policyを利用して業務上の判断を表現する。

Laravel Policyとは明確に役割を分ける。

### Laravel Policy

```text
このActorが、この操作を実行する権限を持っているか
```

### Domain Policy

```text
この状態変更を行った結果、
Domain上のBusiness Ruleを維持できるか
```

例えば、

```text
Permission Manager解除
        ↓
解除後もPermission Managerが1人以上存在するか
        ↓
Domain Policy
```

という責務分担とする。

Database Lockなど、このInvariantを同時実行環境で保証するための技術的処理はInfrastructure側で実現する。

---

## 18. Domain Service

単一EntityやValue Objectへ自然に配置できないDomain Logicが存在する場合にDomain Serviceを利用する。

Domain Serviceは必要な場合のみ導入する。

以下のような曖昧なServiceへ業務ロジックを集約することは避ける。

```text
EmployeeService
SkillService
EmployeeSkillService
```

Domain Serviceを作成する前に、以下の順番で責務の配置先を検討する。

```text
Entity / Aggregate
        ↓
Value Object
        ↓
Domain Policy
        ↓
Domain Service
```

EntityやValue Object自身が自然に持てるBehaviorをServiceへ逃がさない。

---

## 19. Repository Interface

Repository InterfaceはDomain Layerへ配置する。

RepositoryはAggregate単位を基本とする。

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

Repositoryは、

> Domain Aggregateの永続化と復元に必要な抽象

として扱う。

Domain側は永続化方式を知らない。

Repository Interfaceへ以下を露出しない。

- Eloquent Model
- Eloquent Builder
- Laravel Query Builder
- Illuminate Collection
- Database Connection
- HTTP Object
- Infrastructure固有Object

Repository ImplementationはInfrastructure Layerへ配置する。

---

## 20. RepositoryとRead処理の分離

Write側Repositoryへ一覧・検索・DashboardなどのRead用途の処理を詰め込まない。

例えば以下のようなMethodをAggregate Repositoryへ大量に追加することは避ける。

```php
searchEmployees(...);

findEmployeesBySkill(...);

getSkillDashboard(...);

getEmployeeSkillStatistics(...);
```

複雑なRead処理はCQRSのQuery Serviceへ分離する。

```text
Write
    ↓
Repository
    ↓
Aggregate

Read
    ↓
Query Service
    ↓
Read Model
```

これによりRepositoryをAggregateの永続化責務に集中させる。

---

## 21. Domain Exception

業務ルール違反を表現する必要がある場合はDomain Exceptionを利用する。

例:

```text
InvalidSkillLevelForNoExperience
ExperiencePeriodRequired
LastUsedMonthRequired
PermissionManagerRequired
```

Domain ExceptionはDomain上の問題だけを表現する。

以下の情報は持たせない。

- HTTP Status
- JSON Response
- API Error Response
- Laravel Response
- Redirect先

例えばDomain Exception自身が、

```text
409 Conflict
422 Unprocessable Entity
```

などを知る設計にはしない。

Domain ExceptionからHTTP ErrorへのMappingは外側のLayerで行う。

具体的なException設計は `10_Exception設計.md` で定義する。

---

## 22. Domain Layerで扱わないもの

Domain Layerへ以下を持ち込まない。

```text
Laravel Request
Laravel Response
Eloquent Model
Eloquent Relation
Eloquent Builder
Laravel Query Builder
DB Facade
Auth Facade
Cache Facade
Queue
Mail
Logger
HTTP Status
API Response形式
Migration
Framework Validation Rule
Service Container
```

これらはPresentation / Infrastructureなど適切な外側のLayerで扱う。

---

## 23. Framework非依存

Domain LayerではLaravel固有APIを利用しない。

例えば以下のDependencyをDomainへ持ち込まない。

```php
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
```

また、以下によるDependency Resolutionも行わない。

```php
app(...);
resolve(...);
```

Domain Objectが依存を必要とする場合は、その責務が本当にDomainへ属するかを確認したうえで、必要な抽象を明示的に利用する。

Domain Layerは可能な限りPure PHPとして実装できる状態を維持する。

---

## 24. Domain Layerのディレクトリ原則

Domain LayerはBounded Context単位で整理し、その配下をAggregate単位で構成する。

例:

```text
Domain/
└── SkillManagement/
    ├── EmployeeSkill/
    │   ├── EmployeeSkill.php
    │   ├── EmployeeSkillId.php
    │   ├── SkillLevel.php
    │   ├── WorkExperience.php
    │   ├── ExperiencePeriod.php
    │   ├── LastUsedMonth.php
    │   └── Exceptions/
    │
    ├── Skill/
    ├── SkillCategory/
    │
    ├── Repositories/
    └── Policies/
```

以下のような技術分類をDomain最上位へ置く構成は原則として採用しない。

```text
Domain/
├── Entities/
├── ValueObjects/
├── Enums/
└── Services/
```

Domain Objectの技術的な種類より、

> どの業務概念に属しているか

を優先して配置する。

---

## 25. Domain Layer設計原則

Domain Layer全体で以下の原則を維持する。

```text
業務概念・業務ルール
        ↓
Domainで表現する

状態変更
        ↓
意味のあるBehavior経由

整合性
        ↓
Aggregate単位で保証

Aggregate間
        ↓
IDで参照

業務上意味のある値
        ↓
Value Object

有限の状態・分類
        ↓
Domain Enum

単一Aggregateでは判断できないBusiness Rule
        ↓
Domain Policy

Domain Objectに自然に属さないDomain Logic
        ↓
必要な場合のみDomain Service

永続化
        ↓
Repository Interfaceまで

Framework / Database / HTTP
        ↓
Domainへ持ち込まない
```

Domain Layerでは、

> 不正な状態を可能な限り生成できず、正しい状態変更が業務上意味のある操作として表現されていること

を重視する。

LaravelやDatabaseなどの技術的詳細が変更されても、Domainの業務ルールそのものに影響しない構造を維持する。
