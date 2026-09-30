# CI Platform 技術決定

## 1. 採用Platform

Git RepositoryはGitHubで管理する。

CI PlatformにはGitHub Actionsを採用する。

- [x] GitHub
- [x] GitHub Actions
- [ ] GitLab CI
- [ ] その他

CI設定はApplication Codeと同様にRepository内でVersion管理する。

---

## 2. 採用理由

GitHub Actionsを採用する主な理由：

- GitHub Repositoryと直接統合できる
- Pull RequestをTriggerとしてCIを実行できる
- main BranchへのPushでもCIを実行できる
- Required Status Checkとして利用できる
- GitHub Rulesetsと統合できる
- Monorepoに対応できる
- WorkflowをRepository内でVersion管理できる
- Node.js / PHP / PostgreSQLを利用したCIを構築できる
- OpenAPIのLint / Bundle / Type生成を自動化できる
- PlaywrightによるE2E Testを実行できる
- 将来的なCDにも利用できる
- Cloud ProviderとのOIDC認証を利用できる

---

## 3. 基本開発フロー

基本的な開発フローは以下とする。

```text
Issue / User Story
        ↓
Feature Branch
        ↓
   Pull Request
        ↓
  GitHub Actions
        │
        ├── Frontend CI
        ├── Backend CI
        ├── OpenAPI CI
        └── E2E CI
        ↓
   Code Review
        ↓
      Merge
```

Frontend / Backend / OpenAPI / E2Eは、それぞれ責務の異なるCIとして扱う。

Frontend / Backend / OpenAPIは原則として並列実行可能とする。

E2Eについても他Workflowとの複雑な依存関係を作ることを前提とせず、必要なApplication Environmentを構築して自己完結して実行できる構成を基本とする。

Required Status Checkに設定されたCIが失敗している場合はMergeできない構成とする。

---

## 4. Workflow構成

Monorepoの責務に合わせてWorkflowを分割する。

基本構成：

```text
.github/
└── workflows/
    ├── frontend-ci.yml
    ├── backend-ci.yml
    ├── openapi-ci.yml
    └── e2e-ci.yml
```

1つの巨大なWorkflowへすべての処理をまとめない。

各Workflowの責務を明確にし、変更・障害・実行時間を独立して把握できる構成とする。

---

## 5. Frontend CI

対象：

```text
frontend/
```

主な実行内容：

### Blocking Check

1. Dependency Install
2. Prettier Check
3. ESLint
4. TypeScript Type Check
5. Vitest
6. Next.js Build

### Monitoring Check

1. ESLint `complexity`

概念：

```text
Dependency Install
       ↓
Prettier Check
       ↓
ESLint
       ↓
TypeScript Type Check
       ↓
Vitest
       ↓
Next.js Build

ESLint complexity
       ↓
Complexity
       ↓
Monitoring
```

通常のESLint RuleはBlocking Checkとして扱う。

ESLint `complexity` RuleはMonitoring Checkとして扱い、Complexity Threshold超過のみを理由としてMergeをBlockingしない。

DependencyはLock Fileに基づいて再現可能な形でInstallする。

Projectではpnpmを利用するため、CIでもLock Fileを固定してDependencyをInstallする。

具体的なCommandはCI Workflow構築時にProject Commandへ合わせて決定する。

---

## 6. Backend CI

対象：

```text
backend/
```

主な実行内容：

### Blocking Check

1. Composer Dependency Install
2. Laravel Pint Check
3. PHPStan / Larastan
4. PostgreSQL Test Database起動
5. Migration
6. Pest / Laravel Test

### Monitoring Check

1. CleanCode + PHP_CodeSniffer Complexity / Maintainability Check

概念：

```text
Composer Install
       ↓
Pint Check
       ↓
PHPStan / Larastan
       ↓
Migration
       ↓
Pest / Laravel Test

CleanCode + PHP_CodeSniffer
       ↓
Complexity / Maintainability
       ↓
Monitoring
```

Blocking CheckとComplexity Monitoringを分離する。

BackendのBlockingなCode Quality CheckはProject Commandとして、

```bash
composer quality
```

を利用する。

Complexity / Maintainability Monitoringは、

