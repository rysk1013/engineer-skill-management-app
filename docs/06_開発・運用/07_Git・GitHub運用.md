# Git・GitHub運用

Engineer Skill Management AppにおけるGit / GitHubの運用方針を定義する。

本プロジェクトでは、Frontend / Backend / Documentation / Backlogを同一Repositoryで管理し、Pull Requestを中心とした開発フローを採用する。

Task管理およびTask単位の開発フローについては[`06_タスク管理・開発フロー.md`](./06_タスク管理・開発フロー.md)を参照する。

---

## 1. 基本方針

GitHub上にRemote Repositoryを作成し、以下を同一Repositoryで管理する。

- Frontend / BFF
- Backend API
- Documentation
- Backlog
- CI / CD設定
- 開発環境設定

基本方針は以下とする。

- `main`を安定Branchとする
- `dev`を開発統合Branchとする
- 通常のWork Branchは`dev`から作成する
- 通常運用では`main` / `dev`へ直接Commit・Pushしない
- Pull Requestを経由してMergeする
- CIが利用可能な場合は、必要なCIが成功してからMergeする
- Merge前にSelf Reviewを行う
- Commit MessageはConventional Commitsを基本とする
- DocumentationもApplication Codeと同じGit Repositoryで管理する
- TaskとBranch / Pull Requestの対応関係を追跡可能にする
- `main` / `dev`へのForce Pushは禁止する
- GitHub Issues / ProjectsはMVPでは使用しない

---

## 2. Branch Strategy

### 2.1 Branch構成

基本的なBranch構成は以下とする。

