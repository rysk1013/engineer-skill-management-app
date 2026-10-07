# Frontend Architecture 全体方針

## 1. 目的

本プロジェクトのFrontendは、Next.jsを用いたWeb UIとしてだけでなく、BrowserとLaravel APIの間に位置するBFFとしても機能する。

Frontend Architectureでは、次の点を重視する。

- Next.js App Routerとの親和性
- Server Componentを活用したシンプルなデータ取得
- BrowserとLaravel APIの責務境界の明確化
- Better AuthとLaravel Sanctumを組み合わせた認証境界の分離
- Feature単位で変更しやすい構造
- BackendのDomain Logicとの責務重複を避ける
- OpenAPI FirstによるAPI型安全性
- Client側状態管理の最小化
- 過度なFrontend Architectureの複雑化を避ける

Frontendでは、Backendで採用しているClean Architecture / DDDをそのまま再現せず、Next.jsに適したFeature-based Architectureを採用する。

---

# 2. 基本アーキテクチャ

Frontend Architectureの基本方針は以下とする。

```text
Server Component First
        +
Feature-based Architecture
        +
BFF Boundary
        +
OpenAPI Generated Client
```

全体構成は以下とする。

```text
┌────────────────────────────────────────────┐
│ Browser                                    │
│                                            │
│ Client Components                          │
│ - Interaction                              │
│ - Local UI State                           │
│ - Form State                               │
│                                            │
└───────────────────┬────────────────────────┘
                    │
         Better Auth Session Cookie
                    │
                    ▼
┌────────────────────────────────────────────┐
│ Next.js                                    │
│                                            │
│ app/                                       │
│ - Routing                                  │
│ - Layout                                   │
│ - Server Components                        │
│ - Loading / Error Boundary                 │
│                                            │
│ features/                                  │
│ - Employee                                 │
│ - Skill                                    │
│ - Skill Category                           │
│ - Access Control                           │
│                                            │
│ BFF                                        │
│ - Route Handler                            │
│ - Server Action                            │
│                                            │
│ API Client                                 │
│ - OpenAPI Generated Client                 │
│                                            │
│ Better Auth                                │
│ - Browser Session                          │
│                                            │
│ Backend Credential Management              │
│ - Sanctum Token Encryption / Decryption    │
│                                            │
└────────────┬──────────────┬────────────────┘
             │              │
             │              │ Sanctum Token
             │              ▼
             │    ┌────────────────────────────┐
             │    │ Laravel API                │
             │    │                            │
             │    │ Presentation               │
             │    │      ↓                     │
             │    │ Application                │
             │    │      ↓                     │
             │    │ Domain                     │
             │    │                            │
             │    │ Infrastructure             │
             │    └─────────────┬──────────────┘
             │                  │
             │                  ▼
             │             PostgreSQL
             │
             │ Session / Credential
             ▼
┌────────────────────────────────────────────┐
│ Redis                                      │
│                                            │
│ better-auth:*                              │
│ - Better Auth Session                      │
│                                            │
│ backend-credential:*                       │
│ - Encrypted Sanctum Token                  │
│                                            │
└────────────────────────────────────────────┘
```

Application User AuthenticationはLaravel APIが担当する。

Better Auth SessionとBackend CredentialはRedisで管理する。

Next.jsからPostgreSQLへ直接接続しない。

RedisはMVPで1 Instanceを使用し、NamespaceとACLによってSessionとCredentialのAccess権限を分離する。

---

# 3. Next.jsの責務

Next.jsはFrontendとBFFの両方を担当する。

主な責務は以下とする。

```text
Next.js
├─ UI Rendering
├─ Routing
├─ Better Auth Session管理
├─ Backend Credential管理
├─ BFF
├─ Laravel API通信
├─ Frontend固有のデータ変換
├─ Request / Response Adaptation
└─ Frontend固有のOrchestration
```

具体的には以下を担当する。

- 画面描画
- Routing / Layout
- ユーザー操作の受付
- Better AuthによるBrowser Session管理
- RedisによるBetter Auth Session管理
- Backend Credentialの暗号化・保存・取得・削除
- Laravel API呼び出し
- BrowserへLaravel API用Credentialを露出させない
- APIレスポンスからView向けデータへの軽量な変換
- 複数APIのFrontend向け集約
- Frontend固有のNavigation制御
- Loading / Error表示

