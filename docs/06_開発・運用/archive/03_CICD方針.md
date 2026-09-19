# CI/CD 方針

## 1. 基本方針

MVPではCIを導入する。

CDについては本番環境・デプロイ先が未決定のため、
具体的な方式は後続で決定する。

---

## 2. CIの目的

CIでは以下を自動化する。

- Code Format Check
- Lint
- Static Analysis
- Complexity Check
- Unit Test
- Feature / Integration Test
- OpenAPI Validation
- Type Generation Check
- 必要に応じてE2E Test

---

## 3. Trigger

CIは以下を契機として実行する。

### Pull Request

- [x] 実行する

### main BranchへのPush

- [x] 実行する

### Tag / Release

- [ ] MVPでは必須としない
- [x] CD設計時に検討する

---

## 4. Frontend CI

Frontend / BFFでは以下を実行する。

1. Dependency Install
2. Prettier Check
3. ESLint
4. Complexity Check
5. TypeScript Type Check
6. Vitest
7. OpenAPI Generated Type Check
8. Build Check

想定：

    Prettier
       ↓
    ESLint
       ↓
    Type Check
       ↓
    Vitest
       ↓
    Next.js Build

---

## 5. Backend CI

Laravel Backend APIでは以下を実行する。

1. Dependency Install
2. Laravel Pint Check
3. PHPStan / Larastan
4. PHPMD
5. PHPUnit / Laravel Feature Test

想定：

    Pint
       ↓
    PHPStan / Larastan
       ↓
    PHPMD
       ↓
    PHPUnit

---

## 6. OpenAPI CI

OpenAPIについて以下を実行する。

1. Redocly Lint
2. Redocly Bundle
3. openapi-typescriptによる型生成
4. Generated Typeの差分確認

想定：

    OpenAPI
       ↓
    Lint
       ↓
    Bundle
       ↓
    Type Generation
       ↓
    git diff Check

OpenAPI変更後にGenerated Typeの更新漏れがある場合、
CIで検出できる構成を目指す。

---

## 7. PostgreSQL

Laravel Feature TestではTest用PostgreSQLを利用する。

CI上でもPostgreSQLを起動する。

開発用Databaseとは分離する。

例：

    engineer_skill_test

---

## 8. E2E Test

E2EにはPlaywrightを利用する。

MVPではE2EをすべてのCommitで大量に実行しない。

候補：

- Pull Request時
- main BranchへのMerge時
- Release前

MVPでは主要な業務フローのみを対象とする。

---

## 9. CI Jobの分割

MonorepoではCI Jobを役割ごとに分割する。

想定：

    CI
    ├── frontend
    ├── backend
    ├── openapi
    └── e2e

各Jobを可能な範囲で並列実行する。

---

## 10. Pathによる実行制御

将来的に必要であれば、
変更されたDirectoryに応じてCIを実行する。

例：

    frontend/**
        ↓
    Frontend CI

    backend/**
        ↓
    Backend CI

    openapi/**
        ↓
    OpenAPI CI
        +
    Frontend Type Check

ただしMVPでは最適化を急がず、
まず確実にCIが動く構成を優先する。

---

## 11. CI Failure

以下の問題がある場合はCI Failureとする。

### Frontend

- Prettier違反
- ESLint Error
- TypeScript Error
- Test Failure
- Build Failure

### Backend

- Pint違反
- PHPStan / Larastan Error
- PHPUnit Failure

### OpenAPI

- OpenAPI Syntax Error
- Redocly Lint Error
- Bundle Failure
- Type Generation Failure
- Generated Type更新漏れ

---

## 12. Complexity

ComplexityについてはMVPでは監視を中心とする。

### Frontend

ESLint complexity

### Backend

PHPMD

複雑度超過のみを理由として、
初期段階から必ずCI Failureにはしない。

Codebaseの傾向を確認した後、
ThresholdとQuality Gateを調整する。

---

## 13. Branch Protection

main Branchへ直接Pushする運用は避ける。

基本フロー：

    Feature Branch
        ↓
    Pull Request
        ↓
    CI
        ↓
    Code Review
        ↓
    Merge

CI成功をMerge条件とすることを基本方針とする。

---

## 14. Monorepo

CIはMonorepoを前提とする。

    engineer-skill-management/
    ├── frontend/
    ├── backend/
    ├── openapi/
    ├── docs/
    └── compose.yaml

Frontend / Backend / OpenAPIそれぞれの品質チェックを
同じRepositoryで管理する。

---

## 15. DockerとCI

Local DevelopmentではDocker Composeを利用する。

CIでDocker Composeをそのまま利用することは必須としない。

CIでは必要に応じて、

- Node.js Environment
- PHP Environment
- PostgreSQL Service

を直接構築して実行してもよい。

重要なのはLocalとCIで利用するRuntime Versionを合わせることとする。

---

## 16. Cache

CI実行時間短縮のため、
必要に応じてDependency Cacheを利用する。

候補：

### Frontend

- npm Cache

### Backend

- Composer Cache

MVPではCIの正確性を優先し、
過度な最適化は後回しにする。

---

## 17. CD

本番環境が未決定のため、
具体的なCD方式は現時点では決定しない。

将来的に以下を検討する。

    main Merge
        ↓
    Build
        ↓
    Artifact / Container Image
        ↓
    Staging
        ↓
    Test
        ↓
    Production

---

## 18. Deployment Environment

候補：

- AWS
- Azure
- Google Cloud
- その他

Deployment先を決定した後、
具体的なCD Pipelineを設計する。

---

## 19. Secrets

CI/CDで利用する秘密情報をRepositoryへ保存しない。

対象例：

- Database Password
- Laravel APP_KEY
- Sanctum関連Credential
- Production API URL
- Auth.js Secret
- その他Secret

CI/CD PlatformのSecret管理機能を利用する。

---

## 20. CI Platform

具体的なCI Platformは別途選定する。

候補：

- GitHub Actions
- GitLab CI
- その他

Git RepositoryをGitHubで管理する場合は、
GitHub Actionsを第一候補とする。

---

## 21. MVPでのCI構成

MVPでは最低限以下を自動化する。

### Frontend

- Prettier
- ESLint
- TypeScript
- Vitest
- Build

### Backend

- Pint
- PHPStan / Larastan
- PHPUnit

### OpenAPI

- Redocly Lint
- Bundle
- Type Generation

### E2E

主要業務フローについてPlaywrightを実行する。

---

## 22. 決定方針

### CI

MVPから導入する。

### CD

Deployment先決定後に具体化する。

### Pull Request

CI成功をMerge条件とする。

### Monorepo

Frontend / Backend / OpenAPIを別Jobとして扱う。

### Complexity

MVPでは監視中心とし、
厳格なQuality Gateは後から決定する。

### E2E

主要業務フローに限定する。
