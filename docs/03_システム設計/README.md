# システム設計

Engineer Skill Management App のデータベース、認証・認可、Backend APIに関する具体的な設計を管理するディレクトリです。

ここでは、要件とアーキテクチャ方針を、テーブル、認証フロー、API契約などの実装可能な設計へ落とし込みます。上位方針は[`02_アーキテクチャ`](../02_アーキテクチャ/README.md)、採用製品やツールは[`04_技術選定`](../04_技術選定/README.md)を参照してください。

## システム構成

```text
Browser
   │ Better Auth Session Cookie
   ▼
Next.js Frontend / BFF
   │ Sanctum Bearer Token
   ▼
Laravel Backend API
   │
   ▼
PostgreSQL
```

SessionとBackend Credentialは次のように管理します。

```text
Next.js Frontend / BFF
   │
   ├── Better Auth Session
   │       ↓
   │     Redis
   │     better-auth:*
   │
   └── Backend Credential
           ↓
         Redis
         backend-credential:*
```

- BrowserとNext.jsの間では、Better AuthのSession Cookieを使用します。
- Application User AuthenticationはLaravel Backendが担当します。
- Next.js BFFとLaravel Backend APIの間では、Laravel SanctumのPersonal Access Tokenを使用します。
- Laravel用TokenはBrowserへ公開せず、Next.js BFFを経由してAPIへアクセスします。
- Better Auth SessionとBackend CredentialはRedisで管理します。
- Next.jsからPostgreSQLへ直接接続しません。
- PostgreSQLはLaravel Backendが所有するApplication DataとLaravel SanctumのAuthentication Infrastructureを保持します。

## ディレクトリ構成

| ディレクトリ | 内容 |
| --- | --- |
| [`01_データベース`](./01_データベース/README.md) | Entity、ER図、カラム、制約、Migration、日時、PostgreSQLの責務を管理します。 |
| [`02_認証・認可`](./02_認証・認可/README.md) | Browser、Next.js、Redis、Laravel間の認証・認可Flowと責務を管理します。 |
| [`03_API`](./03_API/README.md) | OpenAPI FirstによるAPI仕様と運用方法を管理します。 |

## データベース設計

MVPの主要EntityとPostgreSQL上のSchemaを定義します。

Database SchemaはLaravel MigrationをSource of Truthとし、Next.js側ではMigrationを管理しません。Next.jsからPostgreSQLへ直接接続しません。

1. [Entity](./01_データベース/01_Entity.md) — MVPで扱うEntityとRelation
2. [ER図](./01_データベース/02_ER図.md) — Entity間の関係
3. [カラム設計](./01_データベース/03_カラム設計.md) — TableごとのColumn定義
4. [PostgreSQLテーブル一覧・Migration](./01_データベース/04_PostgreSQLテーブル一覧・Migration.md) — Table一覧、制約、Migration順序
5. [Foreign Keyルール](./01_データベース/05_Foreign-Keyルール.md) — 参照整合性と削除・更新ルール
6. [Laravel Migration設計](./01_データベース/06_Laravel-Migration設計.md) — Migrationの実装方針
7. [Migration Ownership](./01_データベース/07_Migration-Ownership.md) — Schema変更の責務
8. [Date・Time設計](./01_データベース/08_Date・Time設計.md) — 日時、日付、年月、Timezoneの扱い

Better Auth SessionとBackend CredentialはRedisで管理するため、PostgreSQL Schemaには含めません。

Laravel Sanctumの`personal_access_tokens`はLaravel側のAuthentication InfrastructureとしてPostgreSQLで管理します。

過去のER図やMigration設計は[`archive/`](./01_データベース/archive/)に保管します。

## 認証・認可設計

- [認証全体設計](./02_認証・認可/01_認証全体設計.md) — Browser、Next.js BFF、Laravel Backend API間のAuthentication／Authorization Boundary
- [Next.js Better Auth Session管理 設計](./02_認証・認可/02_Next.js-Better-Auth設計.md) — Better Auth Session、Redis、Backend Credential、Cookie、Lifecycle
- [Laravel・Sanctum設計](./02_認証・認可/03_Laravel-Sanctum設計.md) — Application User AuthenticationとBackend API Authentication

