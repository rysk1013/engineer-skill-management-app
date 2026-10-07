# API・OpenAPI

## 1. 基本方針

Frontend / BFF と Backend API の通信には HTTP API を利用する。

基本構成は以下とする。

```text
Browser
   ↓
Next.js
Frontend / BFF
   ↓ HTTP API
Laravel
Backend API
```

Frontend / Backend 間の API Contract は OpenAPI で管理する。

本プロジェクトでは **OpenAPI First** を採用する。

```text
OpenAPI
   ↓
Frontend
   +
Backend
```

OpenAPI を API Contract の Source of Truth とする。

---

## 2. OpenAPI First

API を変更する場合は、原則として実装より先に OpenAPI を変更する。

基本フロー：

```text
API Requirement
   ↓
OpenAPI Change
   ↓
Review
   ↓
Frontend / Backend 反映
   ↓
Implementation
   ↓
Test
```

Laravel の Controller や Route 定義から OpenAPI を生成する Code First 方式は採用しない。

採用：

```text
OpenAPI
   ↓
Laravel Implementation
```

採用しない：

```text
Laravel Implementation
   ↓
OpenAPI Generation
```

これにより API Contract と Framework 実装を分離する。

---

## 3. OpenAPI の責務

OpenAPI では主に以下を定義する。

- Endpoint
- HTTP Method
- Path Parameter
- Query Parameter
- Request Body
- Response Body
- HTTP Status
- Schema
- Validation Constraint
- Error Response
- Authentication Requirement

OpenAPI には Frontend / Backend 間で共有すべき Contract を記述する。

一方で以下は OpenAPI の責務としない。

- Domain Logic
- Database Schema
- Laravel 内部構造
- Next.js 内部構造
- Repository
- Application Handler
- UI Logic

---

## 4. 採用ツール

### OpenAPI Lint / Bundle

- [x] Redocly CLI
- [ ] Spectral

### TypeScript 型生成

- [x] openapi-typescript
- [ ] OpenAPI Generator

### Contract 検証

- [x] CI で OpenAPI Lint / Bundle / Type Generation を実行する
- [ ] MVP で専用 Contract Testing Tool を追加する

---

## 5. Redocly CLI

OpenAPI Specification の Lint と Bundle に Redocly CLI を利用する。

主な用途：

- OpenAPI Lint
- `$ref` 検証
- Schema 構造確認
- API Design Rule のチェック
- 複数 File の Bundle
- OpenAPI Specification の Validation

基本フロー：

```text
openapi/openapi.yaml
   ├── Redocly Lint
   │
   └── Redocly Bundle
          ↓
       dist/openapi.yaml
```

---

## 6. Redocly CLI を採用する理由

Redocly CLI は今回必要となる以下の機能を1つの Tool で扱える。

```text
Redocly CLI
├── Lint
└── Bundle
```

Tool を増やしすぎず OpenAPI 管理に必要な基本機能を揃えられるため採用する。

---

## 7. Spectral を MVP で採用しない理由

Spectral も OpenAPI Linter として有力な選択肢である。

主な特徴：

- OpenAPI 対応
- Custom Rule を作成可能
- API Governance / Style Guide に適している

ただし MVP では、

```text
Redocly CLI
├── Lint
└── Bundle
```

で必要な機能を満たせるため、Redocly CLI に統一する。

将来的に高度な API Governance Rule が必要になった場合は Spectral の導入を再検討する。

---

## 8. OpenAPI File 構成

OpenAPI Specification はリポジトリルートの `openapi/` で管理する。

基本構成：

```text
openapi/
├── openapi.yaml
├── redocly.yaml
├── package.json
├── pnpm-lock.yaml
├── Dockerfile
│
├── paths/
│
├── components/
│   ├── schemas/
│   ├── parameters/
│   ├── responses/
│   └── security-schemes/
│
└── dist/
    └── openapi.yaml
```

`openapi/openapi.yaml` を OpenAPI Specification のエントリーポイントとする。

API Contract の Source of Truth は `openapi/openapi.yaml` と、そこから `$ref` される File 群とする。

