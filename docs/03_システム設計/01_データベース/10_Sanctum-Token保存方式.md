# Sanctum Token 保存方式 決定

## 1. 採用方式

MVPでは、Laravel Sanctum Tokenを
`auth_sessions` に直接保持する。

    auth_sessions
    ├── id
    ├── user_id
    ├── session_token
    ├── expires_at
    ├── sanctum_token
    ├── created_at
    └── updated_at

Auth.js Database Session基盤と、
Laravel Sanctum TokenとのBackend Credential連携は
責務を分離する。

`auth_sessions` のSession自体は
Sanctum Tokenが未設定でも存在できるものとする。

---

## 2. Relation

基本Relation：

    User
      |
      | 1:N
      v
    AuthSession
      |
      | 0..1
      v
    Sanctum Token

Auth.js Database Session作成直後など、
Backend Credential連携前は
`sanctum_token` が存在しない状態を許可する。

通常のLogin完了後は、

    AuthSession : Sanctum Token = 1 : 1

とする。

---

## 3. sanctum_token

Laravel APIへ送信するCredentialとして使用する。

    Next.js BFF
        |
        | Authorization: Bearer <token>
        v
    Laravel API

BrowserへSanctum Tokenを公開しない。

`sanctum_token` はNULLを許可する。

以下の状態を区別する。

    Auth.js Sessionあり
    sanctum_token = NULL
        ↓
    Backend Credential未連携

    Auth.js Sessionあり
    sanctum_token != NULL
        ↓
    Backend Credential連携済み

Backend APIへ認証付きRequestを送信する場合は、
`sanctum_token` が設定済みであることを必須とする。

---

## 4. 保存

`sanctum_token` はSecretとして扱う。

第一候補としてApplication Level Encryptionを使用し、
暗号化した状態でPostgreSQLへ保存する。

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

暗号化・復号はNext.js Server側で行う。

Browserでは行わない。

---

## 5. Auth.js Database Session基盤との責務分離

Auth.js Database Session基盤では、
以下を担当する。

- Session Store
- Session作成
- Session取得
- Session更新
- Session削除
- Session有効期限
- Session Cookie
- UserとSessionのRelation

この段階では、
Sanctum Tokenの取得・暗号化・復号・失効連携を
必須としない。

Backend Credential連携では、
以下を担当する。

- Laravel Login API呼び出し
- LaravelによるUser認証
- Sanctum Token取得
- Sanctum Token暗号化
- 対象AuthSessionへの保存
- Laravel API呼び出し時のToken利用
- Logout時のToken失効
- Session失効時のToken Lifecycle連携

---

## 6. Login

Laravelを認証主体とする。

Login時の概念：

    1. Browser
       ↓
       Login Request

    2. Next.js
       ↓
       CredentialをLaravelへ送信

    3. Laravel
       ↓
       User認証

    4. Laravel
       ↓
       Application User特定
       Sanctum Token発行

    5. Next.js / Auth.js
       ↓
       既存users.idと
       Auth.js Database Sessionを対応付ける

    6. auth_sessions
       ↓
       user_id
       session_token
       expires_at
       sanctum_token = NULL

    7. Next.js
       ↓
       Sanctum Token暗号化

    8. auth_sessions
       ↓
       sanctum_token更新

    9. Browser
       ↓
       Auth.js Session Cookie

    10. Login完了

Auth.js Database Session基盤の構築と、
Laravel Login APIとの統合は別Taskとして扱う。

---

## 7. Backend API Request

Login後：

    Browser
       |
       | Auth.js Session Cookie
       v
    Next.js BFF
       |
       | Auth.js Session確認
       v
    auth_sessions
       |
       | sanctum_token確認
       v

`sanctum_token` がNULLの場合は、
Backend Credential連携済みとして扱わない。

Tokenが存在する場合：

    auth_sessions.sanctum_token
        ↓
    Decrypt
        ↓
    Authorization: Bearer <token>
        ↓
    Laravel API

LaravelではSanctumによってTokenを検証し、
API利用者を特定する。

---

## 8. Logout

Backend Credential連携済みSessionのLogout時：

    Auth.js Session特定
        ↓
    sanctum_token確認
        ↓
    Token存在時のみ復号
        ↓
    Laravel側Token失効
        ↓
    auth_sessions削除
        ↓
    Session Cookie削除

`sanctum_token` がNULLの場合は、
Laravel側Token失効処理は不要とする。

Credential連携済みSessionでは、
Sessionだけ削除して
Laravel Tokenを残さない。

---

## 9. 複数端末

複数Sessionを許可する。

通常のLogin完了後：

    Chrome
      └── Session A
            └── Sanctum Token A

    Other Device
      └── Session B
            └── Sanctum Token B

各Sessionは独立したSanctum Tokenを持つ。

Session作成からCredential連携完了までの間は、

    sanctum_token = NULL

となることを許可する。

これによりSession単位でLogoutできる。

---

## 10. User無効化・Session失効

User無効化や強制Logout等で
Auth.js Sessionを失効させる場合、
対応するSanctum Tokenが存在する場合は
Laravel側Tokenも失効させる。

概念：

    Session失効対象
        ↓
    sanctum_token確認
        ↓
    Token存在時はLaravel側で失効
        ↓
    auth_sessions削除

`sanctum_token` がNULLの場合は
Session Recordのみ削除する。

---

## 11. Session期限切れ

期限切れSession：

    expires_at <= current_timestamp

は利用しない。

期限切れSessionに
`sanctum_token` が存在する場合、
対応するLaravel Tokenも不要となる。

Cleanup時には、
可能な限りSanctum Token失効と
Session削除を対応させる。

具体的なCleanup方式は別途決定する。

---

## 12. セキュリティ

`sanctum_token` はSecretとして扱う。

以下は禁止する。

- Browserへの公開
- localStorageへの保存
- sessionStorageへの保存
- JavaScriptから参照可能なCookieへの保存
- Client Componentへの受け渡し
- API Responseへの含有
- Application Logへの出力
- Analytics等への送信
- Databaseへの平文保存

暗号鍵はRepositoryへ保存しない。

環境変数またはSecret管理機能を使用する。

---

## 13. 将来

以下が必要になった場合は、
`backend_credentials` 等の専用Tableへの分離を再検討する。

- 複数Backend API
- 複数Credential
- Access Token / Refresh Token
- OAuth / OIDC
- Credential Rotation
- Sessionとは異なるCredential Lifecycle
- 複数Credential Provider

MVPではYAGNIの観点から専用Tableは作成しない。

---

## 14. 決定事項

- Auth.js：Database Session
- Session Store：PostgreSQL
- Session Table：`auth_sessions`
- Sanctum Token：`auth_sessions.sanctum_token`
- `sanctum_token` はNULL許可
- Backend Credential連携前は `sanctum_token = NULL` を許可
- 通常のLogin完了後は Session : Sanctum Token = 1 : 1
- Sanctum TokenはBrowserへ公開しない
- Application Level Encryptionを第一候補とする
- 暗号化・復号はNext.js Server側で行う
- Backend API認証時は `sanctum_token IS NULL` をCredential連携済みとして扱わない
- Credential連携済みSessionのLogout時はSessionとSanctum Tokenを両方失効する
- Auth.js Database Session基盤とBackend Credential連携は別責務として実装する
- `backend_credentials` TableはMVPでは作成しない
