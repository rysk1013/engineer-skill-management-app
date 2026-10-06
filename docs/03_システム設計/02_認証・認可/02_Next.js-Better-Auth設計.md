# Next.js Better Auth Session管理 設計

## 1. 目的

Next.js Frontend / BFFにおけるBrowser Session管理、
Laravel BackendとのAuthentication連携、
RedisによるSession / Backend Credential管理の詳細設計方針を定義する。

本設計では以下を前提とする。

```text
Browser
   ↓
Better Auth Session Cookie
   ↓
Next.js Frontend / BFF
   ↓
Laravel Sanctum Token
   ↓
Laravel Backend API
   ↓
PostgreSQL
```

Authentication Stateは以下のように分離する。

```text
Browser Session
=
Better Auth

Application User Authentication
=
Laravel

Backend API Authentication
=
Laravel Sanctum
```

---

## 2. 採用技術

Next.js側のSession管理にはBetter Authを採用する。

Session StoreにはRedisを採用する。

Backend API AuthenticationにはLaravel Sanctumを利用する。

採用構成：

```text
Browser
   ↓
Better Auth
   ↓
Next.js BFF
   ├── Session → Redis
   │
   └── Backend Credential → Redis
             ↓
       Laravel Sanctum
             ↓
          Laravel
             ↓
        PostgreSQL
```

---

## 3. PostgreSQL Access Boundary

PostgreSQLへ直接接続するApplication ComponentはLaravel Backendのみとする。

採用する構成：

```text
Next.js
   ↓ HTTP
Laravel API
   ↓
PostgreSQL
```

採用しない構成：

```text
Next.js
   ↓
PostgreSQL
```

Better Authの導入を理由としてNext.jsからPostgreSQLへ接続しない。

---

## 4. Better Authの役割

Better AuthはBrowserとNext.js間のSession Managementを担当する。

主な責務：

- Session作成
- Session取得
- Session検証
- Session更新
- Session失効
- Session Cookie管理
- Session有効期限管理
- Redis Session Storeとの連携
- Next.js Server SideでのAuthentication State取得

Better AuthはApplication UserのPassword検証を担当しない。

---

## 5. Laravelの役割

LaravelはApplication User Authenticationを担当する。

Login Credential：

```text
login_id
password
```

Laravelで以下を行う。

- `users.login_id`によるUser特定
- `users.password`のHash検証
- `users.is_active`確認
- Application Userの特定
- Sanctum Personal Access Token発行
- Sanctum Token検証
- Sanctum Token失効
- Backend API Authentication
- Business Authorization

Better AuthがLaravelの代わりにPasswordを検証しない。

---

## 6. Browserの責務

BrowserはBetter Auth Session CookieのみをAuthentication Stateとして保持する。

Browserが保持する情報：

```text
Better Auth Session Cookie
```

Browserが保持しない情報：

- Laravel Sanctum Token
- Backend Credential
- Password Hash
- Encryption Key
- Redis Credential

Sanctum Tokenは以下へ保存しない。

- localStorage
- sessionStorage
- IndexedDB
- Client Side Global Store
- JavaScriptから参照可能なCookie
- Better Auth Session Cookie

---

## 7. Next.js BFFの責務

Next.js BFFは以下を担当する。

- Browser Login Request受付
- Laravel Login API呼び出し
- Laravel Authentication結果確認
- Better Auth Session生成
- Better Auth Session取得
- Current User特定
- Backend Credential管理
- Sanctum Token暗号化
- Sanctum Token復号
- Laravel APIへのAuthorization Header付与
- Logout処理
- Session失効処理
- Credential失効処理

Application Dataへ直接アクセスしない。

---

## 8. Better Auth Database方針

Next.jsからBetter Auth用PostgreSQL Databaseを利用しない。

Better AuthをDatabaseなしで利用可能な構成とする。

```text
Better Auth
   ×
PostgreSQL
```

Better AuthのSession StateはRedisへ保存する。

Better Auth内部でPrimary Databaseが必要となるPluginは、
MVPでは原則採用しない。

将来的にPlugin導入によりDatabaseが必要になった場合は、
Architecture Boundaryを再検討する。

---

## 9. Better Auth Secondary Storage

Better AuthのSecondary StorageとしてRedisを利用する。

概念：

```text
Better Auth
   ↓
Secondary Storage
   ↓
Redis
```

