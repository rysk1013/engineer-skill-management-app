# MVP Database Design

## 1. Database

採用：

    PostgreSQL

Database SchemaのSource of Truth：

    Laravel Migration

配置：

    backend/database/migrations

Next.js側ではMigrationを管理しない。

---

## 2. Table一覧

### Employee Management

1. departments
2. employees

### Access Control

3. users
4. sub_manager_assignments
5. team_leader_assignments

### Skill Management

6. skill_categories
7. skills
8. employee_skills

### Authentication / Infrastructure

9. personal_access_tokens

---

## 3. departments

| Column | Type | NULL | Constraint |
| --- | --- | --- | --- |
| id | bigint | NOT NULL | PK |
| name | varchar | NOT NULL | UNIQUE |
| is_active | boolean | NOT NULL | DEFAULT true |
| created_at | timestamptz | NOT NULL | |
| updated_at | timestamptz | NOT NULL | |

通常の完全削除は行わない。

無効化：

    is_active = false

で管理する。

---

## 4. employees

| Column | Type | NULL | Constraint |
| --- | --- | --- | --- |
| id | bigint | NOT NULL | PK |
| employee_number | varchar | NOT NULL | UNIQUE |
| name | varchar | NOT NULL | |
| department_id | bigint | NOT NULL | FK |
| employment_status | varchar | NOT NULL | CHECK |
| retirement_date | date | NULL | CHECK |
| created_at | timestamptz | NOT NULL | |
| updated_at | timestamptz | NOT NULL | |

### employment_status

許可：

    ACTIVE
    LEAVE
    RETIRED

Constraint：

    CHECK (
        employment_status IN (
            'ACTIVE',
            'LEAVE',
            'RETIRED'
        )
    )

### retirement_date

Rule：

    ACTIVE
        → NULL

    LEAVE
        → NULL

    RETIRED
        → NOT NULL

DomainとDatabaseの両方で保証する。

---

## 5. users

| Column | Type | NULL | Constraint |
| --- | --- | --- | --- |
| id | bigint | NOT NULL | PK |
| employee_id | bigint | NOT NULL | FK, UNIQUE |
| login_id | varchar | NOT NULL | UNIQUE |
| password | varchar | NOT NULL | |
| name | varchar | NOT NULL | |
| role | varchar | NOT NULL | CHECK |
| can_manage_permissions | boolean | NOT NULL | DEFAULT false |
| is_active | boolean | NOT NULL | DEFAULT true |
| created_at | timestamptz | NOT NULL | |
| updated_at | timestamptz | NOT NULL | |

### role

許可：

    ADMINISTRATOR
    SUB_MANAGER
    TEAM_LEADER

Constraint：

    CHECK (
        role IN (
            'ADMINISTRATOR',
            'SUB_MANAGER',
            'TEAM_LEADER'
        )
    )

### Permission Manager

以下をDatabaseでも保証する。

    can_manage_permissions = true
        ↓
    role = ADMINISTRATOR

Constraint：

    CHECK (
        can_manage_permissions = false
        OR role = 'ADMINISTRATOR'
    )

Permission Managerを最低1人維持するRuleは
Application Layerで保証する。

---

## 6. sub_manager_assignments

| Column | Type | NULL | Constraint |
| --- | --- | --- | --- |
| user_id | bigint | NOT NULL | FK |
| employee_id | bigint | NOT NULL | FK |
| created_at | timestamptz | NOT NULL | |
| updated_at | timestamptz | NOT NULL | |

Constraint：

    UNIQUE(
        user_id,
        employee_id
    )

Foreign Key：

    user_id
        → users.id

    employee_id
        → employees.id

Assignment対象Userは、

    SUB_MANAGER

でなければならない。

このRuleはApplication Layerで保証する。

---

## 7. team_leader_assignments

