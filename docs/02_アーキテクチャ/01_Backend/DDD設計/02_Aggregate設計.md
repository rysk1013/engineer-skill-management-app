# Aggregate 設計

## 1. 基本方針

Aggregateは、

「常に整合性を保って更新したい単位」

として設計する。

単にTable Relationに合わせて決めない。

---

# 2. 候補

## 案A：Employee Aggregateの内部にEmployeeSkillを含める

構造：

    Employee
      └── EmployeeSkill

EmployeeがAggregate Root。

Skill登録・更新はEmployeeを経由して行う。

### メリット

- 社員単位でSkill整合性を管理しやすい
- 「同じ社員に同じSkillを重複登録しない」ルールをEmployee側で表現しやすい
- EmployeeSkillを外部から直接変更させない設計にできる

### デメリット

- Employeeが大量のEmployeeSkillを持つ可能性がある
- Skill1件更新でもEmployee全体を扱う設計になりやすい
- 検索・更新時の負荷が増える可能性がある
- Aggregateが肥大化しやすい

---

## 案B：EmployeeSkillを独立Aggregate Rootにする

構造：

    Employee Aggregate

    Skill Aggregate

    EmployeeSkill Aggregate

EmployeeSkillは、

    EmployeeId
    SkillId
    ExperienceMonths
    SkillLevel
    LastUsedMonth

などを保持する。

### メリット

- Skill登録・更新のTransaction境界が小さい
- EmployeeSkill単位でRepositoryを持てる
- 大量Skillを持つEmployeeでも扱いやすい
- 今回の業務ルールをEmployeeSkill自身に閉じ込めやすい
- APIの更新単位とも合いやすい

### デメリット

- 「Employee + Skill重複禁止」をRepository / Database Constraintと協調して保証する必要がある
- Employeeが存在するか等をUseCase側で確認する必要がある
- Aggregate間整合性を意識する必要がある

---

# 3. 比較

| 観点 | Employee内部 | EmployeeSkill独立 |
| --- | --- | --- |
| Aggregateの小ささ | △ | ◎ |
| Skill単位更新 | △ | ◎ |
| 業務ルール表現 | ◎ | ◎ |
| 大量Skill対応 | △ | ◎ |
| Repository単純性 | ○ | ◎ |
| Aggregate間整合性 | ◎ | ○ |
| 今回のAPIとの相性 | ○ | ◎ |
| 学習価値 | ◎ | ◎ |

---

# 4. 今回の推奨

**EmployeeSkillを独立Aggregate Rootとする。**

理由：

- EmployeeSkill自体が重要な業務概念である
- Skill登録・編集が独立したUser Storyになっている
- 経験年数・Level・最終利用年月など強い業務ルールを持つ
- Employee全体を読み込まずに更新したい
- Aggregateを小さく保てる
- Repository / Transaction Boundaryが明確になる

---

# 5. Employee Aggregate

Aggregate Root：

    Employee

主な属性：

- EmployeeId
- EmployeeNumber
- Name
- DepartmentId
- EmploymentStatus
- RetirementDate

主な業務ルール：

- EmployeeNumber
- 在籍状態
- 退職日との整合性
- Department所属

EmployeeSkill Collectionは持たないことを第一候補とする。

---

# 6. EmployeeSkill Aggregate

Aggregate Root：

    EmployeeSkill

主な属性：

- EmployeeSkillId
- EmployeeId
- SkillId
- HasWorkExperience
- ExperienceMonths
- SkillLevel
- LastUsedMonth
- Comment
- ExperienceDetails
- IsActive

主な業務ルール：

### 実務経験なし

    ExperienceMonths = 0
    SkillLevel = Level1
    LastUsedMonth = null

### 実務経験あり

    ExperienceMonths >= 1
    SkillLevel = Level1〜Level5
    LastUsedMonth required

### 無効化

    is_active = false

### 再有効化

既存Recordを再利用する。

---

# 7. Skill Aggregate

Aggregate Root：

    Skill

主な属性：

- SkillId
- SkillCategoryId
- SkillName
- IsActive

主な業務ルール：

- 無効Skillは新規EmployeeSkill登録に利用できない
- Skill Nameは一意

SkillCategoryを内部Entityとするのではなく、
別Master Entityとして扱うことを第一候補とする。

---

# 8. Department Aggregate

Departmentは小さなMaster Aggregateとして扱う。

Aggregate Root：

    Department

主な属性：

- DepartmentId
- Name
- IsActive

Employee Collectionは持たない。

---

# 9. User Aggregate

Access Control側のAggregate Root：

    User

主な属性：

- UserId
- EmployeeId
- LoginId
- IsActive

将来的に：

- Role
- Permission管理可否
- Assignment

を扱う。

ただしPassword / Session / Tokenなど
認証Infrastructureの詳細をDomain Entityへ持ち込まないことを検討する。

---

