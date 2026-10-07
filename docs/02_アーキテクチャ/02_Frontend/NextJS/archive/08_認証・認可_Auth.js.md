# 08_認証・認可

## 1. 目的

本プロジェクトでは、AuthenticationとAuthorizationの責務をNext.jsとLaravelで明確に分離する。

目的は以下とする。

- Browser ↔ Next.jsの認証をAuth.jsへ統一する
- Next.js ↔ Laravelの認証をLaravel Sanctumへ統一する
- Sanctum TokenをBrowserへ公開しない
- Frontend AuthorizationとBackend Authorizationの責務を分離する
- UI制御とSecurity Authorityを混同しない
- Role判定の散在を防ぐ
- Resource単位の最終AuthorizationをLaravelへ集約する
- Server Action / Route HandlerをTrust Boundaryとして扱う
- Authentication / Authorizationの多層防御を実現する
- Session / Permission / Credentialの二重管理を防ぐ

基本方針を以下とする。

```text id="1pcr9t"
Authentication
=
Auth.js / Next.js

Frontend Authorization
=
Next.jsで表示・Navigation・操作可否を制御

Business Authorization
=
Laravelで最終保証
```

全体の認証境界は以下とする。

```text id="4ir1j1"
Browser
   │
   │ Auth.js Session
   ▼
Next.js
   │
   │ Sanctum Token
   ▼
Laravel
```

Authorizationの責務は以下とする。

```text id="slw9jq"
Next.js Authorization
=
UX / Early Rejection

Laravel Authorization
=
Security Authority
```

---

## 2. AuthenticationとAuthorizationを分離する

AuthenticationとAuthorizationは別責務として扱う。

```text id="umozzn"
Authentication
=
誰であるか

Authorization
=
何をしてよいか
```

Frontend Architecture上でもこの区別を維持する。

---

## 3. AuthenticationのSource of Truth

Browser ↔ Next.jsのAuthenticationはAuth.jsをSource of Truthとする。

```text id="vv2prd"
Browser
   ↓
Auth.js Session
   ↓
Next.js Server
```

独自のAuthentication Stateを別途Global Storeへ複製しない。

避ける例：

```text id="7hljqf"
isLoggedIn
currentUser
authStore
```

Auth.js Sessionと別のAuthentication Source of Truthを作らない。

---

## 4. Auth.js Session Store

Auth.js Session StoreにはPostgreSQLを利用する。

```text id="q96c1w"
Browser
   │
   │ Session Cookie
   ▼
Auth.js
   │
   ▼
PostgreSQL Session Store
```

BrowserはSession DB Recordそのものを管理しない。

Browser側はAuth.js Session Cookieを利用する。

---

## 5. Laravel Authentication

Next.js → Laravel APIのAuthenticationにはLaravel Sanctum Tokenを使用する。

```text id="hv1u49"
Next.js Server
   │
   │ Bearer Token
   ▼
Laravel Sanctum
```

Sanctum TokenはBrowserへ公開しない。

```text id="lhd1iu"
Browser
  ×
Sanctum Token
```

---

## 6. 二つのAuthentication Boundary

本Applicationには以下の2つのAuthentication Boundaryが存在する。

```text id="81weze"
① Browser
      ↓
   Auth.js
      ↓
   Next.js

② Next.js
      ↓
   Sanctum
      ↓
   Laravel
```

この2つを混在させない。

BrowserからLaravel Sanctumへ直接Authenticationさせる構成は採用しない。

---

## 7. Server-side Session取得

Server Component / Server Action / Route Handler等のServer側処理では、Auth.jsのServer APIからCurrent Sessionを取得する。

概念例：

```ts id="hp733h"
const session = await auth();
```

Server側でAuthentication判断できる場合は、Client ComponentへSession判定を移さない。

---

## 8. Client-side Session取得

Client ComponentでAuthentication情報が本当に必要な場合のみ、Auth.jsのClient APIを利用する。

