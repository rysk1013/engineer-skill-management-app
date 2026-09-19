# Value Object 設計

## 1. 基本方針

Value Objectは、単なる型のラッパーではなく、

- 業務上の意味を持つ
- 不変である
- 自身で整合性を保証できる
- 同値性を値で判断する

ものに対して利用する。

すべてのstring / int / boolをValue Object化しない。

---

# 2. 採用候補

MVPでは以下をValue Object候補とする。

## Employee Management

- EmployeeId
- EmployeeNumber
- DepartmentId
- EmploymentStatus
- RetirementDate

## Skill Management

- SkillId
- SkillCategoryId
- EmployeeSkillId
- ExperienceMonths
- SkillLevel
- LastUsedMonth

## Access Control

- UserId
- LoginId

---

# 3. ID系Value Object

Aggregate間参照ではPrimitiveなbigintを直接使わず、
ID Value Objectを利用する。

例：

    EmployeeId
    SkillId
    UserId

### 目的

以下のような取り違えを防ぐ。

    EmployeeId $employeeId
    SkillId $skillId

Primitiveだけの場合：

    int $employeeId
    int $skillId

だと、引数を逆に渡しても型として検出できない。

---

# 4. EmployeeId

例：

    final readonly class EmployeeId
    {
        public function __construct(
            public int $value
        ) {
            if ($value <= 0) {
                throw new InvalidArgumentException();
            }
        }
    }

主なルール：

- 1以上
- 不変
- Employee識別子としてのみ利用

---

# 5. EmployeeNumber

社員番号をValue Object化する。

理由：

社員番号はDatabase IDとは異なる
業務上の識別子だから。

候補Rule：

- 空文字禁止
- 最大長
- 許可文字
- Normalization

具体的なFormatは要件が決まった段階で追加する。

例：

    EmployeeNumber::fromString('EMP0001')

---

# 6. EmploymentStatus

固定値なのでPHP Enumを利用する。

候補：

    enum EmploymentStatus: string
    {
        case Active = 'ACTIVE';
        case Leave = 'LEAVE';
        case Retired = 'RETIRED';
    }

Value Object Classを別途作らず、
EnumをDomain Valueとして利用する。

---

# 7. RetirementDate

退職日には業務上の意味があるため
Value Object化を候補とする。

例：

    RetirementDate

責務：

- 日付としての妥当性
- DateOnlyで扱う
- 時刻を持たない

ただし、

    retirement_date <= today

のような現在日時依存Ruleは
Value Objectへ直接埋め込みすぎない。

Clock依存を避けるため、
Application / Domain Service側で扱う。

---

# 8. ExperienceMonths

EmployeeSkillで重要なValue Object。

内部表現：

    months

例：

    ExperienceMonths(42)

意味：

    3年6か月

### Rule

    months >= 0

### Method候補

    months()

    years()

    remainingMonths()

    isExperienced()

例：

    42
      ↓
    years() = 3
    remainingMonths() = 6

---

# 9. ExperienceMonths生成

UIでは、

    年
    月

を入力する。

Domainでは、

    ExperienceMonths

へ変換する。

例：

    ExperienceMonths::fromYearsAndMonths(
        years: 3,
        months: 6
    )

内部：

    42

これによりDomain内部では年・月の2値を持たない。

---

# 10. SkillLevel

Skill LevelはEnumを第一候補とする。

    enum SkillLevel: int
    {
        case Level1 = 1;
        case Level2 = 2;
        case Level3 = 3;
        case Level4 = 4;
        case Level5 = 5;
    }

Domain上では裸のintを利用しない。

---

# 11. LastUsedMonth

Databaseでは、

    last_used_date

として、

    YYYY-MM-01

を保存する。

しかしDomainでは、

    LastUsedMonth

として「年月」を直接表現する。

例：

    2026-08

Domain内部で、

    2026-08-01

という擬似的な日付を意識しない。

---

# 12. LastUsedMonthの責務

候補：

- Year
- Month
- 年月形式の妥当性
- 比較

例：

    LastUsedMonth::fromYearAndMonth(
        2026,
        8
    )

Method候補：

    year()

    month()

    isBefore()

    isAfter()

MapperでDatabaseへ保存するときのみ、

    2026-08
       ↓
    2026-08-01

へ変換する。

---

# 13. EmployeeSkillのDomain表現

Value Objectを利用すると、

    EmployeeSkill
    ├── EmployeeSkillId
    ├── EmployeeId
    ├── SkillId
    ├── WorkExperience
    ├── ExperienceMonths
    ├── SkillLevel
    └── LastUsedMonth?

のようになる。

Primitive：

    int
    int
    bool
    int
    int
    DateTime

をそのまま並べるより意味が明確になる。

---

# 14. has_work_experience

booleanをそのまま使う案：

    bool $hasWorkExperience

も可能。

ただし今回のDomain Ruleでは意味が重要なので、

    WorkExperience

Enum / Value Object化も候補とする。

例：

    enum WorkExperience: string
    {
        case Experienced = 'EXPERIENCED';
        case Unexperienced = 'UNEXPERIENCED';
    }

---

# 15. WorkExperienceを導入するメリット

以下より、

    true
    false

以下の方がDomain上明確になる。

    WorkExperience::Experienced
    WorkExperience::Unexperienced

