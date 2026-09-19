# 技術選定

Engineer Skill Management App で採用する技術、Tool、Application 構成と、その判断理由を管理する Directory です。

この Directory では主に、

> **何を採用するか**
>
> **なぜ採用するか**

を記録します。

採用した技術をどのような責務・依存関係で構成するかについては [`02_アーキテクチャ`](../02_アーキテクチャ/README.md)、Database・Authentication・API などの具体的な設計については [`03_システム設計`](../03_システム設計/README.md) を参照してください。

---

## 1. 全体構成

本システムでは Frontend / Backend 分離構成を採用する。

```text
Browser
   ↓
Next.js
Frontend / BFF
   ↓
Laravel
Backend API
   ↓
PostgreSQL
```

Frontend と Backend は独立した Application として扱うが、Source Code は1つの Git Repository で管理する。

```text
Monorepo
├── Frontend / BFF
│   └── Next.js
│
└── Backend API
    └── Laravel
```

主な構成方針：

- Frontend / BFF には Next.js を採用する
- Backend API には Laravel を採用する
- Database には PostgreSQL を採用する
- Browser Authentication には Auth.js を採用する
- Next.js → Laravel API 間の Authentication には Laravel Sanctum を採用する
- Frontend / Backend 間の API Contract は OpenAPI で管理する
- OpenAPI First を採用する
- Local Development Environment は Docker を利用する
- Frontend / Backend 固有の Tool 選定はそれぞれ専用 Directory で管理する

---

## 2. 技術選定 Directory

```text
04_技術選定/
├── Backend/
├── Frontend/
├── 01_アプリケーション構成.md
├── 02_データベース.md
├── 03_認証方式.md
├── 04_API・OpenAPI.md
├── 99_archive/
└── README.md
```

技術選定を以下の3種類に分けて管理する。

```text
技術選定
├── Cross-cutting
│   ├── Application 構成
│   ├── Database
│   ├── Authentication
│   └── API / OpenAPI
│
├── Frontend
│   └── Frontend 固有技術
│
└── Backend
    └── Backend 固有技術
```

---

## 3. 技術スタック概要

| 領域 | 採用技術・方針 |
|---|---|
| Repository | Frontend / Backend 分離の monorepo |
| Frontend / BFF | Next.js / TypeScript |
| Backend API | PHP / Laravel |
| Database | PostgreSQL |
| Browser Authentication | Auth.js |
| Browser Session | Auth.js Database Session |
| Session Store | PostgreSQL |
| Backend API Authentication | Laravel Sanctum |
| API Contract | OpenAPI First |
| OpenAPI Lint / Bundle | Redocly CLI |
| TypeScript Type Generation | openapi-typescript |
| Local Development | Docker |
| Frontend Test | Frontend 技術選定で管理 |
| Backend Test | Backend 技術選定で管理 |
| Frontend Code Quality | Frontend 技術選定で管理 |
| Backend Code Quality | Backend 技術選定で管理 |
| CI / Automation | Frontend / Backend および開発・運用方針で管理 |

個々の Library / Tool の詳細は `Frontend/`、`Backend/` 配下の技術選定ドキュメントを参照する。

---

## Cross-cutting 技術選定

### 4. アプリケーション構成

[`01_アプリケーション構成.md`](./01_アプリケーション構成.md)

Application 全体の構成を管理する。

主な決定：

- Frontend / Backend 分離
- monorepo
- Next.js を Frontend / BFF として利用
- Laravel を Backend API として利用
- Browser → Next.js → Laravel を基本経路とする
- Backend は MVP では単一 Laravel Application とする
- Microservices は採用しない

基本構成：

```text
Browser
   ↓
Next.js
Frontend / BFF
   ↓
Laravel
Backend API
   ↓
PostgreSQL
```

---

### 5. データベース

[`02_データベース.md`](./02_データベース.md)

Database の技術選定と Data Ownership の基本方針を管理する。

主な決定：

- PostgreSQL を採用
- Application Data は Laravel が所有
- Auth.js Data は Next.js / Auth.js が所有
- Next.js から Application Table へ直接アクセスしない
- Application Validation / Domain Rule / Database Constraint を組み合わせる
- Primary Key は `bigint`
- PostgreSQL Sequence を利用可能な構成
- Transaction Isolation は `READ COMMITTED` を基本とする
- 必要な箇所では Pessimistic Lock を利用する
- Backend Test でも PostgreSQL を利用する
- Redis / NoSQL / SQLite を Primary Database として採用しない

Data Ownership：

```text
PostgreSQL
├── Application Data
│   └── Owner: Laravel
│
└── Auth.js Data
    └── Owner: Next.js / Auth.js
```

---

### 6. 認証方式

[`03_認証方式.md`](./03_認証方式.md)

Browser、Next.js、Laravel 間の Authentication Architecture を管理する。

主な決定：

- Browser Authentication に Auth.js を採用
- Auth.js Database Session を採用
- Session Store に PostgreSQL を採用
- Next.js → Laravel API の Authentication に Laravel Sanctum を採用
- Sanctum Token を Browser へ公開しない
- Authentication と Authorization を分離する
- Session と Sanctum Token の Lifecycle を対応させる
- Redis Session Store は MVP では採用しない