```text id="hl4juq"
Client Component
↓
Session参照
```

をApplication全体のDefaultにはしない。

Server Component Firstの方針に従い、Serverで判断可能なAuthentication / AuthorizationはServer側で処理する。

---

## 9. SessionProvider

Client側でAuth.js Session Contextが必要な場合のみ`SessionProvider`を利用する。

以下のようにApplication全体へ無条件にProviderを配置しない。

```text id="vke3jd"
Root Layout
 ↓
SessionProvider
 ↓
Application全体
```

Client Sessionが必要な範囲へ限定する。

---

## 10. Protected Route

Authentication必須Routeへの未Authentication UserのアクセスをNext.js側で防止する。

基本Flow：

```text id="fj4mkr"
Request
   ↓
Next.js Route Boundary
   ↓
Authenticated?
   ├── No  → LoginへRedirect
   └── Yes → Protected Route
```

Next.jsの現在の構成に合わせ、粗いRoute ProtectionにはProxyを利用する。

---

## 11. Proxyの責務

Proxyでは主に粗いAuthentication Boundaryを扱う。

例：

```text id="bi9kf4"
/login
=
Public

/employees/*
/skills/*
/skill-categories/*
/access-control/*
=
Authenticated
```

ProxyへResource単位の複雑なBusiness Authorizationを配置しない。

---

## 12. Proxyで扱わないAuthorization

例えば以下のような判定をProxyだけで完結させない。

```text id="t1n7ot"
Sub Manager Aは
Employee 123を編集可能か？
```

このようなResource Relationを伴うAuthorizationの最終判断はLaravelで行う。

Proxyでは、

```text id="33cgb8"
Authenticatedか
Route大分類へ入れるか
```

程度を基本とする。

---

## 13. Route Group

既存Directory設計のRoute Groupを利用する。

```text id="76havz"
app/
├── (auth)/
└── (dashboard)/
```

概念的には以下とする。

```text id="9ynxra"
(auth)
=
Public / Authentication関連

(dashboard)
=
Authentication必須領域
```

ただしRoute GroupそのものにはSecurity機能がない。

実際のProtectionはAuth.js / Proxy / Server-side Checkで行う。

---

## 14. Server ComponentでのAuthentication Check

重要なServer Componentでは必要に応じてSessionを確認する。

```text id="8ey2vm"
Server Component
      ↓
auth()
      ↓
Session確認
```

Proxyを通過したことだけを理由に、Server側Authentication Contextを無条件に信用しない。

---

## 15. Defense in Depth

Authentication / Authorizationは単一箇所へ依存させない。

```text id="dbbi4o"
Proxy
   ↓
Next.js Server Boundary
   ↓
Laravel
```

各Layerで同一Logicをコピーするのではなく、それぞれ異なる責務を持たせる。

---

## 16. Authorization基本方針

Authorizationは以下の二段階に分ける。

```text id="r2pcro"
Next.js
=
Frontend Authorization

Laravel
=
Backend Authorization
```

Next.jsはUX / Early Rejectionを担当する。

LaravelはSecurity Authorityを担当する。

---

## 17. Frontend Authorization

Next.js側では以下のUI制御を行うことができる。

```text id="kwg4cl"
Menu非表示
Button非表示
Edit UI無効化
Route Navigation抑制
Forbidden UI表示
```

例：

```text id="8latxs"
Team Leader
↓
Employee Detail閲覧可能

Edit Button
↓
非表示
```

これはFrontend UX上のAuthorizationとする。

---

## 18. UI制御をSecurity Authorityとしない

ButtonやMenuを非表示にしてもSecurity保証にはならない。

```text id="1ydhff"
UI非表示
≠
Security
```

Frontendを迂回したRequestが送信される可能性があるため、Laravel側で必ずAuthorizationする。

---

## 19. LaravelをAuthorizationの最終Authorityとする

