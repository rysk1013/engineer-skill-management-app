# Backend 技術・Library選定 - Static Analysis・Code Quality

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend におけるStatic Analysis / Code Quality方針と採用技術を定義する。

対象：

- Static Analysis
- Laravel固有型解析
- Formatting
- Coding Style
- Complexity
- Code Smell
- Architecture Dependency Rule
- Automated Refactoring
- Dead Code
- Duplication
- Type Safety
- Quality Gate
- Composer Scripts
- CI連携
- Git Hookとの関係

本Projectでは、

> 1つのToolですべてを解決しようとせず、各Toolの責務を明確に分離する

ことを基本方針とする。

---

## 2. 全体方針

Backend Code Qualityは以下の役割分担とする。

```text
PHPStan + Larastan
    → Static Analysis / Type Safety

Laravel Pint
    → Formatting / Coding Style

PHPMD
    → Complexity / Code Smell

Pest Architecture Test
    → Architecture Dependency Rule

Rector
    → Automated Refactoring / Upgrade Support
```

各Toolの責務を重複させすぎない。

---

## 3. Quality Model

以下の観点を分離して管理する。

```text
Type Correctness
    → PHPStan / Larastan

Formatting
    → Laravel Pint

Maintainability
    → PHPMD

Architecture Integrity
    → Pest Architecture Test

Automated Modernization
    → Rector

Behavior Correctness
    → Pest Test Suite
```

---

# PHPStan / Larastan

## 4. PHPStan

PHP Static Analysisの中心としてPHPStanを採用する。

役割：

```text
Type Error
Nullable Access
Incorrect Return Type
Invalid Argument
Undefined Property / Method
Unreachable / Impossible Type
```

等の検出。

---

## 5. Larastan

Laravel固有のStatic Analysis ExtensionとしてLarastanを採用する。

```text
PHPStan
    +
Larastan
```

をBackend Static Analysisの標準構成とする。

---

## 6. Larastanの役割

Laravelでは以下のようなFramework固有要素が存在する。

```text
Eloquent
Relation
Collection
Service Container
Facade
Model Scope
Builder
Magic Property / Method
```

LarastanによってこれらをPHPStanから解析可能にする。

---

## 7. PHPStan Level

新規Projectのため高いAnalysis Levelを採用する。

方針：

```text
Initial
    → Level 9

早期安定後
    → Level 10
```

最終目標をLevel 10とする。

---

## 8. Levelを段階導入する理由

最初から大量のIgnoreを作ってLevel 10を形式的に達成することは避ける。

優先：

```text
High Level
    ↓
実際のError修正
    ↓
必要なType改善
    ↓
Level 10
```

とする。

---

## 9. PHPStan Baseline

新規ProjectではPHPStan Baselineを原則利用しない。

Baselineは主に、

```text
Legacy Project
既存大量Error
段階移行
```

のための仕組みとして扱う。

---

## 10. Baseline利用条件

以下のような例外的な場合のみ検討する。

```text
Large Legacy Import
一時的Migration
Third-party由来の大量Issue
```

通常開発では、

```text
Static Analysis Error
    → 修正
```

を基本とする。

---

## 11. Ignore Error

以下を大量利用しない。

```php
// @phpstan-ignore-next-line
```

または広すぎるGlobal Ignore Regex。

優先順位：

```text
1. Codeを修正
2. Native Typeを改善
3. PHPDocを改善
4. Larastan / PHPStan設定を確認
5. NarrowなIgnore
```

とする。

---

## 12. Ignore理由

Ignoreが必要な場合は、

```text
対象を限定
理由を明確化
可能ならIssue / TODOを残す
```

ことを原則とする。

---

# Native Type / PHPDoc

## 13. Native Type優先

PHP 8.5の型Systemを積極的に利用する。

優先順位：

```text
Native Type
    ↓
PHPDoc
```

とする。

---

## 14. Native Type対象

可能な限り以下を明示する。

```text
Parameter Type
Return Type
Property Type
Union Type
Nullable Type
Enum
readonly
```

---

