# 認証方式

## 1. 概要

Engineer Skill Management App では、Frontend / BFF と Backend API を分離し、それぞれの境界に適した Authentication を利用する。

基本構成は以下とする。

```text
Browser
   ↓
Next.js
Frontend / BFF
   ↓
Laravel
Backend API
```

Authentication は以下のように分離する。

```text
Browser
   ↓ Auth.js Session
Next.js BFF
   ↓ Laravel Sanctum Token
Laravel API
```

採用方式：

| 境界 | Authentication |
|---|---|
| Browser ↔ Next.js | Auth.js Session |
| Next.js ↔ Laravel API | Laravel Sanctum |
| Session Store | PostgreSQL |

Browser Authentication と Backend API Authentication を別の責務として扱う。

---

## 2. 採用技術

以下を採用する。

### Web Authentication

**Auth.js**

Browser と Next.js 間の Authentication / Session Management に利用する。

### Session Store

**PostgreSQL**

Auth.js の Database Session を保存する。

### Backend API Authentication

**Laravel Sanctum**

Next.js BFF から Laravel API への API Authentication に利用する。

### Authorization

Laravel Policy / Application Layer / Domain Rule を責務に応じて利用する。

---

## 3. Authentication 全体構成

最終的な Authentication Flow の基本構成を以下とする。

```text
┌──────────────┐
│   Browser    │
└──────┬───────┘
       │
       │ Auth.js Session Cookie
       ▼
┌──────────────────┐
│     Next.js      │
│ Frontend / BFF   │
└────────┬─────────┘
         │
         │ Laravel Sanctum Token
         ▼
┌──────────────────┐
│   Laravel API    │
└──────────────────┘
```

Browser は Sanctum Token を保持しない。

Laravel API への Authentication Credential は Next.js Server 側でのみ扱う。

---

## 4. Browser → Next.js

Browser Authentication には Auth.js を利用する。

```text
Browser
   ↓
Auth.js Session Cookie
   ↓
Next.js
```

Auth.js は主に以下を担当する。

- Login 状態管理
- Session 作成
- Session 検証
- Session 更新
- Session 失効
- Logout
- Session Store との連携

Browser は Auth.js の Session Cookie を利用して Authentication 状態を維持する。

Laravel Session を Browser Authentication には利用しない。

---

## 5. Next.js → Laravel API

Next.js BFF から Laravel API への Authentication には Laravel Sanctum を利用する。

```text
Next.js BFF
   ↓
Sanctum Token
   ↓
Laravel API
```

Sanctum は Browser Session Authentication ではなく、BFF → Backend API 間の API Token Authentication として利用する。

Next.js は Laravel API Request に必要な Authentication Credential を Server Side で付与する。

---

## 6. BFF 方針

Next.js を BFF（Backend for Frontend）として利用する。

Browser は原則として Next.js を経由して Laravel API へアクセスする。

```text
Browser
   ↓
Next.js BFF
   ↓
Laravel API
```

Next.js BFF は Authentication に関して主に以下を担当する。

- Auth.js Session の確認
- Authentication 状態の確認
- Backend API Credential の取得
- Laravel API への Authentication 情報付与
- Credential の安全な管理
- Browser と Laravel API の Security Boundary

Sanctum Token を Browser へ渡さない。

---

## 7. Sanctum Token を Browser へ公開しない

採用する構成：

```text
Browser
   ↓ Auth.js Session
Next.js BFF
   ↓ Sanctum Token
Laravel API
```

採用しない構成：

```text
Browser
   ↓ Sanctum Token
Laravel API
```

Sanctum Token は Next.js Server 側でのみ利用する。

以下への保存を行わない。

- localStorage
- sessionStorage
- Browser JavaScript から直接管理する Cookie
- Client Side State

Browser が Sanctum Token の値へアクセスできる構成にしない。

---

## 8. Session Store

Auth.js の Session Store には PostgreSQL を採用する。

- [x] PostgreSQL
- [ ] Redis

Database-backed Session を利用する。

```text
Browser
   ↓
Auth.js Session Cookie
   ↓
Next.js
   ↓
Session Lookup
   ↓
PostgreSQL
```

これにより Session を Server Side で管理できる構成とする。

---

## 9. PostgreSQL を Session Store に採用する理由

PostgreSQL を採用する主な理由は以下とする。

- Application Data 用 Database として既に PostgreSQL を採用している
- MVP で Redis などの追加 Infrastructure を導入せずに済む
- Application 構成をシンプルに維持できる
- Session の作成・取得・更新・失効を十分実現できる
- Server Side から Session を強制失効できる
- MVP 規模では十分な Performance を期待できる
- Infrastructure の運用対象を増やさずに済む

