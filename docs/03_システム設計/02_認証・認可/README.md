# 認証・認可設計

Engineer Skill Management App のBrowser、Next.js Frontend／BFF、Laravel Backend API間における認証・認可の境界、Session、Token、Login／Logout Flowを管理するディレクトリです。

Browser SessionにはAuth.js、Laravel Backend APIの認証にはLaravel Sanctum Personal Access Tokenを使用します。業務上の最終的な認可はLaravel Backend APIで行います。

## 基本構成

```text
Browser
   │ Auth.js Session Cookie
   ▼
Next.js Frontend / BFF
   │ Sanctum Bearer Token
   ▼
Laravel Backend API
   │
   ▼
PostgreSQL
```

認証情報の保持範囲は次のとおりです。

```text
Browser
  └── Auth.js Session Cookieのみ

Next.js / Auth.js
  ├── Browser Sessionの管理
  └── Sessionに対応するSanctum Tokenのサーバー側管理

Laravel / Sanctum
  ├── Credentialの検証
  ├── Personal Access Tokenの発行・検証・失効
  └── 業務上の最終認可
```

Laravel用TokenをBrowser、JavaScript、`localStorage`へ公開しません。BrowserからLaravel Backend APIを直接呼び出さず、Next.js BFFを信頼境界として使用します。

## 認証と認可の違い

| 項目 | 確認すること | 主な担当 |
| --- | --- | --- |
| 認証（Authentication） | 利用者が誰であるか | LaravelでCredentialを検証し、Auth.jsでBrowser Sessionを管理する |
| API認証 | Laravel APIを呼び出すCredentialが有効か | Laravel Sanctum |
| 認可（Authorization） | 利用者が対象操作を実行できるか | Laravel Policy／GateとApplication／Domain Rule |

Next.js側では、操作可能なButtonの表示制御やRoute保護を行えます。ただし、Frontendの制御だけをSecurity Boundaryとはせず、Laravelで必ず最終確認します。

## Componentの責務

| Component | 責務 | 担当しないこと |
| --- | --- | --- |
| Browser | Session Cookieの送信、Login／Logout操作 | Sanctum Tokenの保持、Laravel APIの直接呼び出し |
| Next.js／Auth.js | Browser Session、Cookie、Session状態、BFFからのAPI呼び出し | 業務上の最終認可、Business Ruleの保証 |
| Laravel／Sanctum | Credential検証、Token発行・検証・失効、API認証 | Browser Session Cookieの管理 |
| Laravel Application／Domain | Actorと対象Resourceに基づく重要な認可Rule | HTTP CookieやAuth.js Sessionの直接操作 |
| PostgreSQL | User、Auth.js Session、Sanctum Token情報の永続化 | 認可判断そのもの |

Next.jsがPostgreSQLへアクセスする用途はAuth.jsのSession管理に限定し、業務データの取得・更新はLaravel Backend APIを経由します。

## 設計ドキュメント

### 1. 認証全体設計

[認証全体設計](./01_認証全体設計.md)では、Browser、Next.js BFF、Laravel Backend APIの境界と、認証・認可の責務分担を定義します。

主な決定事項：

- BrowserとNext.js間ではSession Cookieを使用する
- Next.jsとLaravel間ではAccess Tokenを使用する
- Laravel API用TokenはNext.js BFFのサーバー側で管理する
- Laravel Backend APIで最終的な認可を行う
- 将来のOIDC／OAuthによるSSOへ移行しやすい境界を維持する

### 2. Next.js・Auth.js設計

[Next.js・Auth.js設計](./02_Next.js-Auth.js設計.md)では、Browser Session、Cookie、Route Handler／Server Action、Session Store、Sanctum Tokenとの連携を定義します。

主な決定事項：

- Next.jsのSession管理にAuth.jsを使用する
- Database Sessionを第一候補とする
- Sessionには必要最小限の情報だけを保持する
- Server Component、Route Handler、Server Actionはサーバー側でSessionを確認する
- Sanctum TokenとBrowser Sessionの有効期限・失効を整合させる

### 3. Laravel・Sanctum設計

[Laravel・Sanctum設計](./03_Laravel-Sanctum設計.md)では、Login API、Personal Access Token、Ability、Middleware、Token失効、Laravel Authorizationとの分離を定義します。

主な決定事項：

- Laravel Backend APIの認証にSanctumを使用する
- Sanctum Personal Access TokenをBearer Tokenとして使用する
- SanctumはAPI認証、Laravel Policy／Gateは認可を担当する
- Next.jsからはSanctumの内部実装ではなく、Backend API Credentialとして扱う

## Login Flow

