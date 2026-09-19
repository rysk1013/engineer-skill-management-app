# API実装サイクル

## 1. 目的

本ドキュメントは、Engineer Skill Management App のMVP実装において、1つのAPI / UseCaseを選択してからEnd-to-Endで完成させるまでの標準的な実装サイクルを定義する。

実装全体の基本原則は [`01_実装方針.md`](./01_実装方針.md)、Feature単位の実装順序は [`02_実装フェーズ.md`](./02_実装フェーズ.md) に従う。

本ドキュメントでは、Vertical SliceおよびIncremental OpenAPI Firstを実際の開発作業へ落とし込む。

---

## 2. 基本サイクル

API / UseCaseごとに以下のサイクルを繰り返す。

```text
1. API / UseCase選択
        ↓
2. 既存設計確認
        ↓
3. OpenAPI定義
        ↓
4. OpenAPI検証
        ↓
5. TypeScript型生成
        ↓
6. Backend実装
        ↓
7. Backend Test
        ↓
8. BFF実装
        ↓
9. Frontend実装
        ↓
10. Frontend Test
        ↓
11. Integration確認
        ↓
12. Slice完了確認
        ↓
次のAPI / UseCase
```

各工程を完全に独立したWaterfall工程として扱うのではなく、必要に応じて前工程へ戻りながら小さく実装・検証する。

ただし、OpenAPIをBackend実装から後付け生成する方式には変更せず、API契約のSource of TruthはOpenAPIとする。

---

## 3. API / UseCase選択

最初に、そのサイクルで完成させるAPI / UseCaseを明確にする。

例えばEmployee登録では以下となる。

```text
Feature:
Employee

API:
POST /employees

UseCase:
Employeeを登録する
```

実装単位は可能な限り小さくする。

以下のようにFeature全体を最初から1つのSliceとして扱うことは原則として避ける。

```text
Employee

├── 一覧
├── 詳細
├── 登録
├── 更新
└── その他操作

        ↓

すべて同時に実装
```

代わりに、

```text
Employee登録
     ↓
完成
     ↓
Employee一覧
     ↓
完成
     ↓
Employee詳細
     ↓
完成
```

のように進める。

ただし、複数API / UseCaseが密接に関連し、分割すると不自然な一時実装や大きな手戻りが発生する場合は、同一Sliceとして扱ってよい。

---

## 4. 既存設計確認

実装開始前に、対象API / UseCaseに関係する既存のSource of Truthを確認する。

主な確認先は以下とする。

```text
01_要件定義
02_アーキテクチャ
03_システム設計
04_技術選定
05_MVP実装計画
07_非機能要件
```

すべてのドキュメントを毎回確認する必要はない。

対象UseCaseに影響するものだけを確認する。

例えばEmployee登録の場合は、主に以下が対象となる。

```text
MVP要件
    ↓
Employee Domain設計
    ↓
Database設計
    ↓
Employee API設計
    ↓
Access Control設計
    ↓
OpenAPI実仕様
```

確認する主な観点は以下とする。

- UseCaseの目的
- Requestに必要な情報
- Response
- Domain Invariant
- Authorization
- Validation
- Database Constraint
- Transaction
- Error Response
- Date / Time
- 非機能要件

設計不足や矛盾を発見した場合、実装コード側だけで仕様を補完しない。

必要なSource of Truthを更新してから実装へ進む。

---

## 5. OpenAPI定義

対象APIの契約をOpenAPIへ定義する。

既存のAPI設計およびAPI共通仕様に従い、必要に応じて以下を定義する。

- Path
- HTTP Method
- operationId
- Authentication
- Path Parameter
- Query Parameter
- Request Header
- Request Body
- Response Body
- HTTP Status
- Error Response
- Validation Constraint
- Schema
- Example

API契約の依存方向は以下を維持する。

```text
             OpenAPI
            /       \
           ▼         ▼
Laravel Backend   TypeScript型
                     ↓
                 Next.js BFF
```

Laravel Controller、Eloquent Model、Database SchemaをAPI仕様のSource of Truthにはしない。

---

## 6. OpenAPI検証・型生成

OpenAPIを変更したら、実装へ進む前に仕様を検証する。

基本フローは以下とする。

```text
OpenAPI編集
    ↓
Redocly Lint
    ↓
Bundle
    ↓
openapi-typescript
    ↓
TypeScript型生成
```

少なくとも以下を確認する。

- OpenAPIがSyntax上正しい
- API共通仕様に従っている
- Schema参照が解決できる
- Request / Responseが意図した契約になっている
- Error Responseが共通仕様と整合している
- TypeScript型を正常に生成できる

生成された型は原則として手動編集しない。

変更が必要な場合はOpenAPIを修正し、再生成する。

```text
OpenAPI
   ↓
Generated Type

○ OpenAPIを修正して再生成
× Generated Typeを直接修正
```

---

## 7. Backend実装

OpenAPI契約に基づいてLaravel Backendを実装する。

