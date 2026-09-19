# 04_Server・Client 境界

## 1. 目的

Next.js App Routerでは、Server Component / Client Component / Server Action / Route Handlerがそれぞれ異なる役割を持つ。

本プロジェクトでは、これらの境界を明確にし、以下を実現する。

- Server Componentを基本とした構成
- Client JavaScriptの最小化
- Laravel APIへの安全なアクセス
- Sanctum TokenやSecretのBrowser流出防止
- 不要なRoute Handler経由の通信削減
- UI MutationとHTTP Endpointの責務分離
- Server / Client間の依存関係の明確化
- Business RuleをLaravel側へ集約する
- Next.js BFFの責務を明確に保つ

Frontend全体では、以下を基本方針とする。

```text id="a4mf20"
Read
    → Server Component

Interaction
    → Client Component

Mutation
    → Server Action

HTTP Endpoint
    → Route Handler
```

---

# 2. 基本境界

Next.js内の実行境界を、以下の4種類に分類する。

| 種類 | 主な実行場所 | 主な責務 |
|---|---|---|
| Server Component | Server | 表示、初期データ取得、Composition |
| Client Component | Browser | UI操作、Client State、Browser API |
| Server Action | Server | UIから発生するMutation |
| Route Handler | Server | HTTP Endpoint / BFF API |

概念的には以下とする。

```text id="b73m1c"
Browser
   │
   ▼
Next.js
├── Server Component
├── Server Action
└── Route Handler
        │
        ▼
   Shared API Client
        │
        ▼
    Laravel API
```

Client ComponentはBrowser上で動作する。

Laravel APIへのCredentialをClientへ持ち込まない。

---

# 3. Server Component First

ComponentはServer Componentをデフォルトとする。

実装時は、まず以下を判断する。

```text id="vp80kt"
Server Componentで実現できるか？
```

実現できる場合はServer Componentを採用する。

Client Componentは、Browser上でのInteractionが必要な場合に限定する。

```text id="45c2rx"
Server Component
        ↓
必要な部分だけ
        ↓
Client Component
```

Page全体を安易にClient Componentへ変更しない。

---

# 4. Server Componentの責務

Server Componentは主に以下を担当する。

- 初期データ取得
- Laravel API呼び出し
- Server-side Rendering
- Feature Composition
- Server-side View Model生成
- 認証Sessionを利用した表示制御
- Server上で完結するデータ変換

基本フローは以下とする。

```text id="ru7m4t"
Server Component
      ↓
Feature Server Query
      ↓
API Client
      ↓
Laravel API
```

例：

```tsx id="5qmb6u"
export async function EmployeeList() {
  const employees = await getEmployees();

  return <EmployeeTable employees={employees} />;
}
```

---

# 5. Server ComponentからLaravelへのアクセス

Server ComponentからLaravel APIを呼び出す場合、Next.js Route Handlerを経由しない。

以下を標準とする。

```text id="jy8i7c"
Server Component
      ↓
API Client
      ↓
Laravel API
```

以下の構成は原則採用しない。

```text id="3j5y19"
Server Component
      ↓
Route Handler
      ↓
Laravel API
```

同一Next.js Server内部で不要なHTTP Hopを追加しない。

---

# 6. Server Query

Server Componentから利用するRead処理は、Feature内のServer Moduleへ分離できる。

例：

```text id="4k8x1w"
features/
└── employees/
    └── server/
        ├── get-employees.ts
        └── get-employee.ts
```

概念的には以下とする。

```text id="v0366k"
Server Component
      ↓
getEmployees()
      ↓
API Client
      ↓
Laravel API
```

Server QueryはFrontend用のData Access処理であり、Business Logic Layerとして扱わない。

---

# 7. Client Componentの利用条件

Client Componentは、BrowserでのInteractionが必要な場合に使用する。

代表例は以下とする。

- `useState`
- `useReducer`
- `useEffect`
- Event Handler
- Browser API
- Client-side Form State
- Dialog / Modal
- Interactive Table
- Drag & Drop
- Client専用Library
- Browser上で保持する一時的UI State

