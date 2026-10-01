# CI/CD 方針

## 1. 目的

本ドキュメントでは、Engineer Skill Management AppにおけるCI/CD全体の基本方針を定義する。

CI/CDでは以下を目的とする。

- Code Qualityを継続的に検証する
- Pull Request時に問題を早期検出する
- `main` Branchを常にBuild / Test可能な状態に保つ
- OpenAPIとApplication Codeの不整合を検出する
- 手作業による品質確認への依存を減らす
- 再現可能なBuild / Testを実現する
- 将来のDeploymentを安全かつ再現可能にする

具体的なCI Platform、Workflow、Job、GitHub Rulesets等の設計は`02_CI-Platform.md`で管理する。

---

## 2. 基本方針

MVPからCIを導入する。

CDについてはDeployment先が未決定のため、具体的な実装方式はDeployment先決定後に設計する。

ただし、将来のCDに向けた基本原則は本ドキュメントで定義する。

基本方針：

```text
Code Change
    ↓
Feature Branch
    ↓
Pull Request
    ↓
必要に応じてCIを手動実行
    ↓
dev
    ↓
Pull Request
    ↓
CI
    ↓
Quality Gate
    ↓
main
    ↓
Build Artifact
    ↓
Staging
    ↓
Verification
    ↓
Production
    ↓
Monitoring
    ↓
必要に応じてRollback
```

Feature Branchから`dev` BranchへのPull RequestではCIを自動実行せず、必要に応じて手動実行する。

`dev` Branchから`main` BranchへのPull RequestではCIを自動実行し、Merge前の主要Quality Gateとする。

MVPではまずCIを確実に構築し、CDは段階的に導入する。

---

## 3. CI Platform

CI PlatformにはGitHub Actionsを採用する。

Git RepositoryはGitHubで管理する。

具体的な以下の設計については`02_CI-Platform.md`を参照する。

- Workflow構成
- Job構成
- Trigger
- Required Status Checks
- GitHub Rulesets
- Permissions
- Action Version管理
- Dependency Cache
- GitHub Secrets
- Cloud OIDC

本ドキュメントではPlatform固有の実装詳細ではなく、CI/CD全体の運用原則を扱う。

---

## 4. CIの目的

CIでは以下の品質確認を自動化する。

- Code Format Check
- Lint
- Static Analysis
- Type Check
- Unit Test
- Feature / Integration Test
- Build Check
- OpenAPI Validation
- OpenAPI Bundle
- Generated Type整合性確認
- Complexity / Maintainability監視
- E2E Test

CIは単にTestを実行する仕組みではなく、Pull Requestを`main`へ統合できる品質であるか確認するためのQuality Gateとして利用する。

---

## 5. CI対象

Monorepoの主要責務ごとにCIを分離する。

```text
CI
├── Frontend
├── Backend
├── OpenAPI
└── E2E
```

対象Directory：

```text
engineer-skill-management-app/
├── frontend/
├── backend/
├── openapi/
├── docs/
└── compose.yaml
```

Frontend / Backend / OpenAPI / E2Eは、それぞれ独立した品質確認責務を持つ。

---

## 6. Frontend CI方針

Frontend / BFFでは以下の品質をCIで確認する。

- Format
- Lint
- Complexity
- Type Safety
- Unit Test
- Component / Application Test
- Next.js Build

概念：

```text
Frontend Source
      ↓
Format / Lint
      ↓
Type Check
      ↓
Test
      ↓
Build
```

OpenAPIから生成されたTypeを利用したFrontend Codeの型整合性はFrontend CIで確認する。

OpenAPIとGenerated Typeそのものの同期確認はOpenAPI CIの責務とする。

具体的なTool・Command・Workflowは`02_CI-Platform.md`およびFrontend技術選定を参照する。

---

## 7. Backend CI方針

Laravel Backendでは以下の品質をCIで確認する。

- Format
- Static Analysis
- Complexity / Maintainability
- Unit Test
- Feature Test
- Integration Test
- Database Constraint
- Migration

概念：

```text
Backend Source
      ↓
Format
      ↓
Static Analysis
      ↓
Test
      ↓
Database / Migration Validation
```

Backend CIではProduction / Local Development Databaseを利用せず、CI専用のTest Databaseを利用する。

具体的なTool・Command・Workflowは`02_CI-Platform.md`およびBackend技術選定を参照する。