認証・Session管理の基本的な責務は次のとおりです。

```text
Browser
   │ Better Auth Session Cookie
   ▼
Next.js / Better Auth
   │
   ├── Better Auth Session
   │       ↓
   │     Redis
   │
   └── Backend Credential
           ↓
         Redis
           │
           ▼
   Laravel Backend API
```

Application User AuthenticationとSanctum Token発行・検証・失効はLaravelが担当します。

Browser Session ManagementはBetter Authが担当します。

業務上の最終的なAuthorizationはLaravel Backend APIで行います。

認可のDomain RuleとApplication・Presentation Layerでの適用方法は、アーキテクチャ文書の[Authorization](../02_アーキテクチャ/01_Backend/Laravel/05_Presentation%20Layer設計.md)および[Access Control設計](../02_アーキテクチャ/01_Backend/DDD設計/10_Access-Control設計.md)も参照してください。

## API設計

- [API仕様管理](./03_API/01_API仕様管理.md) — OpenAPI FirstとAPI契約のSource of Truth
- [OpenAPI運用方式](./03_API/02_OpenAPI運用方式.md) — ファイル分割、型生成、変更フロー

Backend APIの契約はOpenAPIをSource of Truthとし、Next.js BFFとLaravel Backend APIの双方が同じ仕様に従います。

```text
User Story / Acceptance Criteria
              ↓
         OpenAPI変更
              ↓
           Review
              ↓
   Next.js BFF / Laravel API
              ↓
             Test
```

BrowserからLaravel Backend APIを直接呼び出さず、Next.js BFFを経由します。

Next.js BFFはBetter Auth Sessionを確認し、Sessionに対応するBackend Credentialを利用してLaravel Backend APIを呼び出します。

## Source of Truth

| 対象 | Source of Truth |
| --- | --- |
| 業務要件 | [`01_要件定義`](../01_要件定義/README.md) |
| Backend API契約 | OpenAPI |
| Database Schema | Laravel Migration |
| Application User Authentication | Laravel Backend |
| Browser Session Management | Better Auth |
| Better Auth Session Store | Redis |
| Backend Credential Store | Redis |
| Backend API Authentication | Laravel Sanctum |
| Domain RuleとLayer境界 | [`02_アーキテクチャ`](../02_アーキテクチャ/README.md) |
| 業務上の最終Authorization | Laravel Backend |

## 推奨する読み順

1. [認証全体設計](./02_認証・認可/01_認証全体設計.md)で、システム間のTrust Boundaryと通信方式を把握する。
2. [Entity](./01_データベース/01_Entity.md)と[ER図](./01_データベース/02_ER図.md)で、管理対象とRelationを確認する。
3. カラム、制約、Migration、日時設計を番号順に確認する。
4. [Next.js Better Auth Session管理 設計](./02_認証・認可/02_Next.js-Better-Auth設計.md)と[Laravel・Sanctum設計](./02_認証・認可/03_Laravel-Sanctum設計.md)で、Session、Redis、Backend Credential、Sanctum Tokenの設計を確認する。
5. API仕様管理とOpenAPI運用方式を確認する。

## 文書管理ルール

- 要件変更時は、影響するDatabase Schema、認証・認可Flow、API契約を確認します。
- API契約を変更する場合は、OpenAPIを先に更新し、Next.jsとLaravelの実装・Testへ反映します。
- Database Schemaを変更する場合は、Laravel Migrationと関連するER図・カラム設計を更新します。
- 認証方式を変更する場合は、認証設計、Better Auth Session、Backend Credential、Sanctum Token、関連するArchitecture Decisionを合わせて更新します。
- Better Auth SessionまたはBackend Credentialの保存方式を変更する場合は、Redis構成、Namespace、ACL、TTL、暗号化、Lifecycleへの影響を確認します。
- PostgreSQLとの責務境界を変更する場合は、Database設計とMigration Ownershipを合わせて更新します。
- 旧設計は内容を上書きせず、該当する`archive/`へ移動します。