Better Auth公式Redis Storage Integrationを第一候補とする。

Key Prefix：

```text
better-auth:
```

を基本とする。

具体的なKey名はBetter Auth内部実装へ依存するため、
Application側から直接操作しない。

---

## 10. Better Auth Session保存方針

Better Auth Sessionの保存先はRedisとする。

```text
Browser
   ↓ Session Cookie
Better Auth
   ↓
Redis
```

SessionをPostgreSQLへ重複保存しない。

Better Auth Sessionの読み書きはBetter Authを経由する。

Application CodeからBetter Auth Session Keyを直接操作しない。

---

## 11. Cookie Cache

MVPではBetter Auth Session Cookie Cacheを利用しない。

基本Flow：

```text
Request
   ↓
Session Cookie
   ↓
Better Auth
   ↓
Redis Session Lookup
```

理由：

- Server Side Session失効を速やかに反映する
- 強制Logoutを明確にする
- Redis上のSession Stateを判断基準とする
- 初期構成を単純化する

Performance上の必要性が確認された場合に再検討する。

---

## 12. Redis Instance

MVPではRedisを1 Instance使用する。

```text
Redis
├── Better Auth Session
└── Backend Credential
```

物理Instanceは共用するが、
責務・Namespace・Access Permissionは分離する。

---

## 13. Redis Namespace

Redis Key Namespaceを以下のように分離する。

```text
better-auth:*
```

Better Auth SessionおよびBetter Authが管理する短命Data。

```text
backend-credential:*
```

Next.js BFFが管理するBackend Credential。

Better Auth Session DataへSanctum Tokenを混在させない。

---

## 14. Redis ACL

Better AuthとBackend Credential ManagementでRedis Access権限を分離する。

概念：

```text
Better Auth Redis User
   ↓
better-auth:*


Backend Credential Redis User
   ↓
backend-credential:*
```

Least Privilegeを適用する。

Better Auth用Credentialから、

```text
backend-credential:*
```

へアクセスさせない。

Backend Credential用Credentialからも、
不要なBetter Auth Keyへアクセスさせない。

具体的なRedis ACL RuleはInfrastructure設計で確定する。

---

## 15. Backend Credential

Backend API CredentialとしてLaravel Sanctum Personal Access Tokenを使用する。

Backend CredentialはBetter Auth Sessionとは別に管理する。

```text
Better Auth Session
        │
        │ Logical Relation
        ▼
Backend Credential
        │
        ▼
Sanctum Token
```

Sanctum TokenそのものをBetter Auth Session Dataへ格納しない。

---

## 16. Backend Credential Store

Backend Credential StoreにはRedisを利用する。

概念：

```text
Redis

better-auth:*
└── Better Auth Session

backend-credential:*
└── Encrypted Sanctum Token
```

Backend Credential Keyの具体形式は実装設計で決定する。

---

## 17. SessionとBackend Credentialの関係

通常のLogin完了後は以下の関係とする。

```text
1 Better Auth Session
        │
        │ 1 : 1
        ▼
1 Backend API Credential
  (Sanctum Token)
```

複数端末Login：

```text
Browser A
   ↓
Session A
   ↓
Credential A
   ↓
Sanctum Token A


Browser B
   ↓
Session B
   ↓
Credential B
   ↓
Sanctum Token B
```

SessionごとにSanctum Tokenを分離する。

---

## 18. Backend Credential Key

Backend CredentialはBetter Auth Sessionを識別可能なIdentifierと関連付ける。

概念：

```text
Better Auth Session Identifier
        ↓
Backend Credential Key
```

Backend Credential Keyへ以下を含めない。

- Sanctum Tokenそのもの
- Password
- Encryption Key

具体的なKey Schemaは実装時に決定する。

---

## 19. Sanctum Token暗号化

Sanctum TokenはRedisへ平文保存しない。

保存Flow：

```text
Sanctum Token
   ↓
Application Level Encryption
   ↓
Encrypted Sanctum Token
   ↓
backend-credential:*
```

利用Flow：

```text
backend-credential:*
   ↓
Encrypted Sanctum Token
   ↓
Decrypt
   ↓
Sanctum Token
   ↓
Authorization Header
```

暗号化・復号はNext.js Server Sideで行う。

---

## 20. Encryption Key