---

## 8. OpenAPI CI方針

OpenAPI SpecificationをBackend API契約のSource of Truthとする。

OpenAPI CIでは以下を保証する。

- OpenAPI Specificationが有効である
- Lint Ruleを満たしている
- Bundle可能である
- Type生成可能である
- Generated Typeが最新OpenAPIと同期している

概念：

```text
OpenAPI
   ↓
Validation / Lint
   ↓
Bundle
   ↓
Type Generation
   ↓
Generated Type差分確認
   ↓
Frontend
```

OpenAPI変更後にGenerated Typeの更新漏れがある場合はCIで検出する。

Generated Typeの同期確認はOpenAPI CIへ集約し、Frontend CIでは生成済みTypeを利用したApplication Codeの型整合性を確認する。

---

## 9. E2E方針

E2E TestにはPlaywrightを利用する。

MVPでは画面単位で大量のE2E Testを作成せず、主要業務シナリオを中心にTestする。

概念：

```text
User
 ↓
Browser
 ↓
Next.js
 ↓
Laravel
 ↓
PostgreSQL
```

E2EではFrontend / BFF / Backend / Databaseを含めたSystem全体の主要フローを確認する。

MVPでは以下を基本とする。

### Pull Request

`main` Branchを対象とするPull RequestでE2Eを実行する。

Feature Branchから`dev` BranchへのPull RequestではE2Eを自動実行しない。

### main BranchへのPush

`main` BranchへのPushでE2Eを実行する。

### Required Status Check

MVP初期では必須化を前提としない。

実行時間・安定性・Flaky Testの発生状況を確認した後でRequired化を判断する。

E2E Test数は必要最小限とし、詳細なBusiness Logicの検証はUnit / Feature / Integration Testへ寄せる。

---

## 10. Trigger方針

CIは以下を基本Triggerとする。

### Manual

Feature Branchから`dev` BranchへのPull RequestではCIを自動実行しない。

必要に応じてCIを手動実行し、`dev`へMergeする前の品質確認に利用する。

```text
Feature Branch
      ↓
Pull Request
      ↓
必要に応じてCIを手動実行
      ↓
     dev
```

MVP初期ではCI Costを考慮し、Feature Branchごとの自動CI実行は必須としない。

具体的な手動実行方法は`02_CI-Platform.md`で定義する。

### Pull Request

`main` Branchを対象とするPull RequestでCIを自動実行する。

```text
dev
 ↓
Pull Request
 ↓
main
 ↓
CI
```

`main`へのMerge前に実行するCIを主要Quality Gateとする。

### main BranchへのPush

```text
Merge
  ↓
main
  ↓
CI
```

Merge後も`main`が正常な状態であることを確認する。

### Tag / Release

MVPではCI Triggerとして必須としない。

Release / CD設計時に必要なWorkflowを別途設計する。

---

## 11. Quality Gate

CI Checkは大きく以下の2種類へ分類する。

```text
CI Check
├── Blocking Check
└── Monitoring Check
```

### Blocking Check

問題が検出された場合、原則としてCI Failureとする。

代表例：

#### Frontend

- Format違反
- Lint Error
- Type Error
- Unit / Application Test Failure
- Build Failure

#### Backend

- Format違反
- Static Analysis Error
- Unit Test Failure
- Feature / Integration Test Failure
- Migration Failure
- Database Constraint Test Failure

#### OpenAPI

- OpenAPI Validation Error
- Lint Error
- Bundle Failure
- Type Generation Failure
- Generated Type更新漏れ

Blocking Checkに失敗しているPull Requestは原則Mergeしない。

---

## 12. Monitoring Check

MVP初期では以下をMonitoring中心で利用する。

- Complexity
- Maintainability
- Frontend / BFFのESLint `complexity`
- Backend APIのCleanCode + PHP_CodeSnifferによるComplexity / Maintainability Metric

Frontend / BFFではESLint `complexity` Ruleを利用する。

Backend APIではCleanCode Standard全体を適用せず、Project Ruleset `backend/phpcs.xml`で選択したCleanCode SniffをPHP_CodeSnifferから実行する。

Monitoring CheckはCode ReviewやRefactoring判断の材料として利用する。

Threshold超過のみを理由として初期段階から必ずCI Failureにはしない。

