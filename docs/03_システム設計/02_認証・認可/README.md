# 認証・認可設計

Engineer Skill Management App のBrowser、Next.js Frontend／BFF、Laravel Backend API間における認証・認可の境界、Session、Backend Credential、Login／Logout Flowを管理するディレクトリです。

Browser Session ManagementにはBetter Auth、Laravel Backend APIの認証にはLaravel Sanctum Personal Access Tokenを使用します。

Application User AuthenticationはLaravelが担当し、業務上の最終的なAuthorizationもLaravel Backend APIで行います。

## 基本構成

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

Session / Backend Credentialの保存は以下とします。

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

認証情報の保持範囲は次のとおりです。

```text
Browser
  └── Better Auth Session Cookieのみ

Next.js / Better Auth
  ├── Browser Sessionの管理
  ├── Better Auth SessionをRedisで管理
  ├── Backend CredentialをRedisで管理
  └── Laravel APIへのCredential付与

Laravel / Sanctum
  ├── Application User Credentialの検証
  ├── Personal Access Tokenの発行・検証・失効
  └── 業務上の最終Authorization

PostgreSQL
  └── Laravelが所有するApplication Data
```

Laravel用Sanctum TokenをBrowser、JavaScript、`localStorage`へ公開しません。

BrowserからLaravel Backend APIを直接呼び出さず、Next.js BFFをTrust Boundaryとして使用します。

Next.jsからPostgreSQLへ直接接続しません。

## 認証と認可の違い

| 項目 | 確認すること | 主な担当 |
| --- | --- | --- |
| Application User Authentication | 利用者が誰であるか | Laravel |
| Browser Session Management | BrowserとNext.js間のLogin状態 | Better Auth |
| Backend API Authentication | Laravel APIを呼び出すCredentialが有効か | Laravel Sanctum |
| Authorization | 利用者が対象操作を実行できるか | Laravel Policy／Application／Domain Rule |

Next.js側では、操作可能なButtonの表示制御やRoute保護などのFrontend Authorizationを行えます。

ただし、Frontendの制御だけをSecurity Boundaryとはせず、Laravelで必ず最終確認します。

## Componentの責務

| Component | 責務 | 担当しないこと |
| --- | --- | --- |
| Browser | Better Auth Session Cookieの送信、Login／Logout操作 | Sanctum Tokenの保持、Laravel APIの直接呼び出し |
| Next.js／Better Auth | Browser Session、Cookie、Session状態、BFFからのAPI呼び出し | Application User Passwordの最終検証、業務上の最終Authorization |
| Redis | Better Auth Session、暗号化されたBackend Credentialの保存 | Application Dataの永続化、Authorization判断 |
| Laravel／Sanctum | Credential検証、Token発行・検証・失効、Backend API Authentication | Browser Session Cookieの管理 |
| Laravel Application／Domain | Actorと対象Resourceに基づく重要なAuthorization Rule | HTTP CookieやBetter Auth Sessionの直接操作 |
| PostgreSQL | Application User、Employee、Skill、Sanctum Token情報などLaravel所有Dataの永続化 | Better Auth Session保存、Authorization判断そのもの |

Next.jsはApplication Data取得・更新のためにPostgreSQLへ直接アクセスせず、Laravel Backend APIを経由します。

Better Auth SessionとBackend CredentialはRedisへ保存します。

## 設計ドキュメント

### 1. 認証全体設計

[認証全体設計](./01_認証全体設計.md)では、Browser、Next.js BFF、Laravel Backend APIの境界と、Authentication／Authorizationの責務分担を定義します。

主な決定事項：

- BrowserとNext.js間ではBetter Auth Session Cookieを使用する
- Application User AuthenticationはLaravelが担当する
- Next.jsとLaravel間ではSanctum Personal Access Tokenを使用する
- Laravel API用TokenはNext.js BFFのサーバー側で管理する
- Laravel Backend APIで最終的なAuthorizationを行う
- BrowserからLaravel Backend APIを直接呼び出さない
- Next.jsからPostgreSQLへ直接接続しない
- 将来のOIDC／OAuthによるSSOへ移行しやすいBoundaryを維持する