| Column | Type | NULL | Constraint |
| --- | --- | --- | --- |
| user_id | bigint | NOT NULL | FK |
| employee_id | bigint | NOT NULL | FK |
| created_at | timestamptz | NOT NULL | |
| updated_at | timestamptz | NOT NULL | |

Constraint：

    UNIQUE(
        user_id,
        employee_id
    )

Assignment対象Userは、

    TEAM_LEADER

でなければならない。

---

## 8. skill_categories

| Column | Type | NULL | Constraint |
| --- | --- | --- | --- |
| id | bigint | NOT NULL | PK |
| name | varchar | NOT NULL | UNIQUE |
| is_active | boolean | NOT NULL | DEFAULT true |
| created_at | timestamptz | NOT NULL | |
| updated_at | timestamptz | NOT NULL | |

完全削除ではなく、

    is_active = false

で無効化する。

---

## 9. skills

| Column | Type | NULL | Constraint |
| --- | --- | --- | --- |
| id | bigint | NOT NULL | PK |
| skill_category_id | bigint | NOT NULL | FK |
| name | varchar | NOT NULL | UNIQUE |
| is_active | boolean | NOT NULL | DEFAULT true |
| created_at | timestamptz | NOT NULL | |
| updated_at | timestamptz | NOT NULL | |

Foreign Key：

    skill_category_id
        → skill_categories.id

SkillCategory変更は許可する。

移動先Categoryが有効であることは
Application Layerで確認する。

---

## 10. employee_skills

| Column | Type | NULL | Constraint |
| --- | --- | --- | --- |
| id | bigint | NOT NULL | PK |
| employee_id | bigint | NOT NULL | FK |
| skill_id | bigint | NOT NULL | FK |
| has_work_experience | boolean | NOT NULL | CHECK |
| experience_months | integer | NOT NULL | CHECK |
| skill_level | smallint | NOT NULL | CHECK |
| last_used_date | date | NULL | CHECK |
| comment | text | NULL | |
| experience_details | text | NULL | |
| is_active | boolean | NOT NULL | DEFAULT true |
| created_at | timestamptz | NOT NULL | |
| updated_at | timestamptz | NOT NULL | |

### UNIQUE

    UNIQUE(
        employee_id,
        skill_id
    )

### Skill Level

    1 <= skill_level <= 5

### 実務未経験

    has_work_experience = false
    experience_months = 0
    skill_level = 1
    last_used_date IS NULL

### 実務経験あり

    has_work_experience = true
    experience_months >= 1
    skill_level BETWEEN 1 AND 5
    last_used_date IS NOT NULL

### last_used_date

「最後に実務で使用した年月」を表す。

Databaseでは、

    YYYY-MM-01

として保存する。

例：

    2026-08-01

Domainでは年月として扱い、
月初日はPersistence表現とする。

---

## 11. personal_access_tokens

Laravel Sanctum標準Schemaを利用する。

主なColumn：

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

Sanctum標準構造を不必要に変更しない。

---

## 12. Foreign Key Policy

### Business Data

| Parent | Child | ON DELETE |
| --- | --- | --- |
| departments | employees | RESTRICT |
| employees | users | RESTRICT |
| skill_categories | skills | RESTRICT |
| employees | employee_skills | RESTRICT |
| skills | employee_skills | RESTRICT |

### Assignment

| Parent | Child | ON DELETE |
| --- | --- | --- |
| users | sub_manager_assignments | CASCADE |
| employees | sub_manager_assignments | CASCADE |
| users | team_leader_assignments | CASCADE |
| employees | team_leader_assignments | CASCADE |

---

## 13. Soft Delete Policy

Laravel SoftDeletesは原則使用しない。

Master / Business Data：

    is_active = false

Assignment：

    DELETE

で扱う。

Employeeの退職は、

    employment_status = RETIRED
    retirement_date = date

として保持する。

退職後3年経過しても自動削除せず、
管理ユーザーの確認後に削除する。

---