```bash
composer complexity
```

を利用する。

`composer complexity`ではProject Ruleset、

```text
backend/phpcs.xml
```

で選択したCleanCode SniffをPHP_CodeSnifferから実行する。

Complexity / Maintainability Threshold超過のみを理由としてMergeをBlockingしない。

CleanCode / PHP_CodeSnifferがNon-zero Exit Codeを返す場合でも、それ自体をProjectとしてのBlocking判定とはしない。

具体的なGitHub Actions上のNon-blocking実装方法はCI Workflow構築時に決定する。

Composer Dependencyは`composer.lock`に基づいてInstallする。

CIでは非対話的かつ再現可能なDependency Installを行う。

概念例：

```bash
composer install --no-interaction --prefer-dist
```

---

## 7. OpenAPI CI

OpenAPI SpecificationをBackend API契約のSource of Truthとする。

OpenAPI実仕様はMonorepo Root配下の以下で管理することを基本とする。

```text
openapi/
```

基本構成：

```text
engineer-skill-management-app/
├── frontend/
├── backend/
├── openapi/
├── docs/
├── .github/
├── compose.yaml
└── README.md
```

OpenAPI CIでは以下を実行する。

1. Redocly Lint
2. Redocly Bundle
3. openapi-typescriptによるType生成
4. Generated Type差分確認

概念：

```text
OpenAPI Source
      ↓
Redocly Lint
      ↓
Redocly Bundle
      ↓
openapi-typescript
      ↓
Generated Type
      ↓
git diff
```

以下の場合はCI Failureとする。

- OpenAPI Specificationが不正
- Bundleに失敗
- Type生成に失敗
- Version管理対象のGenerated Typeに更新漏れがある

OpenAPI変更時にFrontend側Generated Typeとの不整合を残さない。

---

## 8. E2E CI

E2E TestにはPlaywrightを利用する。

MVPでは主要業務フローのみをE2E化する。

画面単位で大量のTestを作成するのではなく、利用者が実際に行う重要な業務シナリオを中心にTestする。

代表例：

```text
管理ユーザーがログイン
        ↓
社員を登録
        ↓
スキルカテゴリを登録
        ↓
スキルを登録
        ↓
社員へスキルを登録
        ↓
社員スキルを編集
        ↓
変更内容を確認
```

E2Eでは必要に応じて以下を起動する。

```text
Frontend
   ↓
Backend
   ↓
PostgreSQL
```

E2E CIは他Workflowの成果物へ過度に依存せず、可能な限り自己完結したTest Environmentを構築する。

Testの基本バランスは以下とする。

```text
Unit / Feature / Integration
        ↓
広くTestする

E2E
        ↓
重要シナリオへ限定する
```

---

## 9. Trigger

### Pull Request

`main` Branchを対象とするPull RequestでCIを実行する。

```text
pull_request
     ↓
    main
```

Pull Request時のCIをMerge前の主要Quality Gateとする。

### Push

`main` BranchへのPushでもCIを実行する。

```text
push
 ↓
main
```

Merge後の`main`でもBuild / Test可能であることを確認する。

---

## 10. MonorepoのPath Filter

GitHub Actionsでは変更Pathに応じたWorkflow実行制御を利用できる。

将来的には以下のような最適化を検討する。

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

まずは重要なCIが確実に実行される構成を優先する。

CIが安定し、実行時間や利用状況を確認した後で必要に応じてPath Filterを導入する。

---

## 11. Path Filter利用時の注意

Required Status CheckとPath Filterを組み合わせる場合は、WorkflowがSkipされた場合のStatusを考慮する。

Required Checkが実行されず、Pull RequestがMerge待ちになる構成を避ける。

そのためMVPでは以下を基本方針とする。

- Workflowを不用意にSkipしない
- Required Check名を安定させる
- Required Checkとして利用するJobを明確にする
- Path FilterはCIが安定してから導入する
- OptimizationよりCorrectnessを優先する

---

## 12. Required Status Checks

`main` BranchではRequired Status Checks成功をMerge条件とする。

MVPの基本候補：

### Required

```text
Frontend CI
Backend CI
OpenAPI CI
```

### 導入後に判断

```text
E2E CI
```