Client Componentには`"use client"`を明示する。

例：

```tsx id="m1cd92"
"use client";

export function EmployeeSearchForm() {
  // Browser interaction
}
```

---

# 8. `"use client"` の位置付け

`"use client"` はComponent単体の設定ではなく、Server / ClientのModule Boundaryとして扱う。

```text id="51kzgh"
"use client"
      ↓
Client Module Graph
```

Client ComponentからimportされるModuleは、Client側へ含まれる可能性がある。

そのためServer専用処理をClient Componentの依存先に置かない。

---

# 9. Client Boundaryを小さく保つ

Client Componentが必要な場合でも、Client Boundaryは必要最小限にする。

例えば以下の画面を考える。

```text id="pk05hb"
EmployeeDetail
├── Header
├── EmployeeInformation
├── EmployeeSkillList
└── EditButton
```

`EditButton`だけにBrowser Interactionが必要な場合は、

```text id="a51rkg"
Server Component
├── Header
├── EmployeeInformation
├── EmployeeSkillList
└── Client Component
       └── EditButton
```

とする。

以下のようにPage全体をClient化しない。

```text id="07zc5i"
"use client"

EmployeeDetail
├── Header
├── EmployeeInformation
├── EmployeeSkillList
└── EditButton
```

---

# 10. Client ComponentからServer専用Moduleを参照しない

以下は禁止する。

```text id="y4msn5"
Client Component
      ↓
server/
```

例えば以下は禁止する。

```ts id="8erwot"
"use client";

import { getEmployees } from "../server/get-employees";
```

Server専用Moduleには必要に応じて以下を使用する。

```ts id="x9yu3h"
import "server-only";
```

これによりServer専用処理がClient側から参照されることを防ぐ。

---

# 11. Server ComponentからClient Componentへの依存

Server ComponentからClient Componentを利用することは許可する。

例：

```tsx id="8qx3d0"
export async function EmployeePage() {
  const employee = await getEmployee();

  return <EmployeeForm initialValue={employee} />;
}
```

Server側で必要なデータを取得し、Client側で必要な値だけPropsとして渡す。

---

# 12. ServerからClientへ渡すデータ

Server → Client Boundaryを越えるデータは必要最小限とする。

基本フローは以下とする。

```text id="jsg8vr"
Laravel API
    ↓
API DTO
    ↓
Server
    ↓
View Model
    ↓
Client Component
```

Client Componentへ渡してはいけないものは以下とする。

```text id="m05r9e"
Sanctum Token
Server Secret
Private Environment Variable
Internal Credential
不要なAuthentication情報
```

Browserへ公開する必要のあるデータだけをPropsやClient Sessionへ渡す。

---

# 13. Server Actionの位置付け

Server Actionは、UIから発生するMutationのServer Boundaryとして使用する。

主な対象は以下とする。

```text id="l6k35s"
Create
Update
Delete
Form Submit
```

基本フローは以下とする。

```text id="q2kozm"
UI
 ↓
Server Action
 ↓
API Client
 ↓
Laravel API
```

---

# 14. MutationはServer Actionを第一候補とする

通常のUI MutationではServer Actionを第一候補とする。

対象例：

- Employee作成
- Employee更新
- EmployeeSkill登録
- EmployeeSkill更新
- Skill作成
- Skill更新
- Skill無効化
- Permission変更

Feature内では必要に応じて以下へ配置する。

```text id="0lo8np"
features/
└── employees/
    └── actions/
        ├── create-employee.ts
        └── update-employee.ts
```

---

# 15. Server Actionの責務

Server Actionの主な責務を以下とする。

```text id="vvp8n6"
UI Request受付
      ↓
Authentication確認
      ↓
Authorization確認
      ↓
Frontend Validation
      ↓
API Client呼び出し
      ↓
Laravel Response処理
      ↓
Error変換
      ↓
Cache Revalidation
      ↓
Redirect / Result返却
```

必要な処理だけを担当させ、Server ActionをApplication ServiceやDomain Layerの代替として使用しない。

