# CI Platform 技術決定

## 1. 採用Platform

Git RepositoryはGitHubで管理する。

CI PlatformにはGitHub Actionsを採用する。

- [x] GitHub
- [x] GitHub Actions
- [ ] GitLab CI
- [ ] その他

---

## 2. 採用理由

GitHub Actionsを採用する主な理由：

- GitHub Repositoryと直接統合できる
- Pull RequestをTriggerとしてCIを実行できる
- main BranchへのPushでもCIを実行できる
- Required Status Checkとして利用できる
- Branch Protection / Rulesetsと統合できる
- Monorepoに対応できる
- WorkflowをRepository内でVersion管理できる
- Node.js / PHP / PostgreSQLを利用したCIを構築できる
- 将来的なCDにも利用できる

---

## 3. 基本開発フロー

    Feature Branch
          ↓
      Pull Request
          ↓
    GitHub Actions
          ↓
    ┌───────────────┐
    │               │
Frontend CI     Backend CI
    │               │
    └───────┬───────┘
            │
        OpenAPI CI
            │
            ↓
        E2E Test
            │
            ↓
       Code Review
            │
            ↓
          Merge

CIが失敗している場合は原則Mergeできない構成とする。

---

## 4. Workflow構成

Monorepoの責務に合わせてWorkflowを分割する。

想定：

    .github/
    └── workflows/
        ├── frontend-ci.yml
        ├── backend-ci.yml
        ├── openapi-ci.yml
        └── e2e-ci.yml

1つの巨大なWorkflowへすべての処理をまとめない。

---

## 5. Frontend CI

対象：

    frontend/

実行内容：

1. Dependency Install
2. Prettier Check
3. ESLint
4. Complexity Check
5. TypeScript Type Check
6. Vitest
7. Next.js Build

概念：

    npm install
        ↓
    Prettier
        ↓
    ESLint
        ↓
    TypeScript
        ↓
    Vitest
        ↓
    Next.js Build

---

## 6. Backend CI

対象：

    backend/

実行内容：

1. Composer Dependency Install
2. Laravel Pint Check
3. PHPStan / Larastan
4. PHPMD
5. PostgreSQL Test Database起動
6. PHPUnit / Laravel Feature Test

概念：

    composer install
        ↓
    Pint
        ↓
    PHPStan / Larastan
        ↓
    PHPMD
        ↓
    PHPUnit

---

## 7. OpenAPI CI

対象：

    openapi/

実行内容：

1. Redocly Lint
2. Redocly Bundle
3. openapi-typescript
4. Generated Type差分確認

概念：

    OpenAPI
       ↓
    Redocly Lint
       ↓
    Bundle
       ↓
    Type Generation
       ↓
    git diff

OpenAPI仕様が不正な場合はCI Failureとする。

Generated Typeの更新漏れもCIで検出する。

---

## 8. E2E CI

Playwrightを利用する。

対象：

- ログイン
- 社員登録
- スキルカテゴリ登録
- 技術・スキル登録
- 社員スキル登録
- 社員スキル編集

MVPでは主要業務フローのみE2E化する。

---

## 9. Trigger

### Pull Request

main Branchを対象とするPull RequestでCIを実行する。

    pull_request
        ↓
    main

### Push

main BranchへのPushでもCIを実行する。

    push
      ↓
    main

---

## 10. MonorepoのPath Filter

GitHub Actionsでは変更Pathに応じたWorkflow実行制御を利用できる。

将来的には例えば以下を検討する。

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
    Frontend CI

ただしMVPでは最適化を急がず、
すべての重要なCIが確実に実行される構成を優先する。

---

## 11. Path Filter利用時の注意

Required Status CheckとPath Filterを組み合わせる場合は、
WorkflowがSkipされた場合のStatusを考慮する。

Required Checkが実行されないことで
Pull RequestがMerge待ちになる構成を避ける。

そのためMVPでは、

- Workflowを不用意にSkipしない
- Required Check名を安定させる
- Path FilterはCIが安定してから導入する

ことを基本方針とする。

---

## 12. Required Status Checks

main BranchではCI成功をMerge条件とする。

Required Check候補：

- frontend-ci
- backend-ci
- openapi-ci
- e2e-ci

ただしE2Eについては実行時間を確認したうえで、
Requiredにするか決定する。

MVPの第一候補：

### Required

- Frontend CI
- Backend CI
- OpenAPI CI

