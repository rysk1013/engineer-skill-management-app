# EmployeeSkill Aggregate Root 設計 決定版

## 1. 位置付け

`EmployeeSkill` は、社員が保有するスキル情報を表すAggregate Rootとする。

単なるEmployeeとSkillの中間Recordではなく、
以下の業務ルールを自身で保証するDomain Modelとして扱う。

- 実務経験あり / なし
- 経験月数
- Skill Level
- 最終利用年月
- コメント
- 実績・経験内容
- 有効 / 無効

`EmployeeSkill` はSkill Management Contextに属する。

---

## 2. Aggregate Root

Aggregate Root：

    EmployeeSkill

識別子：

    EmployeeSkillId

他Aggregateへの参照：

    EmployeeId
    SkillId

EmployeeやSkillのDomain Entityそのものは保持せず、
IDで参照する。

---

## 3. Property

`EmployeeSkill` は以下を保持する。

    EmployeeSkill
    ├── EmployeeSkillId
    ├── EmployeeId
    ├── SkillId
    ├── WorkExperience
    ├── ExperienceMonths
    ├── SkillLevel
    ├── LastUsedMonth?
    ├── comment?
    ├── experienceDetails?
    └── isActive

---

## 4. 使用するDomain Type

### Value Object

- EmployeeSkillId
- EmployeeId
- SkillId
- ExperienceMonths
- LastUsedMonth

### Enum

- WorkExperience
- SkillLevel

### Primitive

- comment
- experienceDetails
- isActive

---

## 5. WorkExperience

DomainではbooleanではなくEnumを使用する。

概念：

    enum WorkExperience
    {
        case Experienced;
        case Unexperienced;
    }

Databaseではbooleanへ変換する。

    Experienced
        ↓
    true

    Unexperienced
        ↓
    false

Database表現とDomain表現を分離する。

---

## 6. SkillLevel

DomainではPHP Enumを使用する。

概念：

    enum SkillLevel: int
    {
        case Level1 = 1;
        case Level2 = 2;
        case Level3 = 3;
        case Level4 = 4;
        case Level5 = 5;
    }

Domain内部では裸のintegerを直接扱わない。

---

## 7. ExperienceMonths

経験期間を月数として表すValue Objectとする。

内部表現：

    months

例：

    ExperienceMonths(42)

意味：

    3年6か月

最低限の不変条件：

    months >= 0

---

## 8. LastUsedMonth

最後に実務で利用した年月を表すValue Objectとする。

例：

    LastUsedMonth(2026, 8)

Domain上では、

    2026-08

という年月を表現する。

Database保存時のみ、

    2026-08-01

へ変換する。

Domain Modelでは「1日」という擬似的な日付を意識しない。

---

## 9. Aggregateの不変条件

EmployeeSkillは常に以下の状態を満たす。

### 実務経験なし

    WorkExperience::Unexperienced

の場合：

    ExperienceMonths = 0

    SkillLevel = Level1

    LastUsedMonth = null

---

### 実務経験あり

    WorkExperience::Experienced

の場合：

    ExperienceMonths >= 1

    SkillLevel = Level1〜Level5

    LastUsedMonth != null

---

## 10. 存在してはいけない状態

以下の状態をDomain上で作成できないようにする。

### NG

    WorkExperience::Unexperienced
    +
    SkillLevel::Level3

### NG

    WorkExperience::Unexperienced
    +
    ExperienceMonths(12)

### NG

    WorkExperience::Experienced
    +
    ExperienceMonths(0)

### NG

    WorkExperience::Experienced
    +
    LastUsedMonth = null

Aggregate自身がこれらを拒否する。

---

## 11. Constructor

Constructorから自由に全Propertyを設定できる構成にはしない。

Constructor：

    private

を第一候補とする。

外部から、

    new EmployeeSkill(...)

を直接実行させない。

EmployeeSkillの生成はNamed Constructor経由とする。

---

## 12. 実務経験ありの新規作成

Named Constructor：

    EmployeeSkill::experienced(...)

を使用する。

概念：

    EmployeeSkill::experienced(
        id: $employeeSkillId,
        employeeId: $employeeId,
        skillId: $skillId,
        experienceMonths: $experienceMonths,
        skillLevel: $skillLevel,
        lastUsedMonth: $lastUsedMonth,
        comment: $comment,
        experienceDetails: $experienceDetails,
    );