---

# 16. Server ActionへBusiness Ruleを置かない

Business Ruleの正はLaravel Domainとする。

例えば、

```text id="piagpl"
未経験の場合はSkill Level 1のみ
```

というRuleをFrontend側でUX目的に検証することは許可する。

ただしBusiness Integrityの保証はLaravel側で行う。

```text id="q7u2gn"
Frontend
↓
UX Validation

Laravel Domain
↓
Business Invariant
```

Server ActionをBusiness RuleのAuthorityとしない。

---

# 17. Server ActionをTrust Boundaryとして扱う

Server ActionはBrowserから到達可能なServer Boundaryとして扱う。

Clientから渡された値を信用しない。

以下を必要に応じて確認する。

```text id="xka0nb"
Authentication
Authorization
Input Validation
Request Context
```

「Server上で実行されるため安全」とは判断しない。

---

# 18. Route Handlerの位置付け

Route Handlerは、HTTP Endpoint自体が必要な場合に利用する。

配置先は以下とする。

```text id="3nh082"
app/api/
```

Route HandlerはすべてのLaravel API通信を中継するProxy Layerとしては使用しない。

---

# 19. Route Handlerを利用するケース

Route Handlerは主に以下で利用する。

### BrowserからHTTP Endpointが必要な場合

```text id="yb3jgj"
Client Component
      ↓
Next.js Route Handler
      ↓
API Client
      ↓
Laravel API
```

### Client-side Data Fetching

Browserから明示的に再取得する必要がある場合。

### Authentication関連Endpoint

Auth.js等がHTTP Endpointを必要とする場合。

### External Callback

外部ServiceからNext.jsへのCallback Endpointが必要な場合。

### Webhook

将来的にWebhook受信が必要になった場合。

### HTTP Response制御

以下のようなHTTP Response自体を制御する必要がある場合。

- File Response
- Streaming
- Custom Header
- Download
- Proxy的なResponse変換

---

# 20. Route Handlerを使用しないケース

Server Componentのデータ取得のためだけにRoute Handlerを作成しない。

以下は原則採用しない。

```text id="8tkubo"
Server Component
      ↓
Route Handler
      ↓
Laravel API
```

以下を利用する。

```text id="ezd72h"
Server Component
      ↓
API Client
      ↓
Laravel API
```

通常のUI MutationについてもRoute HandlerよりServer Actionを第一候補とする。

---

# 21. Server ActionとRoute Handlerの使い分け

基本的な判断基準を以下とする。

| 要件 | 採用 |
|---|---|
| Server Rendering時のRead | Server Component / Server Query |
| Form Submit | Server Action |
| UIからCreate / Update / Delete | Server Action |
| BrowserからHTTP APIが必要 | Route Handler |
| Client-side Fetch | Route Handler |
| Authentication Endpoint | Route Handler |
| External Callback | Route Handler |
| Webhook | Route Handler |
| Server ComponentからLaravel API | API Client直接利用 |

基本原則を以下とする。

```text id="q4387j"
UI Action
↓
Server Action
```

```text id="25ynfx"
HTTP Endpoint
↓
Route Handler
```

---

# 22. 不要な多段Boundaryを作らない

Server ActionからRoute Handlerを経由してLaravelへアクセスしない。

以下は原則禁止する。

```text id="ydqnyr"
Client
 ↓
Server Action
 ↓
Route Handler
 ↓
Laravel API
```

以下とする。

```text id="gr7htx"
Client
 ↓
Server Action
 ↓
API Client
 ↓
Laravel API
```

同様にServer ComponentでもRoute Handlerを経由しない。

---

# 23. Laravel API Clientを共通出口とする

Next.js Server内には複数のEntry Pointが存在する。

```text id="nbeejr"
Server Component
Server Action
Route Handler
```

Laravelへの通信出口は共通化する。

```text id="rjrzvr"
Server Component ────┐
                     │
Server Action ───────┼──→ API Client ───→ Laravel API
                     │
Route Handler ───────┘
```

API Clientで以下を共通化する。

