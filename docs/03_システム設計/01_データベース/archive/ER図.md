# MVP ER図

## 1. 対象Entity

- users
- departments
- employees
- skill_categories
- skills
- employee_skills

---

## 2. ER Diagram

```mermaid
erDiagram

    DEPARTMENTS ||--o{ EMPLOYEES : has

    EMPLOYEES ||--o| USERS : may_have

    EMPLOYEES ||--o{ EMPLOYEE_SKILLS : has

    SKILL_CATEGORIES ||--o{ SKILLS : contains

    SKILLS ||--o{ EMPLOYEE_SKILLS : assigned_to


    DEPARTMENTS {
        bigint id PK
        varchar name UK
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    EMPLOYEES {
        bigint id PK
        varchar employee_number UK
        varchar name
        bigint department_id FK
        varchar employment_status
        date retirement_date
        timestamp created_at
        timestamp updated_at
    }

    USERS {
        bigint id PK
        bigint employee_id FK,UK
        varchar login_id UK
        varchar password
        varchar name
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    SKILL_CATEGORIES {
        bigint id PK
        varchar name UK
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    SKILLS {
        bigint id PK
        bigint skill_category_id FK
        varchar name UK
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    EMPLOYEE_SKILLS {
        bigint id PK
        bigint employee_id FK
        bigint skill_id FK
        boolean has_work_experience
        integer experience_months
        smallint skill_level
        date last_used_date
        text comment
        text experience_details
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }
