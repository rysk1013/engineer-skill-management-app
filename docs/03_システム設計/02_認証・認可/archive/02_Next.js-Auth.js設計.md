# Next.js Session管理 技術決定

## 1. 採用技術

Next.js側のSession管理にはAuth.jsを採用する。

基本構成：

    Browser
       |
       | Auth.js Session Cookie
       v
    Next.js Frontend / BFF
       |
       | Sanctum Bearer Token
       v
    Laravel Backend API
       |
       v
    PostgreSQL

---

## 2. Auth.jsの役割

Auth.jsはBrowserとNext.js間のSession管理を担当する。

主な責務：

- ログイン状態の管理
- Sessionの作成
- Sessionの取得
- Sessionの更新
- Sessionの失効
- Session Cookieの管理
- ログアウト処理
- Next.js側での認証状態取得

ユーザー認証の最終的な主体はLaravelとする。

---

## 3. Browserの責務

BrowserはAuth.jsのSession Cookieのみ保持する。

Browserが保持する情報：

- Auth.js Session Cookie

Browserが保持しない情報：

- Laravel Sanctum Personal Access Token

Sanctum Tokenは以下へ保存しない。

- localStorage
- sessionStorage
- JavaScriptから参照可能なCookie

---

## 4. Next.js BFFの責務

Next.js BFFはAuth.jsを利用してBrowser Sessionを管理する。

主な責務：

- Browserからのログイン要求受付
- Laravel Login APIの呼び出し
- Laravelから返された認証結果の確認
- Auth.js Sessionの作成
- Sessionから利用者を特定する
- Laravel Sanctum Tokenをサーバー側で管理する
- Laravel APIへの認証情報付与
- ログアウト処理
- Session失効処理

---

## 5. Laravelの責務

Laravelはユーザー認証とBackend APIの認証を担当する。

Laravelで以下を行う。

- ID / Password等のCredential検証
- ユーザーの特定
- Sanctum Personal Access Tokenの発行
- Sanctum Tokenの検証
- Sanctum Tokenの失効
- APIアクセスの認証
- 業務上の認可

Auth.jsはLaravelの代わりにユーザー認証を行わない。

---

## 6. ログインフロー

想定するログインフロー：

    1. Browser
       |
       | Login Request
       v
    2. Next.js / Auth.js
       |
       | Credentials
       v
    3. Laravel Login API
       |
       | Credential検証
       v
    4. Laravel
       |
       | Sanctum Token発行
       v
    5. Next.js / Auth.js
       |
       | Session作成
       | Sanctum TokenをServer側で管理
       v
    6. Browser
       |
       | Auth.js Session Cookie
       v
    7. ログイン完了

---

## 7. ログイン後のAPIアクセス

ログイン後は以下の流れでBackend APIへアクセスする。

    Browser
       |
       | Auth.js Session Cookie
       v
    Next.js BFF
       |
       | Session確認
       |
       | Authorization: Bearer <Sanctum Token>
       v
    Laravel Backend API
       |
       | Sanctum Token検証
       | 認可
       | 業務処理
       v
    PostgreSQL

BrowserからLaravel Backend APIを直接呼び出さない。

---

## 8. ログアウトフロー

ログアウト時は以下を行う。

1. BrowserからNext.jsへログアウト要求を送る
2. Next.js BFFからLaravelへToken失効要求を送る
3. Laravel側でSanctum Tokenを失効させる
4. Next.js側で保持している認証情報を破棄する
5. Auth.js Sessionを失効させる
6. BrowserのSession Cookieを無効化する

Browser Sessionのみ削除してSanctum Tokenを残さない。

---

## 9. Session Strategy

Auth.jsではSession Strategyとして以下を検討する。

- JWT Session
- Database Session

今回の構成ではDatabase Sessionを第一候補とする。

---

## 10. Database Sessionを第一候補とする理由

今回のBFF構成では、Laravel Sanctum TokenをBrowserへ公開せず、Next.jsのサーバー側で管理したい。

そのため、Session情報をサーバー側で管理できるDatabase Sessionとの相性がよい。

主な理由：

- Sanctum TokenをServer側で保持しやすい
- SessionをServer側で失効できる
- 強制ログアウトを実装しやすい
- Sessionの有効期限を管理しやすい
- 利用者ごとのSession管理を行いやすい
- BFF構成との責務が明確になる

---

## 11. Database Sessionの構成

基本構成：

    Browser
       |
       | Session Identifier
       v
    Auth.js
       |
       | Session Store
       |   ├── User
       |   ├── Expiration
       |   └── Backend Credential
       |
       v
    Next.js BFF
       |
       | Sanctum Bearer Token
       v
    Laravel Backend API

BrowserにはSessionを識別するCookieのみを持たせる。

Sanctum TokenそのものをBrowserへ公開しない。

---

## 12. Session Store

Database Sessionを採用する場合、Next.js側でSession情報を保存する領域が必要となる。

Session Storeの具体的な保存先は別途決定する。

候補：

- PostgreSQL
- Redis
- その他

MVPでは構成を過度に複雑化しない。

Session Storeの選定は、運用方式・デプロイ構成を踏まえて決定する。

---

## 13. Sessionに保持する情報

Sessionには必要最小限の情報のみ保持する。

候補：

- User ID
- Session ID
- Session Expiration
- Backend Credential参照情報
- 必要最小限の権限情報

以下の業務データをSessionへ大量に保持しない。

- 社員一覧
- 社員スキル
- スキルマスタ
- 担当社員一覧
- その他の業務データ

業務データは必要に応じてLaravel Backend APIから取得する。

---

## 14. Laravel Sanctum Tokenの扱い

Laravel Sanctum TokenはNext.js BFFのサーバー側でのみ扱う。