MVP では Session Store 専用 Infrastructure を追加しない。

---

## 10. PostgreSQL 内の責務分離

PostgreSQL は以下の2種類の用途で利用する。

```text
PostgreSQL
├── Auth.js Data
└── Application Data
```

### Auth.js Data

Owner：

```text
Next.js / Auth.js
```

主に以下を管理する。

- Session
- User Authentication に必要な Auth.js Data
- Session 有効期限
- Auth.js が必要とする Metadata

### Application Data

Owner：

```text
Laravel
```

主に以下を管理する。

- Employee
- Department
- Skill
- EmployeeSkill
- Access Control
- その他 Domain Data

物理的に同じ PostgreSQL を利用する場合でも Ownership は分離する。

---

## 11. Next.js からの Database Access

Next.js から PostgreSQL へのアクセスは Authentication / Session に必要な範囲に限定する。

```text
Next.js
   │
   ├── Auth.js Data
   │       ↓
   │   PostgreSQL
   │
   └── Application Data
           ↓
       Laravel API
           ↓
       PostgreSQL
```

Application Data へ Next.js から直接アクセスしない。

Application Data の取得・更新は Laravel API を利用する。

---

## 12. Laravel からの Database Access

Laravel は Application Data の管理を担当する。

Laravel から Auth.js の内部 Table を直接操作することを原則として行わない。

```text
Laravel
   ↓
Application Tables
```

以下の構成にはしない。

```text
Laravel
   ↓
Auth.js Internal Tables
```

Auth.js Session の Lifecycle は Next.js / Auth.js の責務とする。

---

## 13. Auth.js Session と Sanctum Token

Auth.js Session と Laravel API Authentication Credential は対応関係を持たせる。

MVP では基本的に以下の関係を採用する。

```text
1 Auth.js Session
      │
      │ 1 : 1
      ▼
1 Backend API Credential
   (Sanctum Token)
```

Session 単位で Laravel API Access Credential を分離することで、Session 単位で Token を失効できる構成とする。

これにより、

```text
Session A
→ Sanctum Token A

Session B
→ Sanctum Token B
```

のように管理できる。

Session A を Logout した場合に、Token A のみを失効できる構成を基本とする。

---

## 14. Sanctum Token の保存

Sanctum Token の平文を Browser や Client Side Storage に保存しない。

Next.js Server が Laravel API 呼び出しに必要な Token を復元できる必要があるため、永続化する場合は Application Level Encryption を利用する。

概念：

```text
Sanctum Token
   ↓
Encrypt
   ↓
Server-side Credential Store
   ↓
Decrypt
   ↓
Next.js BFF
   ↓
Authorization Header
   ↓
Laravel API
```

Auth.js Session と Sanctum Token は論理的に関連付ける。

ただし、Sanctum Token を Auth.js 標準 Session Table の Column として直接保持することまでは技術選定段階では固定しない。

具体的な保存方法は認証詳細設計で決定する。

候補：

```text
Auth.js Session
      │
      │ 1 : 1
      ▼
BackendApiCredential
```

これにより Auth.js の内部 Schema と Backend API Credential の責務を分離できる。

---

## 15. Laravel Sanctum

Laravel Backend API の Authentication には Laravel Sanctum を採用する。

利用目的：

```text
Next.js BFF
   ↓
Laravel API
```

間の API Authentication。

Laravel Sanctum は以下を担当する。

- API Token の発行
- Token の検証
- Token の失効
- Authentication User の特定

Sanctum による Authentication 成功だけでは業務操作を許可しない。

Authorization は別の責務として扱う。

---

## 16. Authentication と Authorization の分離

Authentication と Authorization は明確に分離する。

### Authentication

```text
Who are you?
```

利用者が誰であるかを確認する。

担当：

- Auth.js
- Laravel Sanctum

### Authorization

```text
Are you allowed to do this?
```

認証済み利用者が対象操作を実行可能か判断する。

担当：

- Laravel Policy
- Application Layer
- Domain Policy
- Domain Invariant

Sanctum Token が有効であることだけを理由に、すべての操作を許可しない。

---

## 17. Authorization 方針

Laravel Policy は Presentation / HTTP 側の Authorization Adapter として利用する。

重要な Authorization Rule は必要に応じて Application Layer でも保証する。

例えば以下を対象とする。

- Manager が全社員を操作可能
- Sub Manager が担当社員のみ操作可能
- Team Leader が担当社員を閲覧のみ可能
- Administrator の Permission Management
- Permission を管理可能な Administrator を最低1人維持する

Frontend の UI 表示制御のみで Authorization を保証しない。

```text
Frontend UI Control
        +
Backend Authorization
```

