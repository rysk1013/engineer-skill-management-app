# OpenAPI 周辺ツール 技術決定

## 1. 採用ツール

### OpenAPI Lint / Bundle

- [x] Redocly CLI
- [ ] Spectral

### TypeScript型生成

- [x] openapi-typescript
- [ ] OpenAPI Generator

### Contract検証

- [x] CIでOpenAPI Lint / Bundle / Type Generationを実行する
- [ ] MVPで専用Contract Testing Toolを追加する

---

## 2. Redocly CLI

OpenAPI仕様のLintとBundleにRedocly CLIを利用する。

主な用途：

- OpenAPI Lint
- `$ref` の検証
- API Design Ruleのチェック
- 複数ファイルのBundle
- OpenAPI仕様の構造確認

基本フロー：

    openapi/
        ↓
    Redocly Lint
        ↓
    Redocly Bundle
        ↓
    dist/openapi.yaml

---

## 3. Redocly CLIを採用する理由

Redocly CLIはOpenAPI管理に必要な複数機能をまとめて提供する。

今回利用する主なCommand：

    lint
    bundle

1つのToolで、

    Lint
      +
    Bundle

を扱えるため、Tool構成を増やしすぎずに済む。

---

## 4. Spectralを採用しない理由

SpectralもOpenAPI Linterとして有力なToolである。

特徴：

- OpenAPI対応
- Custom Ruleを作成できる
- API Style Guideの適用に向いている

ただしMVPでは、

    Redocly
    ├── Lint
    └── Bundle

を1Toolで扱えるため、
Redocly CLIを優先する。

将来的に複雑なAPI Governance Ruleが必要になった場合は
Spectralの追加を検討する。

---

## 5. OpenAPI File

OpenAPIは複数ファイルで管理する。

例：

    openapi/
    ├── openapi.yaml
    │
    ├── paths/
    │   ├── auth.yaml
    │   ├── employees.yaml
    │   ├── employee-skills.yaml
    │   ├── skills.yaml
    │   └── skill-categories.yaml
    │
    └── schemas/
        ├── auth.yaml
        ├── employee.yaml
        ├── employee-skill.yaml
        ├── skill.yaml
        ├── skill-category.yaml
        └── error.yaml

---

## 6. Bundle

複数ファイルのOpenAPI仕様を単一ファイルへBundleする。

Input：

    openapi/openapi.yaml

Output：

    openapi/dist/openapi.yaml

生成されたBundle Fileは以下で利用できる。

- TypeScript型生成
- API Documentation
- CI Validation
- その他OpenAPI Tool

---

## 7. openapi-typescript

Next.js向けTypeScript型生成には
openapi-typescriptを採用する。

生成対象：

- Request Type
- Response Type
- Path Type
- Schema Type
- Error Response Type

API Client自体は生成しない。

---

## 8. openapi-typescriptを採用する理由

今回必要なのは、

    OpenAPI
       ↓
    TypeScript Types

であり、

    OpenAPI
       ↓
    大量のGenerated API Client

ではない。

openapi-typescriptはOpenAPI Schemaから
静的なTypeScript型を生成できるため、
今回の「型だけ生成」の方針と一致する。

---

## 9. Type Generation

基本フロー：

    openapi/
       ↓
    Redocly Lint
       ↓
    Redocly Bundle
       ↓
    dist/openapi.yaml
       ↓
    openapi-typescript
       ↓
    frontend/generated/api-types.ts

---

## 10. Generated Code

生成されたTypeScript Fileは直接編集しない。

対象例：

    frontend/
    └── generated/
        └── api-types.ts

変更が必要な場合：

    OpenAPI変更
        ↓
    Bundle
        ↓
    Type再生成

とする。

---

## 11. API Client

API ClientはNext.js BFF側で薄く実装する。

例：

    frontend/
    └── lib/
        └── api/
            ├── client.ts
            ├── employees.ts
            ├── skills.ts
            └── skill-categories.ts

共通Clientでは以下を担当する。

