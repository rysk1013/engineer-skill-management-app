# MVP実装計画

Engineer Skill Management App のMVPを、既存の要件・Architecture・System Design・技術選定に従って実装するための計画を管理するディレクトリです。

このディレクトリでは、MVPについて、

- どのような原則で実装するか
- 何をどの順序で実装するか
- 1つのAPI / UseCaseをどのように完成させるか
- 実装中にどのように品質を確認するか
- どの状態をMVP実装完了とするか

を定義します。

要件やAPI仕様そのものを再定義するのではなく、上流で決定した内容を実装へつなぐことを目的とします。

---

## 1. このディレクトリの役割

Engineer Skill Management App のドキュメント全体における位置付けは以下です。

```text id="d28s97"
01_要件定義
「何を作るか」
        ↓
02_アーキテクチャ
「どのような構造で作るか」
        ↓
03_システム設計
「具体的にどのように設計するか」
        ↓
04_技術選定
「何を使って作るか」
        ↓
05_MVP実装計画
「何を、どの順序・単位で実装し、
  どこまでできればMVP完了とするか」
        ↓
06_開発・運用
「開発環境・CI/CD・Staging等を
  どのように運用するか」
        ↓
Staging
        ↓
Production
```

`05_MVP実装計画` は、設計と実装の橋渡しを担当します。

---

## 2. ドキュメント構成

```text id="cp3meb"
05_MVP実装計画/
├── 01_実装方針.md
├── 02_実装フェーズ.md
├── 03_API実装サイクル.md
├── 04_テスト・品質確認.md
├── 05_MVP完了条件.md
└── README.md
```

各ドキュメントの役割は以下です。

| ファイル | 役割 |
|---|---|
| `01_実装方針.md` | MVP実装全体で守る原則を定義する |
| `02_実装フェーズ.md` | Featureの実装順序、依存関係、各Phaseの到達点を定義する |
| `03_API実装サイクル.md` | 1つのAPI / UseCaseをEnd-to-Endで完成させる標準手順を定義する |
| `04_テスト・品質確認.md` | Slice・Feature・MVP全体でのテストと品質確認方法を整理する |
| `05_MVP完了条件.md` | MVP実装完了およびReady for StagingのDefinition of Doneを定義する |

---

## 3. 読む順番

初めてMVP実装へ入る場合は、以下の順番で確認します。

```text id="s7a0kx"
01_実装方針
    ↓
02_実装フェーズ
    ↓
03_API実装サイクル
    ↓
04_テスト・品質確認
    ↓
05_MVP完了条件
```

### 01_実装方針

最初にMVP実装全体の基本原則を確認します。

主な考え方は以下です。

```text id="ybs6xk"
MVP Scope First
       +
Vertical Slice
       +
Incremental OpenAPI First
       +
End-to-End
       +
Small Iteration
```

### 02_実装フェーズ

次に、現在どのFeatureを実装するかを確認します。

基本順序は以下です。

```text id="ohw8zs"
Phase 0: 開発基盤
        ↓
Phase 1: 認証・認可基盤
        ↓
Phase 2: Employee
        ↓
Phase 3: Skill
        ↓
Phase 4: EmployeeSkill
        ↓
Phase 5: Access Control
        ↓
Phase 6: Dashboard
        ↓
Phase 7: MVP統合・E2E
```

これは厳密なWaterfallではなく、主な依存関係を表します。

### 03_API実装サイクル

Feature内で次に実装するAPI / UseCaseを選択し、Vertical Sliceとして完成させます。

### 04_テスト・品質確認

各Sliceの実装中から必要なTestおよび品質確認を実施します。

### 05_MVP完了条件

Phase 7でMVP全体を確認し、Stagingへ進める状態かを最終判定します。

---

## 4. 実装時の使い方

通常の開発では以下の流れで各ドキュメントを利用します。

```text id="55f4kn"
現在のPhaseを確認
        │
        └── 02_実装フェーズ
                ↓
次のAPI / UseCaseを選択
                │
                └── 03_API実装サイクル
                        ↓
OpenAPI
        ↓
Backend
        ↓
BFF
        ↓
Frontend
        ↓
Test
        │
        └── 04_テスト・品質確認
                ↓
Integration確認
        ↓
Vertical Slice完成
        ↓
次のAPI / UseCase
        ↓
Feature完成
        ↓
次のPhase
        ↓
Phase 7
        │
        └── 05_MVP完了条件
                ↓
Ready for Staging
```

実装をBackend、Frontend、Testなどの技術レイヤー単位で長期間分断せず、可能な限り小さなVertical SliceをEnd-to-Endで完成させます。

---

## 5. 基本的な実装フロー

Feature Phaseでは、API / UseCase単位で以下を繰り返します。

```text id="c2buvm"
API / UseCase選択
        ↓
既存設計確認
        ↓
OpenAPI定義
        ↓
Redocly Lint / Bundle
        ↓
openapi-typescript
        ↓
TypeScript型生成
        ↓
Laravel Backend
        ↓
Backend Test
        ↓
Next.js BFF
        ↓
Frontend
        ↓
Frontend Test
        ↓
Integration確認
        ↓
Slice完了
```

OpenAPI仕様をすべて先に完成させてから一括実装する方式にはせず、API / UseCaseごとに小さく繰り返します。

```text id="11y1gj"
API A
OpenAPI → Backend → BFF → Frontend → Test
                              ↓
                           完成

API B
OpenAPI → Backend → BFF → Frontend → Test
                              ↓
                           完成

API C
...
```

これにより、設計上の問題を実装の早い段階で発見し、変更範囲を小さく保ちます。

---

## 6. Source of Truth

`05_MVP実装計画` は、すべての仕様のSource of Truthではありません。

情報の種類ごとに適切なSource of Truthを参照します。