Backend が最終的な Authorization を保証する。

---

## 18. Domain User との分離

Authentication Infrastructure の情報を Domain User に持ち込まない。

Domain User に以下を保持させない。

- Auth.js Session
- Session Token
- Sanctum Token
- Cookie
- HTTP Authentication Information
- Auth.js Object
- Laravel Auth Object

Domain は以下へ依存しない。

```text
Auth.js
Sanctum
Laravel Auth
Cookie
HTTP
```

Authentication は Core Domain として扱わない。

```text
Core Domain
└── Skill Management

Technical Concern
└── Authentication
```

---

## 19. Application Layer への認証情報受け渡し

Application Layer に Laravel / Auth.js 固有 Object を直接渡さない。

Presentation / Authentication 境界で Application が必要とする形式へ変換する。

概念：

```text
Authentication
   ↓
Authenticated Actor
   ↓
ActorContext
   ↓
Application Handler
```

ActorContext には UseCase に必要な最小限の情報のみを持たせる。

例えば：

- User ID
- Role
- Permission 判定に必要な情報

具体的な構造は Backend Architecture / Authentication 詳細設計で定義する。

---

## 20. Session Lifecycle

Database Session を利用するため、Session を Server Side で失効できる。

以下のケースを考慮する。

- Logout
- 強制 Logout
- Session 有効期限切れ
- User 無効化
- Permission / Security 上必要な変更
- Security Incident

Session と Backend API Credential の Lifecycle を可能な限り対応させる。

---

## 21. Session 有効期限

Auth.js Session には有効期限を設定する。

Session Store で Session の有効期限を管理し、Auth.js の設定と整合させる。

詳細設計では以下を決定する。

- Maximum Session Lifetime
- Idle Timeout の有無
- Session Renewal
- Session Rotation
- Sanctum Token Lifetime
- Session と Sanctum Token の Expiration 整合性

具体的な時間は Security 設計で決定する。

---

## 22. Session 失効

Auth.js Session が失効した場合、その Session に対応する Sanctum Token も利用不能にすることを基本方針とする。

避ける状態：

```text
Auth.js Session
→ Invalid

Sanctum Token
→ Valid
```

Session と Token の完全な Transaction 一貫性が難しい場合を考慮し、失効処理は Idempotent に設計する。

具体的な Error Recovery や Retry は認証詳細設計で定義する。

---

## 23. Logout

Logout 時は以下の Authentication State を失効させる。

```text
Logout
   ↓
Backend API Credential 無効化
   +
Auth.js Session 無効化
   +
Browser Session Cookie 無効化
```

基本的な処理対象：

1. 対応する Laravel Sanctum Token を失効
2. Auth.js Session を失効
3. Browser の Session Cookie を無効化

具体的な実行順序、失敗時処理、Retry 方針は認証詳細設計で決定する。

---

## 24. 強制 Logout

Database-backed Session を採用するため、Server Side から Session を失効できる構成とする。

強制 Logout が必要となる例：

- User の無効化
- Security Incident
- Administrator による Session 無効化
- Credential 漏洩の疑い
- Permission 変更に伴い再認証が必要な場合

強制 Logout 時も、関連する Backend API Credential を同時に失効させることを基本とする。

---

## 25. Security 方針

Authentication では以下を基本方針とする。

- HTTPS を前提とする
- Sanctum Token を Browser へ公開しない
- Sanctum Token を Client Side Storage に保存しない
- Server Side に Token を保存する場合は平文保存しない
- Session Cookie に適切な Security Attribute を設定する
- Session と Token の Lifecycle を可能な限り対応させる
- Authentication と Authorization を分離する
- Frontend の UI 制御だけに Authorization を依存しない
- Domain を Authentication Framework へ依存させない
- Authentication Credential を Log に出力しない
- Secret / Encryption Key を Source Code に保存しない

詳細な Security Requirement は非機能要件・Security 設計で管理する。

---

## 26. Cookie 方針

Auth.js Session Cookie には Production Environment で適切な Security Attribute を設定する。

基本方針：

- `HttpOnly`
- `Secure`
- 適切な `SameSite`
- 必要最小限の `Path`
- 適切な有効期限

Cookie の具体的な名称や属性値は Authentication 詳細設計で決定する。

---

## 27. Redis を MVP で採用しない理由

MVP では Redis を Session Store として採用しない。

理由：

- Infrastructure Component が増える
- Local / Production Environment が複雑になる
- Redis の Monitoring・Backup・障害対応が運用対象になる
- MVP 規模では PostgreSQL で十分対応可能と判断する
- Session Performance が Bottleneck になることが現時点では想定されない

Application 構成をシンプルに保つことを優先する。