# 10. Aggregate間参照

Aggregate間ではDomain Entity Objectを直接保持せず、
IDで参照する。

例：

    EmployeeSkill
    ├── EmployeeId
    └── SkillId

以下のようにはしない。

    EmployeeSkill
    ├── Employee
    └── Skill

これによりAggregate間の結合を弱くする。

---

# 11. Repository

Aggregate RootごとにRepository Interfaceを持つ。

候補：

    EmployeeRepository
    DepartmentRepository
    SkillRepository
    SkillCategoryRepository
    EmployeeSkillRepository
    UserRepository

RepositoryはAggregate単位で扱う。

---

# 12. EmployeeSkillRepository

主なInterface候補：

    findById()

    existsByEmployeeAndSkill()

    save()

    delete()

または無効化中心なので：

    save()

を中心とする。

重複確認：

    existsByEmployeeAndSkill(
        EmployeeId,
        SkillId
    )

を利用できる。

---

# 13. 重複Skill登録

業務ルール：

    同一Employee
    +
    同一Skill

を複数登録できない。

保証レイヤ：

### Application

Repositoryで事前確認する。

### Database

    UNIQUE(employee_id, skill_id)

でも最終保証する。

つまり、

    Domain / Application Rule
        +
    Database Constraint

の二重保証とする。

---

# 14. Transaction Boundary

基本的に1 UseCase = 1 Transactionを第一候補とする。

例：

    RegisterEmployeeSkill
        ↓
    Transaction Start
        ↓
    Employee存在確認
        ↓
    Skill確認
        ↓
    重複確認
        ↓
    EmployeeSkill生成
        ↓
    Repository save
        ↓
    Commit

Employee / Skill自体は変更しない。

---

# 15. Aggregate間更新

1つのUseCaseで複数Aggregateを変更する場合は慎重に扱う。

例：

    Employee削除
      +
    User削除
      +
    EmployeeSkill削除

これは通常のAggregate操作ではなく、
Application Service / UseCaseでTransactionを調整する。

MVPではこうした処理を限定する。

---

# 16. Read Model

一覧・検索ではAggregateを大量に復元しない。

例えば：

    PHP経験3年以上
    AND Laravel Level3以上

の検索では、

    EmployeeRepository

を無理に利用してAggregateを構築するのではなく、

    EmployeeSearchQueryService

等のRead Modelを利用する。

---

# 17. Command / Queryの使い分け

## Command

Aggregateを操作する。

例：

    RegisterEmployeeSkill
        ↓
    EmployeeSkill Aggregate

## Query

必要なデータを効率的に取得する。

例：

    SearchEmployeesBySkills

QueryではDomain Entityを必ず返す必要はない。

DTO / Read Modelを直接返してよい。

---

# 18. Aggregate一覧

MVP第一候補：

## Employee Management

- Employee
- Department

## Skill Management

- SkillCategory
- Skill
- EmployeeSkill

## Access Control

- User

---

# 19. Aggregate Root一覧

- Employee
- Department
- SkillCategory
- Skill
- EmployeeSkill
- User

Tableとほぼ対応するが、
TableだからAggregate Rootにするのではなく、
独立した整合性境界を持つためAggregate Rootとして扱う。

---

# 20. EmployeeSkillを独立させる理由

今回のCore DomainではEmployeeSkillが特に重要。

EmployeeSkillは単なるPivotではなく、

- 実務経験
- 経験月数
- Level
- 最終利用年月
- コメント
- 経験内容
- 有効状態

を持つ。

さらに独自の業務ルールがある。

そのため、

    EmployeeSkill = 独立Aggregate Root

とする。

---

# 21. Aggregateを大きくしない

以下のような構造は採用しない。

    Employee
    ├── Department
    ├── User
    └── EmployeeSkills
        ├── Skill
        │   └── SkillCategory
        └── ...

これではEmployeeを取得するだけで
巨大なObject Graphになりやすい。

代わりに：

    Employee
    Department
    User
    EmployeeSkill
    Skill
    SkillCategory

を独立Aggregateとして扱い、
IDで関連付ける。

---

# 22. 決定候補

### EmployeeSkill

独立Aggregate Rootとする。

### Aggregate間参照

IDを基本とする。

### Repository

Aggregate Root単位で作成する。

### Transaction

Application UseCaseで管理する。

### Query

Read Model / Query Serviceを利用可能とする。

### Cross Aggregate Rule

Application Layer + Repository + DB Constraintを組み合わせる。

---

# 23. 推奨決定

MVPでは以下をAggregate Rootとする。

- Employee
- Department
- SkillCategory
- Skill
- EmployeeSkill
- User

特にEmployeeSkillは独立Aggregate Rootとして扱う。

Aggregateは小さく保ち、
必要な関係はIDで参照する。

検索・Dashboard等のRead処理では
Aggregate再構築にこだわらずRead Modelを利用する。