また、Monitoring CommandがNon-zero Exit Codeを返すことと、ProjectとしてMergeをBlockingすることを同一視しない。

```text
Metric
  ↓
CIで可視化
  ↓
Code Review
  ↓
必要に応じてRefactoring
```

具体的なGitHub Actions上のNon-blocking実装方法はCI Workflow構築時に決定する。

Codebaseの傾向や実績データを確認した後、必要に応じてProject固有ThresholdやBlocking Checkへの移行を検討する。

---

## 13. PostgreSQL Test Environment

Backend CIおよび必要なE2E TestではTest専用PostgreSQLを利用する。

```text
CI
 ↓
PostgreSQL Test Instance
 ↓
Migration
 ↓
Test
```

Production DatabaseおよびLocal Development Databaseは利用しない。

CI実行ごとに独立したTest Environmentを利用する。

Test Databaseでは以下を確認する。

- Migration
- Foreign Key
- Unique Constraint
- Check Constraint
- Repository / Infrastructure
- Transaction
- Feature / Integration Test

Test Dataは再現可能な形で生成する。

---

## 14. Monorepo方針

CIはMonorepoを前提とする。

```text
Repository
├── frontend
├── backend
├── openapi
└── docs
```

各領域の品質確認責務を分離する。

```text
frontend
    ↓
Frontend CI

backend
    ↓
Backend CI

openapi
    ↓
OpenAPI CI

System
    ↓
E2E CI
```

依存関係のないCIは可能な限り並列実行する。

---

## 15. Pathによる実行制御

将来的には変更されたDirectoryに応じてCIの実行を最適化できる。

例：

```text
frontend/**
    ↓
Frontend CI
```

```text
backend/**
    ↓
Backend CI
```

```text
openapi/**
    ↓
OpenAPI CI
    +
Frontend CI
```

ただしMVP初期ではPath Filterによる最適化を優先しない。

基本方針：

```text
Correctness
    ↓
Stability
    ↓
Measurement
    ↓
Optimization
```

まず重要なCIが確実に実行される状態を構築する。

Path Filterの具体的な設計は`02_CI-Platform.md`で管理する。

---

## 16. DockerとCI

Local DevelopmentではDocker Composeを利用する。

CIでLocal Development用Docker Composeをそのまま利用することは必須としない。

CIでは必要に応じて以下を直接構築してよい。

- Node.js Environment
- PHP Environment
- PostgreSQL Service
- Browser / Playwright Environment

重要なのはDocker Composeそのものを共有することではなく、Local / CI間で以下の差異を可能な限り小さくすることである。

- Runtime Version
- Dependency Version
- Database Version
- Build条件
- Test条件

```text
Local
  ↓
同等Runtime / Dependency
  ↑
CI
```

---

## 17. DependencyとCache

DependencyはLock Fileに基づいて再現可能な形でInstallする。

```text
frontend
→ pnpm-lock.yaml

openapi
→ pnpm-lock.yaml

backend
→ composer.lock
```

CacheはCI高速化のために利用できるが、Dependency VersionのSource of Truthにはしない。

```text
Lock File
   ↓
Dependency Version

Cache
   ↓
Download Optimization
```

MVP初期では正確性・再現性を優先し、Cacheの過度な最適化は行わない。

---

## 18. main Branch

`main` Branchは常に以下の状態を維持することを目標とする。

```text
Build可能
    +
Test成功
    +
Deploy可能
```

通常の開発作業はFeature Branchで行い、`dev` Branchへ統合する。

`main` Branchへの統合は`dev` BranchからPull Requestを作成して行う。

基本フロー：

```text
Feature Branch
      ↓
Pull Request
      ↓
dev
      ↓
Pull Request
      ↓
CI
      ↓
Code Review
      ↓
Merge
      ↓
main
```

Feature Branchから`dev` BranchへのPull RequestではCIを自動実行せず、必要に応じて手動実行する。

`dev` Branchから`main` BranchへのPull RequestではCIを自動実行する。

Required Status Checksに失敗している変更は原則Mergeしない。

Branch保護の具体的な設定は`02_CI-Platform.md`で管理する。

---

## 19. CD基本原則

具体的なCD PipelineはDeployment先決定後に設計する。

ただし、以下をCDの基本原則とする。

