# Backend 技術・Library選定 - Developer Experience

## 1. 目的

本ドキュメントでは、Engineer Skill Management App のBackendを中心としたDeveloper Experience（DX）の技術・運用方針を定義する。

対象：

- Local Development Environment
- Docker Compose
- Command Interface
- Makefile
- Composer Scripts
- Database Operation
- Development Seed
- Xdebug
- Editor Integration
- Git Hooks
- Local Quality Workflow
- Environment Variables
- Logging / Debugging
- Documentation
- Generated Artifacts
- Tool Version Management

本Projectでは、

> 開発者がInfrastructureやTool固有Commandを毎回意識せず、少数の安定したCommandで日常開発できる状態

を目標とする。

---

# 2. 基本方針

Developer Experienceは以下のFlowをSimpleにする。

```text
Clone
  ↓
Setup
  ↓
Start
  ↓
Develop
  ↓
Test
  ↓
Quality Check
  ↓
Stop
```

代表的な操作を、

```bash
make setup
make up
make test
make quality
make check
make down
```

程度で実行できる状態を目標とする。

---

# 3. Command Architecture

Project全体のCommand構造を以下とする。

```text
Repository Root
    ↓
Makefile
    → Project全体 / Docker操作

Backend
    ↓
Composer Scripts
    → PHP / Laravel固有操作

Frontend / BFF
    ↓
package.json Scripts
    → Next.js / TypeScript固有操作

Runtime
    ↓
Docker Compose
```

責務を明確に分離する。

---

# Makefile

## 4. Root Command Interface

Repository RootのDeveloper向けCommand InterfaceとしてMakefileを採用する。

例：

```bash
make setup
make up
make down
make logs
make test
make quality
make check
```

開発者が長いDocker Compose Commandを毎回入力する必要をなくす。

---

## 5. Makefileの役割

Makefileは、

```text
Human-friendly Command
    ↓
Docker Compose
    ↓
Composer / package.json Scripts
```

を接続するFacadeとして利用する。

Build SystemやApplication Logicとして利用しない。

---

## 6. MakefileへComplex Logicを書かない

Make TargetはSimpleに保つ。

概念：

```makefile
test:
	docker compose exec backend composer test
```

程度を基本とする。

以下を大量に埋め込まない。

```text
複雑なShell Script
Business Logic
大量のEnvironment判定
Deployment Logic
```

複雑になった場合は責務を専用Scriptへ分離する。

---

## 7. Make採用理由

候補：

```text
Make
Task
just
Custom Shell Script
```

のうち、MVPではMakeを採用する。

理由：

```text
追加Runtimeがほぼ不要
macOS / Linuxで利用しやすい
Docker Composeとの相性が良い
CIでも利用可能
Command Facadeとして十分
```

---

# Backend Composer Scripts

## 8. Composer Scripts

Backend固有CommandはComposer Scriptsへ集約する。

候補：

```text
composer test
composer test:unit
composer test:integration
composer test:feature
composer test:contract

composer format
composer lint
composer analyse
composer complexity
composer architecture

composer quality
composer check
```

---

## 9. `composer format`

Auto Formatting：

```text
composer format
    ↓
Laravel Pint
```

とする。

---

## 10. `composer lint`

Formatting Check：

```text
composer lint
    ↓
Pint --test
```

とする。

---

## 11. `composer analyse`

Static Analysis：

```text
composer analyse
    ↓
PHPStan + Larastan
```

とする。

---

## 12. `composer complexity`

Complexity / Code Smell：

```text
composer complexity
    ↓
PHPMD
```

とする。

---

## 13. `composer architecture`

Architecture Rule：

```text
composer architecture
    ↓
Pest Architecture Test
```

とする。

---

## 14. `composer quality`

Static Quality Checkをまとめる。

```text
composer quality
    ↓
Pint --test
PHPStan + Larastan
PHPMD
Architecture Test
```

Test Suite全体とは分離する。

---

## 15. `composer test`

Behavior / Integration / Contract Testをまとめる。

概念：

```text
composer test
    ↓
Unit
Application
Integration
Feature
Contract
```

必要に応じ個別Suiteも実行可能とする。

---

## 16. `composer check`

Pull Request前のBackend総合Checkとする。

```text
composer check
    ↓
composer quality
    ↓
composer test
```

Backendについて、

> 迷ったら`composer check`

で確認できる状態を作る。

---

# Root Commands

## 17. Make Target

Root Makefileでは以下を基本候補とする。