E2Eについては以下を確認したうえでRequired化を判断する。

- 実行時間
- 安定性
- Flaky Testの発生状況
- CI Cost
- 開発速度への影響

Required Status Checkとして利用するJob名は、一意かつ安定した名称とする。

例：

```yaml
jobs:
  frontend-ci:
    # ...
```

```yaml
jobs:
  backend-ci:
    # ...
```

```yaml
jobs:
  openapi-ci:
    # ...
```

複数Workflow間でRequired Checkとして利用するJob名を重複させない。

Workflow File名だけではなく、Required Status Checkとして認識されるJob名を意識して設計する。

---

## 13. GitHub Rulesets

`main` BranchはGitHub Rulesetsを利用して保護する。

MVPではRulesetsをBranch Protectionの第一候補とする。

基本方針：

- Pull Request経由で変更する
- Required Status Checksを設定する
- CI成功をMerge条件とする
- Force Pushを原則許可しない
- Branch削除を原則許可しない
- 必要に応じてCode Reviewを必須にする

概念：

```text
main
 ↓
GitHub Ruleset
 ├── Pull Request
 ├── Required Status Checks
 ├── Force Push禁止
 └── Branch削除禁止
```

一人開発のMVP段階ではRequired Approvalを必須にしない。

チーム開発へ移行した場合はCode Review / Required Approvalの必須化を検討する。

Rulesetsと従来のBranch Protectionを不用意に重複設定せず、Rulesets中心の管理を基本とする。

---

## 14. main Branch

`main` Branchは常に以下を満たすことを目標とする。

```text
Build可能
    +
Test成功
    +
Deploy可能
```

通常の開発作業を`main` Branchへ直接Commitしない。

`main`はDeployment可能な基準Branchとして扱う。

---

## 15. Pull Request

機能開発・修正は原則としてPull Request経由とする。

基本フロー：

```text
Issue / User Story
        ↓
Feature Branch
        ↓
Commit
        ↓
Pull Request
        ↓
GitHub Actions
        ↓
Code Review
        ↓
Merge
```

Pull RequestではCI結果とCode Reviewを利用して変更内容を確認する。

---

## 16. Branch Strategy

MVPでは複雑なGit Flowを採用しない。

基本構成：

```text
main
 │
 ├── feature/...
 ├── fix/...
 └── chore/...
```

必要に応じて以下も利用できる。

```text
docs/...
refactor/...
test/...
```

長期間維持する`develop` Branchは原則設けない。

短命なBranchを作成し、Pull Requestを通して`main`へ統合する。

---

## 17. CI Jobの並列化

依存関係のないCIは可能な限り並列実行する。

概念：

```text
             Pull Request
                  |
      ┌───────────┼───────────┬───────────┐
      ↓           ↓           ↓           ↓
  Frontend     Backend     OpenAPI       E2E
     CI           CI          CI          CI
```

FrontendとBackendを直列実行する必要はない。

Workflow間の依存関係を必要以上に作らない。

各Workflow内部でも独立して実行可能なJobについては、実行時間とのバランスを確認しながら並列化を検討する。

---

## 18. PostgreSQL Test Service

Backend CIではTest専用PostgreSQLを使用する。

GitHub Actions上でPostgreSQL Service Containerを起動することを基本とする。

用途：

- Migration
- Laravel Feature Test
- Integration Test
- Database Constraint Test
- Repository / Infrastructure Test

Production DatabaseやLocal Development Databaseは利用しない。

CI実行ごとに独立したTest Database Environmentを利用する。

---

## 19. Dependency Cache

CI実行時間短縮のため、GitHub ActionsのCache機能を必要に応じて利用する。

対象：

### Frontend

- npm / pnpm等のDependency取得Cache

### Backend

- Composer Dependency Cache

CacheはDependencyのSource of Truthとしない。

Dependencyの正しいVersionはLock Fileによって決定する。

MVP初期ではCIの正確性・再現性を優先し、必要になってからCacheを最適化する。

---

## 20. Secrets

SecretをGit RepositoryへCommitしない。

対象例：

- Auth.js Secret
- Laravel `APP_KEY`
- Database Password
- Production Credential
- Deployment Credential
- API Token
- Cloud Credential
- その他Secret

