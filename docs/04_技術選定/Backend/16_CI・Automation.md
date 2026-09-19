# Backend 技術・Library選定 - CI・Automation

## 1. 目的

本ドキュメントでは、Engineer Skill Management App のBackendを中心としたCI・Automation方針を定義する。

対象：

- GitHub Actions
- Pull Request CI
- Quality Gate
- Test Automation
- PostgreSQL Integration Test
- OpenAPI Validation / Contract Test
- Security Check
- Dependency Audit
- Container Build / Scan
- CI Cache
- Branch Protection
- Workflow Concurrency
- Deployment Automation
- Staging / Production Deployment
- Migration Automation
- Artifact / Image Versioning
- Scheduled Automation
- GitHub Actions Security

本Projectでは、

> Localで実行するQuality / Test / Security CommandをCIでも同じ形で再利用し、Merge可否を自動かつ再現可能に判定する

ことを基本方針とする。

---

# 2. CI/CD全体方針

CI/CD基盤としてGitHub Actionsを採用する。

```text id="x3wr2l"
Pull Request
    ↓
CI
    ↓
Quality / Test / Security
    ↓
Required Checks
    ↓
Review
    ↓
Merge
    ↓
Build
    ↓
Staging
    ↓
Verification
    ↓
Production Approval
    ↓
Production
```

---

# 3. CIとCDの分離

CIとDeployment Automationを責務分離する。

```text id="y41aoc"
CI
    → Merge可能かを検証

CD
    → 検証済みArtifactをEnvironmentへDeploy
```

1つの巨大Workflowへすべてを詰め込まない。

---

# GitHub Actions

## 4. CI/CD Platform

GitHub Actionsを正式採用する。

利用対象：

```text id="mhw3qp"
Pull Request
Push
Manual Workflow
Scheduled Workflow
Build
Test
Security Scan
Deployment
```

Repository / Pull Request / Branch Protectionとの統合を優先する。

---

# Workflow構成

## 5. Workflow File

概念的には以下の責務へ分割する。

```text id="oou8ml"
.github/
└── workflows/
    ├── backend-ci.yml
    ├── frontend-ci.yml
    ├── openapi-ci.yml
    ├── security.yml
    ├── build.yml
    ├── deploy-staging.yml
    └── deploy-production.yml
```

MVP開始時点では過度に分割せず、必要に応じ整理する。

---

## 6. Workflow分割原則

以下を基準とする。

```text id="7gr44p"
責務が異なる
Triggerが異なる
Permissionが異なる
Secret Access範囲が異なる
Deployment Environmentが異なる
```

場合はWorkflowを分ける。

---

# Trigger

## 7. Pull Request

`main`向けPull RequestではCIを必須実行する。

対象：

```text id="s3qph8"
Formatting
Static Analysis
Complexity
Architecture
Unit Test
Integration Test
Feature Test
Contract Test
OpenAPI Validation
Dependency Security
Container Build / Scan
```

---

## 8. main Push

`main`へのMerge後は、

```text id="2giv97"
Immutable Image Build
Image Scan
Registry Push
Staging Deployment
```

を実行する。

---

## 9. Manual Trigger

以下はManual Triggerを利用可能とする。

```text id="ihj6m6"
Production Deployment
Re-deployment
Operational Maintenance
Exceptional Workflow
```

---

## 10. Schedule

定期AutomationにScheduled Workflowを利用する。

候補：

```text id="dntzfv"
Dependency Security Re-scan
Container Image Re-scan
```

---

# PR Quality Gate

## 11. PR CIは必須

Pull RequestをMergeするためにはCI成功を必須とする。

```text id="v2ikvk"
Pull Request
    ↓
Required Checks
    ↓
Review
    ↓
Merge
```

---

## 12. Fast Feedback

Developerが早くFailureを確認できるよう、軽いCheckを優先的に実行する。

候補：

```text id="z1vl6p"
Pint
PHPStan / Larastan
PHPMD
Architecture Test
Unit Test
```

---

## 13. CI Parallelization

CI全体を不必要に直列化しない。

概念：

```text id="ibw8rs"
            ┌── Quality
            ├── Unit
PR ─────────├── Integration
            ├── Feature / Contract
            ├── OpenAPI
            └── Security
```

独立可能なJobは並列実行する。

---

## 14. Job Setup Cost

Jobを細かくしすぎるとDependency Install等が重複するため、MVPでは適度にまとめる。

