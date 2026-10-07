# Next.js Frontendアーキテクチャ

Engineer Skill Management App のNext.js Frontend／BFFに関する、ディレクトリ構成、依存関係、Server／Client境界、データ取得・更新、認証・認可、UI、Testの設計文書を管理するディレクトリです。

Next.jsは画面とBFFを担当し、Business Rule、最終的な認可とValidation、データ整合性はLaravel Backend側で保証します。Frontend Architecture全体の最上位方針は[Frontend Architecture 決定版](./14_Frontend%20Architecture%20決定版.md)、各論の詳細は個別設計書で定義します。

## システム上の位置付け

```text
Browser
   │ Better Auth Session
   ▼
Next.js Frontend / BFF
   │ OpenAPI Generated Client / Sanctum Token
   ▼
Laravel Backend API
   │
   ▼
PostgreSQL
```

- BrowserからLaravel APIを直接呼び出さず、Next.js BFFを経由します。
- Next.jsはUI Rendering、Routing、Layout、Better Auth Session、Frontend向けのデータ変換と処理の調整を担当します。
- Application User AuthenticationはLaravel Backendが担当します。
- LaravelはBusiness Correctness、Authorization、Business Invariantを保証します。
- Sanctum TokenはServer-sideのみで扱い、Browserへ公開しません。
- Next.jsからPostgreSQLへ直接接続しません。
- Laravel APIの契約はOpenAPIをSource of Truthとします。

## 採用Architecture

| 方針 | 目的 |
| --- | --- |
| Server Component First | Server Componentを基本とし、Client側の処理と公開データを必要最小限にする |
| Feature-based Architecture | 機能単位でUI、Server処理、Form、型をまとめる |
| BFF Boundary | Browser SessionとLaravel APIへの接続をNext.js側で管理する |
| OpenAPI Generated Client | API契約に基づくClientと型を生成し、通信処理を共通化する |

FrontendはFeature-oriented、BackendはDomain-orientedとして設計します。Frontendの構成は、BackendのClean Architecture／DDD Layerをそのまま複製せず、画面とFeatureの責務に合わせて定義します。

## ディレクトリと依存関係

| ディレクトリ | 主な責務 |
| --- | --- |
| `src/app/` | Routing、Page、Layout、Framework Boundary、複数FeatureのComposition |
| `src/features/` | Feature固有のUI、Server Query、Server Action、Schema、Mapper、型 |
| `src/components/` | Featureに依存しない共通UIとLayout UI |
| `src/lib/` | API Client、認証などの共通技術基盤 |
| `src/types/` | Application全体で利用するFrontendの型 |
| `src/styles/` | Global Style |

基本的な依存方向は`app → features → shared`です。Sharedには`components/`、`lib/`、`types/`などを含みます。

- Featureから`app/`、SharedからFeatureへの依存を禁止します。
- Feature外からは原則としてPublic APIを利用し、別Featureの内部実装への直接依存を避けます。
- 複数Featureの組み合わせは`app/`で行います。
- Client-safeなPublic APIとServer-onlyなExportを分離します。
- 型の依存にも同じ方向を適用し、循環依存を禁止します。

## ドキュメント構成

| No. | ドキュメント | 主な内容 |
| --- | --- | --- |
| 01 | [Frontend Architecture 全体方針](./01_Frontend%20Architecture%20全体方針.md) | Frontend／BFFの責務、基本原則、Laravelとの境界 |
| 02 | [ディレクトリ構成](./02_ディレクトリ構成.md) | `app`、Feature、共通UI、技術基盤の配置 |
| 03 | [レイヤー・依存関係](./03_レイヤー・依存関係.md) | 依存方向、Feature Public API、Server-only境界 |
| 04 | [Server・Client 境界](./04_Server・Client%20境界.md) | Server／Client Componentの責務と利用条件 |
| 05 | [データ取得・更新](./05_データ取得・更新.md) | Server Query、Server Action、Route Handlerの処理経路 |
| 06 | [API Client・OpenAPI](./06_API%20Client・OpenAPI.md) | API契約、生成Client、手書きAdapter、DTOとMapper |
| 07 | [状態管理](./07_状態管理.md) | Server、URL、Form、Local UI、Contextの使い分け |
| 08 | [認証・認可](./08_認証・認可.md) | Better Auth Session、Backend Credential、Sanctum Token、FrontendとBackendの認可境界 |
| 09 | [フォーム・Validation](./09_フォーム・Validation.md) | Form Model、Schema、入力補助、Server側の再Validation |
| 10 | [エラーハンドリング](./10_エラーハンドリング.md) | Errorの正規化、HTTP Status、Error UI、Error Boundary |
| 11 | [キャッシュ戦略](./11_キャッシュ戦略.md) | Dynamic Data、Cache Scope、更新後のInvalidation |
| 12 | [UI Architecture](./12_UI%20Architecture.md) | Feature／Shared UI、Table、Form、Layout、Accessibility |
| 13 | [テスト戦略](./13_テスト戦略.md) | Static Analysis、Unit、Component、Integration、Contract、E2E |
| 14 | [Frontend Architecture 決定版](./14_Frontend%20Architecture%20決定版.md) | 各設計書の決定事項を統合した最上位方針 |