## 15. PHPDocの用途

PHPDocはNative PHPだけでは十分表現できない型へ利用する。

例：

```text
Generic
Collection Type
Array Shape
Template
Complex Iterable Type
```

---

## 16. PHPDocをRuntime型の代替にしない

以下のような構成を避ける。

```php
/** @var string */
private $name;
```

可能なら、

```php
private string $name;
```

とする。

---

# mixed

## 17. `mixed`

`mixed`を安易に利用しない。

特に、

```text
Domain
Application
```

では極力排除する。

---

## 18. Boundaryでのmixed

HTTP / Framework / External Data Boundaryでは完全排除できない場合がある。

その場合も、

```text
Boundary Input
    ↓
Validation
    ↓
Typed Primitive
    ↓
Enum / Value Object / DTO
```

のように早い段階で型を確定する。

---

# Array

## 19. Complex ArrayをDomain Modelにしない

Business Dataを長期間、

```text
array<string, mixed>
```

で持ち回らない。

以下へ変換する。

```text
Command
Query
DTO
Read Model
Value Object
```

---

## 20. Array Shape

Array Shapeは以下のような限定されたBoundaryで利用できる。

```text
Framework Boundary
Infrastructure Adapter
Short-lived Mapping Data
```

Domain Modelの代替にしない。

---

# strict_types

## 21. strict_types

Project PHP Codeでは既存方針通り、

```php
declare(strict_types=1);
```

をDefaultとする。

---

## 22. strict_typesの位置付け

`strict_types`だけでType Safetyを完成させるのではなく、

```text
PHP Language Types
+
PHPStan
+
Larastan
+
Test
```

を組み合わせる。

---

# Laravel Pint

## 23. Formatter

Code FormatterとしてLaravel Pintを採用する。

```text
Laravel Pint
    → Formatting / Coding Style
```

---

## 24. PHP CS Fixer

PHP CS Fixerを直接Project Toolとして採用しない。

Laravel PintがPHP CS Fixerを内部利用しているため、

```text
Pint
+
PHP CS Fixer直接設定
```

という二重管理を避ける。

---

## 25. Pint Configuration

`pint.json`で設定を管理する。

初期Preset：

```json
{
  "preset": "laravel"
}
```

を基本とする。

---

## 26. Custom Rule

Project固有Ruleは必要最小限とする。

```text
Laravel Default
    ↓
必要な追加Ruleのみ
```

とし、大量の独自Coding Standardを作らない。

---

## 27. Local Formatting

Localでは、

```bash
./vendor/bin/pint
```

で自動修正する。

---

## 28. CI Formatting

CIでは、

```bash
./vendor/bin/pint --test
```

によってFormatting違反を検出する。

違反時はCI Failureとする。

---

## 29. Dirty Files

開発中は必要に応じ、

```bash
./vendor/bin/pint --dirty
```

等を利用し、変更Fileのみ高速に処理する。

---

## 30. Pintの責務

Pintは以下を担当する。

```text
Whitespace
Import Formatting
Brace
Spacing
Coding Style
```

---

## 31. Pintが担当しないもの

以下はPintの責務ではない。

```text
Type Safety
Business Correctness
Complexity
Architecture Dependency
```

それぞれ専用Toolへ委譲する。

---

# PHPStanとPint

## 32. 責務分離

```text
Pint
    → Code Style

PHPStan
    → Code Correctness / Type
```

として明確に分ける。

同じProblemを複数Toolで無理に検出しない。

---

# PHPMD

## 33. PHPMD

Maintainability / Complexity / Code Smell検出にPHPMDを採用する。

---

## 34. PHPMDの役割

主に以下を確認する。

```text
Cyclomatic Complexity
NPath Complexity
Method Length
Class Complexity
Code Smell
Unused Code
```

---

## 35. PHPStanとの違い

```text
PHPStan
    → 型的に正しいか

PHPMD
    → Maintainability上複雑すぎないか
```

とする。

---

## 36. Type CorrectでもComplexなCode

例えば、