- Base URL
- Sanctum Token付与
- Common Header
- Request設定
- Response処理
- API Error normalization
- Trace / Logging関連情報

---

# 24. BrowserからLaravel APIへ直接通信しない

以下は禁止する。

```text id="w2as29"
Browser
   ↓
Laravel API
```

Client ComponentからLaravel APIへ直接`fetch()`しない。

Laravel APIへアクセスする場合は必ずNext.js Server Boundaryを利用する。

```text id="0r19a3"
Client
  ↓
Server Action
  ↓
Laravel
```

または、

```text id="xmz6ei"
Client
  ↓
Route Handler
  ↓
Laravel
```

とする。

---

# 25. Readの基本フロー

通常の一覧・詳細表示では以下を標準とする。

```text id="0a60uc"
Browser Request
      ↓
Server Component
      ↓
Feature Server Query
      ↓
API Client
      ↓
Laravel API
      ↓
API DTO
      ↓
Mapper / View Model
      ↓
Server Component
      ↓
Browser
```

例：

```text id="aij0zz"
employees/page.tsx
      ↓
EmployeeList
      ↓
getEmployees
      ↓
API Client
      ↓
GET /employees
```

---

# 26. Mutationの基本フロー

通常のMutationでは以下を標準とする。

```text id="wq4xrb"
Browser
   ↓
Form / Client Component
   ↓
Server Action
   ↓
Frontend Validation
   ↓
API Client
   ↓
Laravel API
   ↓
Laravel Validation
   ↓
Laravel Domain
   ↓
Result
   ↓
Cache Revalidation
   ↓
UI更新
```

詳細なMutation設計は`05_データ取得・更新.md`で定義する。

---

# 27. Client-side Read

ReadはServer Componentを基本とする。

ただし以下の場合はClient-side Readを許可する。

- ユーザー操作による追加取得
- Autocomplete
- Infinite Scroll
- Polling
- Server Navigationなしで頻繁に更新するデータ
- Client専用Libraryとの統合
- Browser上で完結するInteractionからの再取得

Client-side Readの場合は以下とする。

```text id="ez10sw"
Client Component
      ↓
Route Handler
      ↓
API Client
      ↓
Laravel API
```

BrowserからLaravel APIへ直接アクセスしない。

---

# 28. Search / Filter / Pagination

通常の検索・Filter・PaginationではClient-side Fetchを第一候補としない。

URL Stateを利用する。

例：

```text id="fu3xya"
/employees?keyword=php&department=3&page=2
```

基本フローは以下とする。

```text id="9nhff5"
Browser
 ↓
URL Search Params
 ↓
Server Component
 ↓
Laravel API
```

これにより以下を実現する。

- URL共有
- Browser History
- Reload時の状態維持
- Server Renderingとの統合
- 不要なGlobal Client State削減

---

# 29. Server / Client Composition

Server ComponentのTree内部にClient Componentを配置することを許可する。

```text id="cz70lc"
Server
├── Server
├── Server
├── Client
└── Server
```

Client Componentが必要だからといって、上位ComponentまでClient化しない。

Interactionが必要な位置にClient Boundaryを置く。

---

# 30. Client Componentとchildren Composition

必要に応じてClient ComponentへServer側で生成したUIを`children`として渡すCompositionを利用できる。

概念的には以下とする。

```text id="z2aumm"
Server
 ↓
Client Shell
 ↓
Server Content
```

ただし複雑なCompositionは避ける。

Server / Client Boundaryを分かりにくくする構造は採用しない。

---

# 31. 認証境界

認証境界を以下とする。

```text id="5n52ne"
Browser
   │
   │ Auth.js Session
   ▼
Next.js Server
   │
   │ Laravel Sanctum Token
   ▼
Laravel API
```

BrowserはAuth.js Sessionのみを扱う。

Laravel Sanctum TokenはNext.js Server内で管理する。

---

# 32. Sanctum Tokenの境界

Sanctum TokenへアクセスできるのはServer側のみとする。

対象例：

```text id="9bqug3"
Server Component用Server Module
Server Action
Route Handler
lib/api Server Client
```