最終的なアクセス可否はLaravelで決定する。

```text id="hchpdb"
Next.js
 ↓
Request
 ↓
Laravel
 ↓
Authentication
 ↓
Authorization
 ↓
Allowed / Forbidden
```

Resource単位のAuthorizationはLaravel Policy等で実装する。

---

## 20. Frontend / Backend二重防御

基本原則を以下とする。

```text id="lwcjir"
Frontend
=
できない操作を見せない

Backend
=
できない操作を実行させない
```

したがって、

```text id="278gu0"
Frontend Authorization
+
Backend Authorization
```

を採用する。

---

## 21. Role

本ApplicationのRoleは以下とする。

```text id="uwgh9x"
Administrator
Manager
Sub Manager
Team Leader
General Employee
```

General EmployeeはApplicationを利用しないため、通常のAuthenticated Application Userとして扱わない。

---

## 22. RoleだけでAuthorizationしない

AuthorizationはRoleだけでは決定しない。

特にSub Manager / Team Leaderは担当EmployeeとのRelationshipが必要となる。

基本的な判断要素を以下とする。

```text id="zyfge3"
Role
+
Resource Relationship
+
Permission
```

---

## 23. RoleとResource Scope

基本Scopeを以下とする。

```text id="8y54ip"
Administrator
→ 全体管理

Manager
→ 全Employee操作可能

Sub Manager
→ Assigned Employeeのみ操作可能

Team Leader
→ Assigned Employeeのみ閲覧可能

General Employee
→ Application利用不可
```

---

## 24. Permission管理権限

Administratorには追加属性として、

```text id="mbm72l"
can_manage_permissions
```

が存在する。

Permission管理可否を以下だけで判断しない。

```text id="f2ogof"
role === ADMINISTRATOR
```

Permission管理には、

```text id="jgvloz"
ADMINISTRATOR
+
can_manage_permissions = true
```

を必要とする。

---

## 25. Permission管理者最低1人Invariant

以下のInvariantを維持する。

```text id="5gt7ud"
can_manage_permissions = true
のAdministratorを
最低1人維持する
```

Frontendでは警告・操作抑制等を行ってよいが、Invariantの最終保証はLaravel Application / Domainで行う。

Frontendだけでは保証しない。

---

## 26. Frontend Authorization情報

FrontendへはUI制御に必要な最小限のAuthorization情報のみ渡す。

必要に応じてCapability形式を利用する。

概念例：

```ts id="pwnuxm"
type FrontendPermissions = {
  canViewEmployees: boolean;
  canEditEmployees: boolean;
  canManageSkills: boolean;
  canManagePermissions: boolean;
};
```

具体的なCapability定義はAPI Contractと合わせて確定する。

---

## 27. Role CheckをUIへ散在させない

以下のようなRole Checkを多数のComponentへ散在させない。

```ts id="bo0jje"
if (user.role === "ADMINISTRATOR") {
  // ...
}
```

または、

```ts id="0rs0cq"
if (
  user.role === "MANAGER" ||
  user.role === "ADMINISTRATOR"
) {
  // ...
}
```

Authorization Ruleの重複と変更影響拡大につながるため避ける。

---

## 28. Capabilityを優先する

UI側では可能な範囲でCapabilityを利用する。

```text id="35w052"
Role / Session Context
       ↓
Frontend Authorization
       ↓
Capability
       ↓
UI
```

例：

```ts id="gxh57f"
if (permissions.canEditEmployees) {
  // Edit UI
}
```

Role Structure変更の影響をUIへ広げにくくする。

---

## 29. CapabilityをSecurity Authorityとしない

Frontendへ渡されたCapabilityはUI制御にのみ利用する。

例えば、

```text id="t4oe09"
canEditEmployees = true
```

はSecurity Authorityではない。

Browser側Dataは改変可能であるため、LaravelはRequestごとにAuthorizationする。