```text
make setup

make up
make down
make restart
make ps
make logs

make backend-shell
make frontend-shell
make db-shell

make migrate
make seed

make test
make quality
make check

make clean
make reset
```

実際に必要になったTargetのみ追加する。

---

## 18. Commandを増やしすぎない

すべてのCLI CommandへMake Targetを作らない。

```text
頻繁に利用するWorkflow
    → Make Target

特殊なOperation
    → Container Shell / Native Tool Command
```

とする。

---

# Setup

## 19. `make setup`

初回Local Setupを可能な限り自動化する。

概念：

```text
make setup
    ↓
Local Environment準備
    ↓
Docker Build
    ↓
Container Start
    ↓
Backend Dependency Install
    ↓
Frontend Dependency Install
    ↓
Application Setup
    ↓
Migration
    ↓
Development Seed
```

---

## 20. Setup Idempotency

`make setup`は可能な限りIdempotentにする。

```text
1回目
    → Setup

2回目
    → 壊れない
```

初回しか動かないMagic Scriptにしない。

---

## 21. Secret

Setup ScriptへProduction Secretを埋め込まない。

Local Development用のSafe ValueとProduction Secret Managementを分離する。

---

# Docker

## 22. Docker Compose

Local Development Environmentの基準としてDocker Composeを採用する。

対象：

```text
Frontend / BFF
Backend
PostgreSQL
```

必要になった場合：

```text
Redis
Queue Worker
Scheduler
OpenTelemetry Collector
Local Mail Server
```

等を追加する。

---

## 23. Host Dependency

Host Machineへ必須とするToolをできるだけ減らす。

基本：

```text
Docker
Docker Compose
Git
Make
Editor
```

程度を目標とする。

---

## 24. Host Runtime

以下をHostへ直接InstallすることをProject Requirementにしない。

```text
PHP
Composer
PostgreSQL
Node.js
```

Runtime VersionをDockerで統一する。

---

# Laravel Sail

## 25. Laravel Sail

Laravel Sailは採用しない。

理由：

本ProjectはLaravel単体ではなく、

```text
Next.js BFF
Laravel Backend
PostgreSQL
Observability
Worker / Scheduler候補
```

を含むmonorepo全体をDockerで管理するため。

---

## 26. Docker Composeを直接管理

```text
Laravel Sail
    → 不採用

Project Docker Compose
    → 採用
```

とする。

Infrastructure全体をRepository Rootから確認できる構成を優先する。

---

# Docker Service

## 27. Service Naming

Docker Compose Service名を安定させる。

例：

```yaml
services:
  frontend:
  backend:
  postgres:
```

将来：

```yaml
  redis:
  worker:
  scheduler:
  otel-collector:
```

等を追加できる。

---

## 28. Container Nameへ依存しない

避ける：

```bash
docker exec engineer-skill-management-backend-1 ...
```

推奨：

```bash
docker compose exec backend ...
```

Container NameをDeveloper Interfaceにしない。

---

# Shell

## 29. Backend Shell

```bash
make backend-shell
```

を用意する。

内部では、

```bash
docker compose exec backend sh
```

等を実行する。

---

## 30. Frontend Shell

同様に、

```bash
make frontend-shell
```

を用意できる。

Frontend / BFF Containerへ入るための共通入口とする。

---

## 31. CLI Wrapper

頻繁に利用する場合のみ、

```bash
make artisan ARGS="route:list"
```

```bash
make composer ARGS="..."
```

等のWrapperを追加できる。

すべてのCLIをMakefileで包まない。

---

# Database

## 32. Migration

```bash
make migrate
```

を標準Migration Commandとする。

内部：

```text
Docker Compose
    ↓
Backend
    ↓
php artisan migrate
```

---

## 33. Development Seed

Local Development用Seederを用意する。

候補：

```text
Administrator
Manager
SubManager
TeamLeader

Department
Employee

SkillCategory
Skill
EmployeeSkill

Assignment
```

Frontend / Backend双方が代表Scenarioをすぐ確認できる状態を作る。

---

## 34. Deterministic Seed

重要なDevelopment Dataは再現可能にする。

例えば：

```text
Representative Administrator
Representative Roles
Skill Categories
Representative Skills
Representative Employee Skills
```

すべてをRandom Fakerへ依存させない。

---

## 35. Development SeederとTest Factory

以下を分離する。

```text
Development Seeder
    → 人間がLocal Applicationを操作するData

Test Factory
    → Automated Test用Data
```