---

# 4. Business Logicの責務

業務ルールの正はLaravel Domainとする。

Frontendには、Business Ruleを保証する責務を持たせない。

例えば以下のルールはLaravel側で保証する。

```text
実務未経験の場合
Skill LevelはLevel 1のみ
```

Frontend側でもUX向上のため選択肢をLevel 1だけに制限してよいが、それだけを整合性保証としてはならない。

責務を以下のように分ける。

```text
Frontend
↓
UX / Input Assistance

Laravel Domain
↓
Business Rule / Invariant
```

したがって、

```text
Frontend Validation
≠
Business Rule Guarantee
```

とする。

---

# 5. BrowserからLaravel APIを直接呼ばない

BrowserからLaravel APIへの直接アクセスは禁止する。

以下の構成は採用しない。

```text
Browser
   ↓
Laravel API
```

基本経路を以下とする。

```text
Browser
   ↓
Next.js
   ↓
Laravel API
```

これにより、Laravel API用CredentialをBrowserへ公開しない。

---

# 6. 認証境界

認証境界を以下の2つに分離する。

```text
Browser
   │
   │ Better Auth Session Cookie
   ▼
Next.js
   │
   │ Laravel Sanctum Token
   ▼
Laravel API
```

それぞれの責務は以下とする。

### Browser ↔ Next.js

```text
Better Auth Session
```

を使用する。

BrowserはBetter Auth Session Cookieを利用し、Laravel API用Tokenを保持しない。

Better Auth Sessionの保存先はRedisとする。

Application User AuthenticationはLaravelが担当する。

Laravelでの認証成功後にBetter Auth Sessionを成立させる具体方式は、Better Authの公式APIとExtension Pointを確認して決定する。

### Next.js ↔ Laravel

```text
Laravel Sanctum Token
```

を利用する。

Sanctum TokenはNext.js Server側で管理する。

Backend CredentialはBetter Auth Sessionとは分離してRedisへ保存する。

Sanctum TokenはApplication Level Encryptionして保存する。

Next.jsからPostgreSQLへ直接接続しない。

Application User Authenticationと業務上の最終AuthorizationはLaravelが担当する。

---

# 7. Server Component First

App RouterではServer Componentをデフォルトとする。

原則として、

```text
Server Component First
```

を採用する。

Client Componentは必要な場合のみ使用する。

---

# 8. Server Componentの責務

Server Componentは主に以下を担当する。

- Laravel APIからのデータ取得
- 初期画面描画
- Server側Composition
- Server側で完結する表示データ生成

基本的な通信経路は以下とする。

```text
Server Component
       ↓
Laravel API Client
       ↓
Laravel API
```

Server ComponentからLaravel APIを直接呼び出すことを許可する。

ここでいう「直接」とは、Next.js Route Handlerを経由しないことを意味する。

---

# 9. Client Componentの利用基準

Client Componentは以下が必要な場合に使用する。

- `useState`
- `useEffect`
- `useReducer`
- Event Handler
- Browser API
- Client-side Form State
- インタラクティブUI
- Client側でのみ動作するLibrary

したがって、

```text
"use client"
```

は必要なComponentにのみ付与する。

以下のような方針は採用しない。

```text
Page全体をとりあえずClient Component化する
```

Client Boundaryは可能な限り小さく保つ。

---

# 10. Server ComponentからLaravel APIへのアクセス

Server ComponentはNext.js Server上で動作するため、Laravel APIへ直接アクセスしてよい。

以下を許可する。

```text
Server Component
       ↓
API Client
       ↓
Laravel API
```

以下のように、自身のRoute Handlerを必ず経由する設計にはしない。

```text
Server Component
       ↓
Route Handler
       ↓
Laravel API
```

不要なHTTP Hopを追加しないためである。

---

# 11. ClientからLaravel APIへのアクセス

Client ComponentからLaravel APIへの直接アクセスは禁止する。

必要な場合はNext.js側のServer Boundaryを経由する。

```text
Client Component
       ↓
Next.js Server Boundary
       ↓
Laravel API
```

Server Boundaryとして、用途に応じて以下を使用する。

```text
Route Handler
Server Action
```

Route HandlerとServer Actionの具体的な使い分けについては別途設計する。

---

# 12. Feature-based Architecture