---

## 30. Resource単位Authorization

Resource単位のAuthorizationはUserとResourceの関係をもとに判断する。

例：

```text id="ibnmiw"
Sub Manager A
      ↓
Employee 10
→ Assigned
→ Update Allowed

Employee 20
→ Not Assigned
→ Forbidden
```

この判定の最終AuthorityはLaravelとする。

---

## 31. Server ReadとAuthorization

Server Component / Server QueryがResource APIへアクセスし、Laravelから403が返された場合、Next.js側でForbidden UIへMappingする。

```text id="h4aq93"
Server Component
      ↓
getEmployee(123)
      ↓
Laravel
      ↓
403
      ↓
Forbidden UI
```

Laravel Authorization RuleをFrontendへ完全再実装しない。

---

## 32. Early Authorization

Current SessionのRole / Capabilityから明らかに禁止される操作についてはNext.js側でEarly Rejectionを行ってよい。

例：

```text id="v2l0oe"
Team Leader
+
Employee Create Page
```

の場合、

```text id="imw2pl"
Navigation非表示
Forbidden UI
Redirect
```

等を利用できる。

目的はSecurityの代替ではなく、

```text id="tax394"
UX改善
+
不要Request削減
```

とする。

---

## 33. Server ActionはTrust Boundary

Server ActionはClientから呼び出され得るServer Boundaryとして扱う。

基本Flow：

```text id="3v7m7a"
Server Action
      ↓
Authentication
      ↓
Frontend Authorization
      ↓
Validation
      ↓
API Client
      ↓
Laravel Authorization
```

Client側Button非表示等を信用しない。

---

## 34. Server ActionでもLaravel Authorizationを必須とする

Next.js Server Action側でAuthorizationを確認していても、Laravel Authorizationを省略しない。

```text id="1xoc9p"
Next.js Authorization
+
Laravel Authorization
```

Laravelを最終Authorityとする。

---

## 35. Route HandlerはTrust Boundary

Route HandlerはBrowserから直接到達可能なHTTP Endpointである。

したがって、

```text id="0ix4ld"
Browser
 ↓
Route Handler
 ↓
Authentication
 ↓
Frontend Authorization
 ↓
API Client
 ↓
Laravel Authorization
```

を基本とする。

---

## 36. Route Handlerを無認証Proxyにしない

以下の構成は禁止する。

```text id="5bw4sr"
Browser
 ↓
Route Handler
 ↓
認証確認なし
 ↓
Laravel Credential付与
 ↓
Laravel
```

Route HandlerではCurrent User Contextを必ず確認する。

---

## 37. Sanctum Token

Sanctum TokenはServer-onlyとする。

利用可能な範囲は以下とする。

```text id="vuasst"
Auth.js Server-side処理
Server-side Session関連処理
Server-only API Client
Server Action
Route Handler
Server Query
```

Browserへ返却するDataには含めない。

---

## 38. Sanctum TokenをPropsへ渡さない

以下は禁止する。

```tsx id="t1wlpb"
<EmployeeList
  sanctumToken={token}
/>
```

Server ComponentからClient ComponentへもTokenを渡さない。

---

## 39. Sanctum TokenをBrowser Storageへ保存しない

以下への保存は禁止する。

```text id="oyzj7f"
localStorage
sessionStorage
IndexedDB
Client-side Global Store
```

BrowserはAuth.js Sessionのみを利用する。

---

## 40. Session Responseを最小化する

Clientへ公開するSession情報は必要最小限とする。

候補：

```text id="7yl2v8"
User ID
Display Name
Role
Frontend Capability
Session Expiration
```

以下は公開しない。

```text id="9r9gq7"
Sanctum Token
Internal Credential
Server Secret
Password Hash
Authentication Secret
```

---

## 41. SessionへUser Entity全体を格納しない

FrontendでUser識別が必要な場合は必要なIdentifierをSessionへ含めてよい。

