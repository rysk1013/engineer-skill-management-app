# データベース設計

Engineer Skill Management App のPostgreSQL Schema、Entity、Relation、Column、Constraint、Migration、日時、認証用データの設計を管理するディレクトリです。

Database SchemaのSource of TruthはLaravel Migrationです。このディレクトリの文書は、要件・Domain設計とMigration実装の対応を説明し、Schema変更時の判断基準として使用します。

## 基本方針

- DatabaseにはPostgreSQLを使用する
- Primary Keyは原則として`bigint`を使用する
- SchemaとSeederはLaravel側で一元管理する
- Next.js側へ別のMigration Systemを導入しない
- Domain RuleとLaravel Validationに加え、PK、FK、UNIQUE、CHECK Constraintでも整合性を守る
- Foreign Keyの削除・更新は`RESTRICT`を基本とし、CASCADE DELETEとSET NULLは原則使用しない
- Soft Deleteは原則使用せず、業務上の無効化には`is_active`などの状態を使用する
- TimestampはUTCで保存し、PostgreSQLでは`timestamptz`を使用する
- Constraintには意図が分かる明示的な名前を付ける

## Schemaの全体像

```text
Department
    │ 1:N
    ▼
Employee ─────── User ─────── AuthSession
    │               │
    │               ├── SubManagerAssignment ── Employee
    │               └── TeamLeaderAssignment ── Employee
    │
    │ 1:N
    ▼
EmployeeSkill
    ▲
    │ N:1
Skill
    ▲
    │ N:1
SkillCategory
```

Laravel Sanctumの`personal_access_tokens`はInfrastructure Tableとして使用します。Domain中心のER図からは省略しますが、Database Schemaには含まれます。

## Table一覧

| 領域 | Table | 主な役割 |
| --- | --- | --- |
| Employee Management | `departments` | 部署Master |
| Employee Management | `employees` | 社員、所属、在籍状態、退職日 |
| Access Control | `users` | Application利用者、Role、権限管理可否 |
| Access Control | `sub_manager_assignments` | Sub Managerと担当社員のRelation |
| Access Control | `team_leader_assignments` | Team Leaderと担当社員のRelation |
| Skill Management | `skill_categories` | スキル分類Master |
| Skill Management | `skills` | 技術・スキルMaster |
| Skill Management | `employee_skills` | 社員のSkill、Level、実務経験、経験期間、最終利用年月 |
| Authentication | `auth_sessions` | Auth.js Database SessionとSession単位のSanctum Token |
| Infrastructure | `personal_access_tokens` | Laravel Sanctum標準のToken情報 |

## 設計ドキュメント

### 1. Entity

[Entity](./01_Entity.md)では、MVPで管理するEntityとRelation、属性として扱う値、後続Iterationで検討するEntityを整理します。

### 2. ER図

[ER図](./02_ER図.md)では、Employee Management、Skill Management、Access Control、AuthenticationのTable間RelationとDomain Modelとの対応を示します。

### 3. カラム設計

[カラム設計](./03_カラム設計.md)では、各TableのColumn、型、Null許可、Foreign Key、UNIQUE、CHECK、Indexを定義します。

特に次のRuleをDatabaseでも保証します。

- Employee Numberの一意性
- EmployeeとSkillの組み合わせの一意性
- Skill Levelが1〜5の範囲であること
- 実務経験の有無とLevel・経験期間・最終利用年月の整合性
- 在籍状態と退職日の整合性

### 4. PostgreSQLテーブル一覧・Migration

[PostgreSQLテーブル一覧・Migration](./04_PostgreSQLテーブル一覧・Migration.md)では、Table一覧、Constraint、Index、Migration順序、Rollback順序をまとめます。

### 5. Foreign Keyルール

[Foreign Keyルール](./05_Foreign-Keyルール.md)では、Relationごとの削除・更新規則を定義します。Master DataとEmployeeSkillは物理削除より無効化を基本とし、複数Tableを変更する削除処理はLaravel側のTransactionで明示的に実行します。

### 6. Laravel Migration設計

[Laravel Migration設計](./06_Laravel-Migration設計.md)では、Migrationの作成順序、Schema Builder、CHECK Constraint、Index、Enum表現、Seeder、Rollbackを定義します。