Client ComponentからSanctum Tokenへアクセスさせない。

以下は禁止する。

```text id="zz79h5"
Sanctum Token
      ↓
Client Component
```

```text id="7uwap6"
Sanctum Token
      ↓
Browser Storage
```

---

# 33. Environment Variable境界

Secretを含むEnvironment VariableはServer専用とする。

```text id="3hmgz7"
Server Environment
       ↓
Server Module
```

以下をClient側へ公開しない。

- Laravel Credential
- Authentication Secret
- Internal API Secret
- Server-only Configuration

Clientへ公開する値は、明示的にPublic情報として設計したものだけとする。

---

# 34. Authentication / Authorization

Server Component / Server Action / Route Handlerでは、必要なBoundaryでAuthenticationを確認する。

Mutationや保護されたEndpointではAuthorizationも確認する。

ただし、最終的なAuthorization AuthorityはLaravel側にも持たせる。

概念的には以下とする。

```text id="6cmmwd"
Next.js
↓
Frontend / BFF Access Control

Laravel
↓
Backend Authorization
```

Next.jsだけをSecurity Boundaryとして信用しない。

---

# 35. Server BoundaryのTrust Model

ClientからServer Boundaryへ渡された値は信用しない。

対象は以下とする。

```text id="hbg720"
Form Data
URL Parameter
Search Parameter
Client State
Hidden Field
ID
Role情報
Permission情報
```

Server Boundaryでは必要に応じて以下を実施する。

- Authentication
- Authorization
- Input Validation
- Parameter normalization
- API Request adaptation

Business RuleについてはLaravelで再検証する。

---

# 36. Business RuleのAuthority

Frontend / BFFではUX改善のためBusiness Ruleに関連する制御を行える。

例：

```text id="kv92ye"
未経験を選択
↓
Level 1以外をUI上で選択不可
```

ただしBusiness IntegrityのAuthorityはLaravel Domainとする。

```text id="y9hgky"
Frontend
=
UX Assistance

Laravel Domain
=
Business Correctness
```

Next.js Server Action / Route HandlerへDomain Logicを移植しない。

---

# 37. 不要なClient化を避ける

以下はClient Component化の理由とはしない。

```text id="pno1bf"
データを取得したい
```

```text id="bjh3xr"
APIを呼びたい
```

```text id="57cegf"
async処理を行いたい
```

これらはServer Component / Server Moduleで実現する。

Client Component化の主な理由は、

```text id="aydgak"
Browser Interactionが必要
```

であることとする。

---

# 38. Server Component判断フロー

Component実装時は以下の順番で判断する。

```text id="5nph28"
Componentが必要
      ↓
Server Componentで実現可能か？
      │
      ├── Yes
      │    ↓
      │ Server Component
      │
      └── No
           ↓
Browser Interactionが必要か？
           │
           ├── Yes
           │    ↓
           │ Client Component
           │
           └── No
                ↓
          設計を再確認
```

---

# 39. Read判断フロー

Read処理は以下とする。

```text id="t4tsov"
Read
 │
 ├── Page / Server Renderingで必要
 │       ↓
 │   Server Query
 │       ↓
 │   API Client
 │       ↓
 │   Laravel
 │
 └── Browser Interactionから取得
         ↓
     Route Handler
         ↓
     API Client
         ↓
     Laravel
```

---

# 40. Mutation判断フロー

Mutation処理は以下とする。

```text id="g54vrz"
Mutation
   │
   ├── UI操作に紐づく
   │       ↓
   │   Server Action
   │       ↓
   │   API Client
   │       ↓
   │   Laravel
   │
   └── HTTP Endpoint自体が必要
           ↓
       Route Handler
           ↓
       API Client
           ↓
       Laravel
```

---

# 41. BFFとしてのNext.js

Next.jsをBFFとして使用するが、

```text id="hmy73r"
BFF
=
すべてをRoute Handler経由にする
```

とは定義しない。

Next.js Server上で実行される以下すべてがBFF Boundaryを構成する。

