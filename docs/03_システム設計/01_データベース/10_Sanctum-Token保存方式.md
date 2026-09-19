# Sanctum Token 保存方式 決定

## 採用方式

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

## Relation

    User
      |
      | 1:N
      v
    AuthSession
      |
      | 1:1
      v
    Sanctum Token

1つのAuth.js Sessionに対して、
1つのLaravel Sanctum Tokenを対応させる。

## sanctum_token

Laravel APIへ送信するCredentialとして使用する。

    Next.js BFF
        |
        | Authorization: Bearer <token>
        v
    Laravel API

BrowserへSanctum Tokenを公開しない。

## 保存

`sanctum_token` はSecretとして扱う。

第一候補としてApplication Level Encryptionを使用し、
暗号化した状態でPostgreSQLへ保存する。

## Logout

Logout時：

    Auth.js Session特定
        ↓
    Sanctum Token取得
        ↓
    Laravel側のTokenを失効
        ↓
    auth_sessions削除
        ↓
    Session Cookie削除

SessionとSanctum TokenのLifecycleを対応させる。

## 複数端末

複数Sessionを許可する。

    Chrome
      └── Session A
            └── Sanctum Token A

    Other Device
      └── Session B
            └── Sanctum Token B

これによりSession単位でLogoutできる。

## 将来

以下が必要になった場合は、
`backend_credentials` 等の専用Tableへの分離を再検討する。

- 複数Backend API
- 複数Credential
- Access Token / Refresh Token
- OAuth / OIDC
- Credential Rotation
- Sessionとは異なるCredential Lifecycle

MVPではYAGNIの観点から専用Tableは作成しない。

## 決定事項

- Auth.js：Database Session
- Session Store：PostgreSQL
- Session Table：`auth_sessions`
- Sanctum Token：`auth_sessions.sanctum_token`
- Session : Sanctum Token = 1 : 1
- Sanctum TokenはBrowserへ公開しない
- Application Level Encryptionを第一候補とする
- `backend_credentials` TableはMVPでは作成しない
