# Foreign Key 削除・更新ルール 決定

## 1. 基本方針

Foreign Keyの削除ルールは原則として `RESTRICT` を採用する。

親Recordの削除によって、
関連する子Recordが自動的に削除される構成は避ける。

理由：

- 業務上の削除条件をLaravel側で明示的に管理したい
- 誤削除による連鎖削除を防ぎたい
- 無効化と削除を区別したい
- 退職社員の削除など、確認プロセスが必要な要件がある

---

## 2. 更新ルール

Primary Keyは基本的に変更しないため、
`ON UPDATE` は原則 `RESTRICT` とする。

Auto Increment IDを後から変更する運用は行わない。

---

# 3. departments → employees

Relation：

    departments.id
        ↓
    employees.department_id

## 削除

`RESTRICT`

    ON DELETE RESTRICT

DepartmentにEmployeeが所属している場合、
Departmentを削除できない。

### 理由

Department削除によってEmployeeが削除されることを防ぐ。

Departmentを利用停止する場合は、

    departments.is_active = false

とする。

---

## 更新

    ON UPDATE RESTRICT

Department IDは変更しない。

---

# 4. employees → users

Relation：

    employees.id
        ↓
    users.employee_id

## 削除

`RESTRICT`

    ON DELETE RESTRICT

EmployeeにUserが存在する状態では、
Employeeを直接削除できない。

### 削除時の想定フロー

    Employee削除対象
        ↓
    User確認
        ↓
    User無効化 / 削除
        ↓
    Employee削除

退職後3年経過社員の削除時も、
関連Userを先に確認する。

---

## 更新

    ON UPDATE RESTRICT

---

# 5. skill_categories → skills

Relation：

    skill_categories.id
        ↓
    skills.skill_category_id

## 削除

`RESTRICT`

    ON DELETE RESTRICT

Skillが存在するSkillCategoryは削除できない。

不要なCategoryは、

    skill_categories.is_active = false

とする。

---

## 更新

    ON UPDATE RESTRICT

---

# 6. employees → employee_skills

Relation：

    employees.id
        ↓
    employee_skills.employee_id

## 削除

`RESTRICT`

    ON DELETE RESTRICT

EmployeeSkillが残っているEmployeeを
Database操作だけで削除できないようにする。

### 退職社員削除時

削除対象社員を管理ユーザーが確認した後、
Application側でTransactionを利用して明示的に処理する。

想定：

    Transaction Start

    EmployeeSkill削除
        ↓
    User削除
        ↓
    Employee削除

    Transaction Commit

具体的な削除対象Relationは
退職社員削除機能の詳細設計時に確定する。

---

## 更新

    ON UPDATE RESTRICT

---

# 7. skills → employee_skills

Relation：

    skills.id
        ↓
    employee_skills.skill_id

## 削除

`RESTRICT`

    ON DELETE RESTRICT

EmployeeSkillで利用されているSkillを
直接削除できない。

不要なSkillは、

    skills.is_active = false

とする。

---

## 更新

    ON UPDATE RESTRICT

---

# 8. Foreign Key一覧

| Parent | Child | ON DELETE | ON UPDATE |
| --- | --- | --- | --- |
| departments | employees | RESTRICT | RESTRICT |
| employees | users | RESTRICT | RESTRICT |
| skill_categories | skills | RESTRICT | RESTRICT |
| employees | employee_skills | RESTRICT | RESTRICT |
| skills | employee_skills | RESTRICT | RESTRICT |

---

# 9. CASCADEを原則採用しない理由

例えば以下のような構成は採用しない。

    Department削除
        ↓ CASCADE
    Employee削除
        ↓ CASCADE
    EmployeeSkill削除

業務Applicationでは影響範囲が大きすぎるため。

特に今回、

- Department
- Skill
- SkillCategory
- EmployeeSkill

には「無効化」という業務状態がある。

そのため、

    Database Delete

より、

    is_active = false

を優先する。

---

# 10. SET NULLを原則採用しない理由

以下のRelationは業務上必須である。

    Employee
        ↓
    Department

    EmployeeSkill
        ↓
    Employee

    EmployeeSkill
        ↓
    Skill

そのため、親がなくなった場合に、

    foreign_key = NULL

として子だけ残す状態は許可しない。

例えば、

    employee_skills.skill_id = NULL

のEmployeeSkillは業務上意味を持たない。

---

# 11. Employee削除

Employeeの削除は通常操作では行わない。

主な削除ケース：

    RETIRED
        ↓
    retirement_dateから3年経過
        ↓
    管理ユーザー確認
        ↓
    Applicationから削除

Laravel側で関連データを確認し、
Transaction内で明示的に削除する。

---

# 12. Master Data

以下は原則完全削除しない。

- Department
- SkillCategory
- Skill

利用停止：

    is_active = false

とする。

そのため、Foreign Keyの削除Ruleが
通常運用で発火するケースは少ない。

---

# 13. EmployeeSkill

EmployeeSkillについても通常は完全削除せず、

    is_active = false

とする。

完全削除はEmployeeそのものを削除する場合など、
限定的なケースとする。

---

# 14. Laravelでの削除処理

複数Tableを削除する必要がある場合は
Database Transactionを利用する。

概念：

    DB::transaction(function () {
        // Relation確認
        // Child削除
        // Parent削除
    });

DatabaseのCASCADEへ任せず、
Application側で意図を明確にする。

---

# 15. 削除前チェック

Laravel側で削除前に以下を確認する。

例：

### Department

    Employeeが存在する
        ↓
    削除不可

### SkillCategory

    Skillが存在する
        ↓
    削除不可

### Skill

    EmployeeSkillが存在する
        ↓
    削除不可

### Employee

    通常
        ↓
    削除不可

    退職後3年経過
        +
    管理ユーザー確認
        ↓
    明示的削除

---

# 16. DatabaseとApplicationの役割

## PostgreSQL

Foreign Key `RESTRICT` により
不正なRelation破壊を防ぐ。

## Laravel

業務ルールに従って、

- 削除可能か
- 無効化すべきか
- 関連データをどう処理するか

を判断する。

---

# 17. 決定事項

### Foreign Key ON DELETE

原則 `RESTRICT`

### Foreign Key ON UPDATE

原則 `RESTRICT`

### CASCADE DELETE

原則使用しない。

### SET NULL

原則使用しない。

### Master Data

完全削除ではなく`is_active`による無効化を基本とする。

### EmployeeSkill

`is_active`による無効化を基本とする。

### Employee削除

退職後3年経過 + 管理ユーザー確認後に、
Laravel側で明示的に関連データを処理して削除する。

### Transaction

複数Tableを伴う削除はTransaction内で実行する。