```text
Source Code
    ↓
CI
    ↓
Build
    ↓
Immutable Artifact
    ↓
Staging
    ↓
Verification
    ↓
Production
    ↓
Monitoring
```

Build済みArtifactをEnvironmentごとに作り直すことを基本としない。

Stagingで検証したものと同一ArtifactをProductionへDeployすることを基本とする。

Containerを利用する場合の概念：

```text
Commit
  ↓
Container Image Build
  ↓
Image: Commit SHA
  ↓
Staging
  ↓
Verification
  ↓
同一Image
  ↓
Production
```

これによりStagingとProductionで異なるBuild成果物が利用されることを防ぐ。

---

## 20. Artifact方針

Deploymentに利用するArtifactはImmutableであることを基本とする。

Artifactの候補：

- Container Image
- Application Build Artifact
- その他Deployment Platform固有Artifact

ArtifactはSource Commitを追跡できるようにする。

概念：

```text
Git Commit
    ↓
Artifact
    ↓
Version / SHA
```

ProductionでどのSource Codeが稼働しているか追跡できる状態を維持する。

---

## 21. Staging

CD導入時はProduction Deployment前にStaging Environmentで検証することを基本とする。

```text
Artifact
   ↓
Staging
   ↓
Verification
   ↓
Production
```

Stagingでは必要に応じて以下を確認する。

- Application起動
- Migration
- API疎通
- Authentication
- Authorization
- 主要業務フロー
- Environment Configuration
- External Service連携

具体的なVerification方法はDeployment Architecture決定後に設計する。

---

## 22. Production Deployment

Production DeploymentはCI成功済みのArtifactを利用する。

Production上でSource Codeから直接Buildすることを基本としない。

```text
CI
 ↓
Verified Artifact
 ↓
Production
```

Deployment方式についてはDeployment先決定後に設計する。

以下を検討対象とする。

- Automatic Deployment
- Manual Approval
- Deployment Window
- Migration Strategy
- Zero / Low Downtime Deployment
- Health Check
- Rollback

---

## 23. MonitoringとRollback

Production Deployment後はApplicationの状態を確認できる構成とする。

Deployment後に重大な問題が発生した場合はRollback可能な構成を目標とする。

概念：

```text
Production Deployment
        ↓
Monitoring
        ↓
     Problem?
      /    \
    No      Yes
    ↓        ↓
 Continue  Rollback
```

Rollbackでは可能な限り以前の正常なArtifactへ戻せる構成とする。

具体的なRollback方式はDeployment Platform・Database Migration Strategyと合わせて設計する。

Database Migrationについては単純なApplication Artifact Rollbackだけでは復旧できない場合があるため、別途Deployment設計で考慮する。

---

## 24. Deployment Environment

Deployment先は現時点では確定しない。

Deployment先決定後に以下を具体化する。

- Build
- Artifact / Container Image管理
- Registry
- Staging Environment
- Production Environment
- Deployment Pipeline
- Database Migration
- Health Check
- Monitoring
- Rollback
- Secret管理
- Cloud認証
- Scaling

特定Cloud Providerへ依存する設計はDeployment先決定後に行う。

---

## 25. Secrets・Credential

CI/CDで利用する秘密情報をRepositoryへ保存しない。

基本原則：

```text
Secrets
├── RepositoryへCommitしない
├── Environmentごとに分離する
├── Least Privilege
├── Production SecretをTestで利用しない
├── Logへ出力しない
└── 長期Credentialより短期Credentialを優先
```

対象例：

- Database Password
- Laravel `APP_KEY`
- Auth.js Secret
- API Credential
- Deployment Credential
- Cloud Credential
- その他Secret

EnvironmentごとにCredentialを分離する。

```text
Development
Staging
Production
```

Cloud Providerとの認証では可能な限りOIDC等による短期間Credentialを利用する。

Platform固有のSecret管理・Permission設計は`02_CI-Platform.md`およびDeployment設計で管理する。

---

## 26. MVPで行わないこと

MVP初期では以下を過度に作り込まない。

- 複雑なCI Pipeline
- 過度なPath Filter
- 過度なCache Optimization
- 大量のE2E Test
- Complexityによる厳格なQuality Gate
- Production Deployment Automation
- Multi-Cloud対応
- Blue / Green Deployment等の高度なDeployment Strategy
- Canary Release
- 複雑なArtifact Promotion System

MVPではまず、