Encryption Keyは以下へ保存しない。

- Redis
- PostgreSQL
- Source Code
- Browser
- Client Bundle
- Log

Server Side Secretとして管理する。

具体的なSecret Management方式はInfrastructure設計で決定する。

---

## 21. Login Flow

基本Login Flow：

```text
1. Browser
   ↓
   login_id + password

2. Next.js BFF
   ↓
   Laravel Login API

3. Laravel
   ↓
   User検索
   Password Hash検証
   users.is_active確認

4. Laravel
   ↓
   Authentication成功

5. Laravel
   ↓
   Sanctum Token発行

6. Laravel
   ↓
   Authenticated User情報
   +
   Sanctum Token

7. Next.js
   ↓
   Better Auth Session生成

8. Better Auth
   ↓
   SessionをRedisへ保存

9. Next.js
   ↓
   Sanctum Token暗号化

10. Backend Credential Store
    ↓
    Redisへ保存

11. Browser
    ↓
    Better Auth Session Cookie

12. Login完了
```

---

## 22. Better Auth Session生成

Application User AuthenticationはLaravelで完了する。

そのため、

```text
Laravel Authentication成功
        ↓
Authenticated User情報
        ↓
Next.js
        ↓
Better Auth Session
```

というBridgeが必要となる。

Better Auth標準のemail/password Authenticationを利用しない。

Better Auth Username PluginをApplication Loginの主体として利用しない。

Laravel認証結果からBetter Auth Sessionを生成する具体的なBetter Auth APIまたは拡張方式は、
実装開始時に利用Versionの公式仕様を確認して確定する。

未確認のInternal APIへ依存しない。

---

## 23. Better Auth User表現

Application UserのSource of TruthはLaravelの`users`とする。

```text
Laravel users
=
Application User
```

Better Auth標準User TableをApplication User Storeとして使用しない。

Better Auth SessionにはApplication Userを識別するための必要最小限の情報を持たせる。

候補：

```text
Application User ID
Display Name
Role
Frontend Capability
```

Better Auth内部User表現の具体構造はSession生成方式と合わせて確定する。

---

## 24. Session Payload

Clientへ公開するSession情報は必要最小限とする。

候補：

```text
User ID
Display Name
Role
Frontend Capability
Session Expiration
```

以下をSession Payloadへ含めない。

- Sanctum Token
- Encrypted Sanctum Token
- Backend Credential Keyの秘密情報
- Password Hash
- Redis Credential
- Encryption Key
- Server Secret

---

## 25. User Entity全体を保持しない

SessionへApplication User Entity全体を保持しない。

```text
Session
=
Frontend Authentication Context

≠

Application User Database Record
```

大量の関連Dataも保持しない。

---

## 26. Authorization Data

SessionへResource単位のAuthorization Dataを大量に保持しない。

保持しない例：

- 全担当Employee ID
- ResourceごとのPermission一覧
- Skill Data
- Employee Data

Frontend CapabilityはUI制御用Hintとして扱う。

Security AuthorityはLaravelとする。

---

## 27. Login失敗

Laravel Authenticationが失敗した場合、
Better Auth Sessionを生成しない。

```text
Laravel Authentication
        ↓
Failure
        ↓
Better Auth Session
        ×
```

Sanctum Tokenも発行しない。

---

## 28. Login途中失敗

以下のような部分失敗を考慮する。

```text
Laravel Authentication
→ Success

Sanctum Token
→ Issued

Better Auth Session
→ Failed
```

または、

```text
Better Auth Session
→ Created

Backend Credential保存
→ Failed
```

Login完了条件は以下すべての成功とする。

```text
Laravel Authentication
+
Sanctum Token発行
+
Better Auth Session生成
+
Backend Credential保存
```

途中失敗時は作成済みAuthentication Stateを可能な限りRollbackする。

具体的なCompensation Flowは実装設計で決定する。

---

## 29. Backend API Request Flow

Login後：

```text
Browser
   |
   | Better Auth Session Cookie
   v
Next.js
   |
   | Better Auth Session確認
   v
Redis
   |
   | Session Valid
   v
Next.js BFF
   |
   | Backend Credential取得
   v
Redis
   |
   | Encrypted Sanctum Token
   v
Next.js
   |
   | Decrypt
   v
Sanctum Token
   |
   | Authorization: Bearer <token>
   v
Laravel API
   |
   | Sanctum Authentication
   | Authorization
   | Application Processing
   v
PostgreSQL
```