基本構成：

```text
Browser
   ↓ Auth.js Session
Next.js
Frontend / BFF
   ↓ Laravel Sanctum Token
Laravel
Backend API
```

具体的な Login / Logout / Token 発行・失効などは Authentication 詳細設計で管理する。

---

### 7. API・OpenAPI

[`04_API・OpenAPI.md`](./04_API・OpenAPI.md)

Frontend / Backend 間の API Contract と OpenAPI 周辺 Tool を管理する。

主な決定：

- OpenAPI First
- OpenAPI を API Contract の Source of Truth とする
- Redocly CLI による Lint / Bundle
- `openapi-typescript` による TypeScript Type Generation
- API Client は Next.js BFF 側で薄く実装
- API Client 全体の自動生成は行わない
- MVP では専用 Contract Testing Tool を追加しない
- CI で Lint / Bundle / Type Generation を実行する
- Laravel Implementation から OpenAPI を逆生成しない

基本フロー：

```text
OpenAPI
   ↓
Redocly Lint
   ↓
Redocly Bundle
   ↓
openapi-typescript
   ↓
TypeScript Types
   ↓
Next.js BFF
   ↓
Laravel Backend API
```

---

## Frontend 技術選定

### 8. Frontend

[`Frontend/`](./Frontend/)

Next.js Frontend / BFF に固有の技術選定を管理する。

主な対象：

- Runtime / Framework
- Language
- Package Manager
- Styling
- UI Component
- Form
- Validation
- Data Fetching
- State Management
- Authentication Integration
- API Client
- Feedback / Error UI
- UI Development
- Test
- Static Analysis
- Formatting
- Developer Experience
- CI / Automation
- 採用技術一覧

Cross-cutting な Authentication、Database、API Contract についてはトップレベルのドキュメントを Source of Truth とする。

```text
Frontend/
   ↓
Frontend 固有技術

03_認証方式.md
   ↓
Authentication 共通方針

04_API・OpenAPI.md
   ↓
API Contract 共通方針
```

---

## Backend 技術選定

### 9. Backend

[`Backend/`](./Backend/)

Laravel Backend API に固有の技術選定を管理する。

主な対象：

- PHP / Laravel
- HTTP / API
- Database Access
- ORM
- Migration
- Validation
- Authentication Integration
- Authorization
- Logging
- Cache
- Queue / Async
- Test
- Static Analysis
- Code Quality
- Developer Experience
- Security
- CI / Automation
- 採用技術一覧

Backend Architecture の責務・Layer・Dependency Rule については `02_アーキテクチャ` を Source of Truth とする。

```text
Backend/
   ↓
Backend 固有技術

02_アーキテクチャ/
   ↓
Backend Architecture

03_システム設計/
   ↓
具体的な System Design
```

---

## 10. Cross-cutting と Application 固有技術の境界

技術選定の配置は以下を基本ルールとする。

### Top Level

Frontend / Backend を横断する技術・構成を配置する。

例：

- Application 構成
- Database
- Authentication
- API Contract
- OpenAPI

### `Frontend/`

Frontend / BFF にのみ属する技術を配置する。

例：

- UI Library
- Form Library
- Frontend State Management
- Frontend Test
- Frontend Lint / Format

### `Backend/`

Backend API にのみ属する技術を配置する。

例：

- Laravel Package
- ORM
- Backend Validation
- Backend Test
- PHP Static Analysis
- Queue / Cache

判断基準：

```text
Frontend / Backend 横断
        ↓
Top Level

Frontend のみ
        ↓
Frontend/

Backend のみ
        ↓
Backend/
```

---

## 11. 技術選定と設計文書の関係

各 Directory の責務を以下とする。

| 文書 | 主な問い |
|---|---|
| `04_技術選定` | 何を、なぜ採用するか |
| [`02_アーキテクチャ`](../02_アーキテクチャ/README.md) | どの責務・依存関係で構成するか |
| [`03_システム設計`](../03_システム設計/README.md) | Database・Authentication・API などをどう実現するか |
| [`06_開発・運用`](../06_開発・運用/README.md) | Development Environment・CI/CD・運用をどう構成するか |

概念：

```text
Requirements
     ↓
Technology Selection
     ↓
Architecture
     ↓
System Design
     ↓
Implementation / Operation
```

ただし、実際には設計過程で相互に Feedback しながら更新する。

---

## 12. 技術選定と Architecture の境界

### 技術選定

主に以下を決定する。

```text
What?
Why?
```

例：

- PostgreSQL を採用する
- Auth.js を採用する
- Laravel Sanctum を採用する
- Redocly CLI を採用する

### Architecture

主に以下を決定する。

```text
Where?
Responsibility?
Dependency?
```

例：

- Domain Layer は Framework に依存しない
- Repository Interface は Domain に置く
- Infrastructure が Repository を実装する
- Application Handler を Transaction Boundary とする

---

## 13. 技術選定と System Design の境界