CIで必要なSecretはGitHubのSecret管理機能等を利用する。

Test用に固定値を利用できるものについては、本物のProduction Secretを使用しない。

SecretをLogへ出力しない。

---

## 21. Permissions

GitHub Actions Workflowへ不要な権限を与えない。

Least Privilegeを基本とする。

通常のCIではWorkflow Levelで必要なPermissionを明示する。

例：

```yaml
permissions:
  contents: read
```

Write権限が必要なWorkflow / Jobのみ追加権限を付与する。

以下のような広すぎるPermissionを安易に利用しない。

```text
write-all
```

基本方針：

- WorkflowごとにPermissionを明示する
- 原則Read Onlyとする
- Write権限は必要な処理へ限定する
- CD用権限とCI用権限を分離する

---

## 22. Action Version

GitHub Actionsで利用するActionはVersionを明示的に固定する。

無条件に最新版へ追従する構成を避ける。

SecurityとReproducibilityを重視し、原則としてFull Commit SHAへのPinを第一候補とする。

概念：

```yaml
- uses: actions/checkout@<full-commit-sha>
```

特にThird-party ActionについてはFull Commit SHAへのPinを基本とする。

Action更新時は以下を確認する。

- Release Notes
- Breaking Changes
- Security情報
- Permission変更
- Required Runtime変更

Dependabot等によるAction Version更新の自動化については、CI運用開始後に検討する。

---

## 23. CD

CDについてもGitHub Actionsを第一候補とする。

ただしDeployment先とProduction Architectureが確定していないため、現時点では具体的なDeployment Workflowを設計しない。

将来的な概念：

```text
main
 ↓
GitHub Actions
 ↓
Build
 ↓
Staging
 ↓
Production
```

CIとCDの責務は分離する。

```text
CI
→ Build / Test / Static Analysis / Contract Validation

CD
→ Artifact / Container ImageのDeployment
```

具体的なCD設計はDeployment先決定後に行う。

---

## 24. Cloud認証

将来的にAWS / Azure / Google Cloud等へDeployする場合は、可能な限りGitHub ActionsのOIDCを利用する。

長期間有効なCloud Access KeyをGitHub Secretsへ保存する方式を原則として避ける。

概念：

```text
GitHub Actions
      ↓
     OIDC
      ↓
Cloud Provider
      ↓
Temporary Credential
```

具体的な認証方式・Role・PermissionはDeployment先決定後に設計する。

---

## 25. Complexity

ComplexityはMVP初期ではBlocking Quality GateではなくMonitoringとして扱う。

### Frontend / BFF

```text
ESLint complexity
       ↓
Cyclomatic Complexity
       ↓
Monitoring
```

Local / Project Command：

```bash
pnpm complexity
```

### Backend API

```text
CleanCode + PHP_CodeSniffer
       ↓
backend/phpcs.xml
       ↓
Complexity / Maintainability
       ↓
Monitoring
```

Local / Project Command：

```bash
composer complexity
```

BackendではCleanCode Standard全体を適用せず、Project Ruleset `backend/phpcs.xml`で必要なSniffのみを選択する。

MVPではComplexity / MaintainabilityをCode Qualityの可視化・Code Review・Refactoringの判断材料として利用する。

Complexity Threshold超過のみを理由としてCI Failureとすることは原則行わない。

また、Complexity Monitoring CommandがNon-zero Exit Codeを返すことと、ProjectとしてMergeをBlockingすることを同一視しない。

```text
Command Failure
      ≠
Merge Blocking Policy
```

具体的なGitHub Actions上のNon-blocking実装方法はCI Workflow構築時に決定する。

極端に複雑なCodeが検出された場合は、責務分離やDomain Modelingを見直すためのSignalとして利用する。

将来的にProjectの実績データが蓄積した段階で、Project固有ThresholdやQuality Gateへの組み込みを再検討する。

```text
Monitoring
    ↓
Metric / Violation蓄積
    ↓
Project固有Threshold検討
    ↓
Warning
    ↓
必要な場合のみBlocking
```

---

## 26. CI結果

Pull RequestではGitHub上から以下を確認できる状態とする。

