# Skill / SkillCategory Aggregate Root 設計 決定版

## 1. 位置付け

`Skill` と `SkillCategory` は以下のBounded Contextに属する。

    Skill Management Context

それぞれを独立したAggregate Rootとして扱う。

    SkillCategory Aggregate

    Skill Aggregate

Relation：

    Skill
      ↓
    SkillCategoryId
      ↓
    SkillCategory

SkillはSkillCategory Entityそのものを保持せず、
`SkillCategoryId`によって参照する。

---

# 2. Aggregate構成

Skill Management Context：

    SkillCategory
        ↑
        |
        | SkillCategoryId
        |
      Skill
        ↑
        |
        | SkillId
        |
    EmployeeSkill

それぞれ独立したAggregate Rootとする。

SkillCategoryに、

    Skills[]

を保持させない。

Skillにも、

    EmployeeSkills[]

を保持させない。

---

# 3. SkillCategory Aggregate Root

Aggregate Root：

    SkillCategory

Property：

    SkillCategory
    ├── SkillCategoryId
    ├── name
    └── isActive

---

# 4. SkillCategory Domain Type

## Value Object

    SkillCategoryId

## Primitive

    string name

    bool isActive

`SkillCategoryName`はMVPではValue Object化しない。

名称に強いDomain Ruleが発生した場合に再検討する。

---

# 5. SkillCategoryの責務

SkillCategory Aggregateは以下を担当する。

- Category名称の保持
- Category名称変更
- 有効化
- 無効化

Skill Collectionの管理は担当しない。

---

# 6. SkillCategory生成

新規登録にはNamed Constructorを利用する。

    SkillCategory::register()

概念：

    SkillCategory::register(
        id: $skillCategoryId,
        name: $name,
    );

生成時：

    isActive = true

とする。

---

# 7. SkillCategory Constructor

Constructor：

    private

とする。

外部から、

    new SkillCategory(...)

によって自由な状態を作らせない。

---

# 8. SkillCategory Reconstitution

Persistenceから復元する場合：

    SkillCategory::reconstitute()

を利用する。

Flow：

    EloquentSkillCategory
        ↓
    SkillCategoryMapper
        ↓
    SkillCategory::reconstitute()

新規登録とPersistenceからの復元を区別する。

---

# 9. SkillCategory名称変更

Domain Method：

    rename(string $name)

を利用する。

以下の汎用Setterは作らない。

    setName()

名称の、

- 必須
- 最大文字数
- Input Format

についてはPresentation LayerでもValidationする。

---

# 10. SkillCategory名称の一意性

以下をBusiness Ruleとする。

    SkillCategory.name
        ↓
    UNIQUE

ただしAggregate自身ではDatabase全体を確認できない。

そのためApplication Layerで、

    SkillCategoryRepository
        ->existsByName()

を利用する。

さらにDatabase：

    UNIQUE(name)

で最終保証する。

---

# 11. SkillCategory無効化

Domain Method：

    disable()

を利用する。

結果：

    isActive = false

完全削除は行わない。

---

# 12. SkillCategory再有効化

Domain Method：

    activate()

を利用する。

結果：

    isActive = true

---

# 13. SkillCategory完全削除

通常のApplication操作として完全削除しない。

利用停止：

    disable()

で表現する。

既存Skillから参照されている場合は、
Foreign Key RESTRICTによってDatabase上の削除も防ぐ。

---

# 14. Category無効化時のSkill

SkillCategoryを無効化しても、
配下のSkillを自動的に無効化しない。

つまり：

    SkillCategory.disable()

        ↓

    Skill.isActive

は変更しない。

---

# 15. 自動無効化しない理由

CategoryとSkillの状態を独立させる。

例えば：

    Programming Languages
        ↓
    disabled

になったとしても、

    PHP
    Go
    TypeScript

を自動的に、

    disabled

へ変更しない。

理由：

- 大量のAggregateを同時変更しない
- 意図しない連鎖更新を避ける
- Skill自身の状態を維持できる
- Category再編成が容易になる

---

# 16. SkillCategory Repository

Repository Interface：

    SkillCategoryRepository

Operation：

    findById()

    existsByName()

    save()

必要なUseCaseが発生した場合のみOperationを追加する。

---

# 17. Skill Aggregate Root

Aggregate Root：

    Skill

Property：

    Skill
    ├── SkillId
    ├── SkillCategoryId
    ├── name
    └── isActive

---

# 18. Skill Domain Type

## Value Object

    SkillId

    SkillCategoryId

## Primitive

    string name

    bool isActive

`SkillName`はMVPではValue Object化しない。

名称に強いDomain Ruleが追加された場合に再検討する。