ただし、

```text id="rqel3n"
Session
=
Frontend Authentication Context

≠
User Database Dump
```

とする。

User Entity全体や大量の関連DataをSessionへ詰め込まない。

---

## 42. Sessionへ大量のAuthorization Dataを保持しない

以下のようなDataをSessionへ大量に格納しない。

```text id="4l5i7q"
全担当Employee ID
Resourceごとの全Permission
全Skill Data
大量のBackend Entity Data
```

Resource単位AuthorizationはLaravelへ問い合わせる。

---

## 43. Permission Freshness

Role / Permission変更後、ClientまたはSession上のCapabilityが一時的に古くなる可能性を考慮する。

したがって、

```text id="d1n6sz"
Session Capability
=
UI Hint

Laravel Authorization
=
Current Security Authority
```

とする。

Session情報のFreshnessだけにSecurityを依存しない。

---

## 44. Authentication Failure

未Authentication UserがProtected Routeへアクセスした場合はLoginへ誘導する。

```text id="2uo7dd"
Protected Route
      ↓
Authenticationなし
      ↓
LoginへRedirect
```

Session失効時も同様に再Authenticationへ誘導する。

---

## 45. Authorization Failure

Authentication済みだがPermissionがない場合はForbiddenとして扱う。

```text id="wljuv8"
Authenticated
+
Permissionなし
=
403 Forbidden
```

以下を区別する。

```text id="7o1s6m"
Unauthenticated
→ Login

Unauthorized / Forbidden
→ Forbidden UI
```

---

## 46. 401と403

HTTP Statusの意味を維持する。

```text id="eehaqm"
401
=
Authenticationが必要
またはCredentialが無効

403
=
Authentication済みだがPermissionなし
```

Frontend Error Handlingでもこの違いを保持する。

---

## 47. 404との関係

Resource存在有無を権限のないUserへ公開したくない場合など、Laravel側Security Policyとして403ではなく404を返す設計を許可する。

この判断はBackend Security / API Policy側で行う。

Frontendが独自に403を404へ変換しない。

---

## 48. Login Page

Login PageはPublic Routeとする。

```text id="z7a5ho"
app/
└── (auth)/
    └── login/
```

Authenticated UserがLogin Pageへアクセスした場合は、Dashboard等のAuthenticated領域へRedirectすることを検討する。

---

## 49. Logout

LogoutではAuth.js Sessionを終了する。

必要に応じてLaravel Sanctum Tokenも失効させる。

概念Flow：

```text id="mxpz6a"
Logout
 ↓
Auth.js Session終了
 ↓
Laravel Sanctum Token失効
 ↓
Loginへ遷移
```

具体的なToken LifecycleとLogout手順はAuthentication実装設計で確定する。

---

## 50. Session ExpirationとToken Expiration

Auth.js SessionとLaravel Sanctum TokenのExpiration / Revocationは独立して発生し得る。

例：

```text id="hifqyv"
Auth.js Session
      ↓
有効

Sanctum Token
      ↓
失効

Laravel API
      ↓
401
```

この場合、Laravel 401をAuthentication失効として適切に処理する。

---

## 51. Sanctum Token Lifecycle

以下をAuthentication実装設計で明示する。

```text id="0hqcvn"
発行
保存
取得
利用
Expiration
更新
Revocation
Logout時の失効
```

Frontend Architecture上の必須Ruleは、

```text id="1h4pby"
Sanctum Token Lifecycle
=
Server-only
```

とする。

---

## 52. CSRF

Browser ↔ Next.js AuthenticationについてはAuth.js / Next.jsのSecurity Mechanismを利用する。

Next.js → LaravelはServer-to-ServerのSanctum Token Authenticationとする。

したがって、

```text id="2qae31"
Browser
↓
Laravel Cookie Authentication
```

を採用する構成とは分離する。