Backend推奨Job：

```text id="wjq6rz"
backend-quality
backend-unit
backend-integration
backend-feature-contract
backend-security
```

---

# Backend Quality

## 15. `backend-quality`

以下を実行する。

```text id="9pdzxs"
composer lint
composer analyse
composer complexity
composer architecture
```

---

## 16. Local / CI共通化

CI内でTool固有Commandを再定義しない。

```text id="rzz9zm"
Local
    → composer quality

CI
    → composer quality
```

を基本とする。

---

## 17. Source of Truth

Quality ToolのCommand Definitionは、

```text id="owtb16"
composer.json
```

をSource of Truthとする。

GitHub Actionsはそれを呼び出すだけにする。

---

# Test Automation

## 18. Unit Test

Domain / Application中心の高速TestをPR必須とする。

特徴：

```text id="rz6spk"
No PostgreSQL
No External Service
Fast
Deterministic
```

---

## 19. Architecture Test

Pest Architecture TestもPR必須とする。

Clean ArchitectureのDependency Rule違反をMerge前に検出する。

---

# PostgreSQL Integration Test

## 20. Real PostgreSQL

`12_Test.md`の方針に従い、

```text id="6vncz2"
SQLite
    → 不採用

PostgreSQL
    → 採用
```

とする。

---

## 21. PostgreSQL Version

CIでもProject採用Versionと同じMajorを利用する。

```text id="8wuiv5"
PostgreSQL 18.x
```

とする。

Local / CI / Staging / ProductionでMajor Versionを揃える。

---

## 22. Integration Environment

Backend Integration TestではGitHub Actions Service Container等による一時PostgreSQLを利用する。

Cross-system Testが必要な場合はDocker Composeを利用する。

---

## 23. Database Setup

Integration / Feature TestはFresh Databaseから開始する。

```text id="4e68vk"
PostgreSQL Start
    ↓
Migration
    ↓
Test Fixture
    ↓
Test
```

Production Database Dumpに依存しない。

---

## 24. Migration Test

Migration自体もIntegration Test Environmentで実際に適用可能であることを確認する。

---

# Feature Test

## 25. Feature Test

Laravel Feature TestをPR必須とする。

対象：

```text id="b2a2hj"
Routing
Authentication
Authorization
Validation
Serialization
Problem Details
Rate Limiting
Headers
```

---

# Contract Test

## 26. OpenAPI Contract Test

既存採用済みの、

```text id="hwg15f"
kirschbaum-development/laravel-openapi-validator
```

を利用する。

Contract TestをPR必須とする。

---

## 27. Contract Test対象

以下を確認する。

```text id="l2yuef"
Request Schema
Response Schema
HTTP Status
Content-Type
Required Field
Enum
String ID
Date / DateTime
YearMonth
RFC 9457 Problem Details
```

---

# OpenAPI CI

## 28. OpenAPI Validation

OpenAPI File自体をCIでValidationする。

対象：

```text id="246108"
Syntax
Schema
Reference
Format
```

---

## 29. OpenAPI First

API変更Flow：

```text id="6jwm4r"
Requirement
    ↓
OpenAPI
    ↓
Review
    ↓
Backend
    ↓
Frontend / BFF
    ↓
Contract Test
```

をCIでも支援する。

---

## 30. Breaking Change Detection

OpenAPI Breaking Change Detectionは将来導入候補とする。

対象例：

```text id="4psk3k"
Path Removal
Required Field追加
Response Field削除
Enum互換性破壊
Type変更
```

MVP開始時点では必須Toolにしない。

---

# Dependency Security

## 31. Composer Audit

Backend Dependency Security Checkとして、

```bash id="51y3r4"
composer audit --locked
```

を採用する。

PR必須Checkとする。

---

## 32. Dev Dependency

Production DependencyだけでなくDevelopment Dependencyも原則Audit対象とする。

Developer Tool経由のSupply Chain Riskも考慮する。

---

# Dependabot

## 33. Dependabot

GitHub Dependabotを採用する。

対象候補：

```text id="re4bd3"
Composer
Frontend Package Manager
Docker
GitHub Actions
```

---

## 34. Dependabot PR

DependabotによるUpdateも通常Pull Requestと同じCIを通す。

---

## 35. Auto Merge

MVP開始時点ではDependency Updateを広範囲にAuto Mergeしない。

特に以下はReviewする。

