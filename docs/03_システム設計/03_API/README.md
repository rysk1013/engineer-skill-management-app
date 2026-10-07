# API設計

Engineer Skill Management App のNext.js BFFとLaravel Backend API間におけるAPI契約、OpenAPI仕様、変更・検証フローを管理するディレクトリです。

Backend APIの契約はOpenAPIをSource of Truthとします。Laravelは契約の実装者、Next.js BFFは契約の利用者として、双方が同じOpenAPI仕様へ従います。

## 基本方針

- OpenAPI Firstを採用する
- API実装より先にOpenAPIで契約を定義する
- LaravelのController、Eloquent Model、Database SchemaをAPI仕様のSource of Truthにしない
- Next.jsとLaravelでRequest／Response型を重複して手書きしない
- OpenAPIからNext.js向けTypeScript型を生成する
- API Client全体は自動生成せず、Next.js BFFに薄いClientを実装する
- OpenAPI仕様自体をCode ReviewとCIの対象にする
- API変更は原則としてOpenAPIの変更から開始する

## API境界

```text
Browser
   │
   ▼
Next.js Frontend / BFF
   │ OpenAPI Contract
   │ Authorization: Bearer <Sanctum Token>
   ▼
Laravel Backend API
   │
   ▼
PostgreSQL
```

BrowserはLaravel Backend APIを直接呼び出しません。Next.js BFFがBrowser Sessionを確認し、Laravel用Credentialを付与してBackend APIを呼び出します。

## Source of Truth

| 対象 | Source of Truth |
| --- | --- |
| User Story、Acceptance Criteria | [要件定義](../../01_要件定義/README.md) |
| Backend API契約 | OpenAPI |
| Domain Rule | [Laravel DDD設計](../../02_アーキテクチャ/01_Backend/DDD設計/README.md) |
| Database Schema | Laravel Migration |
| Next.jsのRequest／Response型 | OpenAPIから生成したTypeScript型 |

OpenAPIにはEndpoint、HTTP Method、Parameter、Request Body、Response Body、Status Code、Error Response、Security Requirementを定義します。業務ロジックの内部手順までOpenAPIへ記述することは目的としません。

## 設計ドキュメント

### API仕様管理

[API仕様管理](./01_API仕様管理.md)では、OpenAPI First、Source of Truth、Next.jsとLaravelの責務、Breaking Change、Review、Contract確認を定義します。

主な決定事項：

- OpenAPIをLaravelから独立した契約として管理する
- Laravel固有の内部構造をAPIへ公開しない
- Laravel実装だけを先に変更し、OpenAPIを後追いさせない
- OpenAPI変更を通常のCode Review対象とする
- 将来Backend実装が変わっても、可能な限りAPI契約を維持する

### OpenAPI運用方式

[OpenAPI運用方式](./02_OpenAPI運用方式.md)では、仕様のファイル分割、型生成、Generated Code、API変更フローを定義します。

主な決定事項：

- `openapi.yaml`をEntry Pointとする
- OpenAPI仕様を複数ファイルで管理する
- PathsをResource単位で分割する
- Schemaを再利用可能な単位で分割する
- 自動生成されたTypeScript型を直接編集しない
- OpenAPI変更後に再生成する

## OpenAPIファイル構成

ファイル数の増加に対応できるよう、Entry Point、Path、Schemaを分離します。

```text
openapi/
├── openapi.yaml        # Entry Point
├── paths/              # Resource単位のEndpoint
└── schemas/            # 再利用可能なRequest／Response Schema
```

実際の配置とファイル名はApplicationの初期構築時に確定し、Entry Pointからすべての参照を解決できる状態を保ちます。

## API変更フロー

```text
User Story / Acceptance Criteria
              ↓
          API Design
              ↓
         OpenAPI変更
              ↓
          API Review
              ↓
   Lint / Bundle / Validation
              ↓
      TypeScript型を再生成
        ↙                 ↘
 Next.js BFF          Laravel API
        ↘                 ↙
      Feature / Integration Test
              ↓
             E2E
```

OpenAPI変更と実装変更は同じPull Request、または依存関係が明確なPull Requestとして管理し、契約と実装の不一致を残さないようにします。

## Next.js BFFの責務

- OpenAPIから生成したTypeScript型を使用する
- Browser向けInputをBackend API Requestへ変換する
- Better Auth Sessionを確認する
- Sessionに対応するBackend Credentialを取得する
- Laravel用Sanctum Tokenを付与する
- Backend API ResponseをBrowser向けResponseまたは画面Modelへ変換する
- API ClientはOpenAPI型を利用した薄いAdapterとして実装する

Generated Typeは直接編集せず、契約を変更するときはOpenAPIを修正して再生成します。

## Laravel Backend APIの責務

- OpenAPIで定義されたRouting、Request、Response、Status Codeを実装する
- SanctumによるAPI認証を行う
- Laravel PolicyとApplication／Domain Ruleによる認可を行う
- HTTP Input Validationを行う
- Business InvariantをDomainで保証する
- Application ResultをAPI ResourceでOpenAPI Responseへ変換する
- Feature Testで契約どおりのResponseを確認する