CSRF対策を独自に無効化するのではなく、それぞれのAuthentication Boundaryに適したSecurity Mechanismを利用する。

---

## 53. Open Redirect対策

Login後のRedirect先等を外部Inputから受け取る場合、任意External URLへRedirectできないようにする。

例えば、

```text id="vc7fed"
/login?callbackUrl=...
```

等については、Auth.jsの安全なRedirect Mechanismまたは許可済みApplication Routeのみを利用する。

---

## 54. Authentication DataのLogging

以下をLogへ出力しない。

```text id="7v0ufn"
Password
Session Token
Sanctum Token
Cookie
Authorization Header
Authentication Secret
```

Authentication Failure LogにもCredentialそのものを含めない。

---

## 55. Authorization Audit

監査要件に応じて以下を記録できる。

```text id="hw5u6o"
User ID
Action
Resource Type
Resource ID
Result
Timestamp
```

Authorization Audit Logの主たるSource of TruthはLaravel側とする。

Frontend LogをSecurity AuditのAuthorityとはしない。

---

## 56. Server-only Environment Variable

以下のAuthentication関連設定はServer-onlyとする。

```text id="oysp5b"
AUTH_SECRET
Laravel API Credential関連設定
Internal Laravel API URL
Authentication Secret
```

必要がない限り`NEXT_PUBLIC_*`として公開しない。

---

## 57. `lib/auth/`

Authentication / Frontend Authorizationの共通処理は`lib/auth/`へ配置する。

基本例：

```text id="6s6j2v"
lib/
└── auth/
    ├── auth.ts
    ├── session.ts
    ├── permissions.ts
    └── index.ts
```

実際のFile構成はAuth.jsの設定方式に合わせて調整する。

---

## 58. `auth.ts`

`auth.ts`はAuth.jsのConfigurationおよびServer-side Authentication Entry Pointを担当する。

概念：

```text id="23inkd"
auth.ts
├── Auth.js Configuration
├── auth()
├── signIn()
└── signOut()
```

Authentication関連処理を無秩序に巨大な`auth.ts`へ集約しない。

---

## 59. `session.ts`

必要に応じてSession操作Helperを配置する。

例：

```text id="nwjh4e"
requireSession()
getCurrentUser()
```

ただしAuth.js Sessionを別Stateへ複製するためのHelperにはしない。

---

## 60. `permissions.ts`

Frontend表示制御用の軽量Permission Helperを必要に応じて配置する。

例：

```text id="2uk82u"
canEditEmployee(...)
canManagePermissions(...)
```

ただしLaravel Policy / Domain AuthorizationをFrontendへ完全再実装しない。

Role / Capabilityから明らかなUI制御のみ担当する。

---

## 61. Feature固有Authorization

Resource / Feature固有のUI Authorizationが複雑になった場合は、Feature内部へ配置することを許可する。

例：

```text id="77kzv8"
features/
└── employees/
    └── ...
```

ただしShared Authentication Infrastructureは`lib/auth/`へ置く。

---

## 62. Authentication Dependency

基本Dependencyを以下とする。

```text id="9m2bde"
Feature
   ↓
lib/auth
```

逆依存は禁止する。

```text id="1dhu9g"
lib/auth
   ×
features
```

`lib/auth`がEmployee / Skill等のFeature概念へ依存しないようにする。

---

## 63. Protected Server Query

Authentication必須Dataを取得するServer QueryはCurrent Authentication Contextを利用したAPI Client経由でLaravelへアクセスする。

```text id="l6kxwf"
Server Query
      ↓
API Client
      ↓
Current Authentication Context
      ↓
Sanctum Credential
      ↓
Laravel
```

Feature側でCredentialを組み立てない。

---

## 64. Public APIとAuthenticated API

Laravel側でPublic Endpointを提供する場合は、OpenAPI Contract上でPublic / Authenticated Endpointを明確に区別する。

API ClientがTokenを自動付与することだけに依存してSecurity要件を暗黙化しない。

