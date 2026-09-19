# PostgreSQL テーブル一覧・Migration順序 最終版

## 1. 対象Table

MVPでは以下の8 Tableを使用する。

### Application

1. departments
2. employees
3. users
4. skill_categories
5. skills
6. employee_skills

### Auth.js

7. auth_sessions

### Laravel Sanctum

8. personal_access_tokens

---

# 2. Table Relation

    departments
        |
        | 1:N
        v
    employees
        |
        | 1:0..1
        v
      users
        |
        | 1:N
        v
    auth_sessions


    skill_categories
        |
        | 1:N
        v
      skills
        |
        | 1:N
        v
    employee_skills
        ^
        | N:1
        |
    employees


    users
      |
      └── Laravel Sanctum
          personal_access_tokens

※ Sanctumの実際のRelationは
   tokenable_type / tokenable_id を利用するPolymorphic Relationとする。

---

# 3. Migration Source of Truth

Database SchemaのSource of Truth：

    backend/database/migrations

Next.js側にはMigration Toolを導入しない。

以下をすべてLaravel Migrationで管理する。

- Application Table
- Auth.js Session Table
- Sanctum Table

---

# 4. Migration作成順序

Foreign Key依存関係を考慮し、
以下の順番で作成する。

1. create_departments_table
2. create_employees_table
3. create_users_table
4. create_skill_categories_table
5. create_skills_table
6. create_employee_skills_table
7. create_auth_sessions_table
8. create_personal_access_tokens_table

---

# 5. 依存関係

## departments

依存なし。

    departments

---

## employees

依存：

    departments

Relation：

    employees.department_id
        ↓
    departments.id

---

## users

依存：

    employees

Relation：

    users.employee_id
        ↓
    employees.id

---

## skill_categories

依存なし。

    skill_categories

---

## skills

依存：

    skill_categories

Relation：

    skills.skill_category_id
        ↓
    skill_categories.id

---

## employee_skills

依存：

    employees
    skills

Relation：

    employee_skills.employee_id
        ↓
    employees.id

    employee_skills.skill_id
        ↓
    skills.id

---

## auth_sessions

依存：

    users

Relation：

    auth_sessions.user_id
        ↓
    users.id

---

## personal_access_tokens

Laravel Sanctumが利用する。

User等のTokenable ModelへPolymorphic Relationで紐付く。

代表的なカラム：

    tokenable_type
    tokenable_id

通常のForeign Key Constraintとして
users.idへ固定しない。

---

# 6. departments

主なColumn：

    id
    name
    is_active
    created_at
    updated_at

Constraint：

    PRIMARY KEY (id)
    UNIQUE (name)

---

# 7. employees

主なColumn：

    id
    employee_number
    name
    department_id
    employment_status
    retirement_date
    created_at
    updated_at

Constraint：

    PRIMARY KEY (id)

    UNIQUE (employee_number)

    FOREIGN KEY (
        department_id
    )
    REFERENCES departments(id)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT

CHECK：

    employment_status IN (
        'ACTIVE',
        'LEAVE',
        'RETIRED'
    )

さらに：

    ACTIVE / LEAVE
        → retirement_date IS NULL

    RETIRED
        → retirement_date IS NOT NULL

---

# 8. users

主なColumn：

    id
    employee_id
    login_id
    password
    name
    is_active
    created_at
    updated_at

Constraint：

    PRIMARY KEY (id)

    UNIQUE (employee_id)

    UNIQUE (login_id)

    FOREIGN KEY (
        employee_id
    )
    REFERENCES employees(id)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT

---

# 9. skill_categories

主なColumn：

    id
    name
    is_active
    created_at
    updated_at

Constraint：

    PRIMARY KEY (id)

    UNIQUE (name)

---

# 10. skills

主なColumn：

    id
    skill_category_id
    name
    is_active
    created_at
    updated_at

Constraint：

    PRIMARY KEY (id)

    UNIQUE (name)

    FOREIGN KEY (
        skill_category_id
    )
    REFERENCES skill_categories(id)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT

---

# 11. employee_skills

主なColumn：

    id
    employee_id
    skill_id
    has_work_experience
    experience_months
    skill_level
    last_used_date
    comment
    experience_details
    is_active
    created_at
    updated_at

Constraint：

    PRIMARY KEY (id)

    UNIQUE (
        employee_id,
        skill_id
    )

Foreign Key：

    employee_id
        ↓
    employees.id

    ON DELETE RESTRICT
    ON UPDATE RESTRICT

    skill_id
        ↓
    skills.id

    ON DELETE RESTRICT
    ON UPDATE RESTRICT

CHECK：

    skill_level BETWEEN 1 AND 5

実務経験なし：

    has_work_experience = false
    experience_months = 0
    skill_level = 1
    last_used_date IS NULL

実務経験あり：

    has_work_experience = true
    experience_months >= 1
    skill_level BETWEEN 1 AND 5
    last_used_date IS NOT NULL

last_used_date：

    NULL
    または
    月初日

---

# 12. auth_sessions

主なColumn：

    id
    user_id
    session_token
    expires_at
    sanctum_token
    created_at
    updated_at