---

# 19. Skillの責務

Skill Aggregateは以下を担当する。

- Skill名称
- SkillCategoryId
- Skill名称変更
- Category変更
- Skill有効化
- Skill無効化

EmployeeSkill Collectionは保持しない。

---

# 20. Skill生成

Named Constructor：

    Skill::register()

を利用する。

概念：

    Skill::register(
        id: $skillId,
        skillCategoryId: $skillCategoryId,
        name: $name,
    );

生成時：

    isActive = true

とする。

---

# 21. Skill Constructor

Constructor：

    private

とする。

外部から、

    new Skill(...)

による自由生成を許可しない。

---

# 22. Skill Reconstitution

Persistenceから復元する場合：

    Skill::reconstitute()

を利用する。

Flow：

    EloquentSkill
        ↓
    SkillMapper
        ↓
    Skill::reconstitute()

---

# 23. Skill登録時のCategory確認

Skill Aggregate自身は、

    SkillCategoryが存在するか

    SkillCategoryが有効か

を確認しない。

これはAggregateをまたぐRuleだからである。

Application Layerで確認する。

---

# 24. RegisterSkill UseCase

Flow：

    SkillCategory取得
        ↓
    Category存在確認
        ↓
    Category有効確認
        ↓
    Skill名称重複確認
        ↓
    Skill::register()
        ↓
    SkillRepository::save()
        ↓
    Commit

無効なSkillCategoryへの
新規Skill登録は禁止する。

---

# 25. Skill名称変更

Domain Method：

    rename(string $name)

を利用する。

以下は作成しない。

    setName()

---

# 26. Skill名称の一意性

MVPではSkill名称をApplication全体で一意とする。

Application Layer：

    SkillRepository
        ->existsByName()

Database：

    UNIQUE(name)

で保証する。

---

# 27. 名称表記揺れ

例えば：

    PostgreSQL

    Postgres

はDatabase上では異なる文字列なので、
単純なUNIQUE Constraintでは検出できない。

MVPでは自動Normalizationによる統合は行わない。

必要に応じて管理ユーザーによる
Skill統合機能で対応する。

---

# 28. Skill無効化

Domain Method：

    disable()

結果：

    isActive = false

Skillを完全削除しない。

---

# 29. 無効Skillの扱い

無効化されたSkillは、

    新規EmployeeSkill登録

には利用できない。

ただし既存：

    EmployeeSkill

とのRelationは保持する。

これにより過去の社員Skill情報を失わない。

---

# 30. Skill再有効化

Domain Method：

    activate()

結果：

    isActive = true

既存Skill Recordを再利用する。

---

# 31. Skill Category変更

SkillのCategory分類は変更可能とする。

Domain Method：

    moveToCategory(
        SkillCategoryId $skillCategoryId
    )

を利用する。

---

# 32. Category変更を許可する理由

SkillのIdentityは、

    SkillId

である。

SkillCategoryはSkillの分類情報として扱う。

したがって、

    Skill
      ↓
    別Category

への移動によってSkill自体のIdentityは変わらない。

Category再編成にも対応できる。

---

# 33. Category変更時のRule

Skill Aggregate自身は、
移動先Categoryの存在や有効状態を確認しない。

Application UseCaseで、

    Category存在

        AND

    Category.isActive = true

を確認する。

その後：

    skill->moveToCategory(
        $skillCategoryId
    )

を実行する。

---

# 34. MoveSkillCategory UseCase

Flow：

    Skill取得
        ↓
    移動先SkillCategory取得
        ↓
    Category有効確認
        ↓
    skill->moveToCategory()
        ↓
    SkillRepository::save()
        ↓
    Commit

---

# 35. Skill完全削除

通常運用では行わない。

利用停止：

    disable()

で表現する。

EmployeeSkillから参照されているSkillは、

    Foreign Key RESTRICT

によってDatabase上の削除も防ぐ。

---

# 36. Skill Repository

Repository Interface：

    SkillRepository

Operation：

    findById()

    existsByName()

    save()

必要なUseCaseが発生した場合のみ追加する。

---

# 37. EmployeeSkill登録時のRule

EmployeeSkillを新規登録する場合、

    Skill.isActive = true

だけではなく、

    SkillCategory.isActive = true

も必須とする。

つまり：

    Skill Active
        AND
    SkillCategory Active

の場合のみ新規EmployeeSkill登録可能。

---

# 38. Category無効時

例えば：

    Programming Languages
        ↓
    inactive

    PHP
        ↓
    active

という状態は存在できる。

ただしPHPを新しいEmployeeへ登録することはできない。

既存：

    EmployeeSkill(PHP)