```text id="u309cp"
Major Version
Laravel
PHP Tool
Security-sensitive Library
Database-related Library
```

---

## 36. Future Auto Merge

運用が安定した場合、小さなPatch Update等について限定的なAuto Mergeを検討できる。

---

# Secret Scanning

## 37. Secret Scanning

GitHub Secret Scanning等、利用可能なRepository Security機能を有効化する。

対象：

```text id="0vledw"
API Key
Token
Cloud Credential
Private Key
Known Secret Pattern
```

---

## 38. Additional Tool

GitHub機能で不足する場合、Gitleaks等を追加候補とする。

同種Scannerを理由なく重複導入しない。

---

# Container Build

## 39. Production Image Build Test

Pull RequestではProduction Docker ImageがBuild可能であることを確認する。

```text id="0euj0n"
Dockerfile
    ↓
Build
    ↓
Scan
```

---

## 40. PRではRegistry Pushしない

Pull Requestでは基本的に、

```text id="lq4hkp"
Build
Scan
```

までとする。

Container RegistryへのProduction Artifact Pushは行わない。

---

# Container Image Scan

## 41. Trivy

Container Vulnerability ScannerとしてTrivyを採用する。

主な対象：

```text id="p93qr7"
OS Package
Application Dependency
Container Image
```

---

## 42. Scan Timing

最低限、

```text id="go4dfh"
PR Image Build時
main Image Build時
Scheduled Re-scan時
```

に利用可能な構成とする。

---

## 43. Severity

初期Fail Policyでは、

```text id="tpogk1"
HIGH
CRITICAL
```

を重点対象とする。

最終的なFail条件は実運用を見ながら調整する。

---

## 44. Vulnerability例外

Ignoreを安易に増やさない。

優先順位：

```text id="u046l5"
1. Dependency修正
2. Base Image更新
3. Package更新
4. Configuration改善
5. Narrow Exception
```

とする。

---

## 45. Exception Management

Ignoreする場合は最低限、

```text id="3qb8y8"
Vulnerability
Reason
Impact
Mitigation
Revisit Condition
```

を明確にする。

---

# Image Build

## 46. main Build

`main` Merge後にProduction ImageをBuildする。

```text id="3d9x73"
main
    ↓
Build Image
    ↓
Scan
    ↓
Push Registry
```

---

## 47. Registry

Production InfrastructureでAWS ECSを採用する場合はAmazon ECRを利用する想定とする。

最終Infrastructure選定に従う。

---

# Image Version

## 48. Immutable Tag

Container Imageの識別にはGit Commit SHAを利用する。

例：

```text id="05xjwq"
backend:<git-sha>
```

---

## 49. `latest`

`latest`だけをDeployment Source of Truthにしない。

Deployment対象Imageを一意に特定可能にする。

---

## 50. Release Metadata

Git SHAを以下で共通利用する。

```text id="0i5svv"
Container Image
Deployment
Structured Log
Trace
Error Monitoring
Release Metadata
```

---

# Build Once, Deploy Many

## 51. 原則

Artifactは一度Buildし、Environmentごとに再Buildしない。

```text id="135o6f"
Source
    ↓
CI Build
    ↓
Immutable Image
    ↓
Staging
    ↓
Production
```

---

## 52. Environment差分

Environment差分は、

```text id="boxnti"
Environment Variable
Secret
Infrastructure Configuration
```

で管理する。

Image自体をEnvironmentごとにBuildし直さない。

---

# CI Cache

## 53. Cache

CI高速化のためDependency Cacheを採用する。

対象候補：

```text id="zqm1ux"
Composer Package Cache
Frontend Package Manager Cache
```

---

## 54. `vendor/`

Backendでは原則、

```text id="wd0jmf"
Composer Download Cache
    → Cache

vendor/
    → composer installで再構築
```

とする。

---

## 55. Reproducibility

Cache Hitの有無に関係なく同じResultになることを前提とする。

CacheをCorrectnessの前提にしない。

---

# Runtime Version

## 56. PHP

CIでは採用済みの、

```text id="vjh4zk"
PHP 8.5
```

を使用する。

---

## 57. Laravel

Laravel Versionは`composer.lock`で固定する。

---

## 58. PostgreSQL

CIでは、

```text id="v6m0vh"
PostgreSQL 18.x
```

を利用する。

---

## 59. PHP Version Matrix