```text
Nested if
Nested loop
巨大Method
巨大Class
複雑なBranch
```

はPHPStanでは問題にならなくてもPHPMDで検出できる。

---

## 37. PHPMD Ruleset

Project用Rulesetを作成する。

候補：

```text
cleancode
codesize
design
unusedcode
```

等。

全Ruleを無条件に有効化しない。

---

## 38. controversial Rules

`controversial`等については、

```text
ValueがあるRule
    → Enable

False Positive / Project不適合
    → Disable
```

とし、Project用Rulesetで明示する。

---

## 39. Complexity Monitoring

特に以下を継続監視する。

```text
Cyclomatic Complexity
NPath Complexity
Method Length
Class Complexity
```

---

## 40. Complexity Threshold

開始時点ではPHPMDの標準的なThresholdを基準にする。

根拠なく細かいProject独自Thresholdを大量に作らない。

---

## 41. Threshold調整

実際のCodebaseを見ながら、

```text
False Positive
Review Experience
Codebase Size
Domain Complexity
```

を基準に後から調整する。

---

## 42. Complexity Warning

Complexity Warningは単なる数値Violationではなく、

> 責務配置が間違っていないか確認するSignal

として扱う。

---

# LayerごとのComplexity

## 43. Controller

Single Action Controller方針のためControllerはSimpleであるべき。

基本：

```text
Request
    ↓
Command / Query
    ↓
Handler
    ↓
Resource
```

---

## 44. Controller Warning

ControllerでComplexity Warningが頻発する場合、

```text
Business Logic
Application Logic
Validation Logic
```

がPresentationへLeakしていないか確認する。

---

## 45. Application Handler

HandlerはUseCase Orchestrationへ限定する。

基本：

```text
Load
Validate Application State
Invoke Domain
Persist
Audit
Return
```

---

## 46. Handler Warning

大量の、

```text
if
else
switch
nested branch
```

がHandlerに増えた場合、Business RuleをDomainへ移せないか検討する。

---

## 47. Domain

Domain Complexityは単純な数値だけでは判断しない。

Business Ruleとして自然なComplexityも存在する。

ただし巨大Aggregate / Domain ServiceはDesign Review対象とする。

---

# Rector

## 48. Rector

Automated Refactoring / Code Modernization ToolとしてRectorを採用する。

---

## 49. Rectorの用途

主な用途：

```text
PHP Version Upgrade
Language Modernization
Framework Upgrade補助
Safe Refactoring
Mechanical Code Transformation
```

---

## 50. Rectorの位置付け

日常必須Quality Gateとは少し役割を分ける。

```text
Pint
    → 常時

PHPStan / Larastan
    → 常時

PHPMD
    → 常時

Rector
    → Refactoring / Upgrade中心
```

---

## 51. Rector Configuration

`rector.php`でProject採用Ruleを明示する。

大量のRule Setを無検証で有効化しない。

---

## 52. Rector Rule

優先：

```text
PHP Version対応
安全性の高いCode Quality Rule
ProjectでReview済みRule
```

とする。

---

## 53. Rector Diff Review

Rectorによる自動変更も通常Code ChangeとしてReviewする。

```text
Rector
    ↓
Git Diff
    ↓
Review
    ↓
Test / Analysis
```

を必須とする。

---

## 54. Rector Dry Run

必要に応じCIで、

```bash
./vendor/bin/rector process --dry-run
```

を実行できる。

---

## 55. Rector Quality Gate

MVP初期ではRector Dry Runを必須Quality Gateにしなくてもよい。

ProjectのRector Ruleが安定した段階でRequired Checkへ昇格できる。

---

# Architecture Quality

## 56. Pest Architecture Test

`12_Test.md`で決定済みのPest Architecture TestをArchitecture Ruleの中心として利用する。

---

## 57. Architecture Rule例

```text
Domain
    → Illuminate依存禁止

Domain
    → Infrastructure依存禁止

Application
    → Eloquent依存禁止

Application
    → Presentation依存禁止
```

---

## 58. Architecture RuleとStatic Analysis