### 検討

- E2E CI

---

## 13. Branch Protection / Rulesets

main Branchを保護する。

基本方針：

- Pull Request経由で変更する
- Required Status Checksを設定する
- CI成功をMerge条件とする
- 必要に応じてCode Reviewを必須にする
- Force Pushを原則許可しない
- Branch削除を原則許可しない

具体的にはGitHub Rulesetsの利用を第一候補とする。

---

## 14. main Branch

main Branchは常に、

    Build可能
    +
    Test成功
    +
    Deploy可能

な状態を維持することを目標とする。

通常の開発作業をmain Branchへ直接Commitしない。

---

## 15. Pull Request

すべての機能開発は原則Pull Request経由とする。

基本フロー：

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

---

## 16. Branch Strategy

MVPでは複雑なGit Flowを採用しない。

基本：

    main
      │
      ├── feature/...
      ├── fix/...
      └── chore/...

長期間維持するdevelop Branchは原則設けない。

---

## 17. CI Jobの並列化

可能なJobは並列実行する。

例：

           Pull Request
                |
      ┌─────────┼─────────┐
      ↓         ↓         ↓
    Frontend  Backend   OpenAPI
      │         │         │
      └─────────┼─────────┘
                ↓
               E2E

FrontendとBackendを直列実行する必要はない。

---

## 18. PostgreSQL Test Service

Backend CIではTest用PostgreSQLを使用する。

GitHub Actions上でPostgreSQL Serviceを起動する。

用途：

- Migration
- Laravel Feature Test
- Database Constraint Test

Production / Development Databaseは利用しない。

---

## 19. Dependency Cache

CI実行時間短縮のため、
GitHub ActionsのCache機能を必要に応じて利用する。

対象：

### Frontend

- npm Dependency Cache

### Backend

- Composer Dependency Cache

MVPでは正確性を優先し、
必要になってから最適化する。

---

## 20. Secrets

以下をGit RepositoryへCommitしない。

- Auth.js Secret
- Laravel APP_KEY
- Database Password
- Production Credential
- Deployment Credential
- その他Secret

必要なSecretはGitHubのSecret管理機能等を利用する。

---

## 21. Permissions

GitHub Actions Workflowへ不要な権限を与えない。

可能な限り最小権限とする。

例：

    contents: read

WorkflowがWrite権限を必要とする場合のみ追加する。

---

## 22. Action Version

GitHub Actionsで利用する外部Actionについては
Versionを明示する。

依存するActionを無条件に最新版へ追従させない。

更新時はRelease Note等を確認する。

---

## 23. CD

CDについても将来的にGitHub Actionsを第一候補とする。

ただしDeployment先が未決定のため、
現時点では具体的なWorkflowを設計しない。

将来：

    main
      ↓
    GitHub Actions
      ↓
    Build
      ↓
    Staging
      ↓
    Production

を検討する。

---

## 24. Cloud認証

将来的にAWS / Azure / Google Cloud等へDeployする場合は、
可能であればGitHub ActionsのOIDCを利用する。

長期間有効なCloud Access Keyを
GitHub Secretへ保存する方式をできるだけ避ける。

具体的な方式はDeployment先決定後に設計する。

---

## 25. Complexity

Frontend：

    ESLint complexity

Backend：

    PHPMD

MVPでは複雑度の計測結果を監視する。

複雑度Threshold超過のみを理由に
CI Failureとすることは原則行わない。

---

## 26. CI結果

Pull RequestではGitHub上から以下を確認できる状態とする。

- Frontend CI結果
- Backend CI結果
- OpenAPI CI結果
- E2E結果
- Test Failure
- Static Analysis Error
- Build Error

CI結果をPull Request Reviewの判断材料とする。

---

## 27. 決定事項

### Repository

GitHubを利用する。

### CI Platform

GitHub Actionsを採用する。

### Workflow

Frontend / Backend / OpenAPI / E2Eを分離する。

### main Branch

Branch Protection / Rulesetsで保護する。

### Merge

Required Status Checks成功をMerge条件とする。

### Branch Strategy

main + 短命なFeature Branchを基本とする。

### CD

Deployment先決定後にGitHub Actionsを利用して設計する。

### 基本方針

- Pull Request中心で開発する
- mainへの直接変更を避ける
- CIをMVPから導入する
- CI設定もRepositoryでVersion管理する
- 必要以上にWorkflowを複雑化しない