Application Projectであるため、複数PHP Version Compatibility TestをMVPで行わない。

```text id="q08fej"
PHP 8.5
```

のみをCI対象とする。

Library ProjectのようなVersion Matrixは不要とする。

---

# Workflow Concurrency

## 60. PR Concurrency

同じPull Requestへ新しいCommitがPushされた場合、古いCI RunをCancelする。

概念：

```text id="lhbc9z"
Commit A
    ↓
CI running

Commit B push
    ↓
Commit A CI cancel
Commit B CI start
```

---

## 61. `cancel-in-progress`

PR CIでは、

```text id="0tw7ud"
cancel-in-progress = true
```

相当のConcurrency Policyを採用する。

不要なRunner消費と待ち時間を減らす。

---

# Deployment Concurrency

## 62. Deployment

Deploymentでは同一EnvironmentへのConcurrent Deployを禁止する。

```text id="9x1gin"
Production Deploy A
+
Production Deploy B
    → 禁止
```

---

## 63. Environment単位Concurrency

```text id="f5atxq"
staging
production
```

ごとにDeployment Concurrencyを制御する。

---

# Branch Protection

## 64. `main`

`main`への直接Pushを原則禁止する。

```text id="nyugdw"
Feature Branch
    ↓
Pull Request
    ↓
CI
    ↓
Review
    ↓
Merge
```

とする。

---

## 65. Required Status Checks

最低限以下をMerge必須候補とする。

```text id="bb7r8f"
backend-quality
backend-unit
backend-integration
backend-feature-contract
backend-security
frontend-ci
openapi-ci
```

実際のJob名はWorkflow実装時に固定する。

---

## 66. Review

Pull Requestには原則Reviewを要求する。

少なくとも1 Reviewを基本候補とする。

Team規模に合わせて調整可能とする。

---

## 67. CI Failure

Required CheckがFailureの場合はMerge不可とする。

---

# CODEOWNERS

## 68. CODEOWNERS

MVPでは必須としない。

Team規模・Ownershipが明確になった場合に導入候補とする。

候補：

```text id="u48me8"
/backend
/openapi
/infrastructure
```

---

# Staging Deployment

## 69. Staging

`main` Merge後はStagingへ自動Deployする。

推奨Flow：

```text id="vkva9x"
Merge
    ↓
Build / Scan
    ↓
Registry Push
    ↓
Staging Deploy
    ↓
Health Check
    ↓
Smoke Test
```

---

## 70. Staging Auto Deploy

StagingはAutomatic Deploymentを採用する。

目的：

```text id="2dzqtk"
main
    ≈
deployable state
```

を維持すること。

---

# Deployment Verification

## 71. Health Check

Deploy後にHealth / Readinessを確認する。

既存方針：

```text id="6yeaeq"
Liveness
Readiness
```

を利用する。

---

## 72. Smoke Test

Deploy後のSmoke Testを採用する。

最低限候補：

```text id="8wdq3o"
Application reachable
Readiness = 200
Critical API path reachable
```

---

## 73. Full Regression

Deploy後に全Unit / Integration / Feature Testを再実行することは原則不要とする。

Deployment後はEnvironment-specific Failureの検出に集中する。

---

# Production Deployment

## 74. Production

MVPではProductionへの完全自動Deployを採用しない。

---

## 75. 推奨Flow

```text id="f59cd3"
main
    ↓
Staging Auto Deploy
    ↓
Verification
    ↓
Production Approval
    ↓
Production Deploy
```

---

## 76. Manual Approval

Production DeploymentはManual Approvalを基本とする。

Staging確認後に実行する。

---

# GitHub Environment

## 77. Environment

GitHub Environmentsを利用する。

候補：

```text id="6ghc14"
staging
production
```

---

## 78. Environment Configuration

Environmentごとに、

```text id="73sz9x"
Secret
Variable
Protection Rule
Allowed Branch
Reviewer
```

を管理する。

利用可能なGitHub Plan / Repository設定の範囲で適用する。

---

## 79. Production Protection

Productionでは可能な範囲で、

```text id="f5p0dp"
Required Reviewer
Protected Branch
Deployment Concurrency
Environment-specific Secret
```

を設定する。

---

## 80. Self Approval

GitHub側で利用可能な場合、Production Deploy開始者自身によるApproval禁止も検討する。

必須Requirementにはせず、Organization / Plan設定に応じて採用する。

---

# Secrets