内部的に、

    WorkExperience::Experienced

を設定する。

生成時に以下を検証する。

- experienceMonths >= 1
- SkillLevelがLevel1〜Level5
- LastUsedMonth必須

---

## 13. 実務経験なしの新規作成

Named Constructor：

    EmployeeSkill::unexperienced(...)

を使用する。

概念：

    EmployeeSkill::unexperienced(
        id: $employeeSkillId,
        employeeId: $employeeId,
        skillId: $skillId,
        comment: $comment,
        experienceDetails: $experienceDetails,
    );

内部では自動的に以下を設定する。

    WorkExperience::Unexperienced

    ExperienceMonths = 0

    SkillLevel = Level1

    LastUsedMonth = null

Callerへこれらを自由入力させない。

---

## 14. Named Constructorを採用する理由

以下のようなAPIより、

    EmployeeSkill::create(
        hasWorkExperience: false,
        experienceMonths: 0,
        skillLevel: 1,
        lastUsedMonth: null
    )

以下の方を優先する。

    EmployeeSkill::unexperienced(...)

Domain APIそのものを業務用語として表現できるため。

---

## 15. Reconstitution

Databaseから既存Aggregateを復元するために、

    EmployeeSkill::reconstitute(...)

を用意する。

用途：

    Eloquent Model
        ↓
    Mapper
        ↓
    EmployeeSkill::reconstitute(...)

新規作成とDatabase復元を明確に分離する。

---

## 16. Reconstitution時のValidation

`reconstitute()`でもDomain上存在できない状態は許可しない。

Database上に不正な状態が存在する場合は、
Domain Exceptionを発生させる。

これにより、

    DB Constraint
        +
    Domain Invariant

の両方でデータ整合性を確認する。

---

## 17. Property Setter

汎用Setterは作成しない。

以下のような設計は避ける。

    setSkillLevel()

    setExperienceMonths()

    setWorkExperience()

    setLastUsedMonth()

Property変更は業務操作を表すDomain Method経由で行う。

---

## 18. 実務経験情報の更新

実務経験ありの状態を更新する場合は、

    updateExperience()

等のDomain Methodを利用する。

概念：

    $employeeSkill->updateExperience(
        experienceMonths: $experienceMonths,
        skillLevel: $skillLevel,
        lastUsedMonth: $lastUsedMonth,
    );

このMethod内部で以下を保証する。

    ExperienceMonths >= 1

    SkillLevel = Level1〜Level5

    LastUsedMonth != null

---

## 19. 実務未経験への変更

Domain Method：

    markAsUnexperienced()

を用意する。

実行後：

    WorkExperience = Unexperienced

    ExperienceMonths = 0

    SkillLevel = Level1

    LastUsedMonth = null

となる。

Caller側で4Propertyを個別に変更しない。

---

## 20. 実務経験ありへの変更

Domain Method：

    markAsExperienced(
        ExperienceMonths $experienceMonths,
        SkillLevel $skillLevel,
        LastUsedMonth $lastUsedMonth,
    )

を用意する。

このMethod内部で業務ルールを検証する。

---

## 21. コメント変更

コメント変更は、

    changeComment(?string $comment)

を利用する。

MVPではコメントをValue Object化しない。

長さ等のInput ValidationはPresentation Layerで行う。

Domain固有Ruleが発生した場合は
Value Object化を再検討する。

---

## 22. 実績・経験内容変更

Domain Method：

    changeExperienceDetails(
        ?string $experienceDetails
    )

を利用する。

MVPではPrimitive Stringとして扱う。

---

## 23. 無効化

社員に登録済みのSkillを不要にした場合、
完全削除せず無効化する。

Domain Method：

    disable()

結果：

    isActive = false

---

## 24. 再有効化

無効化済みEmployeeSkillを再利用する場合：

    activate()

結果：

    isActive = true

同じEmployee + Skillについて新しいRecordを作成しない。

Databaseの、

    UNIQUE(employee_id, skill_id)

と整合する。

---

## 25. Skill変更

生成済みEmployeeSkillの`SkillId`は変更不可とする。

以下のMethodは作成しない。

    changeSkill()

例えば、

    PHP
        ↓
    Laravel

へ変更する操作は行わない。