## データ取得と更新

### Read処理

```text
Server Component
    ↓
Feature Server Query
    ↓
API Client
    ↓
Laravel API
```

- 通常のReadはServer側で行い、Server ComponentからRoute Handlerを経由しません。
- Client Interaction後の追加取得が必要な場合は、Client ComponentからRoute Handlerを利用します。
- Generated Codeと手書きAdapterを分離し、Credential InjectionとAPI Errorの正規化を共通API Clientへ集約します。
- Generated Codeは手動編集せず、API DTOをFrontend側で重複定義しません。

### Mutation処理

```text
UI
 ↓
Server Action
 ↓
Authentication / Authorization
 ↓
Validation / Normalization
 ↓
API Client → Laravel API
 ↓
Revalidation
```

- MutationはServer Actionを第一候補とし、Trust Boundaryとして認証・認可と入力の再Validationを行います。
- Business Ruleと最終的な認可はLaravelで保証します。
- 更新成功後にFeature Actionが影響するCacheを判断し、Invalidationを行います。
- Route HandlerはClient-side Fetch、Callback、Downloadなど、HTTP Endpoint自体が必要な場合に使用します。

## 状態、Validation、Cacheの方針

| 対象 | 方針 |
| --- | --- |
| State | Server → URL → Form → Local → Context → Globalの順で配置を検討する |
| URL State | 検索、Filter、Sort、PaginationをURLで管理する |
| Form／Local UI State | Form Scopeまたは最も近いClient Componentへ閉じ込める |
| Authentication State | Better Auth Sessionを基準とし、独自Storeへ複製しない |
| Validation | Frontendは入力補助、Server Actionは入力の再検証、LaravelはAPI入力とBusiness Invariantの保証を担当する |
| Error | Expected／Unexpected Errorを分離し、HTTP Statusの意味を維持してUIへ反映する |
| Cache | Dynamic／Fresh Dataを基本とし、必要なデータだけOpt-inでCacheする |

UserやPermissionのScopeを無視した共有Cacheを禁止し、CredentialをCacheへ保存しません。Frontendの表示制御と早期拒否はUXのために行い、Session内のCapabilityを最終的な認可の根拠にはしません。

## UIとTestの方針

- UIをApp-level、Feature、Sharedへ分類し、Feature固有UIはFeature内に配置します。
- 共通UIはFeatureの業務概念から独立させ、必要性を確認してから共通化します。
- Loading、Empty、Error、Pendingを設計し、Accessibilityを標準要件として扱います。
- Testは実装詳細より利用者から見える振る舞いを対象とします。
- Unit、Component、Integration、Contract Testで各境界を確認し、E2Eは重要な利用フローを中心に実施します。
- Static AnalysisとProduction Buildで型、依存関係、Server／Client境界を確認します。

## 目的別ナビゲーション

| 目的 | 参照先 |
| --- | --- |
| Frontend全体の決定事項を確認する | [Frontend Architecture 決定版](./14_Frontend%20Architecture%20決定版.md) |
| 機能の配置と依存関係を確認する | [ディレクトリ構成](./02_ディレクトリ構成.md)／[レイヤー・依存関係](./03_レイヤー・依存関係.md) |
| API接続と更新処理を実装する | [データ取得・更新](./05_データ取得・更新.md)／[API Client・OpenAPI](./06_API%20Client・OpenAPI.md) |
| Backendとの責務境界を確認する | [Laravelアーキテクチャ](../../01_Backend/Laravel/README.md) |
| 認証フローの具体設計を確認する | [認証・認可設計](../../../03_システム設計/02_認証・認可/README.md) |
| API契約の運用を確認する | [API設計](../../../03_システム設計/03_API/README.md) |
| Frontend技術の採用理由を確認する | [Frontend技術選定](../../../04_技術選定/Frontend/README.md) |

## 推奨する読み順

1. [Frontend Architecture 決定版](./14_Frontend%20Architecture%20決定版.md)と[全体方針](./01_Frontend%20Architecture%20全体方針.md)で、全体像とLaravelとの責務境界を把握する。
2. ディレクトリ構成、レイヤー・依存関係、Server・Client境界で、配置と実行環境を確認する。
3. データ取得・更新、API Client・OpenAPI、認証・認可で、通信とTrust Boundaryを確認する。
4. 状態管理、フォーム・Validation、エラーハンドリング、キャッシュ戦略で、画面の状態と更新時の振る舞いを確認する。
5. UI Architectureとテスト戦略で、Componentの責務と検証方法を確認する。

## 文書管理ルール

- Architecture全体の決定事項は`14_Frontend Architecture 決定版.md`へ統合し、個別設計書に詳細を記録します。
- 方針を変更した場合は、決定版と個別設計書、Laravel側の設計、認証・API設計、技術選定との整合性を確認します。
- API契約の変更時はOpenAPI、Generated Client、Mapper、Form、Testへの影響を確認します。
- Server／Client境界やCache方針の変更時は、CredentialとUser／Permission Scopeの扱いを確認します。
- 文書と実装が異なる場合は、どちらを正とするか確認し、差異を解消します。