- Base URL
- Sanctum Bearer Token
- HTTP Header
- JSON Parse
- Error Handling
- Timeout等の共通処理

---

## 12. API ClientとGenerated Type

API Clientではopenapi-typescriptで生成した型を使用する。

概念：

    Generated Type
          ↓
    Custom API Client
          ↓
    Laravel Backend API

Request / Response型を手書きで重複定義しない。

---

## 13. OpenAPI Lint

OpenAPI変更時は必ずLintする。

確認対象：

- OpenAPI Syntax
- `$ref`
- Required Field
- Schema定義
- Endpoint定義
- HTTP Method
- Response定義
- Naming Rule
- その他API Design Rule

---

## 14. CI

Pull Request時に以下を実行する。

    OpenAPI Lint
        ↓
    OpenAPI Bundle
        ↓
    TypeScript型生成
        ↓
    Generated File差分確認

OpenAPIが不正な場合はCIを失敗させる。

---

## 15. Generated Fileの差分確認

OpenAPIを変更したにもかかわらず、
Generated Typeを更新し忘れることを防止する。

例：

    Type生成
       ↓
    git diff --exit-code

差分が存在する場合はCI Failureとする方式を検討する。

---

## 16. Contract検証

MVPでは専用Contract Testing Toolを追加しない。

まず以下でAPI Contractの品質を保証する。

- OpenAPI Lint
- Laravel Feature Test
- TypeScript型生成
- Integration Test
- E2E Test

必要性が確認された場合のみ、
専用Contract Testing Toolを追加する。

---

## 17. LaravelとのContract確認

Laravel Feature Testでは、

- HTTP Status
- JSON構造
- Validation Error
- Authentication Error
- Authorization Error

を確認する。

OpenAPIで定義したContractと一致するようにテストを書く。

---

## 18. API Documentation

MVPではAPI Documentation専用Toolを必須としない。

必要になった場合、
Redocly CLIによるAPI Reference生成を検討する。

OpenAPI自体をSource of Truthとする。

---

## 19. Docker

OpenAPI ToolもDocker開発環境から実行できるようにする。

基本的にはFrontendのNode.js Containerから実行する。

例：

    docker compose exec frontend npm run openapi:lint

    docker compose exec frontend npm run openapi:bundle

    docker compose exec frontend npm run openapi:types

具体的なScript名はProject Setup時に決定する。

---

## 20. package.json

想定Script：

    openapi:lint
    openapi:bundle
    openapi:types
    openapi:check

例：

    openapi:check
        ↓
    lint
        +
    bundle
        +
    types

CIでは `openapi:check` を利用できる構成とする。

---

## 21. Toolの役割

| 目的 | Tool |
| --- | --- |
| OpenAPI Lint | Redocly CLI |
| OpenAPI Bundle | Redocly CLI |
| TypeScript型生成 | openapi-typescript |
| API実装Test | Laravel Feature Test |
| Frontend / Backend Integration | Integration Test |
| 全体確認 | Playwright |

---

## 22. 採用しないTool

### Spectral

MVPでは採用しない。

Redocly CLIでLint / Bundleを統一する。

複雑なAPI Governanceが必要になった場合に再検討する。

### OpenAPI Generator

MVPでは採用しない。

API Clientを自動生成しない方針のため、
TypeScript型生成にはopenapi-typescriptを利用する。

---

## 23. 決定事項

### OpenAPI Lint

Redocly CLIを採用する。

### OpenAPI Bundle

Redocly CLIを採用する。

### TypeScript型生成

openapi-typescriptを採用する。

### API Client

Next.js BFF側で薄く手書きする。

### Contract Test

MVPでは専用Toolを追加しない。

### CI

OpenAPI Lint / Bundle / Type Generationを実行する。

### 基本フロー

    OpenAPI
       ↓
    Redocly Lint
       ↓
    Redocly Bundle
       ↓
    openapi-typescript
       ↓
    TypeScript Types
       ↓
    Next.js BFF
       ↓
    Laravel Backend API