Architecture TestはPHPStanの代替ではない。

```text
PHPStan
    → Type Dependency / Correctness

Pest Architecture
    → Project Architecture Rule
```

とする。

---

# Deptrac

## 59. Deptrac

MVPではDeptracを採用しない。

---

## 60. 不採用理由

既に、

```text
Pest Architecture Test
```

を採用しており、現在必要なLayer Ruleについては十分表現可能なため。

---

## 61. Tool重複を避ける

以下のように同じRuleを複数Toolで大量管理することを避ける。

```text
Pest Architecture
+
Deptrac
+
独自Script
```

---

## 62. Deptrac再検討条件

以下の段階で再検討する。

```text
Bounded Context増加
Module Dependency複雑化
Dependency Graphの厳格管理
Layer Ruleの大幅増加
```

Project規模が大きくなった場合の将来候補とする。

---

# Duplication

## 63. Copy / Paste Detector

MVPでは専用Copy / Paste Detectorを採用しない。

---

## 64. Duplicationの確認

以下でまず対応する。

```text
Code Review
PHPMD
IDE
Refactoring
```

Tool追加ありきにしない。

---

## 65. DRY

DRYを目的化しない。

多少のDuplicationより、

```text
Wrong Abstraction
```

を避けることを優先する。

---

## 66. Generic Abstraction

以下のような抽象化をDuplication削減だけを理由に作らない。

```text
GenericCrudService
GenericRepository
BaseHandler
BaseDomainService
```

Domain Meaningを優先する。

---

# Dead Code

## 67. Dead Code

Dead Code Detectionは、

```text
PHPStan
Rector
IDE
Code Review
```

を中心に対応する。

専用Dead Code ToolはMVPでは追加しない。

---

## 68. Dead Code削除

未使用Codeを、

```text
将来使うかもしれない
```

という理由だけで残さない。

Git Historyを利用できるため不要Codeは削除する。

---

# final

## 69. `final`

継承を意図していないClassは`final`を基本候補とする。

特に：

```text
Command
Query
Handler
Mapper
DTO
Value Object
```

と相性がよい。

---

## 70. finalを強制しすぎない

すべてのClassへ機械的に`final`を付与するRuleまでは設けない。

Design Intentを基準に判断する。

---

# readonly

## 71. readonly

Immutable Data Carrierでは`readonly`を積極的に利用する。

候補：

```text
Command
Query
DTO
Value Object
一部Read Model
```

---

## 72. final readonly

特にImmutable DTO等では、

```php
final readonly class
```

を基本形として利用する。

---

# Error Suppression

## 73. Error Suppression Operator

PHPのError Suppression Operator：

```php
@
```

は原則使用しない。

---

## 74. 例外

Library / Legacy API等で回避困難な場合のみ使用を許容する。

その場合、

```text
理由
Failure Handling
代替手段がないこと
```

をCode Reviewで確認する。

---

# Dynamic Behavior

## 75. Dynamic Property

Dynamic Propertyを前提としたCodeを書かない。

Propertyを明示する。

---

## 76. Magic

Domain / Applicationでは、

```text
Magic Property
Dynamic Method
Reflection-based Behavior
```

への依存を極力避ける。

---

## 77. Laravel Magic

Infrastructure / PresentationではLaravel Framework上必要なMagicを許容する。

型解析はLarastanで補助する。

---

# Quality Gate

## 78. Pull Request Quality Gate

Pull Requestでは原則以下を実行する。

```text
Pint
PHPStan + Larastan
PHPMD
Pest Architecture Test
Pest Test Suite
OpenAPI Contract Test
```

---

## 79. Failure Policy

原則：

```text
Pint Violation
    → CI Fail

PHPStan Error
    → CI Fail

PHPMD Violation
    → CI Fail

Architecture Violation
    → CI Fail

Test Failure
    → CI Fail

Contract Test Failure
    → CI Fail
```

---

## 80. Warning放置

大量のWarningを許容して形骸化させない。

Issueは、

```text
修正
設定調整
明示的な限定Ignore
```

のいずれかで処理する。