`paths/` は Endpoint 定義、`components/` は複数 API から再利用する Schema、Parameter、Response、Security Scheme 等を管理する。

具体的な File 分割単位は API 設計の規模に応じて調整する。

過度に細かい File 分割は行わない。

---

## 9. Bundle

開発時は必要に応じて OpenAPI Specification を複数 File に分割し、Tool 連携や単一 File が必要な用途向けに Bundle を生成する。

Input：

```text
openapi/openapi.yaml
```

Output：

```text
openapi/dist/openapi.yaml
```

`dist/openapi.yaml` は Redocly CLI による生成物として扱う。

`openapi/dist/` は Git 管理しない。

Bundle File を直接編集しない。

---

## 10. TypeScript 型生成

Next.js 向け TypeScript 型生成には `openapi-typescript` を採用する。

TypeScript 型は OpenAPI の Source of Truth から生成する。

```text
openapi/openapi.yaml
   ↓
openapi-typescript
   ↓
frontend/src/lib/api/generated/schema.d.ts
```

Bundle File を TypeScript 型生成の必須 Input とはしない。

Bundle と TypeScript 型は、それぞれ OpenAPI Specification から生成される独立した Artifact として扱う。

```text
                    ┌── Redocly Bundle
                    │       ↓
openapi.yaml ───────┤   dist/openapi.yaml
                    │
                    └── openapi-typescript
                            ↓
                    frontend/src/lib/api/generated/schema.d.ts
```

生成対象には以下を含む。

- Path
- Operation
- Request
- Response
- Schema
- Error Response

OpenAPI 上の型を Frontend で再定義しない。

---

## 11. openapi-typescript を採用する理由

今回必要なのは、

```text
OpenAPI
   ↓
TypeScript Types
```

である。

API Client 全体を大量に自動生成する構成は採用しない。

`openapi-typescript` は OpenAPI Schema から TypeScript 型を生成することに特化しており、今回の方針と一致する。

---

## 12. API Client

Laravel API を呼び出す API Client は Next.js BFF 側で薄く実装する。

概念例：

```text
frontend/
└── src/
    └── lib/
        └── api/
            ├── client.ts
            ├── employees.ts
            ├── employee-skills.ts
            ├── skills.ts
            └── skill-categories.ts
```

具体的な Directory は Frontend Architecture に従う。

共通 Client は主に以下を担当する。

- Base URL
- Authorization Header
- Sanctum Token 付与
- HTTP Header
- Request
- Response Parse
- Error Handling
- Timeout
- 共通 HTTP 処理

Domain Logic や UI Logic を API Client に持たせない。

---

## 13. API Client と Generated Type

API Client では `openapi-typescript` から生成した型を利用する。

```text
OpenAPI
   ↓
Generated Type
   ↓
Custom API Client
   ↓
Laravel API
```

Request / Response Type を手書きで重複定義しない。

Frontend 独自の View Model や Form Model が必要な場合は、API Contract Type とは別の責務として定義する。

---

## 14. Generated Code

生成された File は直接編集しない。

TypeScript 型の生成先：

```text
frontend/
└── src/
    └── lib/
        └── api/
            └── generated/
                └── schema.d.ts
```

変更フロー：

```text
OpenAPI Change
   ↓
Lint
   ↓
Bundle / Type Generation
```

Generated File を修正する必要がある場合は、生成元である OpenAPI を変更する。

### Git 管理

以下の方針とする。

```text
openapi/dist/
→ Git 管理しない

frontend/src/lib/api/generated/schema.d.ts
→ Git 管理する
```

Bundle は中間生成物として必要時に再生成する。

TypeScript Generated Type は Frontend が直接利用し、OpenAPI 変更時の型差分を Review できるよう Git 管理する。

---

## 15. API Request 経路

Browser から Laravel API を直接呼び出す構成を基本としない。

採用：

```text
Browser
   ↓
Next.js
   ↓
Laravel API
```

採用しない：

```text
Browser
   ↓
Laravel API
```

Laravel API Client は Next.js Server / BFF 側に配置することを基本とする。

Sanctum Token は Browser へ公開しない。

---

## 16. Authentication