## 14. Migration順序

Foreign Key依存関係を考慮する。

1. create_departments_table
2. create_employees_table
3. create_users_table
4. create_skill_categories_table
5. create_skills_table
6. create_employee_skills_table
7. create_sub_manager_assignments_table
8. create_team_leader_assignments_table
9. create_personal_access_tokens_table

---

## 15. Rollback順序

Migrationの逆順とする。

1. personal_access_tokens
2. team_leader_assignments
3. sub_manager_assignments
4. employee_skills
5. skills
6. skill_categories
7. users
8. employees
9. departments

---

## 16. Initial Index

### departments

    UNIQUE(name)

### employees

    UNIQUE(employee_number)
    INDEX(department_id)
    INDEX(employment_status)

### users

    UNIQUE(employee_id)
    UNIQUE(login_id)
    INDEX(role)

### sub_manager_assignments

    UNIQUE(user_id, employee_id)
    INDEX(employee_id)

### team_leader_assignments

    UNIQUE(user_id, employee_id)
    INDEX(employee_id)

### skill_categories

    UNIQUE(name)

### skills

    UNIQUE(name)
    INDEX(skill_category_id)

### employee_skills

    UNIQUE(employee_id, skill_id)
    INDEX(employee_id)
    INDEX(skill_id)

### personal_access_tokens

Laravel Sanctum標準Indexを利用する。

---

## 17. Additional Index

以下は実際のQuery / EXPLAINを確認してから追加する。

候補：

    employees.retirement_date

    users.can_manage_permissions

    employee_skills.experience_months

    employee_skills.skill_level

    employee_skills.last_used_date

    employee_skills.is_active

MVP段階では必要性のないIndexを大量に作らない。

---

## 18. Seeder

MigrationとInitial Dataは分離する。

Seeder候補：

    DepartmentSeeder

    SkillCategorySeeder

    SkillSeeder

    InitialAdminEmployeeSeeder

    InitialAdminUserSeeder

---

## 19. Initial Administrator

初期構築時に最低1人、

    role = ADMINISTRATOR

    can_manage_permissions = true

のUserを作成する。

Flow：

    Employee作成
        ↓
    User作成
        ↓
    Administrator設定
        ↓
    Permission Manager設定

これにより初期状態から
Permission Manager最低1人Ruleを満たす。

---

## 20. Permission Manager Concurrency

Permission Managerを最低1人維持するRuleは、
単純なCHECK Constraintでは保証できない。

Application LayerでTransactionを利用する。

さらに同時更新競合への対策を行う。

候補：

    PostgreSQL Transaction

        +

    SELECT ... FOR UPDATE

または、

    PostgreSQL Advisory Lock

具体方式はPersistence設計で決定する。

---

## 21. Domainとの対応

### Employee Management

Tables：

    departments
    employees

Aggregate Root：

    Department
    Employee

### Access Control

Tables：

    users
    sub_manager_assignments
    team_leader_assignments

Domain：

    User
    SubManagerAssignment
    TeamLeaderAssignment

### Skill Management

Tables：

    skill_categories
    skills
    employee_skills

Aggregate Root：

    SkillCategory
    Skill
    EmployeeSkill

### Authentication

Tables：

    personal_access_tokens

Domainの中心ではなく、
Laravel SanctumのAuthentication Infrastructureとして扱う。

---

## 22. Database全体構成

    PostgreSQL
    │
    ├── Employee Management
    │   ├── departments
    │   └── employees
    │
    ├── Access Control
    │   ├── users
    │   ├── sub_manager_assignments
    │   └── team_leader_assignments
    │
    ├── Skill Management
    │   ├── skill_categories
    │   ├── skills
    │   └── employee_skills
    │
    └── Authentication / Infrastructure
        └── personal_access_tokens

Database：

    PostgreSQL

Migration：

    Laravel Migration

Source of Truth：

    backend/database/migrations
