# Database Migration Ownership 決定

## 採用方式

PostgreSQL SchemaのMigration管理は、
すべてLaravel Migrationへ統一する。

## Source of Truth

```text
backend/database/migrations
```

## Laravel Migrationで管理するTable

- departments
- employees
- users
- skill_categories
- skills
- employee_skills
- personal_access_tokens

## Next.js

Next.js側ではDatabase Migration Toolを導入しない。

Next.jsからPostgreSQLへ直接接続しない。

Better Auth SessionおよびBackend CredentialはRedisで管理するため、
PostgreSQL Migrationの対象外とする。

## Seeder

SeederもLaravel側へ統一する。

## 基本方針

- 同一Databaseに複数Migration Systemを持ち込まない
- Local / CI / Stagingで同じMigration手順を利用する
- `php artisan migrate` でDatabase Schemaを構築できる状態を保つ
- PostgreSQL Schema変更はLaravel Migrationのみで管理する
- Better Auth SessionはRedisで管理し、PostgreSQLへSession Tableを作成しない
- Backend CredentialはRedisで管理し、PostgreSQLへCredential Tableを作成しない