---

## 30. Session確認失敗

Better Auth Sessionが存在しない、
または無効な場合はLaravel Backend APIを呼び出さない。

```text
Session
   ↓
Invalid
   ↓
Laravel API Call
   ×
```

未Authenticationとして扱う。

---

## 31. Backend Credential取得失敗

Better Auth Sessionが有効でもBackend Credentialを取得できない場合を考慮する。

```text
Session
→ Valid

Backend Credential
→ Missing
```

この状態を正常なAuthenticated Stateとして扱わない。

再Authenticationを要求することを基本とする。

---

## 32. Laravel 401

Better Auth Sessionが有効でも、
Laravel Sanctum Tokenが無効・失効している場合がある。

```text
Better Auth Session
→ Valid

Sanctum Token
→ Invalid

Laravel
→ 401
```

この場合Backend Credentialは利用不能として扱う。

必要に応じて、

- Backend Credential削除
- Better Auth Session失効
- Browser Session Cookie無効化
- 再Login要求

を行う。

具体Flowは実装設計で決定する。

---

## 33. Server Component

Server ComponentではBetter AuthのServer Side機能を通じてCurrent Sessionを取得する。

概念：

```text
Server Component
      ↓
Better Auth Server API
      ↓
Current Session
```

用途：

- Authentication確認
- Current User表示
- Frontend Capability確認
- Protected Server Query実行前確認

具体的API名は利用Version確定時に公式仕様へ合わせる。

---

## 34. Route Handler

Route HandlerはBrowserから直接到達可能なTrust Boundaryとして扱う。

基本Flow：

```text
Browser
   ↓
Route Handler
   ↓
Better Auth Session確認
   ↓
Backend Credential取得
   ↓
Laravel Backend API
```

未Authenticationの場合、
Backend Credentialを付与してLaravelを呼び出さない。

---

## 35. Server Action

Server ActionでもBetter Auth Sessionを確認する。

基本Flow：

```text
Server Action
   ↓
Session確認
   ↓
Frontend Authorization
   ↓
Validation
   ↓
Backend Credential取得
   ↓
Laravel API
   ↓
Laravel Authorization
```

Server ActionからPostgreSQLへ直接アクセスしない。

---

## 36. Client Component

Client ComponentでSession情報が必要な場合のみBetter Auth Client Side Integrationを利用する。

利用例：

- User Display Name
- Navigation表示制御
- UI Capability

Client Componentへ以下を渡さない。

- Sanctum Token
- Backend Credential
- Encryption Key
- Redis Credential

Server Sideで判断可能なAuthenticationはServer Sideを優先する。

---

## 37. Session Cookie

BrowserへはBetter Auth Session Cookieのみを保持する。

基本Security属性：

- `HttpOnly`
- Production / Stagingでは`Secure`
- 適切な`SameSite`
- 必要最小限の`Path`
- 適切なExpiration

Production / StagingではHTTPSを使用する。

具体設定値はSecurity設計で決定する。

---

## 38. Session Expiration

Better Auth Sessionには有効期限を設定する。

検討対象：

- Maximum Session Lifetime
- Session Renewal
- Idle Timeout
- Session Rotation
- Redis TTL

具体値はSecurity / Operation Requirementを踏まえて決定する。

---

## 39. Redis TTL

Better Auth SessionのExpirationとRedis TTLを整合させる。

概念：

```text
Better Auth Session Expiration
≈
Redis Session TTL
```

Better AuthがSecondary Storageへ設定するTTLを利用することを基本とする。

Application側からBetter Auth Session TTLを独自に変更しない。

---

## 40. Backend Credential TTL

Backend CredentialにもTTLを設定する。

基本条件：

```text
Backend Credential TTL
<=
Better Auth Session Lifetime
```

Session失効後にBackend Credentialだけが長期間残らないようにする。

Sanctum Token自体のExpirationとも整合させる。

---

## 41. Logout Flow

Logout時：