既存のBackend Architectureに従い、責務を適切なLayerへ配置する。

### Command系UseCase

基本的には以下の流れとする。

```text
HTTP Request
     ↓
Form Request
     ↓
Controller
     ↓
Command
     ↓
CommandHandler
     ↓
Domain
     ↓
Repository Interface
     ↓
Repository Implementation
     ↓
PostgreSQL
```

必要に応じて以下を実装する。

- Form Request
- Controller
- Command
- CommandHandler
- Aggregate
- Entity
- Value Object
- Repository Interface
- Repository Implementation
- Mapper
- Eloquent Model
- Transaction
- Policy
- Response変換

### Query系UseCase

Read処理ではAggregateの復元を必須としない。

必要に応じて以下を利用する。

```text
HTTP Request
     ↓
Controller
     ↓
Query
     ↓
QueryHandler / Query Service
     ↓
Read Model
     ↓
PostgreSQL
```

Queryの目的だけで不要なAggregateを復元しない。

### 実装範囲

そのSliceで必要なコードのみ実装する。

「後で使う可能性がある」という理由だけで、

- 汎用Repository
- 汎用Service
- Domain Service
- 共通Abstraction
- 将来用UseCase

などを先行実装しない。

---

## 8. Backend Test

Backend実装と同じSlice内で必要なTestを実装する。

対象に応じて以下を使い分ける。

### Domain Test

主にDomain Invariantを確認する。

```text
EmployeeSkill
├── 未経験ならLevel 1のみ
├── 経験ありなら1か月以上
├── 経験ありなら最終利用年月必須
└── 不正状態を生成できない
```

### Application Test

主にUseCaseの振る舞いを確認する。

- 正常系
- Domain Error
- Repositoryとの連携
- Transactionが必要な処理
- Application上の競合確認

### Feature / API Test

HTTP境界を確認する。

- Authentication
- Authorization
- Validation
- Status Code
- Response Schema
- Error Response

### Infrastructure Test

必要な場合に以下を確認する。

- Repository
- Mapper
- Database Constraint
- Query Service
- Lock / Concurrency

すべてのAPIにすべての種類のTestを書くことを目的としない。

対象の責務を最も適切なレイヤーで保証する。

---

## 9. BFF実装

Next.js BFFからLaravel Backend APIへアクセスする処理を実装する。

基本経路は以下とする。

```text
Browser
   ↓
Next.js
   ↓
Auth.js Session
   ↓
BFF
   ↓
API Client
   ↓
Sanctum Token
   ↓
Laravel Backend
```

Backend APIとの通信ではOpenAPIから生成した型を利用する。

```text
OpenAPI
   ↓
Generated Type
   ↓
API Client
   ↓
BFF
```

BFFではBackendのDomain Logicを再実装しない。

BFFの主な責務は以下とする。

- Auth.js Session確認
- 認証情報の取得
- Sanctum Tokenの利用
- Backend API呼び出し
- Request / Responseの橋渡し
- BFF固有の必要最小限の変換
- Backend Errorの適切な伝播・変換

Frontend側でBackend API仕様を独自定義しない。

---

## 10. Frontend実装

対象UseCaseをユーザーが利用するために必要なUIを実装する。

```text
Page / Component
       ↓
BFF
       ↓
Laravel Backend
```

既存のFrontend Architectureに従い、以下を適切に実装する。

- Server Component / Client Component
- Form
- Validation
- Loading
- Error UI
- Feedback
- Server State
- Local State
- Table / List
- Accessibility

ユーザー操作を伴うUseCaseでは、Backend APIが完成しただけでSlice完了とはしない。

ユーザーがFrontendから実際にUseCaseを実行できる状態まで実装する。

UIを必要としない内部API等については、この工程を省略できる。

---

## 11. Frontend Test

Frontendの責務に応じて必要なTestを実装する。

主に以下を使い分ける。

- Unit Test
- Component Test
- Integration Test

確認対象の例は以下とする。

- Component表示
- User Interaction
- Form Validation
- Loading
- Error UI
- Authorizationに応じた表示制御
- BFFとの連携

すべてのAPI / UseCaseにE2E Testを作成することは必須としない。

E2E Testは主要なユーザーフローを中心に作成し、Phase 7でも横断的に確認する。

---

## 12. Integration確認

Backend、BFF、Frontendを接続し、対象SliceがEnd-to-Endで動作することを確認する。

```text
Browser
   ↓
Next.js Frontend
   ↓
Next.js BFF
   ↓
Laravel Presentation
   ↓
Application
   ↓
Domain / Query Service
   ↓
Infrastructure
   ↓
PostgreSQL
   ↓
Response
   ↓
Frontend
```

正常系だけでなく、そのAPIで発生し得る主要な異常系も確認する。

例：

- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 409 Conflict
- 422 Unprocessable Entity
- 500 Internal Server Error

すべてのStatus Codeを機械的に確認するのではなく、対象APIで定義されているものを確認する。

