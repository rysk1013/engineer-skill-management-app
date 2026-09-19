# Auth.js Sessionテーブル設計 決定版

## 1. 基本方針

Next.js側のBrowser Session管理にはAuth.jsを使用する。

Session Strategy：

    Database Session

Session Store：

    PostgreSQL

BrowserにはSessionを識別するCookieのみを保持し、
Laravel Sanctum TokenはBrowserへ公開しない。

基本構成：

    Browser
       |
       | Auth.js Session Cookie
       v
    Next.js / Auth.js
       |
       | Session Lookup
       v
    PostgreSQL
       |
       | auth_sessions
       v
    Next.js BFF
       |
       | Sanctum Bearer Token
       v
    Laravel Backend API

---

# 2. Session Entity

Auth.js Sessionを以下のTableで管理する。

    auth_sessions

1つのUserは複数Sessionを持つことができる。

Relation：

    User 1
      |
      | 1:N
      v
    AuthSession

これにより以下へ対応できる。

- 複数端末Login
- Session単位Logout
- 全端末Logout
- 強制Logout

---

# 3. auth_sessions Columns

| Column | Type | NULL | Default | Constraint | 説明 |
| --- | --- | --- | --- | --- | --- |
| id | bigint | NOT NULL | Auto Increment | PK | Session内部ID |
| user_id | bigint | NOT NULL | - | FK | Application User |
| session_token | varchar | NOT NULL | - | UNIQUE | Auth.js Session Token |
| expires_at | timestamptz | NOT NULL | - | - | Session有効期限 |
| sanctum_token | text | NOT NULL | - | - | 暗号化されたLaravel Sanctum Token |
| created_at | timestamptz | NOT NULL | - | - | Session作成日時 |
| updated_at | timestamptz | NOT NULL | - | - | Session更新日時 |

---

# 4. Primary Key

Primary Key：

    auth_sessions.id

Type：

    bigint

Auto Incrementを使用する。

---

# 5. User Relation

Foreign Key：

    auth_sessions.user_id
        ↓
    users.id

Relation：

    User 1
      |
      └── N AuthSession

1 Userに複数Sessionを許可する。

例：

    User A
    ├── Chrome Session
    ├── Safari Session
    └── Mobile Session

---

# 6. Foreign Key削除ルール

`auth_sessions` は業務データではなく一時的な認証状態であるため、
User削除時はSessionも自動削除する。

    ON DELETE CASCADE

を採用する。

理由：

Userが正式に削除された後に、
そのUserのSessionだけを残す意味がないため。

これは業務Tableで原則採用している、

    ON DELETE RESTRICT

とは扱いを分ける。

---

# 7. Foreign Key更新ルール

    ON UPDATE RESTRICT

を使用する。

`users.id` は通常変更しない。

---

# 8. session_token

Auth.js Sessionを識別するToken。

Constraint：

    UNIQUE(session_token)

BrowserのSession CookieからSessionを識別し、
Database上のSessionへ対応付ける。

概念：

    Browser Cookie
        ↓
    session_token
        ↓
    auth_sessions
        ↓
    user_id

---

# 9. session_tokenの扱い

Session Tokenは認証情報として扱う。

以下を禁止する。

- Application Logへの出力
- Error Messageへの出力
- Client Componentへの明示的な受け渡し
- API Responseへの含有
- Analytics等への送信

BrowserではAuth.jsが管理するHttpOnly Cookieとして扱う。

---

# 10. Session Cookie

Browser側のSession Cookieでは以下を基本とする。

- HttpOnly
- Secure
- 適切なSameSite
- 適切なPath
- Session有効期限

Production / StagingではHTTPSを使用する。

JavaScriptからSession Cookieを直接取得する構成にはしない。

---

# 11. expires_at

Sessionの有効期限を保持する。

Type：

    timestamptz

Timezone：

    UTC

有効なSession：

    expires_at > current_timestamp

期限切れSessionは認証済みとして扱わない。

---

# 12. sanctum_token

Laravel Backend APIへ送信する
Sanctum Personal Access Tokenを保持する。

概念：

    AuthSession
        |
        | 1:1
        v
    Sanctum Token

1つのAuth.js Sessionに対して、
1つのSanctum Tokenを対応させる。

---

# 13. Sanctum Tokenの役割

Next.js BFFからLaravelへ以下の形式で送信する。

    Authorization: Bearer <Sanctum Token>

LaravelではSanctumによってTokenを検証し、
API利用者を特定する。

---

