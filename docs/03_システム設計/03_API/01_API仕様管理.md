# API仕様管理 技術決定

## 1. 採用方式

API仕様管理にはOpenAPI Firstを採用する。

API実装より先にOpenAPIでAPI契約を定義し、
Next.js BFFとLaravel Backend APIの双方がその仕様に従う。

---

## 2. Source of Truth

Backend APIの契約についてはOpenAPIをSource of Truthとする。

    OpenAPI
       |
       ├── Next.js BFF
       |
       └── Laravel Backend API

LaravelのControllerやEloquent ModelをAPI仕様のSource of Truthとはしない。

---

## 3. 基本構成

Monorepo内にOpenAPI仕様を配置する。

想定：

    engineer-skill-management/
    ├── frontend/
    │   └── Next.js
    │
    ├── backend/
    │   └── Laravel
    │
    ├── openapi/
    │   └── openapi.yaml
    │
    ├── docs/
    │
    └── compose.yaml

具体的なOpenAPIファイル構成は別途決定する。

---

## 4. 開発フロー

基本的な開発フローを以下とする。

    User Story
        ↓
    Acceptance Criteria
        ↓
    API Design
        ↓
    OpenAPI
        ↓
    API Review
        ↓
    ┌───────────────────────┐
    │                       │
    ↓                       ↓
Next.js BFF              Laravel
型 / Client生成          Backend API実装
BFF実装                  Feature Test
    │                       │
    └───────────┬───────────┘
                ↓
         Integration Test
                ↓
              E2E

---

## 5. API設計

APIを実装する前に以下をOpenAPIで定義する。

- Endpoint
- HTTP Method
- Request Parameter
- Request Body
- Response Body
- HTTP Status
- Error Response
- Validation上必要なAPI契約

業務ロジックの詳細すべてをOpenAPIへ記述することは目的としない。

---

## 6. Next.js BFF

Next.js BFFはOpenAPIで定義されたBackend API契約を利用する。

基本方針：

- Request / Response型を手書きで重複定義しない
- OpenAPIからTypeScript型を生成する
- 必要に応じてAPI Clientも生成する
- Laravel固有の内部構造へ依存しない

---

## 7. Laravel Backend API

LaravelはOpenAPIで定義されたAPI契約を満たすように実装する。

Laravel側で担当するもの：

- Routing
- Authentication
- Authorization
- Validation
- Business Logic
- Database Access
- Response生成

OpenAPIに記載されているからといって、
業務上必要なValidationやAuthorizationを省略しない。

---

## 8. Laravel内部構造との分離

以下をそのままAPI契約へ露出させない。

- Eloquent Model
- Database Table
- Database Column構造
- Laravel固有のClass
- Laravel固有のException
- 内部Service構造

API Request / Responseを独立した契約として扱う。

---

## 9. API変更

API変更時はOpenAPIを先に変更する。

基本フロー：

    Requirement Change
        ↓
    OpenAPI変更
        ↓
    Review
        ↓
    Breaking Change確認
        ↓
    Frontend型 / Client再生成
        +
    Laravel実装修正
        ↓
    Test
        ↓
    Merge

Laravel実装だけを先に変更し、
OpenAPIを後から追従させることは原則避ける。

---

## 10. Breaking Change

API変更時にはBreaking Changeかどうかを確認する。

例：

- Response Field削除
- Request Field必須化
- Field Type変更
- Endpoint削除
- HTTP Method変更
- Status Codeの意味変更

Breaking Changeの扱い・VersioningについてはAPI設計時に決定する。

---

## 11. TypeScript型生成

OpenAPIからNext.js用のTypeScript型を生成する。

対象候補：

- Request Type
- Response Type
- Error Response Type

具体的なGeneratorは別途選定する。

---

## 12. API Client生成

OpenAPIからAPI Clientまで生成するかどうかは別途決定する。

候補：

- 型のみ生成
- 型 + API Client生成

BFF側で過度にGenerator依存しないことも考慮する。

---

## 13. Contract確認

OpenAPIとLaravel実装の乖離を防ぐため、
CI等でContract確認を行うことを検討する。

候補：

- OpenAPI Lint
- Schema Validation
- Contract Test
- Breaking Change検出

具体的なツールはAPI品質ツール選定時に決定する。

---

## 14. OpenAPI Review

OpenAPI変更は通常のCode Review対象とする。

主なReview観点：

- Endpoint名
- Resource設計
- HTTP Method
- Request構造
- Response構造
- Error形式
- Status Code
- Naming
- Breaking Change
- Frontend側で利用しやすい契約か
- Laravel内部実装へ依存していないか

---

## 15. 将来のBackend変更

OpenAPIをLaravelから独立した契約として管理する。

そのため将来的に、

    Laravel
       ↓
    Node.js / TypeScript

などへBackend実装を変更する場合でも、
OpenAPI契約を維持できる構成を目指す。

Next.js BFFから見たBackendは、

    OpenAPI Contractを満たすBackend API

として扱う。

---

## 16. 採用理由

OpenAPI Firstを採用する理由：

- Next.jsとLaravelを別Applicationとしている
- Frontend / Backendの境界を明確にできる
- API実装前にContractをReviewできる
- Next.js用TypeScript型を生成できる
- Frontend / Backendを並行開発しやすい
- Laravel固有実装への依存を減らせる
- 将来的なBackend変更に対応しやすい
- MonorepoでAPI Contractを共有しやすい

---

## 17. 決定事項

### API仕様管理

OpenAPI Firstを採用する。

### Source of Truth

OpenAPIをBackend API ContractのSource of Truthとする。

### Laravel

OpenAPI Contractの実装者として扱う。

### Next.js

OpenAPI Contractの利用者として扱う。

### 基本方針

- API実装前にOpenAPIを定義する
- OpenAPI変更をReviewする
- Request / Response型をOpenAPIから生成する
- Laravel内部構造をAPIへ漏らさない
- API変更は原則としてOpenAPIから開始する
- Frontend / Backend双方がOpenAPI Contractへ従う