---

## 28. 将来的な Redis 利用

以下のような要件が発生した場合は Redis の導入を再検討する。

- Session Access が大幅に増加する
- PostgreSQL への Session Load が問題になる
- TTL Base の Session Management を効率化したい
- Redis を Cache / Queue 等でも採用する
- Session Infrastructure を独立させる必要が生じる

Redis 導入を前提とした過度な Abstraction は MVP では行わない。

必要性が確認された段階で変更する。

---

## 29. 採用しない構成

MVP では以下を採用しない。

### Browser → Laravel API への直接 Token 送信

```text
Browser
   ↓ Sanctum Token
Laravel API
```

採用しない。

Next.js BFF を経由する。

---

### Sanctum Token の Browser 保存

以下への保存は行わない。

- localStorage
- sessionStorage
- Client JavaScript から参照可能な Cookie

---

### Laravel Session による Browser Authentication

Browser Authentication は Auth.js に統一する。

Auth.js Session と Laravel Session を Browser Authentication 用途で二重管理しない。

---

### JWT 中心の独自 Authentication

独自 JWT Authentication System は構築しない。

Auth.js + Laravel Sanctum を利用する。

---

### Next.js から Application Data への直接アクセス

Authentication のために PostgreSQL へ接続することを理由として、Application Data まで Next.js から直接操作しない。

---

### Redis Session Store

MVP では採用しない。

必要性が確認された場合に再検討する。

---

## 30. 技術選定と詳細設計の境界

本ドキュメントでは以下を決定する。

- Authentication Architecture
- Auth.js 採用
- Database Session 採用
- PostgreSQL Session Store 採用
- Laravel Sanctum 採用
- BFF Authentication 方針
- Session / Token Lifecycle の基本方針
- Authentication / Authorization の責務分離

以下は Authentication 詳細設計で管理する。

- Auth.js Table の Column
- Backend API Credential の Table / Column
- Sanctum Token Encryption 方式
- Encryption Key Management
- Login Flow
- Logout Flow
- Token 発行 Flow
- Token 失効 Flow
- Session Rotation
- Session Timeout
- Cookie の具体的な設定値
- Error Handling
- Retry / Recovery
- Next.js / Laravel の具体的な実装

詳細設計：

```text
docs/
└── 03_システム設計/
    └── 02_認証・認可/
```

---

## 31. 関連ドキュメント

### `01_アプリケーション構成.md`

以下を管理する。

- Next.js BFF
- Laravel Backend API
- Frontend / Backend Boundary
- monorepo

### `02_データベース.md`

以下を管理する。

- PostgreSQL
- Data Ownership
- Migration Ownership
- Auth.js Data / Application Data の分離

### `04_API・OpenAPI.md`

以下を管理する。

- API Contract
- OpenAPI First
- Frontend / Backend Integration

### Authentication 詳細設計

以下を管理する。

- Login / Logout
- Session
- Token
- Cookie
- Credential Storage
- Authentication Error

---

## 32. 決定事項

### Authentication Architecture

```text
Browser
   ↓
Auth.js Session
   ↓
Next.js Frontend / BFF
   ↓
Laravel Sanctum Token
   ↓
Laravel Backend API
```

### Browser Authentication

**Auth.js Database Session を採用する。**

### Session Store

**PostgreSQL を採用する。**

```text
Auth.js
   ↓
PostgreSQL
```

### Backend API Authentication

**Laravel Sanctum を採用する。**

```text
Next.js BFF
   ↓
Sanctum Token
   ↓
Laravel API
```

### Session / Token Relation

基本的に以下の関係とする。

```text
1 Auth.js Session
      │
      │ 1 : 1
      ▼
1 Sanctum Token
```

具体的な物理保存 Schema は Authentication 詳細設計で決定する。

### Credential Management

- Sanctum Token は Browser へ公開しない
- Next.js Server Side でのみ利用する
- Client Side Storage へ保存しない
- 永続化する場合は平文保存しない
- Auth.js Session と Lifecycle を対応させる

### Authorization

```text
Authentication
├── Auth.js
└── Laravel Sanctum

Authorization
├── Laravel Policy
├── Application Layer
└── Domain Rule
```

### Session Store Infrastructure

```text
MVP
└── PostgreSQL

Redis
└── 不採用
```

### 責務

```text
Browser
└── Auth.js Session Cookie

Next.js / Auth.js
├── Browser Authentication
├── Session Management
├── Backend API Credential Management
└── BFF

Laravel Sanctum
└── Backend API Authentication

Laravel Policy / Application
└── Authorization

Domain
└── Authentication Framework に依存しない
```

以上を MVP の Authentication 基本方針として採用する。