# 14. Sanctum TokenをBrowserへ公開しない

`sanctum_token` はNext.js Server側のみで利用する。

以下は禁止する。

- localStorageへの保存
- sessionStorageへの保存
- JavaScriptから参照可能なCookieへの保存
- Client Componentへの受け渡し
- API Responseへの含有

BrowserはLaravel用Credentialを保持しない。

---

# 15. sanctum_tokenの保存形式

Sanctum TokenをDatabaseへ平文のまま保存しないことを基本方針とする。

第一候補：

    Application Level Encryption

保存時：

    Sanctum Token
        ↓
    Encrypt
        ↓
    auth_sessions.sanctum_token

利用時：

    auth_sessions.sanctum_token
        ↓
    Decrypt
        ↓
    Authorization Header

---

# 16. 暗号化の責務

Sanctum Tokenの暗号化・復号はNext.js Server側で行う。

Browserでは行わない。

暗号鍵はRepositoryへ保存しない。

環境変数またはSecret管理機能を使用する。

具体的な暗号化Library / Algorithmは
Security詳細設計時に決定する。

---

# 17. Laravel側Token Storageとの違い

Next.js側：

    auth_sessions.sanctum_token

はLaravelへ実際に提示するCredentialを保持する。

Laravel側：

    personal_access_tokens

ではSanctumがToken情報を管理する。

両者は役割が異なる。

    Next.js
    → API呼び出し用Credential

    Laravel
    → API認証用Token管理

---

# 18. Login Flow

Login時：

    1. Browser
       ↓
       Login Request

    2. Next.js / Auth.js
       ↓
       CredentialをLaravelへ送信

    3. Laravel
       ↓
       User認証

    4. Laravel
       ↓
       Sanctum Token発行

    5. Next.js
       ↓
       Sanctum Token暗号化

    6. auth_sessions作成
       ↓
       user_id
       session_token
       expires_at
       sanctum_token

    7. Browser
       ↓
       Auth.js Session Cookie発行

    8. Login完了

---

# 19. API Request Flow

Login後：

    Browser
       |
       | Auth.js Session Cookie
       v
    Next.js BFF
       |
       | Session取得
       v
    auth_sessions
       |
       | sanctum_token取得
       | Decrypt
       v
    Laravel Backend API
       |
       | Authorization: Bearer
       v
    Sanctum認証

---

# 20. Logout Flow

Logout時：

    1. Auth.js Sessionを特定

    2. auth_sessionsからSanctum Token取得

    3. Sanctum Token復号

    4. LaravelへToken失効要求

    5. Laravel側Token失効

    6. auth_sessions削除

    7. Browser Session Cookie削除

Sessionだけ削除してLaravel Tokenを残さない。

---

# 21. 複数端末Login

複数Sessionを許可する。

例：

    Chrome
      └── Session A
            └── Sanctum Token A

    Safari
      └── Session B
            └── Sanctum Token B

各Sessionは独立したSanctum Tokenを持つ。

これによりSession単位でLogoutできる。

---

# 22. 全端末Logout

Userに紐付くすべてのSessionを対象とする。

概念：

    User
      ↓
    Session A
    Session B
    Session C

各Sessionについて対応するSanctum Tokenを失効させた後、

    auth_sessions

を削除する。

単純にSession Recordだけを削除して
Sanctum Tokenを残さない。

---

# 23. User無効化

    users.is_active = false

となった場合、

- 新規Loginを禁止する
- 既存Auth.js Sessionを失効する
- 対応するSanctum Tokenも失効する

ことを基本方針とする。

概念：

    User無効化
       ↓
    Sanctum Token失効
       ↓
    auth_sessions削除

---

# 24. Session期限切れ

    expires_at <= current_timestamp

となったSessionは利用できない。

期限切れSessionに対応するSanctum Tokenも
不要になるため、Cleanup時にはToken失効も行うことを基本とする。

具体的なCleanup方式は後続で決定する。

候補：

- Login / Access時にCleanup
- Scheduled Job
- 定期Cleanup処理

---

# 25. Index

必須：

    PRIMARY KEY (id)

    UNIQUE (session_token)

    INDEX (user_id)

`expires_at`については、
期限切れSession CleanupのQueryが必要になった段階で
Indexを追加することを検討する。

候補：

    INDEX (expires_at)

MVPでは過剰なIndexを追加しない。

---

# 26. Constraint