は維持する。

---

# 39. EmployeeSkill登録Flow

    Employee取得
        ↓
    Skill取得
        ↓
    Skill Active確認
        ↓
    SkillCategory取得
        ↓
    SkillCategory Active確認
        ↓
    Employee + Skill重複確認
        ↓
    EmployeeSkill生成
        ↓
    save()

Cross Aggregate RuleはApplication Layerで調整する。

---

# 40. Skill統合

重複Skillを統合する機能は
単一Skill Aggregateの責務としない。

Application UseCase：

    MergeSkills

として実装する。

---

# 41. Skill統合例

例えば：

    Source Skill
        Postgres

    Target Skill
        PostgreSQL

を統合する場合：

    Source Skill取得
        ↓
    Target Skill取得
        ↓
    関連EmployeeSkill取得
        ↓
    EmployeeSkill Relation整理
        ↓
    Source Skill無効化
        ↓
    Commit

---

# 42. EmployeeSkill重複問題

同じEmployeeが、

    Postgres

と、

    PostgreSQL

の両方を持っている可能性がある。

統合すると：

    UNIQUE(
        employee_id,
        skill_id
    )

に衝突する。

そのため単純な、

    UPDATE employee_skills
    SET skill_id = target

では統合しない。

---

# 43. Skill統合Rule

以下について別途Domain Ruleが必要になる。

- ExperienceMonths
- SkillLevel
- WorkExperience
- LastUsedMonth
- Comment
- ExperienceDetails

例えば、

    どちらの経験月数を採用するか

などを決定する必要がある。

そのためSkill統合の詳細Ruleは
MergeSkills機能の詳細設計時に確定する。

---

# 44. Skill AggregateにmergeInto()を持たせない

以下のような単純Method：

    skill->mergeInto($targetSkill)

はMVPでは採用しない。

理由：

統合処理が、

- Source Skill
- Target Skill
- EmployeeSkill

という複数Aggregateにまたがるため。

Application UseCaseでTransactionを調整する。

---

# 45. Domain Exception

MVPでは以下を第一候補とする。

    InvalidSkillState

    InvalidSkillCategoryState

Exceptionを細かく分けすぎない。

---

# 46. Cross Aggregate Error

例えば：

    無効CategoryへのSkill登録

    無効SkillへのEmployeeSkill登録

    Skill名称重複

などは単一Aggregateだけでは判断できない。

Application Layerで検出する。

必要に応じてApplication Exceptionとして表現する。

---

# 47. SkillCategory Class概念

    final class SkillCategory
    {
        private function __construct(
            private readonly SkillCategoryId $id,
            private string $name,
            private bool $isActive,
        ) {
        }

        public static function register(...): self
        {
            // isActive = true
        }

        public static function reconstitute(...): self
        {
            // restore
        }

        public function rename(
            string $name
        ): void {
            // rename
        }

        public function disable(): void
        {
            $this->isActive = false;
        }

        public function activate(): void
        {
            $this->isActive = true;
        }

        public function isActive(): bool
        {
            return $this->isActive;
        }
    }

---

# 48. Skill Class概念

    final class Skill
    {
        private function __construct(
            private readonly SkillId $id,
            private SkillCategoryId $skillCategoryId,
            private string $name,
            private bool $isActive,
        ) {
        }

        public static function register(...): self
        {
            // isActive = true
        }

        public static function reconstitute(...): self
        {
            // restore
        }

        public function rename(
            string $name
        ): void {
            // rename
        }

        public function moveToCategory(
            SkillCategoryId $skillCategoryId
        ): void {
            $this->skillCategoryId =
                $skillCategoryId;
        }

        public function disable(): void
        {
            $this->isActive = false;
        }

        public function activate(): void
        {
            $this->isActive = true;
        }

        public function isActive(): bool
        {
            return $this->isActive;
        }
    }

---

# 49. Transaction Boundary

基本：

    1 UseCase = 1 Transaction

とする。

Transaction管理はApplication Layerで行う。

Skill / SkillCategory Aggregate自身は
Transactionを意識しない。

---

# 50. Mapper

Eloquent ModelとDomain Aggregateを分離する。

SkillCategory：

    EloquentSkillCategory
        ↓
    SkillCategoryMapper
        ↓
    SkillCategory

Skill：

    EloquentSkill
        ↓
    SkillMapper
        ↓
    Skill

逆方向もMapperで変換する。

---

# 51. Database Constraint

Domain / ApplicationでRuleを保証していても、
PostgreSQL Constraintを維持する。

## skill_categories

    PRIMARY KEY(id)

    UNIQUE(name)