- PostgreSQL ENUMではなく、`varchar`または`smallint`とCHECK Constraintを基本とする
- CHECK Constraintは対象TableのMigration内で定義する
- 初期データはMigrationではなくSeederで管理する
- Soft Delete Columnは原則追加しない

### 7. Migration Ownership

[Migration Ownership](./07_Migration-Ownership.md)では、業務Table、Auth.js Session Table、Sanctum TableをLaravel Migrationで一元管理する方針を定義します。

Local、CI、Stagingで同じMigration手順を利用し、`php artisan migrate`でSchemaを構築できる状態を保ちます。

### 8. Date・Time設計

[Date・Time設計](./08_Date・Time設計.md)では、Timestamp、Date、Year Monthを用途ごとに分けて管理します。

| 種類 | Database | API／Frontend |
| --- | --- | --- |
| Timestamp | `timestamptz`、UTC | ISO 8601 UTC、表示時はAsia/Tokyo |
| Date | `date` | `YYYY-MM-DD` |
| Year Month | `date`の月初日 | `YYYY-MM` |

現在日時に依存するValidationはLaravel側で実行し、DatabaseのCHECK Constraintには時間経過に依存しない構造的なRuleだけを定義します。

### 9. Auth.js Sessionテーブル設計

[Auth.js Sessionテーブル設計](./09_Auth.js-Sessionテーブル設計.md)では、`auth_sessions`のColumn、Cookie、期限、Sanctum Token、Login／Logout、複数端末Sessionを定義します。

- BrowserにはSession Cookieだけを保持する
- Sanctum TokenをBrowserへ公開しない
- SessionとSanctum Tokenを1対1で対応させる
- Logout時はAuth.js SessionとSanctum Tokenを両方失効する
- SessionはSoft Deleteせず、失効時に削除する

### 10. Sanctum Token保存方式

[Sanctum Token保存方式](./10_Sanctum-Token保存方式.md)では、MVPでSanctum Tokenを`auth_sessions.sanctum_token`へApplication Level Encryptionして保存する方針を定義します。

複数Backend、Refresh Token、Credential Rotationなどが必要になった場合は、専用Credential Tableへの分離を再検討します。

## Source of Truthと責務

| 対象 | Source of Truth／責務 |
| --- | --- |
| 業務要件 | [要件定義](../../01_要件定義/README.md) |
| AggregateとDomain Rule | [Laravel DDD設計](../../02_アーキテクチャ/01_Backend/DDD設計/README.md) |
| Database Schema | Laravel Migration |
| API上のData Format | OpenAPI |
| MigrationとSeederの実行・管理 | Laravel Backend |
| Auth.js Sessionの利用 | Next.js BFF |

## Schema変更フロー

```text
要件 / Domain Ruleの変更
          ↓
ER図・カラム・Constraint設計の更新
          ↓
Laravel Migrationの追加
          ↓
PostgreSQL Integration Test
          ↓
API / Application / Documentationの整合性確認
```

既存Migrationを安易に書き換えず、共有環境へ適用済みのSchema変更は新しいMigrationとして追加します。

## 推奨する読み順

1. [Entity](./01_Entity.md)と[ER図](./02_ER図.md)で、管理対象とRelationを把握する。
2. [カラム設計](./03_カラム設計.md)で、Columnと業務Constraintを確認する。
3. [PostgreSQLテーブル一覧・Migration](./04_PostgreSQLテーブル一覧・Migration.md)と[Foreign Keyルール](./05_Foreign-Keyルール.md)で、Schema全体と削除・更新規則を確認する。
4. [Laravel Migration設計](./06_Laravel-Migration設計.md)と[Migration Ownership](./07_Migration-Ownership.md)で、Schemaの実装・管理方法を確認する。
5. [Date・Time設計](./08_Date・Time設計.md)で、外部表現を含む日時Ruleを確認する。
6. 認証を実装するときは、Auth.js SessionとSanctum Tokenの設計を確認する。

## 文書管理ルール

- Schemaを変更した場合は、ER図、カラム設計、Migration設計を合わせて更新します。
- Domain RuleをConstraintへ反映するときは、Laravel ValidationとDomain Invariantとの責務分担を明記します。
- ConstraintとIndexには、目的が分かる明示的な名前を付けます。
- Migrationを追加した場合は、Rollbackと実PostgreSQLでのIntegration Testを確認します。
- 過去の設計は上書きせず、[`archive/`](./archive/)へ保管します。