| 情報 | Source of Truth |
|---|---|
| 業務要件・MVP Scope | `01_要件定義` |
| Layer・Dependency・DDD等 | `02_アーキテクチャ` |
| Database設計 | `03_システム設計/01_データベース` |
| Authentication / Authorization設計 | `03_システム設計/02_認証・認可` |
| API設計・API共通仕様 | `03_システム設計/03_API` |
| API契約 | OpenAPI |
| 採用技術・Tool | `04_技術選定` |
| 実装順序・実装サイクル | `05_MVP実装計画` |
| 開発環境・CI/CD・Staging | `06_開発・運用` |
| 品質要求 | `07_非機能要件` |

実装計画と上位Source of Truthが矛盾する場合は、原因を確認し、適切なSource of Truthを更新した上で実装計画へ反映します。

---

## 7. 他ディレクトリとの責務分離

### `01_要件定義`

管理するもの：

- MVP
- Epic
- User Story
- Acceptance Criteria
- 画面一覧・画面遷移
- 業務要件

`05_MVP実装計画` では要件そのものを再定義しません。

---

### `02_アーキテクチャ`

管理するもの：

- Clean Architecture
- DDD
- CQRS
- Layer
- Dependency
- Aggregate
- Repository
- Mapper
- Frontend Architecture

`05_MVP実装計画` ではArchitectureそのものを再設計しません。

---

### `03_システム設計`

管理するもの：

- Database
- Authentication
- Authorization
- API
- Error Response
- OpenAPI運用

`05_MVP実装計画` では、これらをどの順序・単位で実装するかを扱います。

---

### `04_技術選定`

管理するもの：

- Framework
- Library
- Tool
- Database
- Authentication技術
- OpenAPI Tool
- Test Tool
- Code Quality Tool

`05_MVP実装計画` では技術選定を再度行いません。

---

### `06_開発・運用`

管理するもの：

- 開発環境
- CI Platform
- CI/CD
- Staging
- Code Quality運用
- Deployment

`05_MVP実装計画` では、

> いつ必要になるか

を扱い、具体的な構築・運用方法は `06_開発・運用` で管理します。

---

### `07_非機能要件`

管理するもの：

- 可用性・信頼性
- 性能・スケーラビリティ
- Security
- Data Protection
- Logging / Audit
- Observability
- Maintainability
- API Quality
- Deployment / Operation
- Accessibility
- Compatibility
- Internationalization / Date-Time

`05_MVP実装計画` では非機能要件そのものを再定義せず、実装中およびMVP完了時の確認方法を扱います。

---

## 8. 設計変更が発生した場合

実装中に既存設計では対応できない問題を発見した場合、実装コードだけで仕様を補完しません。

```text id="e2x0cb"
問題発見
    ↓
影響範囲確認
    ↓
Source of Truth確認
    ↓
必要な設計変更
    ↓
OpenAPI等を更新
    ↓
実装
    ↓
Test
    ↓
Documentation確認
```

例えばAPI契約を変更する場合は、

```text id="ip8qk6"
API設計確認
    ↓
OpenAPI更新
    ↓
Lint / Bundle
    ↓
TypeScript型再生成
    ↓
Backend
    ↓
BFF
    ↓
Frontend
    ↓
Test
```

とします。

実装だけを変更し、設計ドキュメントやOpenAPIが古い状態になることを避けます。

---

## 9. ドキュメント更新方針

ドキュメントは実装開始前にすべて固定するものではありません。

Vertical Sliceの実装を通じて設計上の問題や不足が判明した場合は、必要に応じて更新します。

ただし、実装都合だけで既存の決定事項を暗黙的に変更しません。

```text id="uy8nh7"
設計
 ↓
実装
 ↓
問題発見
 ↓
設計を再確認
 ↓
必要なら設計更新
 ↓
実装へ反映
```

すべての変更で全ドキュメントを更新する必要はありません。

変更の影響を受けるSource of Truthのみ更新します。

---

## 10. MVP実装中の判断基準

実装中に迷った場合は、以下の優先順位を基本とします。

```text id="ys5cbh"
1. MVP要件を満たす
        ↓
2. Domain Invariantを守る
        ↓
3. 既存Architectureを守る
        ↓
4. OpenAPI契約を守る
        ↓
5. 必要な品質を保証する
        ↓
6. 実装を小さく保つ
```

学習目的としてClean Architecture、DDD、Lightweight CQRS等を実践しますが、MVPに不要な機能追加や将来予測だけに基づく抽象化は避けます。

---

## 11. MVP完了

各Phaseを進め、Phase 7でMVP全体を横断確認します。

最終判定には [`05_MVP完了条件.md`](./05_MVP完了条件.md) を使用します。

```text id="gk0lqn"
MVP Scope
    +
Functional
    +
OpenAPI
    +
Database
    +
Authentication / Authorization
    +
Test / Quality
    +
Non-Functional Requirements
    +
Documentation
    +
CI
    +
Staging Ready
    +
No Blocker
        ↓
MVP Implementation Complete
        ↓
Ready for Staging
```

MVP実装完了はProduction Readyを意味しません。

---

## 12. MVP完了後

MVP実装完了後はStaging工程へ進みます。

```text id="tahkyu"
Requirements / Design
        ↓
MVP Implementation Plan
        ↓
MVP Implementation
        ↓
Ready for Staging
        ↓
Staging Deploy
        ↓
Staging Verification
        ↓
必要な修正
        ↓
Production Readiness
        ↓
Production
```

Stagingで問題が発見された場合は、必要に応じて設計・OpenAPI・実装・Test・Documentationまで戻って修正します。

`05_MVP実装計画` は、MVPの設計を実際に動作するApplicationへ変換し、Stagingへ安全に進むための実装ガイドとして利用します。