Automated TestをDevelopment Seederへ依存させない。

---

# Database Reset

## 36. `db-fresh`

必要に応じLocal専用Command：

```bash
make db-fresh
```

を用意する。

概念：

```text
migrate:fresh
    ↓
Development Seed
```

とする。

---

## 37. Production禁止

`migrate:fresh`等の破壊的CommandをProduction / Stagingの通常Operationとして利用しない。

Local Development専用とする。

---

# Database Shell

## 38. `make db-shell`

PostgreSQL CLIへ簡単にアクセスできるよう、

```bash
make db-shell
```

を用意する。

内部では`psql`を利用する。

---

## 39. DB GUI

Database GUI ToolはProjectで固定しない。

Developerは、

```text
pgAdmin
DBeaver
DataGrip
その他PostgreSQL Client
```

等を自由に選択できる。

Project RequirementはPostgreSQLへ接続できることのみとする。

---

# Xdebug

## 40. Xdebug

Local DevelopmentのStep Debugging ToolとしてXdebugを採用する。

用途：

```text
Breakpoint
Step Debugging
Variable Inspection
Stack Inspection
CLI Debugging
Test Debugging
```

---

## 41. Environment

XdebugはDevelopment Environmentでのみ利用する。

```text
Development
    → Xdebugあり

Production
    → Xdebugなし
```

Production Runtime Imageへ含めない。

---

## 42. Trigger Mode

Xdebugは常時接続ではなくTrigger方式を採用する。

```ini
xdebug.start_with_request=trigger
```

必要なRequest / CLIだけDebugする。

---

## 43. Xdebug Port

Xdebug 3の標準Port：

```text
9003
```

を利用する。

特別な理由がない限り変更しない。

---

## 44. Debug Flow

```text
Browser / CLI
    ↓
XDEBUG_TRIGGER
    ↓
Backend Container
    ↓
Xdebug
    ↓
Host Editor / IDE
```

とする。

---

## 45. CLI Debug

Artisan / Pest等もDebug可能にする。

概念：

```bash
XDEBUG_TRIGGER=1 php artisan ...
```

```bash
XDEBUG_TRIGGER=1 ./vendor/bin/pest ...
```

Container Environmentに合わせて利用する。

---

## 46. Xdebug Configuration

Host接続情報などはDevelopment Infrastructure側で管理する。

Application / Domain CodeへEditor固有設定を持ち込まない。

---

# Editor

## 47. Editor非依存

Project標準Editorを固定しない。

利用可能：

```text
Neovim
VS Code
Zed
PhpStorm
その他
```

Developerが選択できる。

---

## 48. `.editorconfig`

Repository Rootに、

```text
.editorconfig
```

を配置する。

統一候補：

```text
UTF-8
LF
Final Newline
Indent
Trailing Whitespace
```

---

## 49. PHP Formatting

PHPの詳細なFormattingは`.editorconfig`ではなくLaravel PintをSource of Truthとする。

```text
.editorconfig
    → 基本Editor設定

Pint
    → PHP Coding Style
```

---

## 50. Editor固有設定

`.vscode/`等をRepositoryへCommitする場合は、Project全体へBenefitがある設定のみとする。

個人PreferenceはVersion Controlしない。

---

# Local Development Workflow

## 51. 開発中

通常Flow：

```text
Code
    ↓
Format
    ↓
Target Test
    ↓
Static Analysis
```

Fast Feedbackを優先する。

---

## 52. Format

変更中は必要に応じ、

```bash
./vendor/bin/pint --dirty
```

等で変更FileだけFormatする。

---

## 53. Target Test

変更対象のDomain / Handler / Feature Testだけを高速に実行できる状態を維持する。

毎回Full Integration Testを要求しない。

---

# Pull Request前

## 54. Backend

Backendのみなら、

```bash
composer check
```

で、

```text
Static Quality
+
Tests
```

を確認する。

---

## 55. Repository全体

Project全体では、

```bash
make check
```

を最終Local Checkとする。

概念：

```text
make check
    ↓
Backend Check
Frontend Check
OpenAPI Check
必要なCross-system Check
```

---

# Git Hooks

## 56. Git Hooks

Git HooksをDeveloper Feedback高速化の補助として採用する。

ただしCIの代替にはしない。

---

## 57. Pre-commit

Pre-commitでは軽量処理のみを候補とする。

例：

```text
Formatting
Changed Files Check
```

Commitのたびに重いIntegration Testを実行しない。

---

## 58. Pre-push

必要に応じ、