技術選定では構成と Technology Choice を管理し、具体的な実現方法は System Design へ分離する。

例：

```text
技術選定
↓
Auth.js Database Session を採用

System Design
↓
Session Table
Session Timeout
Login Flow
Logout Flow
Cookie Configuration
```

同様に、

```text
技術選定
↓
OpenAPI First を採用

System Design
↓
Endpoint
Request Schema
Response Schema
Error Code
Pagination
```

という責務分離を行う。

---

## 14. 推奨する読み順

プロジェクト全体を把握する場合は、以下の順序で読む。

1. [`01_アプリケーション構成.md`](./01_アプリケーション構成.md)
2. [`02_データベース.md`](./02_データベース.md)
3. [`03_認証方式.md`](./03_認証方式.md)
4. [`04_API・OpenAPI.md`](./04_API・OpenAPI.md)
5. [`Frontend/README.md`](./Frontend/README.md)
6. [`Backend/README.md`](./Backend/README.md)

概念：

```text
Application
   ↓
Database
   ↓
Authentication
   ↓
API Contract
   ↓
Frontend
   +
Backend
```

Frontend の実装に関心がある場合は `Frontend/`、Backend の実装に関心がある場合は `Backend/` へ直接進んでもよい。

---

## 15. Source of Truth

同じ内容を複数 Document へ重複して定義しない。

各領域の Source of Truth は以下とする。

| 領域 | Source of Truth |
|---|---|
| Application 全体構成 | `01_アプリケーション構成.md` |
| Database 技術・Ownership | `02_データベース.md` |
| Authentication 技術・基本構成 | `03_認証方式.md` |
| API Contract / OpenAPI Tool | `04_API・OpenAPI.md` |
| Frontend 技術選定 | `Frontend/` |
| Backend 技術選定 | `Backend/` |
| Architecture | `02_アーキテクチャ/` |
| 詳細 System Design | `03_システム設計/` |
| Development / Operation | `06_開発・運用/` |

他 Document から同じ内容を説明する場合は、原則として概要のみ記述し Source of Truth を参照する。

---

## 16. Archive

[`99_archive/`](./99_archive/)

過去の技術選定 Document や、現在の構成へ統合された Document を保存する。

例：

- 旧 Frontend 技術選定
- 旧 Backend 技術選定
- 旧 Session Store 単独 Document
- 旧 Test Tool 選定
- 旧 Code Quality Tool 選定

Archive は現在の設計判断の Source of Truth として扱わない。

現在の決定事項と Archive の内容が異なる場合は、現在の Document を優先する。

---

## 17. 文書管理ルール

### 技術選定理由を残す

採用結果だけでなく、

- 採用理由
- 比較対象
- 採用しなかった理由
- 将来的な再検討条件

を可能な範囲で記録する。

---

### Version を過度に固定しない

技術選定段階では特別な理由がない限り Major / Minor Version を固定しすぎない。

開発開始時点で Support されている Stable Version を基本とする。

具体的な Version は以下で固定する。

- `package.json`
- Lock File
- `composer.json`
- `composer.lock`
- Docker Image
- その他 Dependency Definition

---

### 重複を避ける

Frontend / Backend 固有の Tool を Top Level に重複して記述しない。

```text
Frontend Test
→ Frontend/

Backend Test
→ Backend/
```

Cross-cutting な方針のみ Top Level で管理する。

---

### Tool 追加時

新しい Tool を追加する場合は以下を確認する。

- 解決したい問題が明確か
- 既存 Tool と責務が重複していないか
- MVP に必要か
- Maintenance Cost に見合うか
- Local Development / CI / Production への影響は何か
- 将来的に削除・置換しやすいか

---

### 技術変更時

採用技術を変更する場合は、その技術選定 Document だけでなく以下への影響も確認する。

- Requirements
- Architecture
- System Design
- OpenAPI
- Database
- Authentication
- Development Environment
- Test
- CI / Automation
- Deployment / Operation
- Documentation

必要に応じて関連 Document を同じ変更単位で更新する。

---

## 18. 決定事項

`04_技術選定` は以下の構成で管理する。

```text
04_技術選定/
├── Backend/
├── Frontend/
├── 01_アプリケーション構成.md
├── 02_データベース.md
├── 03_認証方式.md
├── 04_API・OpenAPI.md
├── 99_archive/
└── README.md
```

管理方針：

```text
Cross-cutting Technology
→ Top Level

Frontend-specific Technology
→ Frontend/

Backend-specific Technology
→ Backend/
```

Top Level では以下を Source of Truth とする。

```text
01_アプリケーション構成.md
→ Application 全体構成

02_データベース.md
→ PostgreSQL / Data Ownership

03_認証方式.md
→ Auth.js / Session / Sanctum

04_API・OpenAPI.md
→ API Contract / OpenAPI
```

Frontend / Backend 固有の Library・Tool・Developer Experience・Test・Code Quality・CI については、それぞれ `Frontend/`、`Backend/` で管理する。

この構成を Engineer Skill Management App の技術選定ドキュメント管理方針とする。