## skills

    PRIMARY KEY(id)

    UNIQUE(name)

    FOREIGN KEY(skill_category_id)
        REFERENCES skill_categories(id)
        ON DELETE RESTRICT

Application Layerで事前確認し、
Databaseを最終防衛線とする。

---

# 52. Unit Test

## SkillCategory Aggregate

確認：

- registerするとactiveになる
- renameできる
- disableできる
- activateできる
- reconstituteできる

## Skill Aggregate

確認：

- registerするとactiveになる
- renameできる
- Categoryを変更できる
- disableできる
- activateできる
- reconstituteできる

---

# 53. Application Test

Cross Aggregate RuleはUseCase Testで確認する。

確認：

- 無効CategoryにはSkillを登録できない
- 重複Skill名を登録できない
- 重複SkillCategory名を登録できない
- 無効SkillをEmployeeSkillへ登録できない
- 無効Category配下のSkillをEmployeeSkillへ登録できない
- 有効CategoryへSkillを移動できる
- 無効CategoryへSkillを移動できない

---

# 54. SkillCategory 決定事項

## Aggregate Root

`SkillCategory`

## Bounded Context

Skill Management

## Constructor

`private`

## 新規生成

`register()`

## Persistenceからの復元

`reconstitute()`

## 名称変更

`rename()`

## 無効化

`disable()`

## 再有効化

`activate()`

## Skill Collection

保持しない。

## 完全削除

通常運用では行わない。

## Repository

`SkillCategoryRepository`

---

# 55. Skill 決定事項

## Aggregate Root

`Skill`

## Bounded Context

Skill Management

## Constructor

`private`

## 新規生成

`register()`

## Persistenceからの復元

`reconstitute()`

## 名称変更

`rename()`

## Category変更

`moveToCategory()`

## 無効化

`disable()`

## 再有効化

`activate()`

## EmployeeSkill Collection

保持しない。

## 完全削除

通常運用では行わない。

## Repository

`SkillRepository`

---

# 56. Cross Aggregate Rule 決定事項

Application Layerで以下を保証する。

### Skill登録

    SkillCategory.isActive = true

が必要。

### EmployeeSkill登録

    Skill.isActive = true

        AND

    SkillCategory.isActive = true

が必要。

### Category変更

移動先：

    SkillCategory.isActive = true

が必要。

### 名称重複

Repositoryで事前確認し、
Database UNIQUE Constraintでも保証する。

---

# 57. SkillCategory無効化 決定事項

SkillCategoryを無効化しても、
配下Skillを自動無効化しない。

    SkillCategory
        ↓
    inactive

    Skill
        ↓
    状態維持

ただし無効Category配下のSkillは、
新規EmployeeSkill登録には利用できない。

---

# 58. Skill統合 決定事項

重複Skill統合は、

    MergeSkills UseCase

としてApplication Layerで扱う。

Skill Aggregate単体の操作とはしない。

EmployeeSkillの重複解決Ruleについては、
MergeSkills機能の詳細設計時に決定する。

---

# 59. 最終構成

    Skill Management Context
    │
    ├── SkillCategory Aggregate
    │   ├── SkillCategoryId
    │   ├── name
    │   ├── isActive
    │   │
    │   ├── register()
    │   ├── reconstitute()
    │   ├── rename()
    │   ├── disable()
    │   └── activate()
    │
    ├── Skill Aggregate
    │   ├── SkillId
    │   ├── SkillCategoryId
    │   ├── name
    │   ├── isActive
    │   │
    │   ├── register()
    │   ├── reconstitute()
    │   ├── rename()
    │   ├── moveToCategory()
    │   ├── disable()
    │   └── activate()
    │
    └── EmployeeSkill Aggregate
        ├── EmployeeSkillId
        ├── EmployeeId
        ├── SkillId
        ├── WorkExperience
        ├── ExperienceMonths
        ├── SkillLevel
        └── LastUsedMonth

Aggregate間はEntity Objectではなく
Value Object化されたIDで参照する。

---

# 60. 最終決定

Skill Management Contextでは、

    SkillCategory
    Skill
    EmployeeSkill

をそれぞれ独立Aggregate Rootとする。

Aggregateは小さく保ち、
Aggregate間の整合性はApplication UseCaseで調整する。

PersistenceにはEloquentを使用するが、
Domain Aggregateとは分離する。

Repository InterfaceをDomain側に配置し、
Infrastructure側でEloquent実装を提供する。

これにより、

- DDD Aggregate
- Value Object
- Repository Pattern
- Dependency Inversion
- Application UseCase
- Cross Aggregate Rule
- Persistence / Domain分離

を実際のApplication設計に取り入れる。