Frontend内部はFeature-based Architectureを採用する。

Backendで採用している以下のLayer構造をFrontendへそのまま複製しない。

```text
Presentation
Application
Domain
Infrastructure
```

FrontendではFeatureを変更単位の中心とする。

例：

```text
features/
├── employees/
├── skills/
├── skill-categories/
└── access-control/
```

各Feature内には、そのFeatureに必要な以下の要素を配置する。

```text
Component
Form
Schema
Query
Mutation
View Model
Frontend-specific Type
```

詳細なディレクトリ構成は別途定義する。

---

# 13. app/ の責務

`app/`はNext.js Framework Boundaryとして扱う。

主な責務は以下とする。

```text
app/
├─ Routing
├─ Layout
├─ Metadata
├─ Page Entry Point
├─ Loading UI
├─ Error Boundary
└─ Feature Composition
```

Business Logicや大量のFeature Logicを`app/`へ配置しない。

例えば、

```text
app/
└── employees/
    └── page.tsx
```

では、Feature ComponentをCompositionすることを中心とする。

概念的には、

```tsx
<EmployeeList />
```

のような構造とする。

---

# 14. BFFの責務

Next.js BFFはFrontend向けのBoundaryとして使用する。

担当する責務は以下とする。

```text
Authentication
API Aggregation
Frontend-specific Transformation
Request Adaptation
Response Adaptation
Frontend-specific Orchestration
```

例えば、1画面表示のために以下を取得する場合、

```text
Employee API
+
Skill API
+
Department API
```

これらをFrontend向けに集約する処理はBFFに置いてよい。

一方、以下のようなBusiness RuleはBFFに置かない。

```text
EmployeeSkill登録条件
Permission管理者最低1人維持ルール
退職社員保持ルール
Skill無効化ルール
```

これらはLaravel側で保証する。

責務を以下のように整理する。

```text
Next.js BFF
=
Frontend Convenience

Laravel Application / Domain
=
Business Correctness
```

---

# 15. Laravel API Client

Laravel APIとの通信処理は共通API Clientを通す。

各ComponentやFeatureから無秩序に`fetch()`を実行しない。

概念的には以下とする。

```text
Frontend
    ↓
API Client
    ↓
Laravel API
```

API Clientは、認証情報・HTTP Error・Headerなどの共通処理を集約する。

---

# 16. OpenAPI First

Laravel APIとの契約はOpenAPIを正とする。

FrontendではOpenAPIからAPI Client / Typeを生成する。

```text
OpenAPI
   ↓
Generated API Client
   ↓
Frontend
```

Generated Codeと手書きコードは分離する。

例：

```text
lib/
└── api/
    ├── generated/
    │   └── ...
    │
    └── client.ts
```

Generated Codeを直接編集しない。

---

# 17. Frontend Domain Model

BackendのDDD Domain ModelをFrontendへ再実装しない。

Backendには、

```text
Aggregate
Entity
Value Object
Domain Policy
```

が存在するが、Frontendで同一構造を再現する必要はない。

Frontendでは基本的に以下を扱う。

```text
API DTO
+
View Model
+
UI State
```

例えばAPIから、

```json
{
  "experienceYears": 2,
  "experienceMonths": 6
}
```

を受け取った場合、

```text
2年6か月
```

へ変換する処理はFrontendに置いてよい。

ただし、

```text
EmployeeSkill Aggregate
```

そのものをFrontendで再構築しない。

---

# 18. View Model

API DTOをそのままUIへ渡す必要はない。

UI表示に適した形への変換にはView Modelを使用してよい。

```text
API DTO
   ↓
View Model
   ↓
UI
```

View Modelには以下のような処理を許可する。

- 日付表示
- 経験期間表示
- Label変換
- 表示用Status
- Table表示用Data
- UI向けGrouping

ただしBusiness Ruleの判定主体にはしない。

---

# 19. 状態管理方針

Client Stateを可能な限り少なくする。

状態の配置について以下の優先順位を採用する。

```text
1. Server State
2. URL State
3. Form State
4. Local UI State
5. Global Client State
```

まずServerで管理可能か検討する。

次にURLで表現可能か検討する。

そのうえで必要なClient Stateのみ保持する。

---

# 20. URL State

検索・絞り込み・ページングなど、URLで表現可能な状態はURLへ持たせる。

