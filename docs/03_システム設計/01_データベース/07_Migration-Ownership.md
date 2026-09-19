# Database Migration Ownership 決定

## 採用方式

PostgreSQL SchemaのMigration管理は、
すべてLaravel Migrationへ統一する。

## Source of Truth

    backend/database/migrations

## Laravel Migrationで管理するTable

- departments
- employees
- users
- skill_categories
- skills
- employee_skills
- auth_sessions
- personal_access_tokens

## Next.js

Next.js側ではMVP時点でDatabase Migration Toolを導入しない。

Auth.jsは`auth_sessions`を利用するが、
Schema変更自体はLaravel Migrationで管理する。

## Seeder

SeederもLaravel側へ統一する。

## 基本方針

- 同一Databaseに複数Migration Systemを持ち込まない
- Local / CI / Stagingで同じMigration手順を利用する
- `php artisan migrate` でDatabase Schemaを構築できる状態を保つ
- Auth.js都合のSchema変更もLaravel Migrationとして追加する
