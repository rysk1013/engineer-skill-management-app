# MVP Entity 決定

## 採用Entity

1. User
2. Department
3. Employee
4. SkillCategory
5. Skill
6. EmployeeSkill

---

## Relation

    Department
        |
        | 1:N
        v
    Employee
        |
        | 1:N
        v
    EmployeeSkill
        ^
        | N:1
        |
       Skill
        ^
        | N:1
        |
    SkillCategory

    User
      |
      └── Application利用者

---

## 基本方針

### User

Applicationを利用する利用者として管理する。

Employeeとは分離する。

### Employee

スキル管理対象となる社員として管理する。

Applicationを利用しない社員もEmployeeとして保持できる。

### Department

所属部署を独立したEntityとして管理する。

社員は1つのDepartmentに所属する。

### SkillCategory

技術・スキルの分類を管理する。

### Skill

技術・スキルマスタを管理する。

各Skillは1つのSkillCategoryに所属する。

### EmployeeSkill

EmployeeとSkillの関係を管理する。

単純な中間Tableではなく、以下の業務情報を持つEntityとして扱う。

- 実務経験あり / なし
- 経験年数
- スキルレベル
- 最終利用時期
- コメント
- 実績・経験内容
- 有効 / 無効

---

## MVPではEntityにしないもの

以下は固定値またはEmployeeSkill等の属性として扱う。

- スキルレベル
- 実務経験
- 在籍状態
- 職種
- コメント
- 実績・経験内容

---

## 後続Iterationで検討するEntity

- Role / Permission
- SubManagerAssignment
- TeamLeaderAssignment
- Qualification

権限管理可能な管理ユーザーについては、
専用EntityにするかUser属性で表現するかを権限設計時に決定する。