```text id="0kqdm4"
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

`main`と`dev`をLong-lived Branchとし、それ以外をShort-lived Branchとする。

MVPでは以下は導入しない。

- `release/*`
- `hotfix/*`

必要になった段階で追加を検討する。

---

### 2.2 `main`

`main`はProductionへRelease可能な安定状態を管理するBranchとする。

原則として以下のフローで更新する。

```text id="b5m0g3"
dev
 ↓
Pull Request
 ↓
main
```

`main`への直接Commit / Pushは行わない。

Force Pushは禁止する。

---

### 2.3 `dev`

`dev`は開発内容を統合するBranchとする。

通常のWork Branchは`dev`から作成し、以下のフローで統合する。

```text id="9fclq1"
dev
 ↓
Work Branch
 ↓
Pull Request
 ↓
dev
```

`dev`への直接Commit / Pushは通常運用では行わない。

Force Pushは禁止する。

---

### 2.4 Work Branch

用途に応じて以下のPrefixを使用する。

| Prefix | 用途 |
|---|---|
| `feature/` | 機能追加 |
| `fix/` | Bug修正 |
| `refactor/` | Refactoring |
| `docs/` | Documentation |
| `test/` | Test追加・修正 |
| `chore/` | 設定・Tooling・Maintenance |

Taskに対応するWork Branchは以下の形式とする。

```text id="od4ezs"
<type>/<task-id>-<short-description>
```

例：

```text id="2pnn3n"
feature/task-12-create-employee
fix/task-18-skill-validation
refactor/task-24-employee-repository
docs/task-30-update-openapi
test/task-35-employee-api
chore/task-40-setup-docker
```

`<task-id>`にはBacklog.mdが採番したTask IDを使用し、Branch名ではlowercaseへ変換する。

例：

```text id="4n51q5"
TASK-12
   ↓
task-12
```

Taskに紐付かない小規模な変更ではTask IDを省略できる。

例：

```text id="x2g3mq"
docs/update-readme
chore/update-gitignore
```

Branch名は以下を基本とする。

- lowercase
- 数字
- hyphen

Work BranchはMerge後に削除する。

GitHubでは`Automatically delete head branches`を有効にする。

---

## 3. Commit Message

Commit MessageはConventional Commitsを基本とする。

基本形式：

```text id="y0egvf"
<type>(<scope>): <description>
```

`scope`は任意とする。

---

### 3.1 Type

以下のTypeを使用する。

| Type | 用途 |
|---|---|
| `feat` | 機能追加 |
| `fix` | Bug修正 |
| `docs` | Documentation |
| `refactor` | Refactoring |
| `test` | Test |
| `chore` | Maintenance / Tooling |
| `ci` | CI / CD |
| `build` | Build System / Dependency |
| `perf` | Performance改善 |
| `style` | 動作に影響しないFormatting |

---

### 3.2 Description

Descriptionは以下を基本とする。

- English
- lowercaseから開始
- 簡潔に変更内容を表す
- 原則として末尾にPeriodを付けない

例：

```text id="e6l90f"
feat(employee): add employee creation handler
fix(skill): validate experience period
docs(openapi): define employee creation API
test(employee): add employee creation test
chore(docker): add development containers
```

以下のような意図が分からないCommit Messageは避ける。

```text id="0cl0yd"
fix
update
change
work
wip
```

---

### 3.3 Commit Granularity

基本方針は以下とする。

```text id="ajk5hz"
1 Commit = 1 Logical Change
```

1 Taskを1 Commitにまとめる必要はない。

Task内でも、意味のある変更単位でCommitを分割する。

例：

```text id="9w7hpl"
docs(openapi): define employee creation API
feat(employee): add employee creation handler
feat(employee): add employee creation endpoint
test(employee): add employee creation test
```

一方、内部実装の細かな操作単位で過度にCommitを分割することも避ける。

Taskとの関連は主に、

```text id="7bt8fj"
Backlog.md Task
      ↓
Work Branch
      ↓
Pull Request
```

によって管理するため、すべてのCommit MessageへTask IDを含めることは要求しない。

---

### 3.4 Breaking Change

Breaking Changeが発生する場合はConventional Commitsの形式を使用する。

例：

```text id="44tnxn"
feat(api)!: change employee response format
```

必要に応じてCommit Bodyへ記載する。

```text id="n8e30a"
BREAKING CHANGE: employee response structure has changed
```

---

## 4. Taskとの連携

開発TaskはBacklog.mdで管理する。

Task管理、Status、Milestone、Acceptance Criteria、Definition of Done、Implementation Planなどの運用については[`06_タスク管理・開発フロー.md`](./06_タスク管理・開発フロー.md)をSource of Truthとする。

Git / GitHubでは原則として以下の対応関係とする。

```text id="xxnmfb"
1 Task
  ≒
1 Work Branch
  ≒
1 Pull Request
```

基本的なトレーサビリティは以下とする。

```text id="e95b8r"
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

Work BranchおよびPull RequestにはBacklog.mdが採番したTask IDを使用する。

Taskに紐付かないDocumentation修正やRepository Maintenanceなど、小規模な変更についてはTask作成を必須としない。

---

## 5. Pull Request

### 5.1 PR Flow

通常の開発では以下のフローとする。

```text id="0m32qo"
Work Branch
    ↓
Pull Request
    ↓
dev
```

`main`への反映は以下とする。

```text id="evh9sc"
dev
 ↓
Pull Request
 ↓
main
```

Taskに対応する開発では原則として、

```text id="sp3cf5"
1 Task
  ↓
1 Work Branch
  ↓
1 Pull Request
```

とする。

Taskの性質上この対応が不自然な場合は、無理に1対1へ合わせない。

---

### 5.2 PR Title

Taskに対応するPull RequestではBacklog.mdのTask IDを含める。

形式：

```text id="et2z54"
<TASK-ID> <Summary>
```

例：

```text id="9twhl5"
TASK-12 Add employee creation API
```

Taskに紐付かない変更ではTask IDを省略し、変更内容を簡潔に記載する。

---

### 5.3 PR Body

基本Templateは以下とする。

```markdown id="bb9hr1"
## Summary

<!-- 何を変更したか -->

## Changes

-

## Testing

- [ ] Tests pass
- [ ] CI passes

## Related Task

TASK-xxx
```

Taskに紐付かない場合は`Related Task`を省略できる。

必要以上に長いTemplateにはしない。

設計仕様やImplementation Plan全体をPull Requestへ複製せず、必要に応じてBacklog.md Taskや`docs/`を参照する。

---

### 5.4 Self Review

Merge前にSelf Reviewを行う。

主に以下を確認する。

- Task Scope外の変更が含まれていない
- 関係のない変更が含まれていない
- 既存の設計方針と矛盾していない
- Namingが適切である
- 必要なTestが存在する
- Test・Lint・Static Analysisなど必要な品質確認が成功している
- API変更がある場合、OpenAPIと実装が一致している
- 不要なDebug Codeや一時ファイルが残っていない
- Commit Historyが後から理解できる
- 必要なDocumentationが更新されている

個人開発のため、MVPではRequired Approvalは設定しない。

---

### 5.5 Merge Strategy

Work Branchから`dev`へのMerge：

```text id="gmwaz5"
Merge Commit
```

`dev`から`main`へのMerge：

```text id="m8bjg2"
Merge Commit
```

を基本とする。

MVPでは以下を使用しない。

- Squash Merge
- Rebase Merge

Logical Commitの履歴を保持し、

```text id="s7pf11"
Task
 ↓
Work Branch
 ↓
Logical Commits
 ↓
Pull Request
 ↓
Merge Commit
```

という開発履歴を追跡できるようにする。

---

### 5.6 Commit History Cleanup

Pull Request作成前またはMerge前にCommit Historyを確認する。

以下のような一時Commitが多数存在する場合、

```text id="x3x0e7"
wip
fix typo
fix again
temp
```

必要に応じてInteractive Rebaseで整理する。

ただし、Interactive Rebaseを必須運用にはしない。

RemoteへPush済みのWork BranchでHistoryを書き換えた場合は、

```bash id="5oqm0y"
git push --force-with-lease
```

を使用する。

通常の`--force`は使用しない。

`main` / `dev`ではHistory RewriteおよびForce Pushを行わない。

---

## 6. GitHub Repository Settings

### 6.1 Repository

MVP開始時点では以下とする。

```text id="8sqd4n"
Visibility: Private
Default Branch: main
Development Branch: dev
```

必要になった場合はPublicへの変更を検討する。

---

### 6.2 Merge Settings

GitHub Repositoryでは以下を設定する。

```text id="yz71x9"
Allow merge commits                 ON
Allow squash merging                OFF
Allow rebase merging                OFF
Automatically delete head branches ON
```

Merge方法をMerge Commitへ統一し、Repository上でも不要なMerge方式を無効化する。

---

### 6.3 Rulesets

`main`および`dev`を保護する。

#### `main`

基本設定：

- Pull Request required
- Force Push prohibited
- Branch deletion prohibited
- CI構築後はRequired Status Checksを設定する

#### `dev`

基本設定：

- Pull Request required
- Force Push prohibited
- Branch deletion prohibited
- CI構築後はRequired Status Checksを設定する

個人開発のためRequired Approvalは設定しない。

CI Workflow構築前はRequired Status Checksを無理に設定せず、Workflow作成後に追加する。

想定するRequired Check：

```text id="fnopz4"
Frontend CI
Backend CI
OpenAPI CI
```

実際のCheck名はGitHub Actions Workflow構築後の名称を使用する。

---

### 6.4 GitHub Features

MVPでは以下をTask管理には使用しない。

```text id="w76g3k"
GitHub Issues
GitHub Projects
```

Task管理はBacklog.mdへ集約する。

GitHub ActionsはCI / CDで使用する。

Pull RequestはCode ReviewおよびMergeの単位として使用する。

---

## 7. Git関連ファイル

Repository Rootでは以下のGit関連ファイルを管理する。

```text id="e78htq"
engineer-skill-management-app/
├── .editorconfig
├── .gitattributes
├── .gitignore
├── README.md
├── backlog/
├── backend/
├── docs/
└── frontend/
```

---

### 7.1 `.gitignore`

Repository共通の不要ファイル・秘密情報を除外する。

主な対象：

- OS生成ファイル
- Environment Variable
- Dependency
- Build Artifact
- Cache
- Log
- Coverage
- Temporary File

Frontend / Backend生成時には、それぞれの公式Templateが生成する`.gitignore`も確認する。

Application固有の除外設定は必要に応じて各Application側で管理する。

`archive/`は意図的に保持するProject Documentationであるため、一律にGit管理対象外とはしない。

---

### 7.2 `.gitattributes`

Text Fileの改行コードをLFへ統一する。

基本設定：

```gitattributes id="d7u5dg"
* text=auto eol=lf
```

画像やArchiveなどのBinary Fileは必要に応じてBinaryとして扱う。

---

### 7.3 `.editorconfig`

Editor間で以下の基本設定を統一する。

- UTF-8
- LF
- Indentation
- Final Newline
- Trailing Whitespace

Formattingの詳細は各ApplicationのFormatterへ委譲する。

```text id="s5fmr5"
Frontend → Prettier
Backend  → Laravel Pint
```

`.editorconfig`ではEditor間の基本的な差異のみを吸収し、Formatterと責務を重複させない。

---

### 7.4 Environment Variables

秘密情報を含む`.env`はGit管理しない。

Environment VariableのTemplateはApplication構築後に以下のように管理する。

```text id="9w1byd"
frontend/.env.example
backend/.env.example
```

`.env.example`には秘密情報の実値を含めない。

---

### 7.5 `.github/`

GitHub固有の設定は`.github/`で管理する。

想定構成：

```text id="pmq1y7"
.github/
├── pull_request_template.md
└── workflows/
    ├── frontend-ci.yml
    ├── backend-ci.yml
    └── openapi-ci.yml
```

Pull Request運用開始までにPR Templateを追加する。

CI Workflowについては開発環境およびCI構成が確定した段階で追加する。

CI / CDの詳細な方針については[`03_CICD方針.md`](./03_CICD方針.md)を参照する。

---

## 8. Future Extensions

MVPではGit / GitHub運用を必要以上に複雑化しない。

必要になった段階で以下を検討する。

- `release/*`
- `hotfix/*`
- GitHub Release
- Semantic Versioning
- CHANGELOG
- Automated Release
- CODEOWNERS
- Required Review
- Multiple Reviewer
- Release Automation

導入する場合は、実際に発生した運用上の課題やRelease要件をもとに判断する。
