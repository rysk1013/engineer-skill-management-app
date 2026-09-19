# 開発・運用

Engineer Skill Management Appの開発環境、CI/CD、ステージング環境、コード品質、タスク管理、Git / GitHub運用に関する方針を管理するディレクトリです。

このディレクトリでは、採用した技術を開発者がどのように実行・検証・管理・デプロイするかを定義します。

技術そのものの選定理由は[`04_技術選定`](../04_技術選定/README.md)、システムの具体設計は[`03_システム設計`](../03_システム設計/README.md)を参照してください。

---

## 開発・運用方針

以下を基本方針とします。

- 開発環境はDocker Composeで統一します。
- Next.js、Laravel、PostgreSQLはそれぞれContainer上で実行します。
- RepositoryはGitHubで管理します。
- CIにはGitHub Actionsを使用します。
- `main`を安定Branch、`dev`を開発統合Branchとします。
- 通常のWork Branchは`dev`から作成します。
- `main` / `dev`への直接Commit・Pushは通常運用では行いません。
- Pull Requestを経由して変更を統合します。
- 開発TaskはBacklog.mdで管理します。
- 原則として1 Taskに対して1 Work Branch、1 Pull Requestを対応させます。
- MVPではCIを導入し、CDはデプロイ先の決定後に具体化します。
- ステージング環境はAWS ECS / Fargate / RDS for PostgreSQLを第一候補として継続検討します。
- コードの複雑度は品質目標ではなく、責務の集中やリファクタリング時期を判断する指標として扱います。

Task管理・開発フローの詳細は[`06_タスク管理・開発フロー.md`](./06_タスク管理・開発フロー.md)、Git / GitHub運用の詳細は[`07_Git・GitHub運用.md`](./07_Git・GitHub運用.md)を参照してください。

---

## 全体フロー

開発は以下の流れを基本とします。

```text
docs / MVP Implementation Plan
              ↓
         Backlog.md
              ↓
        Work Branch
              ↓
        Implementation
              ↓
         Local Check
              ↓
        Pull Request
              ↓
        GitHub Actions
       ┌──────┼──────┐
       ▼      ▼      ▼
  Frontend  Backend  OpenAPI
      CI       CI       CI
       └──────┼──────┘
              ▼
        Self Review
              ↓
             dev
              ↓
       Integration Check
              ↓
        Pull Request
              ↓
             main
              ↓
     CD（導入決定後）
```

Task単位の詳細な実装フローについては[`06_タスク管理・開発フロー.md`](./06_タスク管理・開発フロー.md)をSource of Truthとします。

Branch、Commit、Pull Request、Mergeなどの詳細については[`07_Git・GitHub運用.md`](./07_Git・GitHub運用.md)をSource of Truthとします。

---

## ドキュメント構成

| ドキュメント | 内容 | 現在の方針 |
|---|---|---|
| [開発環境](./01_開発環境.md) | Container、Volume、Network、起動・Command実行方法 | Docker Compose |
| [CI Platform](./02_CI-Platform.md) | Repository、Workflow、Trigger、Branch保護、権限 | GitHub / GitHub Actions |
| [CI/CD方針](./03_CICD方針.md) | CI Job、実行条件、Failure、Cache、CD | MVPではCIを導入、CDは後続決定 |
| [ステージング環境](./04_ステージング環境.md) | Hosting候補、Network、Cloud認証、今後の決定事項 | AWS ECS構成を第一候補として継続検討 |
| [コード品質・複雑度監視](./05_コード品質・複雑度監視.md) | Complexityの計測、Threshold、CIでの扱い | ESLint `complexity` / PHPMD |
| [タスク管理・開発フロー](./06_タスク管理・開発フロー.md) | Backlog.md、Task、Implementation Plan、Definition of Done、Phase運用 | Backlog.mdをSource of TruthとしてTaskを管理 |
| [Git・GitHub運用](./07_Git・GitHub運用.md) | Branch、Commit、Pull Request、Merge、GitHub Repository設定 | `main` / `dev` + Pull Request中心の運用 |

---

## ローカル開発環境

[開発環境](./01_開発環境.md)では、HostへNode.js、PHP、PostgreSQLを直接導入せず、Containerを中心として開発する方針を定義します。

主なContainerは以下です。

| Container | 主な構成 |
|---|---|
| `frontend` | Node.js、Next.js、TypeScript、Auth.js |
| `backend` | PHP、Composer、Laravel、Sanctum |
| `postgres` | PostgreSQL |

Source CodeはHostとContainerで共有し、FrontendとBackendの開発時にはHot Reloadを利用します。

具体的な起動手順やCommandはApplicationのセットアップ後に[開発環境](./01_開発環境.md)へ反映します。

---

## タスク管理・開発フロー

開発TaskはBacklog.mdで管理します。

基本的な管理単位は以下とします。

```text
MVP
└── Phase / Milestone
    └── Task
```

Taskは1つの目的を持ち、Acceptance Criteriaによって単独で完了判定できる単位とします。

Task単位では以下の流れを基本とします。

```text
Task
  ↓
Investigation
  ↓
Implementation Plan
  ↓
Plan Review
  ↓
Implementation
  ↓
Test / Quality Check
  ↓
Acceptance Criteria
  ↓
Definition of Done
  ↓
Final Summary
  ↓
Done
```

Task管理の詳細は[`06_タスク管理・開発フロー.md`](./06_タスク管理・開発フロー.md)を参照してください。

---

## Git / GitHub

GitHub上では`main`と`dev`をLong-lived Branchとして使用します。

基本的なBranch構成は以下とします。

```text
main
 │
 └── dev
      ├── feature/*
      ├── fix/*
      ├── refactor/*
      ├── docs/*
      ├── test/*
      └── chore/*
```