Constraint：

    PRIMARY KEY (id)

    UNIQUE (session_token)

    FOREIGN KEY (
        user_id
    )
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE RESTRICT

Relation：

    User 1:N AuthSession

---

# 13. auth_sessions の削除Rule

`auth_sessions`だけはSessionという一時データなので、

    ON DELETE CASCADE

を採用する。

つまり：

    User削除
        ↓
    AuthSession自動削除

を許可する。

Applicationの業務データに対する
CASCADE DELETEとは扱いを分ける。

---

# 14. personal_access_tokens

Laravel Sanctum標準のMigrationを基本とする。

概念上の主なColumn：

    id
    tokenable_type
    tokenable_id
    name
    token
    abilities
    last_used_at
    expires_at
    created_at
    updated_at

Laravel Sanctumの標準Schemaを
不必要に独自変更しない。

---

# 15. Sanctum TokenとAuthSession

1 AuthSessionに対し、
1つのSanctum Tokenを対応させる。

概念：

    auth_sessions
        |
        | sanctum_token
        v
    Laravel API

Laravel側では同じTokenに対応する情報を、

    personal_access_tokens

で管理する。

両者の役割：

    auth_sessions.sanctum_token
    → Laravelへ提示するCredential

    personal_access_tokens
    → LaravelがTokenを検証するための情報

---

# 16. Migration Rollback順

作成順の逆になる。

1. personal_access_tokens
2. auth_sessions
3. employee_skills
4. skills
5. skill_categories
6. users
7. employees
8. departments

Laravel MigrationのTimestamp順序によって
この依存関係を維持する。

---

# 17. Seeder

Migrationには初期Dataを入れない。

初期DataはSeederで管理する。

MVP候補：

    DepartmentSeeder
    SkillCategorySeeder
    SkillSeeder
    AdminEmployeeSeeder
    AdminUserSeeder

---

# 18. Seeder実行順

候補：

1. DepartmentSeeder
2. SkillCategorySeeder
3. SkillSeeder
4. AdminEmployeeSeeder
5. AdminUserSeeder

Relation依存順に実行する。

---

# 19. Factory

Laravel Feature TestではFactoryを利用する。

候補：

    DepartmentFactory
    EmployeeFactory
    UserFactory
    SkillCategoryFactory
    SkillFactory
    EmployeeSkillFactory

AuthSessionについては
認証テストの必要性に応じてFactoryを検討する。

---

# 20. Index

最初から作るもの：

## departments

    UNIQUE(name)

## employees

    UNIQUE(employee_number)

    INDEX(department_id)

    INDEX(employment_status)

## users

    UNIQUE(employee_id)

    UNIQUE(login_id)

## skill_categories

    UNIQUE(name)

## skills

    UNIQUE(name)

    INDEX(skill_category_id)

## employee_skills

    UNIQUE(employee_id, skill_id)

    INDEX(employee_id)

    INDEX(skill_id)

## auth_sessions

    UNIQUE(session_token)

    INDEX(user_id)

## personal_access_tokens

Sanctum標準Indexを基本とする。

---

# 21. 後から検討するIndex

実Queryを確認して追加する。

候補：

    employees.retirement_date

    employee_skills.experience_months

    employee_skills.skill_level

    employee_skills.last_used_date

    employee_skills.has_work_experience

    employee_skills.is_active

    auth_sessions.expires_at

過剰なIndexをMVPから作らない。

---

# 22. Soft Delete

以下ではSoft Deleteを原則使用しない。

    departments
    employees
    users
    skill_categories
    skills
    employee_skills
    auth_sessions

業務上の無効化は：

    is_active

Session失効は：

    auth_sessions Record削除

で扱う。

---

# 23. Database全体像

    PostgreSQL
    │
    ├── Application
    │   ├── departments
    │   ├── employees
    │   ├── users
    │   ├── skill_categories
    │   ├── skills
    │   └── employee_skills
    │
    ├── Auth.js
    │   └── auth_sessions
    │
    └── Laravel Sanctum
        └── personal_access_tokens

Schema管理：

    Laravel Migration

Application責務：

    Next.js
    → auth_sessions利用

    Laravel
    → Application Tables
    → personal_access_tokens

---

# 24. Migration実行

Local：

    docker compose exec backend php artisan migrate

Test：

    docker compose exec backend php artisan migrate:fresh

Staging：

    php artisan migrate --force

Production：

    Deployment設計時に決定する。

---

# 25. 決定事項

## Database

PostgreSQL

## Migration Tool

Laravel Migrationへ統一する。

## Table数

MVPでは8 Table。

## Application Tables

- departments
- employees
- users
- skill_categories
- skills
- employee_skills

## Auth.js

- auth_sessions

## Sanctum

- personal_access_tokens

## Migration Source of Truth

    backend/database/migrations

## Seeder

Laravelへ統一する。

## Foreign Key

業務Table：

    RESTRICT

AuthSession：

    users → auth_sessions
    CASCADE

## Soft Delete

原則使用しない。

## Schema変更

Next.js側から直接Migrationを実行しない。