必要な場合：

    PHP EmployeeSkillを無効化

        +

    Laravel EmployeeSkillを登録

とする。

---

## 26. Employee変更

生成済みEmployeeSkillの`EmployeeId`も変更不可とする。

EmployeeSkillを別Employeeへ付け替える操作は許可しない。

---

## 27. Immutable Identity

以下は生成後変更不可。

- EmployeeSkillId
- EmployeeId
- SkillId

EmployeeSkillのIdentity / Relationを構成する値として扱う。

---

## 28. 変更可能な状態

Domain Method経由で以下を変更可能とする。

- WorkExperience
- ExperienceMonths
- SkillLevel
- LastUsedMonth
- Comment
- ExperienceDetails
- IsActive

直接Propertyを書き換えない。

---

## 29. Domain Exception

Aggregateの不変条件に違反した場合はDomain Exceptionを発生させる。

MVP第一候補：

    InvalidEmployeeSkillState

例：

    throw new InvalidEmployeeSkillState(
        'Experienced skill requires at least one month of experience.'
    );

最初からException Classを細かく増やしすぎない。

必要性が出た場合に細分化する。

---

## 30. Domain Exception候補

将来的に必要なら以下へ分離できる。

- InvalidEmployeeSkillExperience
- InvalidSkillLevel
- LastUsedMonthRequired
- InvalidEmployeeSkillStatus

MVPでは過度に分割しない。

---

## 31. Aggregate内部Validation

各Named Constructor / Domain Methodで
必要な業務ルールを保証する。

必要に応じて内部共通Method：

    assertValidExperiencedState()

    assertValidState()

等を利用する。

ただしValidation Methodを大量に作り、
業務操作が読みにくくならないようにする。

---

## 32. Behavior Rich Model

EmployeeSkillを単なるData Bagにはしない。

避ける構造：

    EmployeeSkill
    ├── getter
    ├── setter
    ├── getter
    └── setter

第一候補：

    EmployeeSkill
    ├── experienced()
    ├── unexperienced()
    ├── reconstitute()
    ├── updateExperience()
    ├── markAsExperienced()
    ├── markAsUnexperienced()
    ├── changeComment()
    ├── changeExperienceDetails()
    ├── disable()
    └── activate()

Domain上の操作をMethod名として表現する。

---

## 33. Repository

EmployeeSkillは独立Aggregate Rootなので、
専用Repository Interfaceを持つ。

候補：

    EmployeeSkillRepository

主なOperation：

    findById()

    existsByEmployeeAndSkill()

    save()

必要な場合のみ追加する。

Repositoryへ以下のような部分更新Methodを大量に作らない。

    updateSkillLevel()

    updateExperienceMonths()

    updateLastUsedMonth()

基本：

    Aggregate取得
        ↓
    Domain Method
        ↓
    save()

とする。

---

## 34. 重複Skill確認

同一Employee + Skillの重複登録は禁止する。

Application Layer：

    existsByEmployeeAndSkill(
        EmployeeId,
        SkillId
    )

で事前確認する。

Database：

    UNIQUE(
        employee_id,
        skill_id
    )

で最終保証する。

---

## 35. RegisterEmployeeSkill UseCase

登録Flow：

    Employee存在確認
        ↓
    Skill存在確認
        ↓
    Skillが有効か確認
        ↓
    Employee + Skill重複確認
        ↓
    EmployeeSkill::experienced()
        または
    EmployeeSkill::unexperienced()
        ↓
    Repository save
        ↓
    Commit

---

## 36. UpdateEmployeeSkill UseCase

更新Flow：

    EmployeeSkill取得
        ↓
    Domain Method実行
        ↓
    Repository save
        ↓
    Commit

Application LayerからPropertyを直接変更しない。

---

## 37. Transaction Boundary

基本：

    1 UseCase = 1 Transaction

とする。

Transaction管理はApplication Layerの責務。

EmployeeSkill自身はTransactionを意識しない。

---

## 38. Database Constraint

Domainで業務ルールを保証していても、
PostgreSQL CHECK Constraintを残す。

保証：

### Domain

Application経由で不正状態を作らせない。

### Database

Domainを経由しない不正データも拒否する。

二重防御とする。

---

## 39. Form Requestとの責務分離

### Form Request

Inputとして成立するか確認する。