## 81. Environment Secret分離

以下を明確に分離する。

```text id="10fyai"
CI Test Secret
Staging Secret
Production Secret
```

---

## 82. Production Secret

Production SecretをPull Request Workflowから参照させない。

---

## 83. Test Credentials

CI TestではDedicated Test Credential / Fake / Temporary Serviceを使用する。

Production Credentialを利用しない。

---

# Cloud Authentication

## 84. AWS

AWS ECSを採用する場合、GitHub ActionsからAWSへの認証はOIDCを第一候補とする。

---

## 85. Long-lived Access Key

可能な限り、

```text id="n4gk9r"
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

のような長期CredentialをGitHub Secretとして固定保存しない。

---

## 86. Least Privilege

Deployment用IAM RoleはDeploymentに必要な最小Permissionのみ付与する。

---

# Migration Automation

## 87. Deployment Migration

Database MigrationをDeployment Pipelineで自動化する。

---

## 88. Replica起動時Migration禁止

Application Container起動ごとに全Replicaが、

```text id="gwffsh"
php artisan migrate
```

を競合実行する構成にはしない。

---

## 89. Dedicated Migration Step

推奨：

```text id="kfrtgn"
Deploy Workflow
    ↓
Migration Task
    ↓
Application Rollout
```

とする。

AWS ECSならOne-off Task等が候補となる。

---

## 90. Migration Failure

MigrationがFailureした場合、原則Application Deploymentを継続しない。

---

# Backward-compatible Migration

## 91. Deployment互換性

Application Rollout中に旧Version / 新Versionが一時共存する可能性を考慮する。

---

## 92. Destructive Change

以下を単一Deploymentで不用意に行わない。

```text id="j4n8tv"
Column削除
Column Rename
Type変更
Immediate NOT NULL
Breaking Constraint
```

---

## 93. Expand / Contract

必要な場合、

```text id="xdh5of"
Expand
    ↓
Application Deploy
    ↓
Data Migration
    ↓
Contract
```

方式を利用する。

---

# Scheduled Security Automation

## 94. Scheduled Scan

Code変更がなくても新しいVulnerabilityが公開されるため、Scheduled Security Checkを採用する。

---

## 95. Candidate

```text id="q7tgwj"
composer audit
Container Image Scan
```

をScheduled実行候補とする。

---

## 96. Frequency

初期候補としてDaily実行を推奨する。

GitHub Security Alert / Dependabot等との重複を確認し、必要に応じ調整する。

---

# Flaky Tests

## 97. Retry Policy

Test Failureを自動RetryしてGreenにすることを標準にしない。

```text id="ukfjdd"
Flaky Test
    ↓