基本方針：

- Browserへ公開しない
- localStorageへ保存しない
- sessionStorageへ保存しない
- Client Componentへ渡さない
- ログへ出力しない
- ログアウト時に失効させる
- Session失効時に不要なTokenを残さない

---

## 15. Server ComponentでのSession利用

Server ComponentではAuth.jsを利用してSession情報を取得できる構成とする。

利用例：

- ログイン済みか確認する
- 利用者情報を取得する
- 権限に応じて表示内容を変更する

ただし、業務上の最終的な認可はLaravel Backend APIで行う。

---

## 16. Client ComponentでのSession利用

Client Componentでは必要な範囲でログイン状態や表示用の利用者情報を利用する。

Client Componentへ以下を渡さない。

- Laravel Sanctum Token
- Backend APIの秘密情報
- Server専用Credential

Frontend側のSession情報はUI制御のために利用する。

---

## 17. Route Handlerでの認証

Next.js Route Handlerを利用する場合、Auth.js Sessionを確認してから処理する。

基本フロー：

    Browser
       |
       v
    Route Handler
       |
       | Auth.js Session確認
       v
    Laravel Backend API

未認証の場合はLaravel Backend APIを呼び出さない。

ただし、Laravel Backend APIでも必ずSanctumによる認証を行う。

---

## 18. Server Actionでの認証

Server Actionを利用する場合もAuth.js Sessionを確認する。

利用例：

- 社員登録
- 社員編集
- 社員スキル登録
- 社員スキル編集

Server Actionから直接Databaseへアクセスしない。

業務処理はLaravel Backend APIへ委譲する。

基本フロー：

    Server Action
       |
       | Auth.js Session確認
       v
    Laravel Backend API
       |
       | Sanctum認証
       | 認可
       | 業務処理
       v
    PostgreSQL

---

## 19. 認証と認可の責務

### Auth.js / Next.js

担当：

- Browser Session
- ログイン状態
- Session Cookie
- Session有効期限
- Frontend側の表示制御

### Laravel Sanctum

担当：

- Backend API認証
- Token検証
- API利用者特定

### Laravel Authorization

担当：

- 管理ユーザーか
- 権限管理可能な管理ユーザーか
- サブマネージャーか
- チームリーダーか
- 対象社員を閲覧可能か
- 対象社員を編集可能か
- マスタ管理可能か
- 権限管理可能か

Laravelが最終的な認可を行う。

---

## 20. Session Cookieのセキュリティ

Auth.js Session Cookieでは以下を考慮する。

- HttpOnly
- Secure
- SameSite
- Path
- Expiration

本番環境ではHTTPSを使用する。

CookieをJavaScriptから直接取得する構成にはしない。

---

## 21. Session有効期限

Sessionには有効期限を設定する。

検討対象：

- 最大Session有効期間
- 非操作時のSession失効
- Session更新
- Token有効期限との整合性

具体的な時間はセキュリティ要件・運用要件を踏まえて決定する。

---

## 22. SessionとSanctum Tokenの有効期限

Auth.js SessionとLaravel Sanctum Tokenの有効期限をそれぞれ管理する。

以下のような状態を考慮する。

    Auth.js Session
    有効

    Sanctum Token
    失効

この場合、Next.js BFFはLaravelからの401 Unauthorizedを検出し、
利用者を再認証させる等の処理を行う。

SessionとTokenのライフサイクルについては認証詳細設計時に決定する。

---

## 23. 権限変更

ログイン中に利用者の権限が変更される可能性がある。

例：

    管理ユーザー
       ↓
    サブマネージャーへ変更

Session内の権限情報だけを長期間信用しない。

重要な操作ではLaravel Backend API側の最新権限情報を基準として認可する。

---

## 24. 将来的なSSO対応

将来的に社内SSOを導入する可能性を考慮する。

候補：

- Microsoft Entra ID
- Okta
- Google Workspace
- その他OIDC Provider

将来的に認証元を変更しても、

    Browser
       ↓
    Auth.js Session
       ↓
    Next.js BFF
       ↓
    Backend API

という基本境界を維持できる構成を目指す。

---

## 25. 独自Session管理を採用しない理由

今回は独自Session管理を採用しない。

理由：

- Session作成処理を自前実装する必要がある
- Session ID生成を自前実装する必要がある
- Cookie管理を自前実装する必要がある
- Session期限管理を自前実装する必要がある
- Session失効処理を自前実装する必要がある
- セキュリティ上の考慮事項が増える
- MVPの本質的な価値ではない部分の実装量が増える

認証基盤自体を学習・検証することが目的ではないため、Auth.jsを利用する。

---

## 26. 決定事項

### Next.js Session管理

Auth.jsを採用する。

### Session Strategy

Database Sessionを第一候補とする。

### Browserが保持する認証情報

Auth.js Session Cookieのみ保持する。

### Backend API Credential

Laravel Sanctum Personal Access TokenをNext.js BFFのサーバー側で管理する。

### Laravel API認証

Laravel Sanctumを利用する。

### 最終認可

Laravel Backend APIで行う。

### 基本構成

    Browser
       |
       | Auth.js Session Cookie
       v
    Next.js Frontend / BFF
       |
       | Sanctum Bearer Token
       v
    Laravel Backend API
       |
       v
    PostgreSQL

### 基本方針

- Browser Session管理はAuth.jsへ任せる
- Laravel Sanctum TokenをBrowserへ公開しない
- Laravelをユーザー認証・API認証の主体とする
- 業務上の認可はLaravelで必ず行う
- Next.jsからDatabaseへ直接アクセスしない
- Session情報には必要最小限の情報のみ保持する
- 将来的なOIDC / SSOへの変更を考慮する