---

## 65. Client Componentへ渡すUser情報

Client ComponentへCurrent User情報を渡す場合は必要最小限とする。

概念例：

```ts id="06e1jc"
type CurrentUserView = {
  id: string;
  displayName: string;
  canEditEmployee: boolean;
};
```

Server Session Object全体をClientへ渡すことをDefaultとしない。

---

## 66. Authorization UI Component

必要に応じて以下のようなPresentation Utilityを作成できる。

```text id="5sdlio"
<Can>
<Authorized>
<PermissionGate>
```

ただし初期段階から汎用Authorization Frameworkを構築しない。

Simpleな条件分岐で十分ならそれを利用する。

---

## 67. Authorization UI ComponentはSecurity Boundaryではない

例えば、

```tsx id="kmrn1q"
<PermissionGate permission="employee.update">
  <EditButton />
</PermissionGate>
```

を利用してもSecurity Boundaryにはならない。

これはPresentation Utilityであり、Laravel Authorizationを必須とする。

---

## 68. Navigation

Navigation MenuはFrontend Capabilityに基づいて表示制御する。

例：

```text id="86u885"
Access Control
```

をPermission管理不可Userへ表示しない。

ただしURL直接入力に対してもServer / Backend側でProtectionする。

---

## 69. Layout Authorization

Role / Capabilityによって大きくNavigation Structureが異なる場合はServer LayoutでCurrent Sessionを利用してよい。

ただしLayoutへResource単位のAuthorization Logicを集中させない。

---

## 70. Authentication判断フロー

```text id="d7jxm0"
Request
   │
   ▼
Public Route？
   │
   ├── Yes
   │    ↓
   │ Allow
   │
   └── No
        │
        ▼
Authenticated？
        │
        ├── No
        │    ↓
        │ LoginへRedirect
        │
        └── Yes
             ↓
        Next.js Route処理
             ↓
        必要に応じFrontend Authorization
             ↓
        Laravel API
             ↓
        Laravel Authorization
```

---

## 71. Authorization判断フロー

```text id="3o8qzt"
User Action
   │
   ▼
Frontend Capability上で明らかに禁止？
   │
   ├── Yes
   │    ↓
   │ UI非表示 / Forbidden
   │
   └── No
        │
        ▼
Server Action / Route Handler / Server Query
        │
        ▼
Laravel API
        │
        ▼
Policy / Authorization
        │
        ├── Allowed
        │    ↓
        │ Execute
        │
        └── Forbidden
             ↓
           403
```

---

## 72. 全体Architecture

```text id="1y1nuc"
┌────────────────────────────────────┐
│ Browser                            │
│                                    │
│ Auth.js Session Cookie             │
│ Client UI                          │
│ Frontend Capability表示制御       │
└─────────────────┬──────────────────┘
                  │
                  ▼
┌────────────────────────────────────┐
│ Next.js                            │
│                                    │
│ Proxy                              │
│ Server Component                   │
│ Server Query                       │
│ Server Action                      │
│ Route Handler                      │
│ Auth.js                            │
│ Frontend Authorization             │
│                                    │
│ Sanctum Token                      │
└─────────────────┬──────────────────┘
                  │
                  ▼
┌────────────────────────────────────┐
│ Laravel                            │
│                                    │
│ Sanctum Authentication             │
│ Policy / Authorization             │
│ Application                        │
│ Domain                             │
│                                    │
│ Security Authority                 │
└────────────────────────────────────┘
```

---

## 73. 責務境界

最終的な責務を以下とする。

```text id="frf8l0"
Auth.js
=
Browser ↔ Next.js Authentication

Next.js Proxy
=
粗いRoute Authentication Boundary

Next.js Server
=
Frontend Authentication Context
Frontend Authorization
Early Rejection
UI Capability

Laravel Sanctum
=
Next.js ↔ Laravel Authentication

Laravel Authorization
=
Resource / Business Authorization

Laravel Domain
=
Business Invariant
```