```text
Pull Request
    ↓
Reliable CI
    ↓
Quality Gate
    ↓
Safe Merge
```

を確立することを優先する。

---

## 27. 導入順序

CI/CDは段階的に導入する。

### Phase 1：MVP CI

```text
Frontend CI
Backend CI
OpenAPI CI
E2E CI
```

まず`main` Branchを対象とするPull Requestの品質確認を自動化する。

Feature Branchから`dev` BranchへのPull Requestでは、必要に応じてCIを手動実行する。

### Phase 2：Staging CD

Deployment先決定後、

```text
main
 ↓
Build Artifact
 ↓
Staging
```

を自動化する。

### Phase 3：Production CD

Staging運用が安定した後、

```text
Verified Artifact
      ↓
Production
      ↓
Monitoring
```

を設計する。

Production Deploymentの自動化レベルは運用要件に応じて決定する。

---

## 28. 決定事項

### CI

MVPから導入する。

### CI Platform

GitHub Actionsを採用する。

具体的なPlatform設計は`02_CI-Platform.md`で管理する。

### CI対象

以下を主要CI単位とする。

```text
Frontend
Backend
OpenAPI
E2E
```

### Quality Gate

CI Checkを以下へ分類する。

```text
Blocking Check
Monitoring Check
```

Format / Lint / Static Analysis / Type / Test / Build / OpenAPI Contract等は原則Blockingとする。

Complexity / MaintainabilityはMVP初期ではMonitoring中心とする。

Frontend / BFFではESLint `complexity` Ruleを利用する。

Backend APIではCleanCode + PHP_CodeSnifferを利用し、Project Ruleset `backend/phpcs.xml`で必要なCleanCode Sniffを選択する。

Monitoring CommandのNon-zero Exit CodeとProjectとしてのMerge Blocking Policyは分離して扱う。

具体的なGitHub Actions上のNon-blocking実装方法はCI Workflow構築時に決定する。

### OpenAPI

OpenAPI SpecificationをBackend API契約のSource of Truthとする。

Generated Typeの同期確認はOpenAPI CIの責務とする。

### E2E

Playwrightを利用する。

MVPでは主要業務フローに限定する。

`main` Branchを対象とするPull Requestおよび`main` BranchへのPushで実行し、Required化は安定性・実行時間を確認した後に判断する。

### Database

CIではTest専用PostgreSQLを利用する。

Production / Local Development Databaseは利用しない。

### Pull Request

Feature Branchから`dev` BranchへのPull RequestではCIを自動実行せず、必要に応じて手動実行する。

`dev` Branchから`main` BranchへのPull RequestではCIを自動実行し、Merge前の主要Quality Gateとする。

Required Status Checksに設定されたCIの成功を`main`へのMerge条件とする。

### main

常にBuild / Test / Deploy可能な状態を維持することを目標とする。

### Monorepo

Frontend / Backend / OpenAPI / E2Eの品質確認責務を分離する。

### Optimization

MVP初期ではCorrectnessとStabilityを優先し、Path FilterやCache等の最適化は後から行う。

### CD

Deployment先決定後に具体的なPipelineを設計する。

### Artifact

Deployment ArtifactはImmutableとすることを基本とする。

Stagingで検証したArtifactと同一のArtifactをProductionへDeployする。

### Staging

Production Deployment前にStagingで検証することを基本とする。

### Production

CI成功済み・Staging検証済みのArtifactを利用する。

### Rollback

Production Deployment後に問題が発生した場合、以前の正常なArtifactへRollbackできる構成を目標とする。

### Security

- SecretをRepositoryへCommitしない
- EnvironmentごとにCredentialを分離する
- Least Privilegeを適用する
- Production SecretをTestで利用しない
- 長期間Credentialより短期間Credentialを優先する

### 基本方針

- CIをMVPから導入する
- `main` Branchを対象とするPull Requestを主要Quality Gateとする
- Blocking CheckとMonitoring Checkを分離する
- CIの正確性と再現性を優先する
- OpenAPIとGenerated Typeの同期をCIで保証する
- `main`を常に健全な状態に保つ
- CIとCDの責務を分離する
- Build Once / Deploy Same Artifactを基本とする
- Stagingで検証してからProductionへDeployする
- Production Deployment後のMonitoring / Rollbackを考慮する
- MVPでは必要以上にCI/CDを複雑化しない