### 2. Next.js Better Auth Session管理 設計

[Next.js Better Auth Session管理 設計](./02_Next.js-Better-Auth設計.md)では、Browser Session、Cookie、Redis、Route Handler／Server Action、Backend Credential、Sanctum Tokenとの連携を定義します。

主な決定事項：

- Browser Session ManagementにBetter Authを使用する
- Better Auth Session StoreにはRedisを使用する
- Better Auth SessionをPostgreSQLへ保存しない
- Backend CredentialはBetter Auth Sessionとは別にRedisへ保存する
- Better Auth SessionとBackend CredentialはNamespaceを分離する
- Redis ACLによってAccess権限を分離する
- Sanctum TokenはApplication Level EncryptionしてRedisへ保存する
- Sessionには必要最小限の情報だけを保持する
- Server Component、Route Handler、Server ActionはServer SideでSessionを確認する
- Better Auth SessionとSanctum Tokenの有効期限・失効を可能な限り整合させる
- Laravel Authentication結果からBetter Auth Sessionを生成する具体方式は、利用Versionの公式仕様を確認して確定する

### 3. Laravel・Sanctum設計

[Laravel・Sanctum設計](./03_Laravel-Sanctum設計.md)では、Login API、Personal Access Token、Ability、Middleware、Token失効、Laravel Authorizationとの分離を定義します。

主な決定事項：

- Application User AuthenticationはLaravelで行う
- Login Credentialには`login_id + password`を使用する
- Laravel Backend APIのAuthenticationにSanctumを使用する
- Sanctum Personal Access TokenをBearer Tokenとして使用する
- SanctumはAPI Authentication、Laravel Policy／Application／DomainはAuthorizationを担当する
- Next.jsからはSanctumの内部実装ではなく、Backend API Credentialとして扱う

## Login Flow

```text
1. Browser
   └── login_id + passwordをNext.jsへ送信

2. Next.js BFF
   └── CredentialをLaravel Login APIへ送信

3. Laravel
   ├── users.login_idからUserを特定
   ├── Password Hashを検証
   ├── users.is_activeを確認
   └── Sanctum Personal Access Tokenを発行

4. Next.js
   ├── Laravel Authentication結果を受け取る
   └── Better Auth Sessionを生成

5. Better Auth
   └── SessionをRedisへ保存

6. Next.js BFF
   ├── Sanctum Tokenを暗号化
   └── backend-credential:*へ保存

7. Browser
   └── Better Auth Session Cookieを受け取る

8. Login完了
```

Credential検証とSanctum Token発行はLaravel、
Browser Sessionの管理はNext.js／Better Authが担当します。

Laravel Authentication結果からBetter Auth Sessionを成立させる具体的な公開API／Extension Pointは、実装時にBetter Auth公式仕様を確認して確定します。

## API Access Flow

```text
Browser
   │ Better Auth Session Cookie
   ▼
Next.js / Better Auth
   │ Session確認
   ▼
Redis
   │ Better Auth Session
   ▼
Next.js BFF
   │ Backend Credential取得
   ▼
Redis
   │ Encrypted Sanctum Token
   ▼
Next.js BFF
   │ Decrypt
   │ Authorization: Bearer <Sanctum Token>
   ▼
Laravel Backend API
   ├── Sanctum Tokenを検証
   ├── Actorを特定
   ├── Laravel Policy／Application／DomainでAuthorization
   └── Business Logicを実行
              │
              ▼
         PostgreSQL
```

Better Auth Sessionが無効な場合は、Backend Credentialを利用してLaravel Backend APIを呼び出しません。

## Logout Flow