```text
Static Analysis
Unit Test
Architecture Test
```

程度をPre-pushで実行できる。

Developer Productivityを著しく下げる場合は減らす。

---

## 59. HookをQuality Gateにしない

```text
Git Hook
    → Fast Local Feedback

CI
    → Authoritative Quality Gate
```

とする。

HookをSkipしてもCIで必ず検出する。

---

## 60. Hook Management

`.git/hooks`へDeveloperが手動Copyする運用を避ける。

Hook Scriptを利用する場合はRepositoryでVersion Control可能な形にする。

---

## 61. Hook Framework

MVPではGit Hook専用Frameworkを新たな必須Dependencyとして導入しない。

理由：

```text
monorepo
Frontend
Backend
```

を横断するため、まずはSimpleなRepository管理Script / Setupで十分だからである。

必要性が高まった場合に再検討する。

---

# Logs

## 62. Local Logs

```bash
make logs
```

でProject全体のContainer Logを確認できるようにする。

必要に応じ、

```bash
make backend-logs
make frontend-logs
```

を追加する。

---

## 63. stdout / stderr

Local DevelopmentでもContainerの、

```text
stdout
stderr
```

を基本的なLog確認経路とする。

ProductionのStructured Logging方針とも大きく乖離させない。

---

# Telescope

## 64. Laravel Telescope

Laravel TelescopeはMVP必須Toolとして採用しない。

```text
Laravel Telescope
    → 将来候補
```

とする。

---

## 65. Telescope再検討条件

以下がDeveloper Productivity上必要になった場合に再検討する。

```text
Request Inspection
Query Inspection
Exception Inspection
Job Inspection
Cache Inspection
```

Xdebug / Structured Log / DB ToolだけではDebug効率が低い場合に導入を検討する。

---

# Debugbar

## 66. Laravel Debugbar

Laravel Debugbarは採用しない。

今回の構成：

```text
Browser
    ↓
Next.js
    ↓
BFF
    ↓
Laravel API
```

では、Laravel Server-rendered ApplicationほどBenefitが大きくないため。

---

# External Services

## 67. Local External Service

Local Developmentから本物のExternal Serviceへ不用意に接続しない。

```text
Fake
Stub
Local Emulator
Sandbox
```

を優先する。

---

## 68. Local Mail

Email機能を導入した場合は、

```text
Mailpit
```

等のLocal SMTP Toolを候補とする。

Email機能が必要になるまではDependencyとして追加しない。

---

# Environment Variables

## 69. `.env.example`

`.env.example`をVersion Controlする。

含める：

```text
Variable Name
Safe Local Default
Required Empty Value
必要なComment
```

Secretそのものを含めない。

---

## 70. Configuration Change

Environment Variableを追加・変更した場合、

```text
Code
+
.env.example
```

を同じPull Requestで更新する。

---

## 71. Local Default

可能な範囲でSafe Local Defaultを用意する。

例：

```env
DB_HOST=postgres
```

初回Setupで大量の手入力を要求しない。

---

## 72. Fail Fast

必須Configuration不足は可能な限り早期に検出する。

```text
Missing Configuration
    ↓
Startup / Initialization時にFailure
```

とし、Runtime途中で原因不明のFailureになることを避ける。

---

## 73. Environment Validation Library

Environment Validationだけを目的に専用Libraryを追加しない。

Laravel標準Configurationと必要最小限のValidationで対応する。

---

# Documentation

## 74. Root README

Repository Root READMEにはDeveloperが日常必要とする情報を記載する。

最低限：

```text
Prerequisites
Setup
Start
Stop
Test
Quality Check
Database
Debug
Troubleshooting
```

---

## 75. Stable CommandをDocumentationする

READMEでは、

```bash
make setup
make up
make check
make down
```

等のStable Developer Interfaceを中心に説明する。

長い内部Docker Commandを主要Documentationにしない。

---

## 76. Internal Command変更

内部実装が、

```text
Pint
PHPStan
Docker Compose Option
```

等で変更されても、

```bash
make check
```

のようなDeveloper Interfaceは可能な限り維持する。

---

# Troubleshooting

## 77. Troubleshooting対象

頻出ProblemのみDocumentation化する。

候補：

```text
Docker Port Conflict
Container Startup Failure
PostgreSQL Connection Failure
Migration Failure
Dependency Installation Failure
Xdebug Connection Failure
Volume Reset
File Permission
```

---

## 78. Documentationを増やしすぎない