```text
1. Browser
   ↓
   Logout Request

2. Next.js
   ↓
   Better Auth Session確認

3. Next.js
   ↓
   Backend Credential取得

4. Next.js
   ↓
   Sanctum Token復号

5. Next.js
   ↓
   Laravel Token Revocation API

6. Laravel
   ↓
   Sanctum Token失効

7. Next.js
   ↓
   Backend Credential削除

8. Better Auth
   ↓
   Session失効

9. Browser
   ↓
   Session Cookie無効化

10. Login Pageへ遷移
```

---

## 42. LogoutのIdempotency

Logout処理は可能な限りIdempotentとする。

例えば、

```text
Sanctum Token
→ 既に失効済み

Backend Credential
→ 既に削除済み

Better Auth Session
→ 既に失効済み
```

の場合でも安全に終了できる設計とする。

---

## 43. Session自然失効

Redis TTLによりBetter Auth Sessionが自然失効する場合を考慮する。

```text
Better Auth Session
→ Expired

Backend Credential
→ Remaining
```

という孤立Credentialを長期間残さないよう、
Backend Credential TTLをSession Lifetime以下とする。

完全な同時削除をDistributed Transactionで保証しない。

---

## 44. 強制Logout

Server SideからSessionを失効可能とする。

対象：

- User無効化
- Security Incident
- Administratorによる強制Logout
- Credential漏洩疑い
- Permission変更による再Authentication要求

基本Flow：

```text
Target Session特定
   ↓
Backend Credential特定
   ↓
Sanctum Token失効
   ↓
Backend Credential削除
   ↓
Better Auth Session失効
```

---

## 45. User無効化

Application User：

```text
users.is_active = false
```

となった場合、

- 新規Login禁止
- 既存Session失効対象
- Sanctum Token失効対象
- Backend Credential削除対象

とする。

LaravelをUser StateのSource of Truthとする。

既存Sessionを検索する具体方式は実装設計で決定する。

---

## 46. 複数端末Login

複数端末Loginを許可する。

```text
User
├── Session A
│   └── Credential A
│       └── Sanctum Token A
│
└── Session B
    └── Credential B
        └── Sanctum Token B
```

Session単位でLogout可能とする。

---

## 47. 全端末Logout

全端末LogoutではUserに関連するすべての、

- Better Auth Session
- Backend Credential
- Sanctum Token

を失効対象とする。

Session検索方式はBetter Authの利用可能APIおよびSession Index設計を確認して確定する。

---

## 48. Permission変更

Login中にRole / Permissionが変更される可能性を考慮する。

例：

```text
Manager
   ↓
Sub Manager
```

Session上のRole / CapabilityだけをSecurity Authorityとして扱わない。

Laravel Backend APIが最新Authorization Stateを基準に判断する。

必要に応じてSession再生成・強制Logoutを行える設計とする。

---

## 49. Redis障害時

Redisへアクセスできない場合、
Authentication Stateを安全側に倒す。

```text
Sessionを確認できない
        ↓
Authenticatedとして扱わない
```

未検証Sessionを有効として扱わない。

Backend Credentialを取得できない場合もLaravel APIをAuthenticated Requestとして呼び出さない。

---

## 50. Redis Data Loss

Redis DataはAuthentication用短命Stateとして扱う。

Redis Dataが失われた場合：

```text
Better Auth Session
→ Lost

Backend Credential
→ Lost
```

Userへ再Loginを要求できる構成とする。

Application DataはPostgreSQLへ保存されるため、
Redis Data Lossによって業務Dataを失わない。

---

## 51. Redis Persistence

Redis Persistence / Backupの具体方式はInfrastructure設計で決定する。

Authentication設計としては、

```text
Redis
≠
Application Data Primary Store
```

とする。

---

## 52. Authentication Failure

未Authentication User：

```text
Protected Resource
      ↓
Sessionなし
      ↓
LoginへRedirect
```

Authentication済みだがLaravel Credentialが無効な場合も、
必要に応じてSessionを無効化して再Loginを要求する。

---

## 53. Authorization Failure

Authentication済みだがPermission不足の場合：

```text
Laravel
   ↓
403 Forbidden
```

として扱う。

Next.jsでAuthentication FailureとAuthorization Failureを混同しない。

---

## 54. 401 / 403

意味を以下とする。

```text
401
=
Authenticationが必要
またはCredential無効

403
=
Authentication済みだがPermission不足
```

Frontend Error Handlingでも区別する。

---

## 55. CSRF

Browser ↔ Next.jsについてはBetter Auth / Next.jsの標準Security Mechanismを利用する。