1. BrowserからNext.jsへLogoutを要求する。
2. Next.jsでBetter Auth Sessionを確認する。
3. Sessionに対応するBackend CredentialをRedisから取得する。
4. Sanctum Tokenを復号する。
5. Next.js BFFからLaravelへSanctum Tokenの失効を要求する。
6. LaravelでSanctum Tokenを削除または失効させる。
7. RedisからBackend Credentialを削除する。
8. Better Auth Sessionを失効させる。
9. BrowserのSession Cookieを無効化する。

Browser Sessionだけを削除してSanctum Tokenを残さず、両方のLifecycleを可能な限り揃えます。

Logout処理は、TokenやSessionがすでに失効済みの場合でも安全に終了できるようIdempotentに設計します。

## 認可モデル

MVPでは、次のRoleを扱います。

| Role | 主な位置付け |
| --- | --- |
| Administrator | 全体管理。権限管理可否は`can_manage_permissions`で区別する |
| Manager | 全Employeeに対する管理操作 |
| Sub Manager | AssignmentされたEmployeeに対する管理操作 |
| Team Leader | AssignmentされたEmployeeに対する限定的な閲覧・操作 |
| General Employee | Applicationを利用しない |

詳細なDomain Ruleは[Access Control設計](../../02_アーキテクチャ/01_Backend/DDD設計/10_Access-Control設計.md)、Laravel Layerでの適用方法は[Presentation Layer設計](../../02_アーキテクチャ/01_Backend/Laravel/05_Presentation%20Layer設計.md)を参照してください。

## SessionとBackend Credentialの保存

Better Auth SessionとBackend CredentialはRedisへ保存します。

```text
Redis
├── better-auth:*
│   └── Better Auth Session
│
└── backend-credential:*
    └── Encrypted Sanctum Token
```

基本方針：

- RedisはMVPで1 Instance使用する
- Better Auth SessionとBackend CredentialはNamespaceを分離する
- Redis ACLによってそれぞれのAccess権限を分離する
- Better Auth SessionへSanctum Tokenを直接保存しない
- Sanctum TokenはApplication Level Encryptionして保存する
- Encryption KeyはRedisへ保存しない
- Encryption KeyをRepositoryへ保存しない
- Better Auth SessionとBackend Credentialは1対1を基本とする
- 複数端末LoginはSessionを分けて許可する
- Session単位でSanctum Tokenを分離する
- Backend Credential TTLはBetter Auth Session Lifetimeを超えないようにする
- RedisをApplication DataのPrimary Storeとして使用しない

詳細は[Next.js Better Auth Session管理 設計](./02_Next.js-Better-Auth設計.md)を参照してください。

## PostgreSQLとの責務分離

PostgreSQLへ直接アクセスするApplication ComponentはLaravel Backendのみとします。

```text
Next.js
   ↓ HTTP
Laravel Backend API
   ↓
PostgreSQL
```

Next.jsからPostgreSQLへ直接接続しません。

Better Auth Session用TableをPostgreSQLへ作成しません。

Backend Credential用TableもPostgreSQLへ作成しません。

Laravel Sanctumの`personal_access_tokens`はLaravel側のAuthentication InfrastructureとしてPostgreSQLで管理します。

## Security方針

- Better Auth Session Cookieは`HttpOnly`を使用する
- Production／StagingではCookieへ`Secure`属性を設定する
- 適切な`SameSite`属性とCSRF対策を設定する
- Sanctum TokenをBrowserへ公開しない
- Sanctum Tokenを`localStorage`、`sessionStorage`、Client Component Stateへ保存しない
- Sanctum TokenをBetter Auth Session Dataへ保存しない
- Sanctum TokenをRedisへ平文保存しない
- Backend CredentialはApplication Level Encryptionして保存する
- Encryption KeyをRedis、Browser、Repositoryへ保存しない
- Better Auth SessionとBackend CredentialでRedis Namespace／ACLを分離する
- SessionとTokenに有効期限を設定し、Logout時に両方を失効対象とする
- 認証失敗時に利用者の存在や内部情報を不要に返さない
- Secretや平文TokenをLogへ出力しない
- RedisからSessionを確認できない場合はAuthenticatedとして扱わない
- User無効化時は新規Loginを禁止し、既存Session／Tokenを失効対象とする
- 重要なPermission変更時は必要に応じてSession失効や再Authenticationを行う
- Frontend CapabilityをSecurity Authorityとして扱わない
- Laravel Authorizationを最終防衛線とする

