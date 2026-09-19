# Laravel Migration 設計

## 1. 基本方針

MigrationはTable単位で分割する。

MVPでは以下の6 Tableを作成する。

1. departments
2. employees
3. users
4. skill_categories
5. skills
6. employee_skills

Foreign Keyの依存順に作成する。

---

## 2. Migration作成順

依存関係を考慮し、以下の順番で作成する。

    departments
        ↓
    employees
        ↓
      users


    skill_categories
        ↓
      skills


    employees
        +
      skills
        ↓
    employee_skills

Migration順：

1. create_departments_table
2. create_employees_table
3. create_users_table
4. create_skill_categories_table
5. create_skills_table
6. create_employee_skills_table

---

## 3. departments Migration

対象：

    departments

主な定義：

- id
- name
- is_active
- created_at
- updated_at

Constraint：

    PRIMARY KEY (id)

    UNIQUE (name)

Foreign Keyなし。

---

## 4. employees Migration

対象：

    employees

主な定義：

- id
- employee_number
- name
- department_id
- employment_status
- retirement_date
- created_at
- updated_at

Foreign Key：

    department_id
        ↓
    departments.id

削除ルール：

    ON DELETE RESTRICT

更新ルール：

    ON UPDATE RESTRICT

Constraint：

    UNIQUE(employee_number)

    CHECK employment_status

    CHECK employment_status / retirement_date

---

## 5. users Migration

対象：

    users

主な定義：

- id
- employee_id
- login_id
- password
- name
- is_active
- created_at
- updated_at

Foreign Key：

    employee_id
        ↓
    employees.id

Constraint：

    UNIQUE(employee_id)

    UNIQUE(login_id)

削除ルール：

    ON DELETE RESTRICT

更新ルール：

    ON UPDATE RESTRICT

---

## 6. skill_categories Migration

対象：

    skill_categories

主な定義：

- id
- name
- is_active
- created_at
- updated_at

Constraint：

    UNIQUE(name)

Foreign Keyなし。

---

## 7. skills Migration

対象：

    skills

主な定義：

- id
- skill_category_id
- name
- is_active
- created_at
- updated_at

Foreign Key：

    skill_category_id
        ↓
    skill_categories.id

Constraint：

    UNIQUE(name)

削除ルール：

    ON DELETE RESTRICT

更新ルール：

    ON UPDATE RESTRICT

---

## 8. employee_skills Migration

対象：

    employee_skills

主な定義：

- id
- employee_id
- skill_id
- has_work_experience
- experience_months
- skill_level
- last_used_date
- comment
- experience_details
- is_active
- created_at
- updated_at

Foreign Key：

    employee_id
        ↓
    employees.id

    skill_id
        ↓
    skills.id

削除ルール：

    ON DELETE RESTRICT

更新ルール：

    ON UPDATE RESTRICT

Constraint：

    UNIQUE(employee_id, skill_id)

    CHECK skill_level

    CHECK 実務経験ルール

    CHECK last_used_dateが月初日

---

# 9. Laravel Schema Builderで定義するもの

可能なものはLaravel Schema Builderで定義する。

例：

    $table->id();

    $table->string('name');

    $table->boolean('is_active')
        ->default(true);

    $table->timestamps();

Foreign Key：

    $table->foreignId('department_id')
        ->constrained('departments')
        ->restrictOnDelete()
        ->restrictOnUpdate();

UNIQUE：

    $table->unique('employee_number');

Composite UNIQUE：

    $table->unique([
        'employee_id',
        'skill_id',
    ]);

---

# 10. CHECK Constraint

CHECK Constraintについては
PostgreSQLのConstraintとして明示的に定義する。

対象：

### employees

- employment_status
- retirement_dateとの整合性

### employee_skills

- skill_level 1〜5
- 実務経験と経験月数
- 実務経験とSkill Level
- 実務経験とlast_used_date
- last_used_dateの月初日

Laravel Validationだけには依存しない。

---

# 11. CHECK Constraintの配置

可能であれば対象Tableを作成するMigration内で定義する。

例：

    create_employees_table

の中で、

    employment_status

関連Constraintを設定する。

同様に、

    create_employee_skills_table

の中でEmployeeSkillのConstraintを設定する。

Constraint専用Migrationを大量に分離しない。

---

# 12. Constraint名

CHECK Constraintには明示的な名前を付けることを推奨する。

例：

    chk_employees_employment_status

    chk_employees_retirement_date

    chk_employee_skills_skill_level

    chk_employee_skills_work_experience

    chk_employee_skills_last_used_date

理由：

- Error解析しやすい
- Migration変更時に扱いやすい
- Database上で確認しやすい

---

# 13. Index