- Frontend CI結果
- Backend CI結果
- OpenAPI CI結果
- E2E CI結果
- Test Failure
- Static Analysis Error
- Format / Lint Error
- Type Error
- Build Error
- OpenAPI Contract Error

CI Failure時には、可能な限りGitHub ActionsのLogから原因を追跡できる状態とする。

CI結果をPull Request Reviewの判断材料として利用する。

---

## 27. MVPで行わないこと

MVP初期では以下を過度に作り込まない。

- 複雑なPath Filter
- Dynamic Matrixの多用
- Reusable Workflowの過剰な抽象化
- Composite Actionの先行作成
- 複雑なWorkflow間依存
- CI専用の独自Orchestration
- 過度なCache最適化
- Complexityによる厳格なQuality Gate
- 大量のE2E Test
- Production Deployment Workflow

まずは単純で理解しやすく、確実に動作するCIを構築する。

必要性が確認できた段階で段階的に最適化する。

---

## 28. 決定事項

### Repository

GitHubを利用する。

### CI Platform

GitHub Actionsを採用する。

### Workflow

以下の責務でWorkflowを分離する。

```text
Frontend CI
Backend CI
OpenAPI CI
E2E CI
```

### Frontend CI

Blocking：

```text
Dependency Install
Prettier
ESLint
Type Check
Vitest
Next.js Build
```

Monitoring：

```text
ESLint complexity
```

### Backend CI

Blocking：

```text
Composer Install
Laravel Pint
PHPStan / Larastan
Migration
Pest / Laravel Test
```

Monitoring：

```text
CleanCode + PHP_CodeSniffer
    ↓
Complexity / Maintainability
```

Backend Complexity MonitoringではProject Ruleset `backend/phpcs.xml`で選択したCleanCode Sniffを実行する。

### Complexity Monitoring

Frontend / BackendともにComplexityをMVP初期ではMonitoringとして扱う。

Complexity Threshold超過のみを理由としてMergeをBlockingしない。

```text
Frontend
    → pnpm complexity

Backend
    → composer complexity
```

具体的なGitHub Actions上のNon-blocking実装方法はCI Workflow構築時に決定する。

### OpenAPI CI

以下を基本とする。

```text
Redocly Lint
Redocly Bundle
openapi-typescript
Generated Type差分確認
```

OpenAPI SpecificationをBackend API契約のSource of Truthとする。

### E2E CI

Playwrightを利用し、MVPの主要業務シナリオへ限定する。

### Dependency

DependencyはLock Fileに基づいて再現可能な形でInstallする。

### main Branch

GitHub Rulesetsで保護する。

### Merge

Required Status Checks成功をMerge条件とする。

MVPでは以下をRequiredの基本候補とする。

```text
Frontend CI
Backend CI
OpenAPI CI
```

E2E CIのRequired化は安定性・実行時間を確認して判断する。

### Required Check

Required Status Checkとして利用するJob名は一意かつ安定させる。

### Path Filter

MVP初期では最適化を優先せず、重要CIを確実に実行する。

CI安定後に必要に応じて導入する。

### Branch Strategy

`main` + 短命なFeature Branchを基本とする。

長期間維持する`develop` Branchは原則設けない。

### PostgreSQL

Backend CIでは独立したTest用PostgreSQL Serviceを利用する。

### Security

- SecretをRepositoryへCommitしない
- Workflow PermissionはLeast Privilegeとする
- ActionはVersionを固定する
- 原則としてFull Commit SHAへのPinを第一候補とする
- Cloud認証では可能な限りOIDCを利用する

### CD

Deployment先決定後にGitHub Actionsを利用して別途設計する。

### 基本方針

- Pull Request中心で開発する
- `main`への直接変更を避ける
- CIをMVPから導入する
- CI設定もRepositoryでVersion管理する
- Frontend / Backend / OpenAPI / E2Eの責務を分離する
- DependencyはLock Fileで再現可能にする
- Required Check名を安定させる
- Workflowへ最小権限のみ付与する
- SecurityとReproducibilityを重視する
- CIの正確性を最適化より優先する
- 必要以上にWorkflowを複雑化しない
- CIとCDの責務を分離する