Next.js BFF → Laravel API 間では Laravel Sanctum を利用する。

```text
Next.js BFF
   ↓
Authorization: Bearer ...
   ↓
Laravel API
```

Authentication の詳細は `03_認証方式.md` で管理する。

OpenAPI では Endpoint ごとの Authentication Requirement を定義する。

Credential の保存方法や Token Lifecycle は OpenAPI の責務としない。

---

## 17. HTTP Method

Resource と操作の意味に応じて HTTP Method を選択する。

基本方針：

| Method | 用途 |
|---|---|
| GET | 取得 |
| POST | 作成・Command |
| PUT | Resource 全体の更新 |
| PATCH | 部分更新 |
| DELETE | 削除・無効化 API |

ただし Domain 上の操作が単純な CRUD として自然に表現できない場合は、操作の意味を優先した Endpoint 設計を許可する。

HTTP Method の形式に Domain Model を無理に合わせない。

---

## 18. HTTP Status

HTTP Status は API Contract の一部として OpenAPI に定義する。

基本的には標準 HTTP Status を利用する。

例：

```text
200 OK
201 Created
204 No Content

400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
422 Unprocessable Content

500 Internal Server Error
```

具体的な利用ルールは Backend の HTTP / API 方針に従う。

独自 Status Code は作成しない。

---

## 19. Error Response

Error Response は Frontend / Backend 間で共通の形式を定義する。

OpenAPI に Error Schema を定義する。

対象例：

- Validation Error
- Authentication Error
- Authorization Error
- Resource Not Found
- Conflict
- Domain / Business Rule Violation
- Internal Server Error

概念：

```text
Laravel Exception
   ↓
HTTP Error Response
   ↓
OpenAPI Error Schema
   ↓
Next.js
```

Laravel の Exception Class 名や Stack Trace を API Contract に公開しない。

---

## 20. Pagination

一覧 API で Pagination が必要な場合は、API 間で形式を統一する。

OpenAPI で以下を明示する。

- Request Parameter
- Items
- Current Position
- Total
- Next / Previous に必要な情報

Offset / Cursor 等の具体方式は API の要件に応じて決定する。

方式を無目的に混在させない。

---

## 21. Search / Filter / Sort

検索 API では Query Parameter を利用することを基本とする。

例：

```text
GET /employees?department_id=1
GET /employees?keyword=php
GET /skills?category_id=2
```

複数 Skill 条件など複雑な検索について、Query Parameter で表現が不自然になる場合は Search Endpoint を利用することを許可する。

API の読みやすさと拡張性を優先する。

具体的な Search API は API 設計で決定する。

---

## 22. Versioning

MVP では API Versioning を過度に複雑化しない。

API の互換性を壊す変更は OpenAPI Review で明示的に確認する。

外部公開 API ではなく Frontend / Backend を同一 monorepo で管理するため、初期段階では独立した複数 Version を同時運用することを前提としない。

将来的に外部 Consumer や Independent Deployment Requirement が発生した場合は Versioning 方針を再検討する。

---

## 23. OpenAPI Lint

OpenAPI 変更時は Lint を必須とする。

Redocly CLI の `recommended` Rule Set を基本として利用する。

Project の性質に適合しない Rule は理由を明確にしたうえで設定を調整する。

確認対象：

- OpenAPI Syntax
- `$ref`
- Schema
- Required Property
- Endpoint
- HTTP Method
- Request
- Response
- Naming Rule
- Security Scheme
- その他 API Design Rule

不正な OpenAPI を Main Branch へ Merge しない。

---

## 24. OpenAPI 開発コマンド

OpenAPI Tooling は `openapi/package.json` で管理する。

Package Manager には pnpm を利用する。

基本コマンド：

```bash
pnpm run lint
pnpm run bundle
pnpm run generate:types
pnpm run generate
pnpm run check
```

責務：

```text
pnpm run lint
└── OpenAPI Lint

pnpm run bundle
└── OpenAPI Bundle

pnpm run generate:types
└── TypeScript Type Generation

pnpm run generate
├── Bundle
└── TypeScript Type Generation

pnpm run check
├── Lint
└── Generate
    ├── Bundle
    └── TypeScript Type Generation
```