一度しか起きていない特殊ProblemをすべてREADMEへ追加しない。

頻度・影響が高いProblemを中心にする。

---

# Clean / Reset

## 79. `make clean`

Safe Cleanup用Commandとする。

対象候補：

```text
Temporary Files
Generated Cache
Coverage Artifact
Local Build Artifact
```

---

## 80. CleanでDBを削除しない

`make clean`によってDatabase Volume等のPersistent Development Dataを削除しない。

---

## 81. `make reset`

破壊的Resetは別Commandへ分離する。

```bash
make reset
```

例：

```text
Container Stop
Volume Remove
Environment再構築
Migration
Seed
```

---

## 82. Destructive Operation

破壊的Commandは名前から危険性が分かるようにする。

必要に応じConfirmationを設ける。

---

# Generated Artifacts

## 83. Generated File

Generated Artifactは手動操作ではなくCommandから生成する。

候補：

```text
OpenAPI Generated Client / Types
Coverage Report
Static Analysis Cache
Frontend API Client
```

---

## 84. OpenAPI Workflow

OpenAPI First方針に従う。

```text
OpenAPI変更
    ↓
Validation
    ↓
必要なCode / Type生成
    ↓
Backend / Frontend Check
```

生成手順をScript化する。

---

## 85. Generated ArtifactのVersion Control

Generated FileをGitへCommitするかどうかはArtifactごとに決定する。

ただし、

> 生成方法は必ず再現可能

とする。

---

# Version Management

## 86. Composer

Backend Dependency Versionは、

```text
composer.json
composer.lock
```

で管理する。

`composer.lock`をVersion Controlする。

---

## 87. Frontend

Frontend DependencyもPackage ManagerのLockfileで固定する。

---

## 88. Docker

Docker Image Versionを明示する。

避ける：

```text
php:latest
postgres:latest
```

---

## 89. Version Consistency

Local / CI / Staging / Productionで可能な限り同じMajor / Minor Runtimeを利用する。

特にPHP / PostgreSQLは既存のVersion Policyに従う。

---

# Host Independence

## 90. OS

Local Developmentは主に、

```text
macOS
Linux
```

で動作可能な構成を目標とする。

---

## 91. OS固有Command

Makefile / ScriptへmacOS固有Commandを不用意に埋め込まない。

必要な場合は明示的に分離する。

---

# CPU Architecture

## 92. Multi Architecture

Docker Imageは可能な限り、

```text
arm64
amd64
```

双方に対応したものを利用する。

---

## 93. Apple Silicon

Apple Siliconで不要なEmulationを発生させない。

理由なく、

```yaml
platform: linux/amd64
```

へ固定しない。

---

# File Permissions

## 94. Container Generated Files

Docker Containerから生成したFileをHostで正常に編集できるようにする。

対象：

```text
Composer Generated Files
Artisan Generated Files
OpenAPI Generated Files
Frontend Generated Files
```

---

## 95. UID / GID

必要に応じDevelopment ContainerのUID / GIDを調整する。

Host側でRoot所有Fileが大量生成される構成を避ける。

---

# Local CI

## 96. Local CI相当Command

CIで実行する主要Quality CheckをLocalからも実行可能にする。

```bash
make check
```

をLocal CI相当の入口とする。

---

## 97. Local / CI共通Script

可能な限り、

```text
Local
    ↓
Composer / package Scripts

CI
    ↓
同じComposer / package Scripts
```

を利用する。

CI専用に同じQuality Logicを再実装しない。

---

# Source of Truth

## 98. Command Source of Truth

責務を以下とする。

```text
Makefile
    → Human / Repository Workflow

Docker Compose
    → Local Runtime Environment

composer.json
    → Backend Tool Workflow

package.json
    → Frontend Tool Workflow

CI Configuration
    → Automation / Required Gate
```

---

# 採用技術

## 99. Adoption Matrix

| 項目 | 決定 |
|---|---|
| Root Command Interface | Makefile |
| Backend Command Interface | Composer Scripts |
| Frontend Command Interface | package.json Scripts |
| Local Runtime | Docker Compose |
| Laravel Sail | 不採用 |
| Host PHP | 必須にしない |
| Host Composer | 必須にしない |
| Host Node.js | 必須にしない |
| Host PostgreSQL | 必須にしない |
| `.editorconfig` | 採用 |
| Editor固定 | しない |
| Development Seeder | 採用 |
| Test Factory | Seederと分離 |
| Xdebug | Developmentで採用 |
| Xdebug Trigger Mode | 採用 |
| Xdebug Port | 9003 |
| Production Xdebug | 不採用 |
| Git Hooks | 補助として採用 |
| Hook専用Framework | MVPでは不採用 |
| CI | Authoritative Quality Gate |
| Laravel Telescope | MVP不採用・将来候補 |
| Laravel Debugbar | 不採用 |
| `.env.example` | 必須 |
| DB CLI | `make db-shell` |
| DB GUI | Developer自由 |
| Docker Version固定 | 採用 |
| Multi-arch Image | 優先 |
| Local CI Command | `make check` |