---

## 74. 決定事項

Frontendの認証・認可として、以下を正式採用する。

- AuthenticationとAuthorizationを明確に分離する
- Browser ↔ Next.js AuthenticationはAuth.jsを使用する
- Auth.js SessionをFrontend AuthenticationのSource of Truthとする
- Auth.js Session StoreはPostgreSQLを使用する
- Next.js ↔ LaravelはSanctum Token Authenticationとする
- BrowserからLaravelへ直接Authenticationしない
- BrowserからLaravel APIを直接利用しない
- Sanctum TokenはServer-onlyとする
- Sanctum TokenをClient Componentへ渡さない
- Sanctum TokenをPropsへ渡さない
- Sanctum TokenをBrowser Storageへ保存しない
- Server側Session取得にはAuth.jsのServer APIを利用する
- Client側Session取得は本当に必要な場合のみ利用する
- `SessionProvider`をApplication全体へ無条件配置しない
- Protected Routeの粗い入口制御にはNext.js Proxyを利用する
- ProxyではAuthentication / Route大分類のみを基本的に扱う
- Resource単位の複雑なAuthorizationをProxyへ置かない
- `(auth)` / `(dashboard)` Route Groupを構造整理へ利用する
- Route GroupそのものをSecurity Boundaryとは扱わない
- Next.js AuthorizationはUX / Early Rejectionを目的とする
- Laravel AuthorizationをSecurity Authorityとする
- Frontend + Backendの二重Authorizationを採用する
- UI非表示のみをSecurity対策とは扱わない
- RoleだけでなくResource Relationship / Permissionを考慮する
- `ADMINISTRATOR + can_manage_permissions = true`をPermission管理条件とする
- Permission管理者最低1人InvariantはLaravelで最終保証する
- FrontendではRole Checkの散在を避ける
- 必要に応じてCapabilityベースのUI制御を利用する
- CapabilityをSecurity Authorityとは扱わない
- Resource単位AuthorizationはLaravelで最終判断する
- Laravel Policy / Authorization RuleをFrontendへ完全再実装しない
- Server ActionをTrust Boundaryとして扱う
- Server ActionでAuthentication / Frontend Authorization / Validationを確認する
- Server Action側で確認していてもLaravel Authorizationを省略しない
- Route HandlerもBrowser到達可能なTrust Boundaryとして扱う
- Route Handlerを無認証Laravel Proxyにしない
- Auth.js SessionへUser Entity全体を格納しない
- Sessionへ大量のResource Permission Dataを保持しない
- Clientへ必要最小限のUser / Capability情報のみ公開する
- Session CapabilityのFreshnessをSecurity Authorityとはしない
- 401と403を明確に区別する
- 未Authentication UserはLoginへ誘導する
- Permission不足はForbiddenとして扱う
- 403 / 404のSecurity PolicyはLaravel側で決定する
- LogoutではAuth.js SessionとSanctum Token双方のLifecycleを考慮する
- Sanctum Token LifecycleはServer-onlyで管理する
- CSRF対策は各Authentication Boundaryに適した標準Mechanismを利用する
- Open Redirectを防止する
- Authentication CredentialをLoggingしない
- Laravel側Audit LogをAuthorization AuditのSource of Truthとする
- Authentication Secret / Internal CredentialはServer Environmentへ限定する
- Authentication共通処理は`lib/auth/`へ配置する
- `lib/auth`からFeatureへの逆依存を禁止する
- ClientへServer Session Object全体を無条件に渡さない
- Authorization UI ComponentはPresentation Utilityとして扱う
- Authorization UI ComponentをSecurity Boundaryとは扱わない
- Navigation非表示と直接URL Protectionの両方を行う
- Laravel Authorizationを常に最終防衛線とする

以上をFrontendの認証・認可方針とする。