Next.js ↔ LaravelはServer-to-ServerのBearer Token Authenticationとする。

```text
Next.js
   ↓ Authorization: Bearer
Laravel
```

Laravel Cookie AuthenticationはBrowser Authenticationへ利用しない。

---

## 56. Open Redirect

Login後Redirect先を外部Inputから受け取る場合、
許可済みApplication Routeのみ利用する。

External URLへの任意Redirectを許可しない。

Better Auth固有のRedirect APIを利用する場合は、
利用Versionの公式仕様を確認して実装する。

---

## 57. Logging

以下をLogへ出力しない。

- Password
- Session Token
- Sanctum Token
- Encrypted Sanctum Token
- Cookie
- Authorization Header
- Better Auth Secret
- Redis Credential
- Encryption Key

Authentication Failure LogにもCredential自体を含めない。

---

## 58. Environment Variable

Authentication関連SecretはServer-onlyとする。

想定：

```text
BETTER_AUTH_SECRET
Redis Connection Information
Better Auth Redis Credential
Backend Credential Redis Credential
Backend Credential Encryption Key
BACKEND_API_URL
```

具体名は実装・Infrastructure設計と合わせて確定する。

`NEXT_PUBLIC_*`として公開しない。

---

## 59. Better Auth Redis Client

Better Auth用Redis ClientはBetter Auth Infrastructure内で管理する。

概念：

```text
Better Auth
   ↓
Redis Storage Adapter
   ↓
Redis Client
```

Application FeatureからBetter Auth Redis Clientへ直接依存しない。

---

## 60. Backend Credential Redis Client

Backend Credential用Redis ClientはBetter Auth用Clientと論理的に分離する。

概念：

```text
Backend Credential Store
   ↓
Credential Redis Client
   ↓
Redis
```

同一Redis Instanceを利用しても、
接続Credential / ACLを分ける。

---

## 61. Directory構成

基本構成候補：

```text
src/
└── lib/
    └── auth/
        ├── auth.ts
        ├── session.ts
        ├── credential.ts
        ├── redis.ts
        ├── permissions.ts
        └── index.ts
```

具体的File名は実装時に調整する。

---

## 62. `auth.ts`

Better Auth Configurationを管理する。

責務候補：

- Better Auth Configuration
- Session Configuration
- Redis Secondary Storage Configuration
- Cookie Configuration
- Better Auth Server Entry Point

Application Feature固有処理を含めない。

---

## 63. `session.ts`

Better Auth Session操作Helperを管理する。

候補：

```text
getCurrentSession()
requireSession()
getCurrentUser()
```

具体APIはBetter Auth公式APIへ合わせる。

---

## 64. `credential.ts`

Backend Credential管理を担当する。

責務：

- Credential Key生成
- Sanctum Token暗号化
- Sanctum Token保存
- Credential取得
- Sanctum Token復号
- Credential削除
- TTL管理

Featureから直接Redis操作を行わない。

---

## 65. `redis.ts`

Redis Connection Infrastructureを管理する場合に利用する。

ただし、

```text
Better Auth Redis Access
```

と、

```text
Backend Credential Redis Access
```

はACL上分離する。

1つのGlobal Redis Clientへすべての権限を与える構成を避ける。

---

## 66. Better Auth API Route

Better Authが要求するNext.js API Route Integrationを利用する。

具体的Route PathおよびHandler構成は利用するBetter Auth Versionの公式Next.js Integrationへ従う。

独自互換Routeを作らない。

---

## 67. Better Auth Client

Client ComponentからSession情報が必要な場合のみBetter Auth Clientを利用する。

概念：

```text
Client Component
   ↓
Better Auth Client
   ↓
Session
```

Application全体のClient State Managerとして使用しない。

---

## 68. Better Auth内部APIへの依存

Better Authの非公開Internal APIへ依存しない。

Laravel Authentication結果からSessionを生成する際も、
公開API・Extension Point・公式にサポートされる方式を利用する。

必要な公開方式が存在しない場合は、
Better Auth採用そのものを再評価する。

---

## 69. Better Auth Version確認

実装開始時に以下を公式Documentationで再確認する。

- Databaseなし構成
- Secondary Storage
- Redis Storage Package
- Session作成API
- Session失効API
- Session一覧取得API
- Server Side Session取得API
- Client Integration
- Next.js Route Handler Integration
- Cookie Configuration
- User Representation
- Custom Authentication Integration