---

# Fast Fail

## 81. CI実行順

Fast Feedbackを考慮し、概念的には以下を推奨する。

```text
1. Pint --test

2. PHPStan / Larastan

3. PHPMD

4. Architecture Test

5. Unit Test

6. Integration Test

7. Feature Test

8. Contract Test
```

---

## 82. Parallel Execution

独立可能なJobはCI上でParallel実行してよい。

具体的なWorkflowは`16_CI・Automation.md`で定義する。

---

# Composer Scripts

## 83. Tool Commandの統一

Developerが各Toolの細かいCommandを毎回覚える必要がないようComposer Scriptsを利用する。

---

## 84. Script候補

概念：

```text
composer format
composer lint
composer analyse
composer quality
composer test
```

---

## 85. `composer format`

概念：

```text
composer format
    ↓
Pint
```

Auto Fix用途。

---

## 86. `composer lint`

概念：

```text
composer lint
    ↓
Pint --test
```

Formatting Check用途。

---

## 87. `composer analyse`

概念：

```text
composer analyse
    ↓
PHPStan / Larastan
```

Static Analysis用途。

---

## 88. `composer quality`

概念：

```text
composer quality
    ↓
Pint --test
PHPStan / Larastan
PHPMD
Architecture Test
```

Local / CIで共通利用できるEntry Pointとする。

---

## 89. Script詳細

最終的なComposer Scripts構成やLocal Developer Workflowは`14_Developer-Experience.md`で整理する。

---

# Local Development

## 90. Fast Feedback

Local開発ではFull Quality Suiteだけでなく変更対象に絞ったCommandを利用できるようにする。

例：

```text
Pint --dirty
Targeted Pest Test
PHPStan
```

---

## 91. Save時Format

EditorでPint相当のFormatをSave時に実行してもよい。

ただしDeveloper Environmentへ強制しすぎない。

CIを最終Quality Gateとする。

---

# Git Hooks

## 92. Git Hook

Git HookはDeveloper Feedback高速化のため利用可能とする。

候補：

```text
Pint
PHPStan
Targeted Test
```

---

## 93. Git HookをSource of Truthにしない

Git HookはSkip可能なため、

```text
Git Hook
    → Developer Convenience

CI
    → Required Quality Gate
```

とする。

---

## 94. Hook詳細

Git Hook Toolや実行範囲については`14_Developer-Experience.md`で決定する。

---

# Testとの関係

## 95. Static AnalysisとTest

Static Analysisが通ることとBusiness Correctnessは別である。

```text
Static Analysis
    → 型・Code Structure

Test
    → Behavior
```

両方必要。

---

## 96. TestでStatic Analysisを代替しない

例えばNullable Type Errorを、

```text
Testが通っているから問題なし
```

とはしない。

PHPStan Errorとして修正する。

---

## 97. Static AnalysisでTestを代替しない

逆に、

```text
PHPStanが通る
    → Business Ruleも正しい
```

とは考えない。

Domain / Application Testを維持する。

---

# Architectureとの関係

## 98. Domain

Domainでは特に以下を重視する。

```text
strict_types
Native Types
readonly
final
PHPStan
Pest Architecture
PHPMD
```

Framework-independentな強いType Safetyを目指す。

---

## 99. Application

Applicationでは、

```text
Typed Command / Query
Typed Handler
Typed Port
No Eloquent Leak
Low Complexity
```

をQuality Goalとする。

---

## 100. Presentation

PresentationではLaravel固有Codeを許容するが、

```text
Thin Controller
Typed Conversion
No Business Rule
```

を維持する。

---

## 101. Infrastructure

InfrastructureではLaravel / Eloquent / External Library依存を許容する。

ただし、

```text
Domain Interface実装
Mapper Boundary
Type Safety
```

を明確に保つ。

---

# Tool Adoption

## 102. 採用技術一覧

