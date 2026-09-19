# Session Store 技術決定

## 1. 採用技術

Auth.jsのDatabase Sessionを保存するSession StoreとしてPostgreSQLを採用する。

- [x] PostgreSQL
- [ ] Redis

---

## 2. 採用理由

PostgreSQLをSession Storeとして採用する主な理由は以下とする。

- 既に業務データ用DatabaseとしてPostgreSQLを採用している
- MVPでRedisなどの追加インフラを導入せずに済む
- 構成をシンプルに保てる
- Sessionの作成・取得・更新・失効を十分実現できる
- 強制ログアウトなどのSession管理を行いやすい
- MVP規模では十分な性能を期待できる
- 運用対象を増やさずに済む

---

## 3. 基本構成

    Browser
       |
       | Auth.js Session Cookie
       v
    Next.js Frontend / BFF
       |
       | Session Lookup
       v
    PostgreSQL
       |
       | Auth.js Session
       |
       v
    Next.js BFF
       |
       | Sanctum Bearer Token
       v
    Laravel Backend API
       |
       | Business Data Access
       v
    PostgreSQL

PostgreSQLは以下の2つの用途で利用する。

- Auth.js Session Store
- Laravel Backend APIの業務データストア

---

## 4. Session Storeの責務

PostgreSQLにはAuth.jsのSession管理に必要な情報を保存する。

主な対象：

- Session ID
- User ID
- Session有効期限
- Auth.jsが必要とするSession情報
- Backend Credentialを参照するために必要な情報

Session Storeへ社員スキルなどの業務データを保持しない。

---

## 5. 業務データとの分離

同じPostgreSQLを利用する場合でも、Session情報と業務データの責務を明確に分離する。

概念上：

    PostgreSQL
    ├── Auth.js Session Data
    │
    └── Application Business Data
        ├── Employees
        ├── Skills
        ├── Skill Categories
        └── Employee Skills

具体的なDatabase / Schemaの分離方法についてはDatabase設計時に決定する。

---

## 6. Next.jsからのDatabaseアクセス

原則としてNext.jsから業務データへ直接アクセスしない。

Next.jsがPostgreSQLへアクセスする用途はAuth.jsのSession管理に限定する。

基本方針：

    Next.js
       |
       +-- Session Data
       |      ↓
       |   PostgreSQL
       |
       └-- Business Data
              ↓
           Laravel API
              ↓
           PostgreSQL

業務データの取得・更新は必ずLaravel Backend APIを経由する。

---

## 7. LaravelからのDatabaseアクセス

Laravelは業務データの管理を担当する。

Laravelから扱う主なデータ：

- 社員
- 所属部署
- 在籍状態
- スキルカテゴリ
- 技術・スキルマスタ
- 社員スキル
- 権限
- 担当社員
- その他業務データ

Auth.js Sessionの管理責務はLaravelへ持たせない。

---

## 8. Session失効

Database Sessionを採用するため、SessionをServer側で失効できる。

以下のケースを考慮する。

- ログアウト
- 強制ログアウト
- Session有効期限切れ
- 権限変更時
- アカウント無効化時
- セキュリティ上必要な場合

具体的な失効ルールは認証詳細設計時に決定する。

---

## 9. Session有効期限

Sessionには有効期限を設定する。

PostgreSQL上のSession情報に有効期限を保持し、Auth.jsのSession管理と整合させる。

検討事項：

- 最大Session有効期間
- 非操作時のSession失効
- Session更新タイミング
- Sanctum Token有効期限との整合性

具体的な時間は後続のセキュリティ設計で決定する。

---

## 10. Sanctum Token

Laravel Sanctum Personal Access TokenはBrowserへ公開しない。

Next.js BFFのサーバー側で扱う。

SessionとSanctum Tokenの関係を管理し、ログアウト時には以下を行う。

1. Laravel側のSanctum Tokenを失効する
2. Auth.js Sessionを失効する
3. BrowserのSession Cookieを無効化する

---

## 11. RedisをMVPで採用しない理由

MVPではRedisをSession Storeとして採用しない。

理由：

- 新しいインフラコンポーネントが増える
- 開発環境・本番環境の構成が複雑になる
- Redisの監視・バックアップ・障害対応など運用対象が増える
- MVP規模ではPostgreSQLで十分対応可能
- Session性能がボトルネックになることが現時点では想定されない

---

## 12. 将来的なRedis利用

将来的に以下のような要件が発生した場合、Session StoreをRedisへ変更することを検討する。

- Sessionアクセス量が大幅に増加する
- PostgreSQLへのSessionアクセス負荷が問題になる
- TTLベースのSession管理をより効率化したい
- 複数インスタンス間で高速なSession共有が必要になる
- RedisをCacheなど別用途でも導入する

Session Storeの抽象化を過度に行う必要はないが、将来的な変更可能性を妨げない構成を意識する。

---

## 13. 決定事項

### Session Store

PostgreSQLを採用する。

### Auth.js

Database Sessionを利用する。

### PostgreSQLの用途

- Auth.js Session Store
- Laravel Backend APIの業務データストア

### Next.jsのDatabase利用

Auth.js Session管理に限定する。

### LaravelのDatabase利用

業務データの管理に限定する。

### Redis

MVPでは導入しない。

### 基本構成

    Browser
       ↓
    Auth.js Session Cookie
       ↓
    Next.js Frontend / BFF
       ↓
    PostgreSQL
    (Session Store)
       ↓
    Next.js BFF
       ↓
    Sanctum Bearer Token
       ↓
    Laravel Backend API
       ↓
    PostgreSQL
    (Business Data)