例：

```text
/employees?keyword=php&department=3&page=2
```

これにより、

- Reloadしても状態を維持できる
- URL共有が可能
- Back / Forward操作に対応しやすい
- Server Componentとの相性がよい

という利点を得る。

---

# 21. Global Client State

ReduxやZustandなどのGlobal State Libraryを初期段階では導入しない。

以下の順番で解決を試みる。

```text
Server State
↓
URL State
↓
Form State
↓
Local State
↓
Context
↓
Global State Library
```

明確な必要性が出た場合のみ導入する。

したがって、

```text
Global State Library
=
必要になってから採用
```

とする。

---

# 22. Frontend Validation

Frontend ValidationはUX向上を目的として実施する。

例：

- 必須項目の即時表示
- 文字数制限
- Format Check
- Form入力補助
- 選択可能項目の制御

ただしFrontend ValidationのみをBusiness Rule保証として使用しない。

```text
Frontend Validation
↓
UX

Laravel Validation / Domain
↓
Correctness
```

とする。

---

# 23. Dependencyの基本方針

Frontendの依存方向は概念的に以下とする。

```text
app
 ↓
features
 ↓
shared / lib / api
```

Framework Boundaryである`app/`からFeatureを利用する。

Featureは共通UIやAPI Clientを利用できる。

逆方向の依存は避ける。

```text
shared → features
```

のような依存は原則禁止する。

詳細なDependency Ruleはディレクトリ構成設計時に定義する。

---

# 24. FrontendとBackendのArchitecture方針の違い

BackendはDomain中心のArchitectureとする。

```text
Laravel Backend

Presentation
    ↓
Application
    ↓
Domain
```

FrontendはFeature中心のArchitectureとする。

```text
Next.js Frontend

app
 ↓
features
 ↓
shared / api
```

つまり、

```text
Backend
=
Domain-oriented Architecture

Frontend
=
Feature-oriented Architecture
```

とする。

FrontendへBackendと同じArchitectureを機械的に適用しない。

---

# 25. Architecture原則

Frontend Architecture全体として以下を原則とする。

```text
Server Component First
```

```text
BrowserからLaravel APIを直接呼ばない
```

```text
Business Ruleの正はLaravel Domain
```

```text
Feature単位でコードを配置する
```

```text
app/を薄く保つ
```

```text
Generated CodeとHandwritten Codeを分離する
```

```text
Client Stateを増やしすぎない
```

```text
FrontendにBackend Domain Modelを再実装しない
```

```text
必要になるまでArchitectureを複雑化しない
```

---

# 26. 決定事項

Frontend Architectureの全体方針として、以下を正式採用する。

- Next.js App Routerを採用する
- Next.jsをFrontend + BFFとして扱う
- Server Component Firstを採用する
- Client Componentは必要最小限とする
- BrowserからLaravel APIへの直接アクセスは禁止する
- Server ComponentからLaravel APIへの直接アクセスを許可する
- ClientからLaravel APIへアクセスする場合はNext.js Server Boundaryを経由する
- Browser ↔ Next.jsはBetter Auth Sessionを使用する
- Better Auth Sessionの保存先はRedisとする
- Backend CredentialはBetter Auth Sessionと分離してRedisへ暗号化保存する
- RedisはMVPで1 Instanceとし、NamespaceとACLでAccess権限を分離する
- Application User AuthenticationはLaravelが担当する
- Next.js ↔ LaravelはLaravel Sanctum Tokenを使用する
- Next.jsからPostgreSQLへ直接接続しない
- Frontend内部はFeature-based Architectureとする
- `app/`はRouting / Layout / Compositionを中心とする
- Business RuleはLaravel Domainを正とする
- Frontend ValidationはUX向上目的とする
- BFFにはFrontend固有の集約・変換・適応のみを持たせる
- Laravel API通信は共通API Clientを使用する
- OpenAPI Generated Clientを標準とする
- Generated Codeと手書きコードを分離する
- BackendのDDD Domain ModelをFrontendへ再実装しない
- FrontendではAPI DTO / View Model / UI Stateを中心に扱う
- 状態管理はServer StateとURL Stateを優先する
- Global Client State Libraryは必要になるまで導入しない
- BackendはDomain-oriented、FrontendはFeature-orientedとする

以上をFrontend Architectureの基本方針とする。