| Tool / 技術 | 判断 |
|---|---|
| PHPStan | 採用 |
| Larastan | 採用 |
| PHPStan Level 9 | 初期採用 |
| PHPStan Level 10 | 最終目標 |
| PHPStan Baseline | 原則不採用 |
| Narrow Ignore | 必要時のみ |
| Laravel Pint | 採用 |
| Laravel preset | 採用 |
| PHP CS Fixer直接利用 | 不採用 |
| PHPMD | 採用 |
| Custom PHPMD Ruleset | 採用 |
| Rector | 採用 |
| Rector CI Dry Run | 段階導入 |
| Pest Architecture Test | 採用済み |
| Deptrac | MVP不採用 |
| Copy / Paste専用Tool | MVP不採用 |
| Dead Code専用Tool | MVP不採用 |
| Infection | 将来候補 |
| `strict_types=1` | 採用 |
| Native Type優先 | 採用 |
| `mixed`最小化 | 採用 |
| Error Suppression `@` | 原則禁止 |
| Dynamic Property | 不採用 |

---

# Tool Responsibility

## 103. Responsibility Matrix

| Concern | Tool |
|---|---|
| PHP Type Safety | PHPStan |
| Laravel Type Analysis | Larastan |
| Formatting | Pint |
| Coding Style | Pint |
| Complexity | PHPMD |
| Code Smell | PHPMD |
| Layer Dependency | Pest Architecture |
| Framework Leak | Pest Architecture |
| Automated Refactoring | Rector |
| Version Upgrade | Rector |
| Business Behavior | Pest |
| API Contract | OpenAPI Contract Test |

---

# CI Quality Pipeline

## 104. 最終Pipeline

```text
Source Code
    ↓
Pint
    ↓
PHPStan + Larastan
    ↓
PHPMD
    ↓
Pest Architecture
    ↓
Pest Tests
    ↓
OpenAPI Contract Tests
    ↓
Mergeable
```

---

## 105. Rector

Rectorは通常Pipelineとは少し分離し、

```text
Refactoring / Upgrade
    ↓
Rector
    ↓
Diff Review
    ↓
Quality Pipeline
```

とする。

安定後にDry RunをQuality Gateへ追加可能とする。

---

# 最終方針

## 106. Static Analysis

Backend Static Analysisは、

```text
PHPStan
+
Larastan
```

を中心とする。

新規ProjectであるためBaselineへ依存せず、最終的にPHPStan Level 10を目標とする。

---

## 107. Formatting

FormattingはLaravel Pintへ統一する。

```text
Laravel Pint
    → Project Formatter
```

とし、PHP CS Fixerを直接二重管理しない。

---

## 108. Maintainability

Complexity / Code SmellはPHPMDで監視する。

特に、

```text
Controller
Application Handler
Domain Service
Mapper
```

等の責務肥大化を検出する補助として利用する。

---

## 109. Architecture

Architecture DependencyはPest Architecture Testで保証する。

現時点ではDeptracを追加しない。

---

## 110. Automated Refactoring

Rectorを、

```text
PHP Upgrade
Laravel Upgrade
Code Modernization
Mechanical Refactoring
```

の補助Toolとして採用する。

日常Formatting / Static Analysisとは責務を分離する。

---

## 111. 最終構成

Backend Code Qualityの標準構成を以下とする。

```text
PHPStan + Larastan
    → Type Safety

Laravel Pint
    → Formatting

PHPMD
    → Complexity / Maintainability

Pest Architecture Test
    → Architecture Integrity

Rector
    → Automated Evolution

Pest
    → Behavior Verification

OpenAPI Contract Test
    → API Contract Verification
```

---

## 112. 最重要原則

本Projectでは、

> Tool数を増やすこと自体をQuality向上と考えない

ことを原則とする。

各Toolには明確な責務を持たせ、

```text
Type
Style
Complexity
Architecture
Behavior
Contract
```

をそれぞれ適切なToolで検証する。

最終的に、

```text
Format
    ↓
Static Analysis
    ↓
Complexity
    ↓
Architecture
    ↓
Tests
    ↓
Contract
```

というQuality Pipelineを継続的に実行し、Clean Architecture / DDDをCodebase上でも維持する。