## Redis障害時

RedisはAuthentication用の短命Stateを保持します。

RedisへアクセスできずBetter Auth Sessionを検証できない場合は、

```text
Sessionを確認できない
        ↓
Authenticatedとして扱わない
```

とします。

Backend Credentialを取得できない場合も、Authenticated RequestとしてLaravel Backend APIを呼び出しません。

Redis Dataが失われた場合は再Loginを要求できる構成とします。

Application DataはPostgreSQLへ保存されるため、Redis Data Lossによって業務Dataを失わない構成とします。

## Session Lifecycle

Better Auth SessionとSanctum Tokenは独立して失効する可能性があります。

例えば、

```text
Better Auth Session
→ Valid

Sanctum Token
→ Invalid

Laravel
→ 401 Unauthorized
```

という状態を考慮します。

Laravelから401が返された場合は、Backend Credentialを利用不能として扱い、必要に応じて、

- Backend Credential削除
- Better Auth Session失効
- Browser Session Cookie無効化
- 再Login要求

を行います。

## User無効化

```text
users.is_active = false
```

となった場合は、

- 新規Loginを禁止する
- 既存Better Auth Sessionを失効対象とする
- 対応するSanctum Tokenを失効対象とする
- Backend Credentialを削除対象とする

ことを基本方針とします。

Application User StateのSource of TruthはLaravelとします。

## 将来のSSO対応

将来的にMicrosoft Entra ID、Okta、Google WorkspaceなどのOIDC／OAuth Providerを利用する場合も、

```text
Browser
   ↓
Next.js / Better Auth
   ↓
Laravel Backend API
```

というBoundaryを可能な限り維持します。

Authentication Providerを変更しても、Backend DomainとAuthorization Ruleへの影響を抑える構成とします。

LaravelをApplication AuthorizationのSecurity Authorityとして維持します。

## 推奨する読み順

1. [認証全体設計](./01_認証全体設計.md)で、Trust Boundaryと責務分担を把握する。
2. [Next.js Better Auth Session管理 設計](./02_Next.js-Better-Auth設計.md)で、Browser Session、Redis、Backend Credential、BFFの処理を確認する。
3. [Laravel・Sanctum設計](./03_Laravel-Sanctum設計.md)で、Application User Authentication、API Authentication、Token Lifecycleを確認する。
4. [Database設計](../01_データベース/README.md)で、PostgreSQLとAuthentication Infrastructureの責務境界を確認する。
5. Access Control設計で、Roleと業務上のAuthorization Ruleを確認する。

## 文書管理ルール

- Authentication方式を変更した場合は、Login、API Access、Logoutの全Flowを更新します。
- Better Auth SessionまたはBackend Credentialの保存方式を変更した場合は、Redis、暗号化、TTL、失効処理を合わせて確認します。
- PostgreSQLとの責務境界を変更した場合は、Database設計とMigration Ownershipを合わせて更新します。
- RoleやAuthorization Ruleを変更した場合は、Laravel Policy、Application、Domain、Frontend表示制御、Testを確認します。
- Security上のSecret、Cookie、Tokenの実値は文書へ記載しません。
- Authentication／Authorizationの設計変更には、Feature TestとSecurity観点のReviewを伴わせます。
- 過去の設計は現行仕様と混在させず、`archive/`へ保管します。