例：

- required
- integer
- boolean
- string
- YYYY-MM形式
- 最大文字数

### Domain

Businessとして成立するか確認する。

例：

    実務経験なし
        +
    Level3

を拒否する。

Presentation ValidationとDomain Invariantを分離する。

---

## 40. Mapper

Eloquent ModelとDomain Aggregateを分離する。

取得：

    EloquentEmployeeSkill
        ↓
    EmployeeSkillMapper
        ↓
    EmployeeSkill

保存：

    EmployeeSkill
        ↓
    EmployeeSkillMapper
        ↓
    EloquentEmployeeSkill

MapperでPersistence表現とDomain表現を変換する。

---

## 41. Persistence変換例

### has_work_experience

Database：

    boolean

Domain：

    WorkExperience

---

### skill_level

Database：

    smallint

Domain：

    SkillLevel

---

### last_used_date

Database：

    YYYY-MM-01

Domain：

    LastUsedMonth

Mapperがこれらの変換を担当する。

---

## 42. APIとの関係

OpenAPIではPrimitiveとして表現する。

例：

    {
      "hasWorkExperience": true,
      "experienceMonths": 42,
      "skillLevel": 3,
      "lastUsedMonth": "2026-08"
    }

Presentation / Application Layerで、

    Primitive
        ↓
    Domain Type

へ変換する。

OpenAPI SchemaをDomain Modelとして直接利用しない。

---

## 43. Unit Test

EmployeeSkill Aggregateは重点的なUnit Test対象とする。

### Creation

- 実務経験ありで生成できる
- 実務経験なしで生成できる

### Invalid Creation

- 経験0か月の実務経験ありを拒否する
- LastUsedMonthなしの実務経験ありを拒否する
- 実務未経験でLevel2〜5の状態を作れない

### State Change

- 実務経験ありへ変更できる
- 実務未経験へ変更できる
- 実務未経験へ変更すると0か月 / Level1 / LastUsedMonth nullになる
- Commentを変更できる
- ExperienceDetailsを変更できる
- disableできる
- activateできる

---

## 44. EmployeeSkill Class 概念

    final class EmployeeSkill
    {
        private function __construct(
            private readonly EmployeeSkillId $id,
            private readonly EmployeeId $employeeId,
            private readonly SkillId $skillId,
            private WorkExperience $workExperience,
            private ExperienceMonths $experienceMonths,
            private SkillLevel $skillLevel,
            private ?LastUsedMonth $lastUsedMonth,
            private ?string $comment,
            private ?string $experienceDetails,
            private bool $isActive,
        ) {
        }

        public static function experienced(...): self
        {
            // Business Rule
        }

        public static function unexperienced(...): self
        {
            // Business Rule
        }

        public static function reconstitute(...): self
        {
            // Persistenceから復元
        }

        public function updateExperience(...): void
        {
            // Business Rule
        }

        public function markAsExperienced(...): void
        {
            // Business Rule
        }

        public function markAsUnexperienced(): void
        {
            // 0 months / Level1 / null
        }

        public function changeComment(?string $comment): void
        {
            // change
        }

        public function changeExperienceDetails(
            ?string $experienceDetails
        ): void {
            // change
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

## 45. 決定事項

### Aggregate Root

`EmployeeSkill`

### Bounded Context

Skill Management

### Constructor

`private`

### 新規生成

Named Constructorを利用する。

- `experienced()`
- `unexperienced()`

### Persistenceからの復元

`reconstitute()`

### Identity

以下は生成後変更不可。

- EmployeeSkillId
- EmployeeId
- SkillId

### 状態変更

Domain Method経由で行う。

### Generic Setter

使用しない。

### Skill変更

不可。

### Employee変更

不可。

### 無効化

`disable()`

### 再有効化

`activate()`

### Domain Exception

不正状態はDomain Exceptionで拒否する。

MVPでは`InvalidEmployeeSkillState`を第一候補とする。

### Repository

Aggregate Root単位で`EmployeeSkillRepository`を持つ。

### Transaction

Application UseCaseで管理する。

### Persistence

Eloquent Modelとは分離し、
Mapper経由で変換する。

### Database Constraint

Domain Ruleと併用して維持する。

### Test

EmployeeSkill AggregateのUnit Testを重点的に作成する。