```text id="ad7yhl"
Server Component
Server Query
Server Action
Route Handler
API Client
```

目的は、

- BrowserからBackend Credentialを隠す
- Frontend向けデータ変換
- API aggregation
- Request / Response adaptation
- Authentication Context付与

であり、不要なHTTP Layerを追加することではない。

---

# 42. 境界の全体像

最終的な境界を以下とする。

```text id="my2i2t"
┌──────────────────────────────────────────┐
│ Browser                                  │
│                                          │
│ Client Component                         │
│ Auth.js Session                          │
└───────────────────┬──────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────┐
│ Next.js Server                           │
│                                          │
│ Server Component                         │
│ Server Query                             │
│ Server Action                            │
│ Route Handler                            │
│                                          │
│              ↓                           │
│          API Client                      │
│                                          │
│ Sanctum Token / Server Secret            │
└───────────────────┬──────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────┐
│ Laravel API                              │
│                                          │
│ Validation                               │
│ Authorization                            │
│ Application                              │
│ Domain                                   │
└──────────────────────────────────────────┘
```

---

# 43. 基本パターン

本プロジェクトでは、以下の4パターンを基本とする。

## Read

```text id="2kao6f"
Server Component
      ↓
API Client
      ↓
Laravel
```

## Interaction

```text id="eyngoi"
Server Component
      ↓
必要な箇所のみ
      ↓
Client Component
```

## Mutation

```text id="rk0pcj"
Client / Form
      ↓
Server Action
      ↓
API Client
      ↓
Laravel
```

## HTTP API

```text id="8k6n4w"
Browser / External Client
      ↓
Route Handler
      ↓
API Client
      ↓
Laravel
```

---

# 44. 決定事項

FrontendのServer / Client境界として、以下を正式採用する。

- Server Component Firstを採用する
- ComponentはServer Componentをデフォルトとする
- Client ComponentはBrowser Interactionが必要な場合に限定する
- `"use client"`をServer / Client Module Boundaryとして扱う
- Client Boundaryを可能な限り小さくする
- Page全体の不要なClient Component化を避ける
- 初期ReadはServer Component / Server Queryを基本とする
- Server ComponentからLaravel APIへ共通API Client経由で直接アクセスする
- Server Componentから自分自身のRoute Handlerを経由しない
- FeatureのServer専用Read処理は`server/`へ配置する
- Client ComponentからServer-only Moduleへの直接依存は禁止する
- Server専用Moduleでは必要に応じて`server-only`を利用する
- Server ComponentからClient Componentへの依存を許可する
- ServerからClientへ渡すデータは必要最小限とする
- Sanctum TokenやServer SecretをClientへ渡さない
- 通常のUI MutationではServer Actionを第一候補とする
- Server ActionはUI MutationのServer Boundaryとして扱う
- Server ActionをBusiness Logic Layerとして使用しない
- Server ActionでもAuthentication / Authorization / Input Validationを行う
- Clientから渡された値を信用しない
- Route HandlerはHTTP Endpoint自体が必要な場合に使用する
- Route HandlerをLaravel APIの一律Proxyとして使用しない
- Client-side ReadはRoute Handler経由を基本とする
- Auth Endpoint / Callback / Webhook等ではRoute Handlerを使用する
- Server ActionからRoute Handlerを経由してLaravelへアクセスしない
- Server Component / Server Action / Route HandlerからLaravelへの通信を共通API Clientへ集約する
- BrowserからLaravel APIへの直接アクセスは禁止する
- 検索・Filter・PaginationはURL State + Server Componentを優先する
- BrowserはAuth.js Sessionを扱う
- Next.js ServerのみLaravel Sanctum Tokenを扱う
- Secretを含むEnvironment VariableはServer専用とする
- Next.js側でも必要なAccess Controlを行うが、Backend Authorizationも必ず維持する
- Frontend / BFFはUX Assistanceを担当し、Business CorrectnessはLaravel Domainが保証する
- BFFはすべての通信をRoute Handler化することを意味しない

以上をFrontendのServer・Client境界とする。