基本Constraint：

    id
    PRIMARY KEY

    user_id
    NOT NULL

    session_token
    NOT NULL
    UNIQUE

    expires_at
    NOT NULL

    sanctum_token
    NOT NULL

    created_at
    NOT NULL

    updated_at
    NOT NULL

---

# 27. auth_sessionsではis_activeを使用しない

AuthSessionには、

    is_active

を持たせない。

Session状態は、

- Recordが存在する
- expires_atが有効

ことで表現する。

無効Sessionは削除する。

業務Entityの無効化とは扱いを分ける。

---

# 28. Soft Delete

`auth_sessions`ではSoft Deleteを使用しない。

Session失効時はRecordを削除する。

理由：

Sessionは履歴ではなく現在の認証状態だから。

将来的にLogin履歴やSecurity Auditが必要になった場合は、
Session Tableとは別のAudit Tableを追加する。

---

# 29. Audit Logとの分離

Session履歴を保持する目的で
`auth_sessions`を残さない。

将来的に必要な場合は、

    authentication_logs

等の専用Entityを設計する。

例：

- Login成功
- Login失敗
- Logout
- Session失効
- 強制Logout

Session管理とAuditを分離する。

---

# 30. Auth.js標準Modelとの関係

MVPでは以下を使用する。

    users
    auth_sessions

既存Application Userを利用するため、
Auth.js専用Userを二重作成しない。

---

# 31. MVPで作成しないAuth.js関連Table

以下はMVPでは作成しない。

## accounts

OAuth / OIDC Provider連携時に検討する。

例：

- Microsoft Entra ID
- Google
- Okta

---

## verification_tokens

Magic Link / Email Verification等が必要になった場合に検討する。

---

## authenticators

Passkey / WebAuthn導入時に検討する。

---

# 32. 将来的なCredential分離

MVPでは、

    auth_sessions.sanctum_token

へ直接保持する。

以下が必要になった場合に、

    backend_credentials

等の専用Tableへの分離を検討する。

- 複数Backend API
- Access Token + Refresh Token
- OAuth / OIDC
- Credential Rotation
- Sessionとは異なるCredential有効期限
- 複数Credential Provider

現時点ではYAGNIの観点から分離しない。

---

# 33. Database全体での位置付け

PostgreSQL：

    Application Tables
    ├── departments
    ├── employees
    ├── users
    ├── skill_categories
    ├── skills
    └── employee_skills

    Auth.js
    └── auth_sessions

    Laravel Sanctum
    └── personal_access_tokens

責務：

    users
    → Application利用者

    auth_sessions
    → Browser ↔ Next.js Session

    personal_access_tokens
    → Next.js BFF ↔ Laravel API認証

---

# 34. Migration Ownership

`auth_sessions`はNext.js / Auth.js側のSession管理用Tableとする。

ただし同一PostgreSQL DatabaseをNext.jsとLaravelが利用するため、
Migration Ownershipを明確にする。

第一候補：

    Laravel Migration
    → Application / Laravel管理Table

    Next.js側Migration
    → Auth.js Session Table

同じTableを複数のMigration Toolから変更しない。

具体的なMigration Tool選定は別途決定する。

---

# 35. Date / Time

Session関連日時はUTCで管理する。

Database：

    timestamptz

対象：

    expires_at
    created_at
    updated_at

Frontend表示用のTimezone変換は原則不要。

Session内部の制御日時として扱う。

---

# 36. セキュリティ基本方針

- Session CookieはHttpOnly
- Production / StagingではSecure Cookie
- HTTPSを利用する
- Sanctum TokenをBrowserへ公開しない
- Sanctum TokenをLogへ出力しない
- Sanctum TokenをDatabaseで暗号化する
- 暗号鍵をRepositoryへ保存しない
- Logout時にSessionとSanctum Tokenを両方失効する
- User無効化時に既存Sessionも失効する

---

# 37. 決定事項

## Session Strategy

Database Session

## Session Store

PostgreSQL

## Table

`auth_sessions`

## User Relation

    User 1 : N AuthSession

## Session Token

`session_token`

UNIQUEとする。

## Session Expiration

`expires_at`

`timestamptz` / UTC

## Laravel Credential

`sanctum_token`

を`auth_sessions`へ直接保持する。

## Token保存

Application Level Encryptionを第一候補とする。

## Browser

Sanctum Tokenを保持しない。

## Logout

Auth.js SessionとSanctum Tokenを両方失効する。

## Multiple Sessions

許可する。

## Soft Delete

使用しない。

## Credential専用Table

MVPでは作成しない。

## OAuth関連Table

MVPでは作成しない。
