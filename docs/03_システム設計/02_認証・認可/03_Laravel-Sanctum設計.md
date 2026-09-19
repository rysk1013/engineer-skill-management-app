# Laravel認証方式 決定

## 1. 採用技術

Laravel Backend APIのトークン認証にはLaravel Sanctumを採用する。

利用方式：

- Laravel Sanctum Personal Access Token
- Bearer Token認証

SanctumのSPA Cookie認証は今回の構成では使用しない。

---

## 2. 基本構成

    Browser
       |
       | Session Cookie
       v
    Next.js Frontend / BFF
       |
       | Authorization: Bearer <Sanctum Token>
       v
    Laravel Backend API
       |
       v
    PostgreSQL

BrowserはLaravel Sanctum Tokenを保持しない。

Sanctum TokenはNext.js BFF側で管理する。

---

## 3. BrowserとNext.js

BrowserとNext.jsの間ではSession Cookieを利用する。

Browserが保持する認証情報：

- Next.js用Session Cookie

Browserが保持しない認証情報：

- Laravel Sanctum Token

Laravel用トークンを以下へ保存しない。

- localStorage
- sessionStorage
- JavaScriptから参照可能なCookie

---

## 4. Next.js BFF

Next.js BFFは以下を担当する。

- BrowserとのSession管理
- ログイン状態の確認
- Laravel Sanctum Tokenの安全な保持
- Laravel Backend APIへのToken付与
- ログアウト時のToken失効
- Laravelから返された認証エラーの処理

Laravel APIへは以下の形式でアクセスする。

    Authorization: Bearer <sanctum-token>

---

## 5. Laravel Backend API

LaravelはSanctum Tokenを検証し、API利用者を特定する。

主な責務：

- Sanctum Tokenの検証
- 利用者の特定
- 認証
- 認可
- 権限制御
- 業務ロジック
- バリデーション
- データアクセス

保護対象APIにはSanctumの認証Middlewareを適用する。

---

## 6. ログインフロー

想定するログインフロー：

    1. Browser
       ↓
       ログイン情報送信

    2. Next.js BFF
       ↓
       Laravel Login APIを呼び出す

    3. Laravel
       ↓
       利用者を認証する

    4. Laravel
       ↓
       Sanctum Personal Access Tokenを発行する

    5. Next.js BFF
       ↓
       Sanctum Tokenをサーバー側で保持する

    6. Next.js
       ↓
       BrowserへSession Cookieを発行する

    7. Browser
       ↓
       ログイン完了

---

## 7. APIアクセスフロー

ログイン後：

    Browser
       |
       | Session Cookie
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

---

## 8. ログアウトフロー

ログアウト時は以下を行う。

1. Next.jsからLaravelへToken失効要求を送る
2. Laravel側でSanctum Tokenを削除・失効させる
3. Next.js側でToken情報を破棄する
4. BrowserのSessionを破棄する

Browser Sessionだけを削除し、Sanctum Tokenを残さない。

---

## 9. Token発行

Sanctum Personal Access Tokenはログイン成功時に発行する。

Tokenは利用者と紐付ける。

必要に応じてToken Nameを設定する。

例：

    nextjs-bff

MVPでは利用者ごとに必要以上のTokenを発行しない。

---

## 10. Token Ability

SanctumではToken Abilityを設定できる。

ただし今回の業務上の権限制御はLaravelの認可機能を主体とする。

例：

    管理ユーザー
    サブマネージャー
    チームリーダー
    担当社員

これらの判定をSanctum Abilityだけで表現しない。

基本方針：

    Sanctum
    → API利用者を認証する

    Laravel Policy / Gate等
    → 業務上の認可を行う

必要性が明確になった場合のみToken Abilityを利用する。

---

## 11. 認証と認可の分離

### Sanctum

担当：

- Token検証
- 利用者特定
- API認証

### Laravel Authorization

担当：

- 全社員を閲覧できるか
- 社員を編集できるか
- 担当社員かどうか
- マスタ管理できるか
- 権限管理できるか

認証済みであっても、権限のない操作は許可しない。

---

## 12. セキュリティ方針

- Sanctum TokenをBrowserへ公開しない
- TokenをlocalStorageへ保存しない
- Tokenをログへ出力しない
- HTTPSを使用する
- Token失効機能を用意する
- ログアウト時にTokenを失効させる
- Token漏洩時に個別失効できるようにする
- Laravel側で必ず認可する
- Next.js側のUI制御のみを信用しない

---

## 13. Sanctum SPA認証

今回の構成ではSanctumのSPA Cookie認証を使用しない。

理由：

    Browser
       ↓
    Next.js BFF
       ↓
    Laravel API

というBFF構成を採用しており、
BrowserからLaravelへ直接アクセスしないため。

Laravel Session CookieをBrowserへ直接持たせるのではなく、
Next.jsとのSessionとLaravel用Tokenを分離する。

---

## 14. 将来のBackend変更

Next.jsはLaravel Sanctumの内部実装へ直接依存しすぎないようにする。

Next.jsから見たBackend認証は、

    Backend API Credential

として扱う。

将来的にBackendをNode.js / TypeScriptなどへ変更する場合、
Next.js側の認証Adapter等を変更することで対応できる構造を意識する。

---

## 15. 決定事項

### Laravel API認証

Laravel Sanctumを採用する。

### Sanctum利用方式

Personal Access Tokenを利用する。

### Browser ↔ Next.js

Session Cookieを利用する。

### Next.js ↔ Laravel

Sanctum Bearer Tokenを利用する。

### Token保存場所

Next.js BFF側で管理する。

### 認可

Laravel Policy / Gate等で最終的な認可を行う。

### 基本構成

    Browser
       ↓
    Next.js Session
       ↓
    Next.js BFF
       ↓
    Sanctum Bearer Token
       ↓
    Laravel Backend API
       ↓
    PostgreSQL