特に以下の整合性を確認する。

```text
OpenAPI
   ↕
Backend Response
   ↕
BFF
   ↕
Frontend Error Handling
```

---

## 13. Slice完了確認

対象API / UseCaseについて、該当する以下の項目を確認する。

### API Contract

- [ ] OpenAPIが最新である
- [ ] Redocly Lintが成功する
- [ ] Bundleが成功する
- [ ] TypeScript型生成が成功する
- [ ] Generated Typeを手動変更していない

### Backend

- [ ] OpenAPI契約に従っている
- [ ] 適切なLayerへ責務が配置されている
- [ ] Domain Invariantが保証されている
- [ ] Validationが実装されている
- [ ] Authorizationが実装されている
- [ ] 必要なDatabase Constraintが存在する
- [ ] 必要なTransaction / Lockが実装されている
- [ ] Backend Testが成功する

### BFF

- [ ] Generated Typeを利用している
- [ ] Backend APIをBFF経由で利用している
- [ ] Backend Domain Logicを重複実装していない
- [ ] Authentication / Error Handlingが適切である

### Frontend

- [ ] 対象UseCaseをUIから利用できる
- [ ] Loadingが適切である
- [ ] Validation Errorを扱える
- [ ] Error UIが適切である
- [ ] 必要なFrontend Testが成功する

### Integration

- [ ] 正常系がEnd-to-Endで動作する
- [ ] 主要な異常系が期待通り動作する
- [ ] OpenAPIと実装に重大な乖離がない
- [ ] CIが成功する

対象Sliceに該当しない項目については省略できる。

---

## 14. 仕様変更時の戻り方

実装中にAPI契約や既存設計の変更が必要になった場合、実装コードだけを変更しない。

例えばBackend実装中にRequest情報が不足していることが判明した場合は、以下のように対応する。

```text
問題発見
   ↓
既存設計確認
   ↓
必要なSource of Truth更新
   ↓
OpenAPI更新
   ↓
OpenAPI検証
   ↓
TypeScript型再生成
   ↓
Backend修正
   ↓
BFF修正
   ↓
Frontend修正
   ↓
Test
   ↓
Integration確認
```

変更がDomainやDatabaseにも影響する場合は、それぞれのSource of Truthも更新する。

```text
要件
 ↓
Architecture
 ↓
System Design
 ↓
OpenAPI
 ↓
Implementation
```

すべての変更で上位ドキュメントすべてを更新する必要はない。

実際に影響するSource of Truthのみ更新する。

設計と実装の乖離を放置しない。

---

## 15. 不具合発見時の扱い

実装・Test・Integration確認で不具合を発見した場合は、原因となるレイヤーまで戻って修正する。

```text
UIで問題発見
      ↓
原因確認
      │
      ├── Frontend
      ├── BFF
      ├── API Contract
      ├── Application
      ├── Domain
      └── Database
             ↓
        原因箇所を修正
             ↓
           Test
             ↓
      Integration再確認
```

上位レイヤーで下位レイヤーの問題を回避するためだけのWorkaroundを追加しない。

---

## 16. Git・変更単位

Gitの変更単位は、レビュー・理解・検証可能な小さな単位を基本とする。

`1 API = 1 Commit` のような厳密なルールは設けない。

1つのSliceは例えば以下の変更から構成される。

```text
Employee登録Slice
│
├── OpenAPI
├── Backend
├── Backend Test
├── BFF
├── Frontend
└── Frontend Test
```

変更量が大きい場合は、意味のある単位へCommitを分割する。

例：

```text
feat(employee): define create employee API

feat(employee): implement create employee backend

feat(employee): implement create employee UI
```

小さなSliceであれば1つのCommitへまとめてもよい。

Commit数を増やすこと自体を目的とせず、変更理由と責務を追跡できることを重視する。

未完成の巨大な変更を長期間保持しない。

---

## 17. 実装サイクルまとめ

API / UseCaseの標準的な実装サイクルを以下とする。

```text
┌──────────────────────────────┐
│ 1. API / UseCase選択         │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ 2. 既存設計確認              │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ 3. OpenAPI定義               │
│ 4. Lint / Bundle             │
│ 5. TypeScript型生成          │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ 6. Laravel Backend           │
│ 7. Backend Test              │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ 8. Next.js BFF               │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ 9. Frontend                  │
│ 10. Frontend Test            │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ 11. Integration確認          │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ 12. Slice完了確認            │
└──────────────┬───────────────┘
               ↓
          次のAPI / UseCase
```

実装途中で仕様変更や不具合が発生した場合は、原因となる設計・契約・レイヤーまで戻って修正し、再度サイクルを進める。

最終的な目的は、各技術レイヤーのコードを完成させることではなく、

```text
OpenAPI
   +
Backend
   +
Database
   +
BFF
   +
Frontend
   +
Test
   +
Integration
   ↓
利用可能なVertical Slice
```

を小さく継続的に完成させることである。
