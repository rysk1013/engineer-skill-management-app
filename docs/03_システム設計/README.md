# システム設計

Engineer Skill Management App のデータベース、認証・認可、Backend APIに関する具体的な設計を管理するディレクトリです。

ここでは、要件とアーキテクチャ方針を、テーブル、認証フロー、API契約などの実装可能な設計へ落とし込みます。上位方針は[`02_アーキテクチャ`](../02_アーキテクチャ/README.md)、採用製品やツールは[`04_技術選定`](../04_技術選定/README.md)を参照してください。

## システム構成

```text
Browser
   │ Auth.js Session Cookie
   ▼
Next.js Frontend / BFF
   │ Sanctum Bearer Token
   ▼
Laravel Backend API
   │
   ▼
PostgreSQL
```

- BrowserとNext.jsの間では、Auth.jsのSession Cookieを使用します。
- Next.js BFFとLaravel Backend APIの間では、Laravel SanctumのTokenを使用します。
- Laravel用TokenはBrowserへ公開せず、Next.js BFFを経由してAPIへアクセスします。
- PostgreSQLは業務データに加え、Auth.js SessionとSanctum Tokenに関するデータも保持します。

## ディレクトリ構成

| ディレクトリ | 内容 |
| --- | --- |
| [`01_データベース`](./01_データベース/README.md) | Entity、ER図、カラム、制約、Migration、日時、Session・Tokenの保存方式を管理します。 |
| [`02_認証・認可`](./02_認証・認可/README.md) | Browser、Next.js、Laravel間の認証フローと責務を管理します。 |
| [`03_API`](./03_API/README.md) | OpenAPI FirstによるAPI仕様と運用方法を管理します。 |

## データベース設計

MVPの主要EntityとPostgreSQL上のSchemaを定義します。Database SchemaはLaravel MigrationをSource of Truthとし、Next.js側ではMigrationを管理しません。

1. [Entity](./01_データベース/01_Entity.md) — MVPで扱うEntityとRelation
2. [ER図](./01_データベース/02_ER図.md) — Entity間の関係
3. [カラム設計](./01_データベース/03_カラム設計.md) — TableごとのColumn定義
4. [PostgreSQLテーブル一覧・Migration](./01_データベース/04_PostgreSQLテーブル一覧・Migration.md) — Table一覧、制約、Migration順序
5. [Foreign Keyルール](./01_データベース/05_Foreign-Keyルール.md) — 参照整合性と削除・更新ルール
6. [Laravel Migration設計](./01_データベース/06_Laravel-Migration設計.md) — Migrationの実装方針
7. [Migration Ownership](./01_データベース/07_Migration-Ownership.md) — Schema変更の責務
8. [Date・Time設計](./01_データベース/08_Date・Time設計.md) — 日時、日付、年月、Timezoneの扱い
9. [Auth.js Sessionテーブル設計](./01_データベース/09_Auth.js-Sessionテーブル設計.md) — Next.js Sessionの永続化
10. [Sanctum Token保存方式](./01_データベース/10_Sanctum-Token保存方式.md) — Laravel API Tokenの保存方法

過去のER図やMigration設計は[`archive/`](./01_データベース/archive/)に保管します。

## 認証・認可設計

- [認証全体設計](./02_認証・認可/01_認証全体設計.md) — Browser、Next.js BFF、Laravel Backend API間の認証境界
- [Next.js・Auth.js設計](./02_認証・認可/02_Next.js-Auth.js設計.md) — Sessionの作成、取得、更新、失効、Cookie管理
- [Laravel・Sanctum設計](./02_認証・認可/03_Laravel-Sanctum設計.md) — Backend APIのToken認証

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

## Source of Truth

| 対象 | Source of Truth |
| --- | --- |
| 業務要件 | [`01_要件定義`](../01_要件定義/README.md) |
| Backend API契約 | OpenAPI |
| Database Schema | Laravel Migration |
| Domain RuleとLayer境界 | [`02_アーキテクチャ`](../02_アーキテクチャ/README.md) |

## 推奨する読み順

1. [認証全体設計](./02_認証・認可/01_認証全体設計.md)で、システム間の境界と通信方式を把握する。
2. [Entity](./01_データベース/01_Entity.md)と[ER図](./01_データベース/02_ER図.md)で、管理対象とRelationを確認する。
3. カラム、制約、Migration、日時設計を番号順に確認する。
4. Auth.jsとSanctumの設計、およびSession・Tokenの保存方式を確認する。
5. API仕様管理とOpenAPI運用方式を確認する。

## 文書管理ルール

- 要件変更時は、影響するDatabase Schema、認証フロー、API契約を確認します。
- API契約を変更する場合は、OpenAPIを先に更新し、Next.jsとLaravelの実装・Testへ反映します。
- Database Schemaを変更する場合は、Laravel Migrationと関連するER図・カラム設計を更新します。
- 認証方式を変更する場合は、認証設計、Session・Tokenの保存方式、関連するArchitecture Decisionを合わせて更新します。
- 旧設計は内容を上書きせず、該当する`archive/`へ移動します。