Root Cause Fix
```

とする。

---

## 98. Infrastructure Retry

外部ServiceやRunner側一時障害など、明らかなInfrastructure Failureに限りWorkflow単位の再実行を許容する。

Test CodeのFlakiness隠蔽には使わない。

---

# CI Artifacts

## 99. Failure Artifact

Debugに必要な場合、

```text id="0o6421"
Test Report
Coverage Report
Build Log
Diagnostic Artifact
```

を保存可能とする。

---

## 100. Sensitive Data

CI Artifactへ以下を含めない。

```text id="x23a6e"
Secret
Token
Authorization Header
Production Credential
Sensitive Personal Data
```

---

# Coverage

## 101. Coverage

`12_Test.md`の方針を維持する。

Coverageは補助指標として利用する。

---

## 102. Coverage Threshold

MVPでは、

```text id="ifka7z"
80%
90%
100%
```

等の任意なGlobal Coverage ThresholdをMerge条件にしない。

Core DomainのTest Qualityを優先する。

---

# GitHub Actions Security

## 103. Least Privilege

GitHub Actionsの`permissions`をWorkflow / JobのPurposeに応じて最小化する。

---

## 104. Default Write Permission

すべてのWorkflowへ広いWrite Permissionを与えない。

通常CIはRead中心とする。

---

## 105. Deployment Permission

Registry Push / Deployment等のWrite Permissionは必要なWorkflowにのみ付与する。

---

# Third-party Actions

## 106. Version Pinning

Third-party GitHub ActionはVersionを明示する。

---

## 107. Commit SHA Pinning

Security Requirementが高いActionについてはCommit SHA Pinningを検討する。

特にDeployment / Credential / Security関連Actionを優先する。

---

## 108. Action Selection

不要に多数のThird-party Actionを導入しない。

優先順位：

```text id="rx6juw"
Official GitHub Action
Cloud Provider Official Action
Established Tool Official Action
Trusted Third-party
Custom Script
```

とする。

---

# Pull Request Security

## 109. `pull_request`

通常のPull Request CIでは、

```text id="uoa7vv"
pull_request
```

を利用する。

---

## 110. `pull_request_target`

`pull_request_target`はUntrusted PR CodeとRepository Secretの組み合わせRiskがあるため、安易に利用しない。

必要な場合はThreat Modelを明示して別設計する。

---

# Fork / Untrusted Code

## 111. Secret Exposure

Untrusted Pull RequestがProduction / Deployment Secretを参照できない構成を維持する。

---

# Path Filtering

## 112. Path Filter

Monorepoのため、将来的には変更範囲に応じてWorkflowを絞ることを検討する。

例：

```text id="s1h938"
backend/**
    → backend-ci

frontend/**
    → frontend-ci

openapi/**
    → openapi-ci
```

---

## 113. Cross-cutting Change

ただし、

```text id="noonaw"
OpenAPI
Docker
Shared Configuration
Root Tooling
```

等は複数Workflowへ影響するため、Path Filterを過度に狭くしない。

CorrectnessをCI時間削減より優先する。

---

# CI Command Model

## 114. Backend

```text id="72jzrr"
composer quality
composer test
composer audit --locked
```

をCIの主要入口とする。

---

## 115. Repository

```text id="5i4fgt"
make check
```

はLocal総合Checkとして利用する。

CIでは必要に応じJob単位へ分割するが、内部ScriptはLocalと共有する。

---

# Recommended PR Pipeline

## 116. Backend Pipeline

```text id="148g4d"
Pull Request
    │
    ├── backend-quality
    │     ├── Pint
    │     ├── PHPStan / Larastan
    │     ├── PHPMD
    │     └── Architecture
    │
    ├── backend-unit
    │
    ├── backend-integration
    │     └── PostgreSQL 18
    │
    ├── backend-feature-contract
    │     ├── Feature
    │     └── OpenAPI Contract
    │
    ├── backend-security
    │     ├── composer audit
    │     └── security-related tests
    │
    ├── openapi-ci
    │
    └── container-build-scan
          ├── Build
          └── Trivy
```

---

# Recommended Deployment Pipeline

## 117. main

```text id="f16dwz"
Merge to main
    ↓
Build Immutable Image
    ↓
Trivy Scan
    ↓
Push Registry
    ↓
Staging Deploy
    ↓
Migration
    ↓
Readiness
    ↓
Smoke Test
```

---

## 118. Production

```text id="33lwsh"
Verified Staging Artifact
    ↓
Manual Approval
    ↓
Same Immutable Image
    ↓
Production Migration
    ↓
Production Deploy
    ↓
Readiness
    ↓
Smoke Test
```

---

# Adoption Matrix

## 119. 採用技術

| 項目 | 決定 |
|---|---|
| CI/CD Platform | GitHub Actions |
| Pull Request CI | 必須 |
| CI/CD Workflow分離 | 採用 |
| `main` Direct Push | 原則禁止 |
| Branch Protection | 採用 |
| Required Status Checks | 採用 |
| PR Review | 採用 |
| Backend Quality Check | PR必須 |
| Unit Test | PR必須 |
| Architecture Test | PR必須 |
| PostgreSQL Integration Test | PR必須 |
| Feature Test | PR必須 |
| OpenAPI Contract Test | PR必須 |
| OpenAPI Validation | PR必須 |
| Breaking Change Detection | 将来候補 |
| `composer audit --locked` | 採用 |
| Dependabot | 採用 |
| Dependency Auto Merge | MVPでは原則不採用 |
| Secret Scanning | 採用 |
| Gitleaks | 必要時候補 |
| Production Image Build Test | 採用 |
| Trivy | 採用 |
| HIGH / CRITICAL Scan | 初期重点対象 |
| PR Registry Push | 不採用 |
| main Registry Push | 採用 |
| Image Tag | Git SHA |
| `latest`のみでDeploy | 不採用 |
| Build Once Deploy Many | 採用 |
| Composer Cache | 採用 |
| `vendor/` Cache | 原則不採用 |
| PHP CI Version | PHP 8.5 |
| PHP Version Matrix | 不採用 |
| PostgreSQL CI | 18.x |
| PR `cancel-in-progress` | 採用 |
| Deployment Concurrency | 採用 |
| Staging Auto Deploy | 採用 |
| Production Auto Deploy | 不採用 |
| Production Manual Approval | 採用 |
| GitHub Environments | 採用 |
| Environment Secret分離 | 採用 |
| AWS GitHub Authentication | OIDC第一候補 |
| Dedicated Migration Step | 採用 |
| Expand / Contract Migration | 必要時採用 |
| Scheduled Security Scan | 採用 |
| Automatic Test Retry | 原則不採用 |
| Coverage | 補助指標 |
| Global Coverage Threshold | MVP不採用 |
| GitHub Actions Least Privilege | 採用 |
| Third-party Action Version Pin | 採用 |
| Commit SHA Pin | Security-sensitive Actionで候補 |
| `pull_request_target` | 原則利用しない |
| CODEOWNERS | 将来候補 |
| Path Filtering | 将来最適化候補 |

---

# Final Architecture

## 120. Development → CI

```text id="zl8nht"
Developer
    ↓
make check
    ↓
Git Push
    ↓
Pull Request
    ↓
GitHub Actions
    ↓
Same Project Scripts
```

LocalとCIで異なるQuality Definitionを作らない。

---

## 121. Pull Request

```text id="1fe67f"
Pull Request
    ↓
┌────────────────────────────┐
│ Quality                    │
│ Unit                       │
│ Integration + PostgreSQL   │
│ Feature / Contract         │
│ OpenAPI                    │
│ Dependency Security        │
│ Container Build / Scan     │
└────────────────────────────┘
    ↓
Required Checks
    ↓
Review
    ↓
Merge
```

---

## 122. Artifact

```text id="9wqxr1"
main
    ↓
Build
    ↓
Immutable Container Image
    ↓
Git SHA
```

Artifactを一意に追跡可能にする。

---

## 123. Deployment

```text id="bwexui"
Immutable Image
    ↓
Staging
    ↓
Health / Smoke Test
    ↓
Production Approval
    ↓
Production
```

StagingとProductionで同一Imageを利用する。

---

## 124. Security

```text id="v7e37n"
Source Code
    ↓
Dependency Audit
    ↓
Secret Scan
    ↓
Container Build
    ↓
Container Scan
    ↓
Deployment
```

Security CheckをApplication Sourceだけに限定しない。

---

# 最終方針

## 125. CIはQuality Gate

CIの主要目的は、

> Pull RequestがProjectで合意した品質・Test・Security・API Contractを満たしているかを自動判定する

こととする。

---

## 126. Local / CI共通化

以下を維持する。

```text id="o4bcgn"
Local
    → Composer / package Scripts

CI
    → Same Scripts
```

GitHub Actions独自のQuality Definitionを作らない。

---

## 127. Parallel CI

Fast Feedbackのため独立Jobを並列実行する。

一方でJob Setup CostとのBalanceを取り、MVPでは過剰なJob分割を避ける。

---

## 128. Production Artifact

Productionでは、

> Source Codeを再Buildするのではなく、CIで作成・検証済みのImmutable ArtifactをDeployする

ことを原則とする。

---

## 129. Deployment Safety

Deploymentについては、

```text id="b06x0i"
Staging
    → Automatic

Production
    → Approval Required
```

を基本とする。

---

## 130. Migration Safety

Database MigrationはDeployment Workflowに組み込むが、Application Replica起動時に競合実行させない。

Dedicated Migration Stepを使用する。

---

## 131. Security Automation

以下を継続的にAutomationする。

```text id="cfnprh"
Dependency Vulnerability
Secret Leak
Container Vulnerability
Security Test
```

Code変更がない期間もScheduled Scanによって新しいVulnerabilityを検出可能にする。

---

## 132. 最終原則

CI・Automationでは、

```text id="v4icph"
Fast Feedback
+
Reproducibility
+
Required Quality Gate
+
Immutable Artifact
+
Least Privilege
+
Safe Deployment
```

を基本原則とする。

最終的に、

```text id="ndghnr"
Developer
    ↓
Local Check
    ↓
Pull Request
    ↓
Automated Quality / Test / Security
    ↓
Protected Merge
    ↓
Immutable Build
    ↓
Staging Verification
    ↓
Controlled Production Deployment
```

という一貫したSoftware Delivery Pipelineを採用する。