開発者および CI が OpenAPI 全体を検証する際は、原則として `pnpm run check` を利用する。

---

## 25. CI

Pull Request 時に OpenAPI 関連 Check を実行する。

基本フロー：

```text
OpenAPI Lint
   ↓
OpenAPI Bundle
   ↓
TypeScript Type Generation
   ↓
Generated File Difference Check
```

OpenAPI が不正な場合は CI を Failure とする。

---

## 26. Generated File の差分確認

OpenAPI を変更したにもかかわらず Generated Type を更新し忘れる状態を防止する。

基本構成：

```text
Type Generation
   ↓
git diff --exit-code
```

CI 内で TypeScript 型を再生成し、Repository 内の Generated File と差分がある場合は Failure とする。

`frontend/src/lib/api/generated/schema.d.ts` は Git 管理対象とする。

`openapi/dist/` は Git 管理対象としないため、Bundle の差分確認対象とはしない。

---

## 27. Contract 検証

MVP では専用 Contract Testing Tool を追加しない。

まず以下を組み合わせて Contract 品質を保証する。

- OpenAPI Lint
- OpenAPI Type Generation
- Laravel Feature Test
- Frontend Integration Test
- Frontend / Backend Integration Test
- E2E Test

専用 Contract Testing Tool は、実際に必要性が確認された場合に追加する。

---

## 28. Laravel と OpenAPI の整合性

Laravel Feature Test では主に以下を確認する。

- HTTP Status
- Response Structure
- Validation Error
- Authentication Error
- Authorization Error
- Domain Error
- Boundary Value

Implementation は OpenAPI Contract と一致させる。

ただし Laravel Feature Test だけで OpenAPI との機械的な完全一致を保証しているとは扱わない。

MVP では Test と Review を組み合わせて Contract Drift を防止する。

---

## 29. Frontend と OpenAPI の整合性

Frontend は OpenAPI から生成した TypeScript Type を利用する。

```text
OpenAPI
   ↓
Generated Type
   ↓
Next.js API Client
   ↓
Frontend / BFF
```

これにより Frontend で Request / Response Type を独自に重複定義することを防ぐ。

API Contract 変更時には Type Error を利用して影響箇所を発見できる構成とする。

---

## 30. API Documentation

OpenAPI 自体を API Specification の Source of Truth とする。

MVP では API Documentation 専用 Service の導入を必須としない。

必要になった場合は OpenAPI から API Reference を生成する。

Documentation を実装から手書きで二重管理しない。

---

## 31. Docker

OpenAPI Tooling は専用の `openapi` Container で実行する。

構成：

```text
Docker Compose
├── frontend
│   └── Next.js Frontend / BFF
├── backend
│   └── Laravel Backend API
├── db
│   └── PostgreSQL
└── openapi
    ├── Redocly CLI
    └── openapi-typescript
```

OpenAPI Container は開発 Server として常駐させず、必要な処理を実行する一時 Container として利用する。

OpenAPI 全体の検証：

```bash
docker compose run --rm openapi pnpm run check
```

個別実行：

```bash
docker compose run --rm openapi pnpm run lint
docker compose run --rm openapi pnpm run bundle
docker compose run --rm openapi pnpm run generate:types
```

OpenAPI Specification は Frontend 固有 Artifact ではなく、Frontend / Backend 共有の Contract として扱う。

OpenAPI Tooling の Node.js Dependency は `openapi/package.json` で管理し、Frontend の Dependency とは分離する。

---

## 32. Tool の責務

| 目的 | Tool |
|---|---|
| API Contract | OpenAPI |
| OpenAPI Lint | Redocly CLI |
| OpenAPI Bundle | Redocly CLI |
| TypeScript 型生成 | openapi-typescript |
| API Client | Next.js 側で薄く実装 |
| Backend API Test | Laravel Feature Test |
| Frontend / Backend Integration | Integration Test |
| E2E | Playwright |

---

## 33. 採用しない構成・Tool

### Code First OpenAPI

Laravel Implementation から OpenAPI を生成する方式は採用しない。

OpenAPI First とする。

### Spectral