MVPで最初から作るIndex：

### departments

    UNIQUE(name)

### employees

    UNIQUE(employee_number)

    INDEX(department_id)

    INDEX(employment_status)

### users

    UNIQUE(employee_id)

    UNIQUE(login_id)

### skill_categories

    UNIQUE(name)

### skills

    UNIQUE(name)

    INDEX(skill_category_id)

### employee_skills

    UNIQUE(employee_id, skill_id)

Foreign Key ColumnのIndexについては、
PostgreSQLではForeign Key作成だけでは自動生成されない点に注意する。

実Queryに応じて追加Indexを調整する。

---

# 14. MVPで最初から追加しないIndex

以下は検索要件を確認してから追加する。

- employee_skills.skill_level
- employee_skills.experience_months
- employee_skills.last_used_date
- employee_skills.has_work_experience
- employee_skills.is_active
- skills.is_active
- departments.is_active
- retirement_date

Indexを先回りして大量に作らない。

---

# 15. Enumの扱い

`employment_status` はDatabase ENUM型ではなく、
varchar + CHECK Constraintを第一候補とする。

理由：

- Migration変更が比較的容易
- Laravel Enumと組み合わせやすい
- PostgreSQL ENUM固有の変更手順を避けられる

Application側ではPHP Enumを利用できる。

例：

    EmploymentStatus::Active
    EmploymentStatus::Leave
    EmploymentStatus::Retired

Database：

    ACTIVE
    LEAVE
    RETIRED

---

# 16. skill_level

Databaseではsmallintを使用する。

Application側では必要に応じてPHP Enumを利用する。

例：

    SkillLevel::Level1
    SkillLevel::Level2
    SkillLevel::Level3
    SkillLevel::Level4
    SkillLevel::Level5

Databaseでは：

    1
    2
    3
    4
    5

を保存する。

---

# 17. last_used_date

Database：

    date

保存：

    YYYY-MM-01

Laravel：

    Carbon / Date Cast

API：

    YYYY-MM

として扱う。

Database表現とAPI表現を分ける。

---

# 18. retirement_date

Database：

    date

API：

    YYYY-MM-DD

Laravel ModelではDate Castを利用することを候補とする。

---

# 19. Timestamp

Laravel標準の：

    $table->timestamps();

を利用する。

つまり：

    created_at
    updated_at

を保持する。

Timezone方針は別途Date / Time設計で決定する。

---

# 20. Soft Delete

Migrationでは：

    $table->softDeletes();

を原則追加しない。

業務上の無効化は：

    is_active

で管理する。

---

# 21. Migration Rollback

MigrationはRollback可能な状態を維持する。

各Migrationの`down()`では
対象Tableを削除する。

依存順を逆にしてRollbackされる前提とする。

作成：

    departments
        ↓
    employees
        ↓
    users

Rollback：

    users
        ↓
    employees
        ↓
    departments

---

# 22. Seederとの関係

Migration：

    Database Structure

Seeder：

    Initial Data

として責務を分ける。

Migration内にDepartmentやSkillCategoryの初期値を直接INSERTしない。

初期値はSeederで管理する。

---

# 23. 初期Seeder候補

MVPでは以下を検討する。

- DepartmentSeeder
- SkillCategorySeeder
- SkillSeeder
- AdminEmployeeSeeder
- AdminUserSeeder

TestではFactoryを中心に利用する。

---

# 24. Migrationで行わないこと

Migrationへ以下を詰め込まない。

- Application Business Logic
- 大量の初期Data
- User作成処理
- Password生成
- API関連処理

Schema変更に集中させる。

---

# 25. Migration File構成

想定：

    backend/
    └── database/
        ├── migrations/
        │   ├── xxxx_create_departments_table.php
        │   ├── xxxx_create_employees_table.php
        │   ├── xxxx_create_users_table.php
        │   ├── xxxx_create_skill_categories_table.php
        │   ├── xxxx_create_skills_table.php
        │   └── xxxx_create_employee_skills_table.php
        │
        ├── seeders/
        │   ├── DepartmentSeeder.php
        │   ├── SkillCategorySeeder.php
        │   └── ...
        │
        └── factories/
            └── ...

---

# 26. 決定候補

### Migration単位

Table単位で分割する。

### 作成順

1. departments
2. employees
3. users
4. skill_categories
5. skills
6. employee_skills

### Foreign Key

RESTRICTを基本とする。

### CHECK Constraint

対象TableのMigration内で定義する。

### Constraint名

明示的に付ける。

### Enum

PostgreSQL ENUMではなくvarchar / smallint + CHECKを基本とする。

### Initial Data

Seederで管理する。

### Soft Delete

原則使用しない。