```text
1. Browser
   └── Login RequestをNext.jsへ送信

2. Next.js / Auth.js
   └── CredentialをLaravel Login APIへ送信

3. Laravel
   ├── Userを認証
   └── Sanctum Personal Access Tokenを発行

4. Next.js / Auth.js
   ├── Database Sessionを作成
   └── Sanctum TokenをSessionに対応付けてサーバー側で保持

5. Browser
   └── Auth.js Session Cookieを受け取る
```

Credential検証とToken発行はLaravel、Browser Sessionの作成とCookie発行はNext.js／Auth.jsが担当します。

## API Access Flow

```text
Browser
   │ Session Cookie
   ▼
Next.js BFF
   ├── Sessionを確認
   └── Authorization: Bearer <Sanctum Token>
              │
              ▼
Laravel Backend API
   ├── Sanctum Tokenを検証
   ├── Actorを特定
   ├── Laravel Policy／Applicationで認可
   └── Business Logicを実行
              │
              ▼
         PostgreSQL
```

## Logout Flow

1. BrowserからNext.jsへLogoutを要求する。
2. Next.js BFFからLaravelへSanctum Tokenの失効を要求する。
3. LaravelでTokenを削除または失効させる。
4. Next.js側でToken情報とAuth.js Sessionを破棄する。
5. BrowserのSession Cookieを無効化する。

Browser Sessionだけを削除してSanctum Tokenを残さず、両方のLifecycleを揃えます。

## 認可モデル

MVPでは、主に次のRoleを扱います。

| Role | 主な位置付け |
| --- | --- |
| Administrator | 全体管理。権限管理可否は`canManagePermissions`で区別する |
| SubManager | Assignmentされた社員に対する管理操作 |
| TeamLeader | Assignmentされた社員に対する限定的な操作 |

詳細なDomain Ruleは[Access Control設計](../../02_アーキテクチャ/01_Backend/DDD設計/10_Access-Control設計.md)、Laravel Layerでの適用方法は[Presentation Layer設計](../../02_アーキテクチャ/01_Backend/Laravel/05_Presentation%20Layer設計.md)を参照してください。

## SessionとTokenの保存

- Auth.jsのSession StoreにはPostgreSQLを使用します。
- `auth_sessions`はUser、Session Token、期限、暗号化されたSanctum Tokenを管理します。
- Auth.js SessionとSanctum Tokenは1対1を基本とします。
- 複数端末LoginはSessionを分けて許可し、Session単位でLogoutできるようにします。
- Sanctum TokenをApplication Level Encryptionして保存することを第一候補とします。

Tableと保存方式の詳細は[Auth.js Sessionテーブル設計](../01_データベース/09_Auth.js-Sessionテーブル設計.md)と[Sanctum Token保存方式](../01_データベース/10_Sanctum-Token保存方式.md)を参照してください。

## Security方針

- Session Cookieは`HttpOnly`を使用する
- 本番環境ではCookieへ`Secure`属性を設定する
- 適切な`SameSite`属性とCSRF対策を設定する
- Sanctum TokenをBrowserへ公開しない
- Tokenを`localStorage`やClient ComponentのStateへ保存しない
- SessionとTokenに有効期限を設定し、Logout時に両方を失効する
- 認証失敗時に利用者の存在や内部情報を不要に返さない
- Secretや平文TokenをLogへ出力しない
- Userの無効化や重要な権限変更時は、既存Session／Tokenの扱いを確認する

## 将来のSSO対応

将来的にMicrosoft Entra ID、Okta、Google WorkspaceなどのOIDC／OAuth Providerを利用する場合も、BrowserとNext.jsのSession境界、Next.jsとBackend APIのCredential境界を維持します。認証元を変更しても、BackendのDomainとAuthorization Ruleへの影響を抑える構成とします。

## 推奨する読み順

1. [認証全体設計](./01_認証全体設計.md)で、信頼境界と責務分担を把握する。
2. [Next.js・Auth.js設計](./02_Next.js-Auth.js設計.md)で、Browser SessionとBFFの処理を確認する。
3. [Laravel・Sanctum設計](./03_Laravel-Sanctum設計.md)で、API認証とToken Lifecycleを確認する。
4. Database設計で、SessionとTokenの保存方式を確認する。
5. Access Control設計で、Roleと業務上の認可Ruleを確認する。

## 文書管理ルール

- 認証方式を変更した場合は、Login、API Access、Logoutの全Flowを更新します。
- SessionまたはTokenの保存方式を変更した場合は、Database Schema、暗号化、期限、失効処理を合わせて確認します。
- Roleや認可Ruleを変更した場合は、Laravel Policy、Application、Domain、Frontend表示制御、Testを確認します。
- Security上のSecret、Cookie、Tokenの実値は文書へ記載しません。
- 認証・認可の設計変更には、Feature TestとSecurity観点のReviewを伴わせます。