通常のWork Branchは`dev`から作成し、Pull Requestを経由して`dev`へ統合します。

一定の機能群を`dev`で確認した後、Pull Requestを経由して`main`へ反映します。

Taskとの対応関係は原則として以下とします。

```text
Backlog.md Task
      ↓
Work Branch
      ↓
Commit
      ↓
Pull Request
      ↓
dev
```

Branch Strategy、Commit Message、Pull Request、Merge Strategy、GitHub Rulesetsなどの詳細は[`07_Git・GitHub運用.md`](./07_Git・GitHub運用.md)を参照してください。

---

## CI

GitHub Actionsでは変更領域に応じてJobを分割し、可能な処理は並列実行します。

### Frontend / BFF

- Format Check
- ESLint
- TypeScript Type Check
- Complexity Check
- Vitest
- React Testing Library
- Build

### Backend API

- Laravel Pint
- PHPStan / Larastan
- PHPMD
- PHPUnit
- Laravel Feature Test
- PostgreSQL Integration Test

### OpenAPI

- Redocly Lint
- Bundleと`$ref`の検証
- TypeScript型生成
- 生成差分の確認

CIで使用する具体的なToolはテストツール（[Frontend](../04_技術選定/Frontend/12_テスト.md) / [Backend](../04_技術選定/Backend/12_Test.md)）、コード品質ツール（[Frontend](../04_技術選定/Frontend/13_コード品質・Developer-Experience.md) / [Backend](../04_技術選定/Backend/13_Static-Analysis・Code-Quality.md)）、[API・OpenAPI](../04_技術選定/04_API・OpenAPI.md)を参照してください。

CIのTrigger、Job構成、Failure時の扱い、Cacheなどの詳細は[`03_CICD方針.md`](./03_CICD方針.md)を参照してください。

---

## CDとステージング環境

MVP時点では本番・ステージングのデプロイ先を確定せず、CDの実装は後続の判断とします。

現時点では以下を第一候補として継続検討します。

```text
GitHub Actions
      ↓
  Amazon ECR
      ↓
AWS ECS / Fargate
      ↓
RDS for PostgreSQL
```

採用を確定する前に、以下を検討・決定します。

- 費用
- Network
- Domain
- TLS
- Secret管理
- Migration実行方法
- Monitoring
- Backup
- Rollback方法

具体的な検討状況については[`04_ステージング環境.md`](./04_ステージング環境.md)をSource of Truthとします。

CDの方針については[`03_CICD方針.md`](./03_CICD方針.md)を参照してください。

---

## コード品質と複雑度

コード品質・複雑度については以下を基本方針とします。

- Frontend / BFFではESLintの`complexity` Ruleを使用します。
- Backend APIではPHPMDを使用します。
- 複雑度の増加は、Component、Use Case、Aggregate、Handler、Policyなどへの責務集中を見直すSignalとして扱います。
- MVP初期では複雑度超過だけを理由にCIを失敗させず、計測と警告を中心に運用します。
- 数値を下げることだけを目的とした過度な分割や不要なLayer追加は行いません。

詳細は[`05_コード品質・複雑度監視.md`](./05_コード品質・複雑度監視.md)を参照してください。

---

## Source of Truth

開発・運用に関連する情報は、責務ごとにSource of Truthを分離します。

| 情報 | Source of Truth |
|---|---|
| 開発環境 | `01_開発環境.md` |
| CI Platform | `02_CI-Platform.md` |
| CI / CD | `03_CICD方針.md` |
| ステージング環境 | `04_ステージング環境.md` |
| コード品質・複雑度 | `05_コード品質・複雑度監視.md` |
| Task管理・開発フロー | `06_タスク管理・開発フロー.md` |
| Git / GitHub運用 | `07_Git・GitHub運用.md` |
| Backlog.md設定 | `backlog/config.yml` |
| API Contract | OpenAPI |
| 実装Task・進捗 | Backlog.md |
| 実装結果 | Source Code |

READMEは各方針の概要とNavigationを提供し、詳細な仕様は各Source of Truthへ委譲します。

---

## 推奨する読み順

初めて開発へ参加する場合は、以下の順番で確認します。

1. [開発環境](./01_開発環境.md)でローカル開発環境の基本構成を確認する。
2. [タスク管理・開発フロー](./06_タスク管理・開発フロー.md)でTaskの進め方を確認する。
3. [Git・GitHub運用](./07_Git・GitHub運用.md)でBranch、Commit、Pull Requestのルールを確認する。
4. [CI Platform](./02_CI-Platform.md)でGitHubとGitHub Actionsの基本構成を確認する。
5. [CI/CD方針](./03_CICD方針.md)で自動検証の対象とFailure時の扱いを確認する。
6. [コード品質・複雑度監視](./05_コード品質・複雑度監視.md)で品質指標の運用方法を確認する。
7. デプロイを検討するときに[ステージング環境](./04_ステージング環境.md)を参照する。

---

## 文書管理ルール

- READMEには各方針の概要を記載し、詳細な仕様は個別文書をSource of Truthとします。
- 開発CommandやCI Jobを変更した場合は、ローカル環境とCIの差異が生じないか確認します。
- CIへToolを追加・削除した場合は、関連する技術選定文書も更新します。
- Task管理や開発フローを変更した場合は`06_タスク管理・開発フロー.md`を更新します。
- Branch、Commit、Pull Request、Mergeなどの運用を変更した場合は`07_Git・GitHub運用.md`を更新します。
- デプロイ先が確定したら、ステージング環境とCI/CD方針の未決定事項を更新します。
- SecretやCloud認証情報の値は文書やRepositoryへ記載せず、管理方法と必要な変数名のみを記録します。
- 運用上の判断を変更した場合は、必要に応じて理由と影響範囲を関連文書へ反映します。