条件：

    if ($workExperience->hasExperience())

のような表現も可能。

---

# 16. 推奨

学習目的を考慮して、

**has_work_experienceもDomainではEnum化する。**

ただしDatabaseでは引き続きbooleanで保持してよい。

つまり：

    Database
    boolean

    Domain
    WorkExperience Enum

Mapperで変換する。

これによりPersistence ModelとDomain Modelの違いも学べる。

---

# 17. LoginId

UserのLogin IDをValue Object化する。

候補Rule：

- 空文字禁止
- 最大長
- Normalization

ただしFormat要件が単純な場合は
無理に複雑なRuleを持たせない。

---

# 18. SkillName / DepartmentName

候補ではあるが、
MVPでは一旦Value Object化しないことを推奨する。

理由：

現時点では、

- 必須
- 最大長

程度しかRuleがない可能性が高い。

単なるstring wrapperになりやすい。

将来、

- 正規化
- 重複判定
- Naming Rule

などが増えた段階でValue Object化できる。

---

# 19. Comment

Value Object化しない。

    string|null

で十分。

同様に：

    experience_details

もMVPではValue Object化しない。

---

# 20. is_active

Domainでは単純boolでもよい。

ただしEntityに、

    disable()
    activate()

等のBehaviorを持たせ、

    $entity->isActive = false

のような直接変更は避ける。

---

# 21. Value Object候補まとめ

## 積極的に採用

- EmployeeId
- EmployeeNumber
- DepartmentId
- SkillCategoryId
- SkillId
- EmployeeSkillId
- UserId
- LoginId
- ExperienceMonths
- LastUsedMonth

## Enumとして採用

- EmploymentStatus
- SkillLevel
- WorkExperience

## 候補

- RetirementDate

## MVPでは採用しない

- EmployeeName
- DepartmentName
- SkillName
- Comment
- ExperienceDetails
- IsActive

---

# 22. Value Objectの不変性

Value ObjectはImmutableとする。

PHPでは、

    final readonly class

を第一候補とする。

Valueを変更するSetterを持たない。

変更が必要な場合は新しいValue Objectを作成する。

---

# 23. Equality

Value ObjectはIdentityではなくValueで比較する。

例：

    EmployeeId(10)
    ==
    EmployeeId(10)

同じ値なら同一とみなす。

必要に応じて、

    equals()

を実装する。

---

# 24. Domain Ruleの置き場所

Value Objectは自身だけで完結するRuleを持つ。

例：

    ExperienceMonths
    → 0以上

    SkillLevel
    → 1〜5

Aggregate間や複数Valueの関係Ruleは
Aggregate Root側で保証する。

例：

    WorkExperience = Unexperienced
        +
    SkillLevel = Level1

というRuleは、

    EmployeeSkill Aggregate

で保証する。

---

# 25. Value Objectに置かないRule

例えば：

    同じEmployeeに同じSkillを登録できない

はValue Objectの責務ではない。

これは、

- Application
- Repository
- Database Constraint

で保証する。

---

# 26. Mapper

Persistence ModelとDomain Modelの変換時に
Value Objectを生成する。

例：

    EloquentEmployeeSkill
        ↓
    Mapper
        ↓
    EmployeeSkill(
        EmployeeSkillId,
        EmployeeId,
        SkillId,
        WorkExperience,
        ExperienceMonths,
        SkillLevel,
        LastUsedMonth
    )

保存時は逆変換する。

---

# 27. OpenAPIとの関係

APIではPrimitiveとして表現する。

例：

    experienceMonths: 42

    skillLevel: 3

    lastUsedMonth: "2026-08"

Domain：

    ExperienceMonths
    SkillLevel
    LastUsedMonth

Presentation Layerで変換する。

OpenAPI SchemaとDomain型を同一視しない。

---

# 28. Test

Value ObjectはUnit Test対象とする。

例：

### ExperienceMonths

- 0を作成できる
- 42を作成できる
- 負数を拒否する
- 3年6か月 → 42か月

### LastUsedMonth

- 2026-08を作成できる
- Month 13を拒否する

### EmployeeNumber

- 空文字を拒否する

---

# 29. 過度なValue Object化を避ける

以下のような設計にはしない。

    EmployeeName
    SkillName
    DepartmentName
    Comment
    ExperienceDetails
    IsActive

まで全部Class化する。

学習目的でも、
意味のないWrapper Classを増やさない。

---

# 30. 決定候補

## ID

Value Object化する。

## EmployeeNumber

Value Object化する。

## LoginId

Value Object化する。

## ExperienceMonths

Value Object化する。

## LastUsedMonth

Value Object化する。

## SkillLevel

PHP Enum。

## EmploymentStatus

PHP Enum。

## WorkExperience

DomainではPHP Enum。

Databaseではboolean。

## RetirementDate

Value Objectを第一候補とする。

## 単純名称・Comment

Primitiveを使用する。

---

# 31. 推奨決定

MVPではValue Objectを積極的に利用するが、
Business Ruleや意味を持つ値に限定する。

特にCore DomainであるSkill Managementでは、

- EmployeeId
- SkillId
- EmployeeSkillId
- ExperienceMonths
- SkillLevel
- WorkExperience
- LastUsedMonth

を明確なDomain Typeとして扱う。