---

# Recommended Commands

## 100. Initial Setup

```bash
make setup
```

---

## 101. Daily Operation

```bash
make up
make down
make restart
make ps
make logs
```

---

## 102. Development

```bash
make backend-shell
make frontend-shell
make db-shell
make migrate
make seed
```

---

## 103. Quality

```bash
make test
make quality
make check
```

Backend内部：

```bash
composer format
composer lint
composer analyse
composer complexity
composer architecture
composer test
composer quality
composer check
```

---

## 104. Maintenance

```bash
make clean
make reset
```

`reset`は破壊的Operationとして扱う。

---

# Final Developer Workflow

## 105. Initial

```text
git clone
    ↓
make setup
    ↓
Application Ready
```

---

## 106. Daily Start

```text
make up
    ↓
Frontend / BFF
Backend
PostgreSQL
    ↓
Development
```

---

## 107. Development Loop

```text
Code
    ↓
Format
    ↓
Target Test
    ↓
Static Analysis
    ↓
Debug if needed
```

---

## 108. Pull Request前

```text
make check
    ↓
Backend Quality
Backend Tests
Frontend Quality
Frontend Tests
OpenAPI / Contract
    ↓
Ready for PR
```

---

## 109. CI

```text
Push / Pull Request
    ↓
CI
    ↓
同じProject Scripts
    ↓
Required Quality Gate
```

Git HookやLocal CheckをSkipしてもCIが最終的に保証する。

---

# 最終Architecture

## 110. Command Layer

```text
Developer
    ↓
Makefile
    ↓
┌─────────────────────────────┐
│                             │
▼                             ▼
Docker Compose          Project Scripts
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
               Composer             package.json
               Backend              Frontend/BFF
```

---

## 111. Development Environment

```text
Host
├── Docker
├── Git
├── Make
└── Editor
      │
      ▼
Docker Compose
├── frontend
├── backend
└── postgres
```

必要になった場合のみ、

```text
redis
worker
scheduler
otel-collector
mail
```

を追加する。

---

## 112. Debug

```text
Request / CLI
    ↓
XDEBUG_TRIGGER
    ↓
Backend Container
    ↓
Xdebug :9003
    ↓
Host Editor
```

XdebugはDevelopment限定とする。

---

## 113. Quality

```text
Developer
    ↓
make check
    ↓
Backend
│   ├── Pint
│   ├── PHPStan / Larastan
│   ├── PHPMD
│   ├── Architecture Test
│   └── Pest / Contract Test
│
└── Frontend / BFF
    └── Frontend側Quality Pipeline
```

---

# 114. 最終方針

Developer Experienceでは、

> 開発者向けInterfaceと内部Toolを分離し、日常操作を少数の安定したCommandへ集約する

ことを中心方針とする。

Project全体では、

```text
Makefile
    → Developer Interface

Docker Compose
    → Runtime Environment

Composer Scripts
    → Backend Tooling

package.json Scripts
    → Frontend / BFF Tooling
```

という責務分離を採用する。

Local RuntimeはDockerへ統一し、

```text
Host Runtime差異
PHP Version差異
PostgreSQL Version差異
Node.js Version差異
```

を可能な限り排除する。

Backend DebugにはDevelopment限定のXdebugを採用し、Trigger方式によって必要なRequest / CLIのみStep Debuggingする。

Git HooksはFast Feedbackの補助として利用するが、

```text
Git Hooks
    → Convenience

make check
    → Local Final Check

CI
    → Authoritative Quality Gate
```

という役割分担を維持する。

Laravel Sail / Debugbar / Telescope / Git Hook専用Framework等は、現時点で明確な必要性がないためMVP必須Dependencyにはしない。

最終的に、

```text
Simple Setup
+
Stable Commands
+
Docker Reproducibility
+
Fast Local Feedback
+
Local / CI Shared Workflow
```

をDeveloper Experienceの基本構成として採用する。