Version差異を推測して実装しない。

---

## 70. 将来的なSSO

将来的に以下のIdentity Providerを利用する可能性を考慮する。

- Microsoft Entra ID
- Okta
- Google Workspace
- その他OIDC Provider

基本Boundary：

```text
Browser
   ↓
Next.js / Better Auth
   ↓
Laravel Backend API
```

を可能な限り維持する。

Application AuthorizationはLaravelへ残す。

---

## 71. 独自Session管理を採用しない

Better Authを利用し、
Session ID生成・Cookie管理・Session Validation等を独自実装しない。

独自実装を避ける対象：

- Session Token Generation
- Session Cookie Security
- Session Validation
- Session Expiration
- Session Rotation
- Session Revocation

Backend Credential管理は本Application固有のBFF責務として実装する。

---

## 72. 採用しない構成

以下を採用しない。

### Auth.js

Better Authへ変更する。

### Next.jsからPostgreSQLへ直接接続

採用しない。

### Better Auth Database SessionをPostgreSQLへ保存

採用しない。

### Better Auth built-in email/passwordをApplication Loginへ利用

採用しない。

### Better Auth Username PluginをApplication Loginの主体として利用

採用しない。

### Sanctum TokenをBetter Auth Session Dataへ保存

採用しない。

### Sanctum TokenをBrowserへ保存

採用しない。

### Laravel SessionをBrowser Session管理へ利用

採用しない。

### Redis 2 Instance

MVPでは採用しない。

### 独自JWT Authentication

採用しない。

---

## 73. 詳細未確定事項

以下は実装開始時に確定する。

- Laravel認証結果からBetter Auth Sessionを生成する具体方式
- Better Auth内部User表現
- Better Auth Session Payload詳細
- Session Identifier取得方法
- Backend Credential Key Schema
- Better Auth SessionとCredentialの関連付け方法
- Better Auth Session一覧取得方法
- User単位Session失効方法
- 全端末Logout方式
- User無効化時のSession検索方式
- Session Expiration具体値
- Redis TTL具体値
- Sanctum Token Expiration
- Encryption Algorithm
- Encryption Key Rotation
- Redis ACL具体設定
- Cookie属性具体値
- Login途中失敗時のCompensation Flow
- Logout失敗時のRetry
- Redis障害Recovery

---

## 74. 決定事項

### Browser Session Management

Better Authを採用する。

### Application User Authentication

Laravelを採用する。

```text
login_id
+
password
```

をLaravelで検証する。

### Better Auth Database

Next.jsからPostgreSQLへ接続しない。

Better Auth用Primary DatabaseをMVPでは利用しない。

### Session Store

Redisを利用する。

Better Auth Secondary StorageとしてRedisを設定する。

### Redis構成

MVPでは1 Redis Instanceを利用する。

```text
Redis
├── better-auth:*
└── backend-credential:*
```

Namespace / ACLを分離する。

### Backend API Authentication

Laravel Sanctumを利用する。

### Backend Credential Store

Sanctum TokenはRedisへ保存する。

Better Auth Sessionとは別Namespaceで管理する。

### Credential Encryption

Sanctum TokenはApplication Level Encryptionを行って保存する。

### Browser Credential

BrowserにはBetter Auth Session Cookieのみを保持する。

Sanctum TokenをBrowserへ公開しない。

### Session / Credential Relation

基本的に、

```text
1 Better Auth Session
:
1 Backend Credential
```

とする。

### PostgreSQL

PostgreSQLへ直接アクセスするのはLaravel Backendのみとする。

### Authorization

LaravelをSecurity Authorityとする。

### Better Auth / Laravel Bridge

Laravel Authentication成功後にBetter Auth Sessionを生成する。

具体的な公開API / Extension Pointは実装開始時にBetter Auth公式仕様を確認して確定する。

非公開Internal APIへ依存しない。

### 障害時

RedisからSessionを確認できない場合はAuthenticatedとして扱わない。

### Lifecycle

Better Auth SessionとSanctum TokenのLifecycleを可能な限り対応させる。

Logout / 強制Logout / User無効化時には双方を失効対象とする。

以上をNext.js Better Auth Session管理の基本設計とする。