MVP では採用しない。

Redocly CLI で Lint / Bundle を統一する。

高度な API Governance が必要になった場合に再検討する。

### OpenAPI Generator

MVP では採用しない。

API Client 全体を自動生成せず、TypeScript 型のみ生成する。

### 専用 Contract Testing Tool

MVP では採用しない。

既存 Test で不足が確認された場合に追加する。

### Browser → Laravel Direct Access

Browser から Laravel API を直接利用する構成を基本としない。

Next.js BFF を経由する。

### Laravel から OpenAPI を自動生成

OpenAPI を Implementation の副産物として扱わない。

OpenAPI を API Contract の Source of Truth とする。

---

## 34. 技術選定と詳細設計の境界

本ドキュメントでは以下を管理する。

- OpenAPI First
- API Contract
- OpenAPI Tool
- Type Generation
- API Client 基本方針
- Lint / Bundle
- CI
- Contract Validation の基本方針

以下は API 詳細設計で管理する。

- Endpoint 一覧
- Resource Path
- Request / Response Schema
- Pagination 形式
- Search Parameter
- Error Code
- HTTP Status の具体的対応
- Individual Endpoint Security
- Schema Naming
- API Naming Rule
- OpenAPI File の詳細分割

---

## 35. 関連ドキュメント

### `01_アプリケーション構成.md`

以下を管理する。

- Frontend / Backend Boundary
- Next.js BFF
- Laravel Backend API
- API による連携

### `02_データベース.md`

以下を管理する。

- PostgreSQL
- Data Ownership
- Database Access

### `03_認証方式.md`

以下を管理する。

- Better Auth
- Redis Session Store
- Laravel Sanctum
- BFF Authentication
- Credential Management

### Frontend 技術選定

以下を管理する。

- API Client 実装
- Generated Type
- Data Fetching
- Error Handling

### Backend 技術選定

以下を管理する。

- HTTP
- Validation
- Laravel API
- Exception / Error Response
- Test

---

## 36. 決定事項

### API Architecture

```text
Browser
   ↓
Next.js Frontend / BFF
   ↓
Laravel Backend API
```

Frontend / Backend は HTTP API で通信する。

### API Contract

**OpenAPI First を採用する。**

```text
OpenAPI
├── Frontend Contract
└── Backend Contract
```

OpenAPI を Source of Truth とする。

### OpenAPI 管理

OpenAPI Specification はリポジトリルートの `openapi/` で管理する。

`openapi/openapi.yaml` とそこから参照される File 群を Source of Truth とする。

### OpenAPI Lint

**Redocly CLI を採用する。**

### OpenAPI Bundle

**Redocly CLI を採用する。**

Bundle は `openapi/dist/openapi.yaml` へ生成し、Git 管理しない。

### TypeScript Type Generation

**openapi-typescript を採用する。**

生成先：

```text
frontend/src/lib/api/generated/schema.d.ts
```

Generated Type は Git 管理する。

### API Client

**Next.js BFF 側で薄く実装する。**

API Client 全体の自動生成は行わない。

### OpenAPI Tooling

OpenAPI Tooling の Dependency は `openapi/package.json` で管理する。

Package Manager には pnpm を利用し、`openapi/pnpm-lock.yaml` を Git 管理する。

Docker では専用の `openapi` Containerを利用する。

基本的な検証コマンド：

```bash
docker compose run --rm openapi pnpm run check
```

### Contract Validation

MVP では専用 Contract Testing Tool を導入しない。

以下を組み合わせる。

```text
OpenAPI Lint
+
Type Generation
+
Laravel Feature Test
+
Integration Test
+
E2E Test
```

### CI

以下を実行する。

```text
OpenAPI
   ├── Redocly Lint
   ├── Redocly Bundle
   └── openapi-typescript
          ↓
       Generated Type
          ↓
       Difference Check
```

### 採用しないもの

- Code First OpenAPI
- Laravel からの OpenAPI 自動生成
- Spectral
- OpenAPI Generator
- MVP での専用 Contract Testing Tool
- Browser → Laravel API の直接アクセス

以上を API / OpenAPI の基本方針として採用する。
