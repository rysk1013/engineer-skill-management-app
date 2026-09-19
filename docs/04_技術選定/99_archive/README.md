# 技術選定

Engineer Skill Management App で採用する技術、ツール、アプリケーション構成と、その判断理由を管理するディレクトリです。

このディレクトリでは「何を採用するか」と「なぜ採用するか」を記録します。採用した技術をどのような責務と依存関係で構成するかは[`02_アーキテクチャ`](../02_アーキテクチャ/README.md)、具体的なデータベース・認証・API設計は[`03_システム設計`](../03_システム設計/README.md)を参照してください。

## 採用構成

```text
Browser
   │
   ▼
Next.js Frontend / BFF
   │ OpenAPIに基づくHTTP API
   ▼
Laravel Backend API
   │
   ▼
PostgreSQL
```

- FrontendとBackendを別アプリケーションとして構成し、一つのRepositoryで管理します。
- Next.jsはFrontendとBFFを担当し、BrowserからLaravel APIを直接呼び出しません。
- LaravelはBackend API、Business Logic、認可、Validation、データ整合性を担当します。
- PostgreSQLは業務データとAuth.jsのDatabase Sessionを保持します。

## 技術スタック

| 領域 | 採用技術・方針 |
| --- | --- |
| Repository構成 | Frontend／Backend分離のMonorepo |
| Frontend／BFF | Next.js、TypeScript |
| Backend API | PHP、Laravel |
| Database | PostgreSQL |
| Browser Session | Auth.js、HttpOnly Session Cookie |
| Backend API認証 | Laravel Sanctum |
| Session Store | PostgreSQL |
| API仕様 | OpenAPI First |
| OpenAPI Lint／Bundle | Redocly CLI |
| TypeScript型生成 | openapi-typescript |
| Frontend Test | Vitest、React Testing Library、Playwright |
| Backend Test | PHPUnit、Laravel Feature Test |
| Frontend品質 | ESLint、Prettier、TypeScript Type Check |
| Backend品質 | Laravel Pint、PHPStan、Larastan |

## 技術選定ドキュメント

### 1. アプリケーション構成

[アプリケーション構成](./01_アプリケーション構成.md)では、FrontendとBackendを分離しながら、一つのRepositoryで管理するMonorepo構成を採用した理由を記録します。

### 2. フロントエンド

[フロントエンド](./02_フロントエンド.md)では、Next.jsをFrontend兼BFFとして使用し、画面表示、Session管理、Laravel APIの呼び出しを担当させる方針を記録します。

### 3. バックエンド

[バックエンド](./03_バックエンド.md)では、PHPとLaravelをBackend APIとして使用し、Business Ruleと最終的な認可・Validation・データ整合性をBackendで保証する方針を記録します。

### 4. データベース

[データベース](./04_データベース.md)では、検索・集計・将来拡張を考慮してPostgreSQLを採用した理由と、Laravelを経由して業務データへアクセスする方針を記録します。

### 5. 認証方式

[認証方式](./05_認証方式.md)では、Browser、Next.js、Laravel間で使用する認証方式を管理します。具体的な認証フローは[認証・認可設計](../03_システム設計/02_認証・認可/README.md)を参照してください。

### 6. Session Store

[Session Store](./06_Session-Store.md)では、Auth.jsのDatabase Sessionを保存するStoreとしてPostgreSQLを採用し、MVPでRedisなどの追加Infrastructureを導入しない判断を記録します。

### 7. API・OpenAPI

[API・OpenAPI](./07_API・OpenAPI.md)では、Redocly CLIによるLint／Bundle、openapi-typescriptによる型生成、CIでのAPI契約検証を記録します。

### 8. テストツール

[テストツール](./08_テストツール.md)では、Frontend、BFF、Backend API、E2Eの各Test Levelで使用するツールと責務を記録します。

### 9. コード品質ツール

[コード品質ツール](./09_コード品質ツール.md)では、Formatting、Lint、型検査、Static Analysisに使用するツールとCIでの役割を記録します。

## 技術選定と設計文書の関係

| 文書 | 主な問い |
| --- | --- |
| `04_技術選定` | 何を、なぜ採用するか |
| [`02_アーキテクチャ`](../02_アーキテクチャ/README.md) | どの責務・依存関係で構成するか |
| [`03_システム設計`](../03_システム設計/README.md) | Database、認証、APIをどう実現するか |
| [`05_開発・運用`](../05_開発・運用/README.md) | 開発環境とCI/CDでどう運用するか |

## 推奨する読み順

1. [アプリケーション構成](./01_アプリケーション構成.md)で、システムとRepositoryの分割方針を確認する。
2. [フロントエンド](./02_フロントエンド.md)と[バックエンド](./03_バックエンド.md)で、Next.jsとLaravelの責務を確認する。
3. [データベース](./04_データベース.md)、[認証方式](./05_認証方式.md)、[Session Store](./06_Session-Store.md)で、データと認証の基盤を確認する。
4. [API・OpenAPI](./07_API・OpenAPI.md)で、FrontendとBackend間の契約管理を確認する。
5. [テストツール](./08_テストツール.md)と[コード品質ツール](./09_コード品質ツール.md)で、品質保証の手段を確認する。

## 文書管理ルール

- 採用した選択肢と採用しなかった候補を明示し、判断理由を残します。
- Version番号は開発開始時点の安定版を基準とし、具体的なVersionは各Applicationの依存関係ファイルで固定します。
- 技術を変更する場合は、Architecture、System Design、開発環境、CI/CDへの影響を合わせて確認します。
- 新しいツールを追加する場合は、目的が既存ツールと重複していないか、MVPの運用負荷に見合うかを確認します。

[ドキュメント一覧へ戻る](../README.md)