OpenAPIに記載されていても、業務上必要な認可、Domain Validation、Database Constraintは省略しません。

## APIへ公開しない内部構造

- Eloquent ModelとRelation
- Database Table、Column、Constraintの構造
- Laravel固有のClass名
- Domain／Application内部のClass構成
- Laravel固有のException
- Stack Trace、SQL、Secretなどの内部情報

API Request／Responseは独立した外部契約として定義し、内部ModelをそのままSerializationしません。

## API表現ルール

| 項目 | 方針 |
| --- | --- |
| API Version | MVPでは`/api/v1`を第一候補とする |
| JSON Property | `camelCase` |
| Query／Path Parameter | `camelCase`を基本とする |
| Database | `snake_case` |
| Timestamp | ISO 8601／RFC 3339のUTC表現 |
| Date | `YYYY-MM-DD` |
| Year Month | `YYYY-MM` |
| Authentication | Sanctum Bearer Token |

CRUD形式だけに限定せず、退職処理など業務上のOperationを明確に表す必要がある場合はDomain Operation Endpointを使用できます。

詳細は[Presentation Layer設計](../../02_アーキテクチャ/01_Backend/Laravel/05_Presentation%20Layer設計.md)を参照してください。

## Error契約

Error ResponseもOpenAPIで定義し、機械判定可能なError Codeを持たせます。Domain Exception自体にはHTTP Statusを持たせず、Presentation LayerでAPI Errorへ変換します。

| 状況 | HTTP Status |
| --- | --- |
| Authentication Error | `401 Unauthorized` |
| Authorization Error | `403 Forbidden` |
| Resourceが存在しない | `404 Not Found` |
| Business Conflict | `409 Conflict` |
| Input Validation Error | `422 Unprocessable Entity` |

Error Messageには、認証情報、内部Exception、SQL、Stack Traceなどの不要な情報を含めません。詳細は[Exception設計](../../02_アーキテクチャ/01_Backend/Laravel/10_Exception設計.md)を参照してください。

## OpenAPI ToolingとCI

| 目的 | Tool／方法 |
| --- | --- |
| Lint | Redocly CLI |
| Bundle、`$ref`検証 | Redocly CLI |
| TypeScript型生成 | openapi-typescript |
| Laravel実装確認 | Laravel Feature Test |
| BFF確認 | Vitest |
| 全体Flow | Playwright |

CIではOpenAPIのLint、Bundle、参照解決、型生成を実行します。生成結果をRepositoryで管理する場合は、再生成後の差分が残っていないことも確認します。

Tool選定の詳細は[API・OpenAPI技術選定](../../04_技術選定/04_API・OpenAPI.md)、CI全体は[CI/CD方針](../../06_開発・運用/03_CICD方針.md)を参照してください。

## Breaking Change

API変更時は、少なくとも次の変更が既存利用者を壊さないか確認します。

- Response Fieldの削除
- Request Fieldの必須化
- Field Typeや意味の変更
- EndpointまたはHTTP Methodの削除・変更
- Status CodeやError Codeの意味の変更
- Authentication／Authorization Requirementの強化

Breaking Changeが必要な場合は、Versioning、移行期間、Next.js BFFの切り替え、既存Endpointの廃止方法をReviewで明確にします。

## OpenAPI Review観点

- User StoryとAcceptance Criteriaを満たしているか
- Resource、Endpoint、HTTP Methodが適切か
- Request／Responseが過不足なく定義されているか
- NamingとDate／Time表現が統一されているか
- Successと主要ErrorのStatus Codeが定義されているか
- AuthenticationとAuthorization Requirementが明記されているか
- Pagination、Filter、Sortの形式が一貫しているか
- Breaking Changeに該当しないか
- Next.js BFFから利用しやすいか
- Laravel、Eloquent、Databaseの内部構造が漏れていないか

## 推奨する読み順

1. [API仕様管理](./01_API仕様管理.md)で、OpenAPI Firstと各Applicationの責務を把握する。
2. [OpenAPI運用方式](./02_OpenAPI運用方式.md)で、ファイル構成と変更フローを確認する。
3. LaravelのPresentation Layer設計とException設計で外部表現を確認する。
4. 認証・認可設計でSecurity Schemeと信頼境界を確認する。
5. API・OpenAPI技術選定とCI/CD方針で自動検証方法を確認する。

## 文書管理ルール

- API変更はOpenAPIから開始します。
- Generated Codeを直接編集しません。
- OpenAPI、Next.js、Laravel、Testの変更を同じ契約単位で追跡します。
- 共通Schemaは再利用可能な単位に保ち、用途の異なる巨大Schemaへ集約しません。
- OpenAPI変更ではBreaking ChangeとSecurityへの影響を必ず確認します。
- 文書とOpenAPIが異なる場合は、Source of TruthであるOpenAPIを確認して差異を解消します。
