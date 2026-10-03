# Backend 技術・Library選定 - Static Analysis・Code Quality

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend におけるStatic Analysis / Code Quality方針と採用技術を定義する。

対象：

- Static Analysis
- Laravel固有型解析
- Formatting
- Coding Style
- Complexity
- Maintainability
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

CleanCode + PHP_CodeSniffer
    → Complexity / Maintainability / Code Smell

Pest Architecture Test
    → Architecture Dependency Rule

Rector
    → Automated Refactoring / Upgrade Support
```

各Toolの責務を重複させすぎない。

また、Quality Checkを以下の2種類へ分離する。

```text
Blocking
    → Merge可否を判断するQuality Gate

Monitoring
    → Refactoringや設計ReviewのSignal
```

Complexity / MaintainabilityはMonitoringとして扱い、単一の数値Violationのみを理由としてMergeを禁止しない。

---

## 3. Quality Model

以下の観点を分離して管理する。

```text
Type Correctness
    → PHPStan / Larastan

Formatting
    → Laravel Pint

Maintainability
    → CleanCode + PHP_CodeSniffer

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

基本Configuration：

```json
{
  "preset": "laravel",
  "rules": {
    "declare_strict_types": {
      "strategy": "enforce"
    }
  }
}
```

Laravel Presetを基本とし、Project固有Ruleは必要最小限に追加する。

`declare_strict_types` Ruleによって、Project PHP Codeでは以下を強制する。

```php
declare(strict_types=1);
```

未定義の場合はPint実行時に追加し、既存の `strict_types` 宣言についても `1` へ統一する。

これにより、`strict_types` の付与をDeveloperの手作業に依存させない。

---

## 26. Custom Rule

Project固有Ruleは必要最小限とする。

```text
Laravel Default
    ↓
必要な追加Ruleのみ
```

とし、大量の独自Coding Standardを作らない。

現時点では、Project全体のType Safety方針を自動適用するため、以下を追加する。

```text
declare_strict_types
    → enforce
```

Coding Style上の好みだけを理由としてCustom Ruleを増やさない。

---

## 27. Local Formatting

Localでは、

```bash
composer format
```

を標準Commandとする。

内部ではLaravel Pintを実行する。

---

## 28. CI Formatting

Formatting Checkでは、

```bash
composer lint
```

を利用する。

内部では、

```bash
./vendor/bin/pint --test
```

を実行する。

Formatting違反はBlockingとし、CI Failureとする。

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
strict_types宣言の統一
```

`strict_types` についてはType SafetyそのものをPintが検証するのではなく、

```php
declare(strict_types=1);
```

がProject PHP Codeへ一貫して付与されている状態を自動的に維持する。

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

# CleanCode / PHP_CodeSniffer

## 33. CleanCode

Maintainability / Complexity / Code Smell監視にCleanCodeを採用する。

CleanCodeはPHP_CodeSniffer向けのCoding Standard / Custom Sniff群として利用する。

構成：

```text
PHP_CodeSniffer
    +
CleanCode
    +
Project Ruleset
```

Project Rulesetは、

```text
backend/phpcs.xml
```

で管理する。

---

## 34. 採用理由

当初はPHPMDを採用候補としていた。

しかし、現在のLaravel / Symfony依存関係ではStable版PHPMDの導入にDependency Conflictが発生する。

PHPMD 3系についても関連DependencyをDevelopment Versionへ依存させる必要があり、Phase 0時点の標準Toolとして採用しない。

代替候補としてPhpMetricsも検証したが、Complexity Metricsの可視化には適する一方、当初求めていた以下の責務を十分に満たさない。

```text
NPath Complexity
Code Smell
Unused Code
```

CleanCodeについて検証した結果、現在のBackend環境でDependency Conflictなく導入でき、必要なComplexity / Maintainability関連Sniffを選択して利用できることを確認した。

そのため、BackendのComplexity / Maintainability Monitoring ToolとしてCleanCode + PHP_CodeSnifferを採用する。

---

## 35. CleanCodeの役割

主に以下を確認する。

```text
Cyclomatic Complexity
NPath Complexity
Method Length
Class Complexity
Code Smell
Unused Code
```

ただし、CleanCode Standard全体を有効化するのではなく、Projectの目的に必要なSniffのみを選択する。

---

## 36. PHPStanとの違い

```text
PHPStan
    → 型的に正しいか

CleanCode
    → Maintainability上複雑すぎないか
      設計上Reviewすべき兆候がないか
```

とする。

---

## 37. Type CorrectでもComplexなCode

例えば、

```text
Nested if
Nested loop
巨大Method
巨大Class
複雑なBranch
```

はPHPStanでは問題にならなくても、Complexity / Maintainability上のReview対象となる。

CleanCodeをそのSignalとして利用する。

---

## 38. CleanCode Ruleset

Project用Rulesetとして、

```text
backend/phpcs.xml
```

を利用する。

初期構成：

```xml
<?xml version="1.0"?>
<ruleset name="EngineerSkillManagementApp">
    <description>
        Code complexity and maintainability monitoring rules for the backend.
    </description>

    <file>app</file>

    <rule ref="CleanCode.Metrics.CyclomaticComplexity"/>
    <rule ref="CleanCode.Metrics.NPathComplexity"/>
    <rule ref="CleanCode.Functions.ExcessiveMethodLength"/>
    <rule ref="CleanCode.Metrics.ExcessiveClassComplexity"/>
    <rule ref="CleanCode.Functions.DisallowBooleanArgumentFlag"/>
    <rule ref="CleanCode.DeadCode.UnusedFormalParameter"/>
    <rule ref="CleanCode.DeadCode.UnusedPrivateElements"/>
</ruleset>
```

---

## 39. Selective Rules

CleanCode Standard全体は利用しない。

CleanCodeにはProject ArchitectureやCoding Policyに対してOpinionatedなRuleも含まれるため、

```text
CleanCode Standard全体
    → 不採用

必要なSniff
    → 個別採用
```

とする。

特に以下のようなRuleを無条件に導入しない。

```text
Repository Class禁止
Static Member禁止
Conditional禁止
Else禁止
Test File必須
Namespace Naming制約
```

Project Architecture / DDD / Laravel方針と独立して、外部Toolの思想をそのままArchitecture Ruleとして採用しない。

---

## 40. Complexity Monitoring

以下を継続監視する。

```text
Cyclomatic Complexity
NPath Complexity
Method Length
Class Complexity
```

これらはCode Quality Gateではなく、Refactoringや責務分割を検討するためのMonitoring指標として扱う。

---

## 41. Cyclomatic Complexity

以下のSniffを利用する。

```text
CleanCode.Metrics.CyclomaticComplexity
```

初期ThresholdはCleanCodeのDefaultを利用する。

```text
Report Level
    → 10
```

Project独自Thresholdが必要になった場合は`phpcs.xml`で明示する。

---

## 42. NPath Complexity

以下のSniffを利用する。

```text
CleanCode.Metrics.NPathComplexity
```

初期Threshold：

```text
Minimum
    → 200
```

条件分岐の組み合わせによるExecution Pathの増大を検出するSignalとして利用する。

---

## 43. Method Length

以下のSniffを利用する。

```text
CleanCode.Functions.ExcessiveMethodLength
```

初期Threshold：

```text
Minimum
    → 100 lines
```

巨大Methodを検出し、責務分割を検討するSignalとして利用する。

---

## 44. Class Complexity

以下のSniffを利用する。

```text
CleanCode.Metrics.ExcessiveClassComplexity
```

初期Threshold：

```text
Maximum WMC
    → 50
```

Class内MethodのComplexityを基に、Class自体の責務肥大化を確認する。

---

## 45. Code Smell

初期Code Smell Ruleとして、

```text
CleanCode.Functions.DisallowBooleanArgumentFlag
```

を利用する。

Boolean Flagによって1つのMethodが複数のBehaviorを持っていないか確認するSignalとして扱う。

ただし、

```text
Boolean Argument
    = 必ずDesign Error
```

とは判断しない。

検出結果をReview対象として扱う。

---

## 46. Unused Code

以下を利用する。

```text
CleanCode.DeadCode.UnusedFormalParameter
CleanCode.DeadCode.UnusedPrivateElements
```

主に、

```text
Unused Parameter
Unused Private Property
Unused Private Method
```

を検出する。

ただし、これらだけでProject全体のDead Codeを完全に検出できるとは考えない。

PHPStan / IDE / Rector / Code Reviewと組み合わせる。

---

## 47. Complexity Threshold

開始時点ではCleanCodeのDefault Thresholdを基準にする。

```text
Cyclomatic Complexity
    → 10

NPath Complexity
    → 200

Method Length
    → 100

Class WMC
    → 50
```

根拠なく細かいProject独自Thresholdを大量に作らない。

---

## 48. Threshold調整

実際のCodebaseを見ながら、

```text
False Positive
Review Experience
Codebase Size
Domain Complexity
Monitoring Result
```

を基準に後から調整する。

Thresholdを変更する場合は、

```text
backend/phpcs.xml
```

で明示する。

---

## 49. Complexity Warning

Complexity Violationは単なる数値Violationではなく、

> 責務配置が間違っていないか確認するSignal

として扱う。

CleanCode / PHPCSがNon-zero Exit Codeを返す場合でも、Complexity Monitoring自体をMerge Blocking条件とはしない。

---

# LayerごとのComplexity

## 50. Controller

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

## 51. Controller Warning

ControllerでComplexity Warningが頻発する場合、

```text
Business Logic
Application Logic
Validation Logic
```

がPresentationへLeakしていないか確認する。

---

## 52. Application Handler

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

## 53. Handler Warning

大量の、

```text
if
else
switch
nested branch
```

がHandlerに増えた場合、Business RuleをDomainへ移せないか検討する。

---

## 54. Domain

Domain Complexityは単純な数値だけでは判断しない。

Business Ruleとして自然なComplexityも存在する。

ただし巨大Aggregate / Domain ServiceはDesign Review対象とする。

---

# Rector

## 55. Rector

Automated Refactoring / Code Modernization ToolとしてRectorを採用する。

---

## 56. Rectorの用途

主な用途：

```text
PHP Version Upgrade
Language Modernization
Framework Upgrade補助
Safe Refactoring
Mechanical Code Transformation
```

---

## 57. Rectorの位置付け

日常必須Quality Gateとは少し役割を分ける。

```text
Pint
    → 常時 / Blocking

PHPStan / Larastan
    → 常時 / Blocking

CleanCode
    → 常時利用可能 / Monitoring

Rector
    → Refactoring / Upgrade中心
```

---

## 58. Rector Configuration

`rector.php`でProject採用Ruleを明示する。

大量のRule Setを無検証で有効化しない。

---

## 59. Rector Rule

優先：

```text
PHP Version対応
安全性の高いCode Quality Rule
ProjectでReview済みRule
```

とする。

---

## 60. Rector Diff Review

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

## 61. Rector Dry Run

必要に応じCIで、

```bash
./vendor/bin/rector process --dry-run
```

を実行できる。

---

## 62. Rector Quality Gate

MVP初期ではRector Dry Runを必須Quality Gateにしなくてもよい。

ProjectのRector Ruleが安定した段階でRequired Checkへ昇格できる。

---

# Architecture Quality

## 63. Pest Architecture Test

`12_Test.md`で決定済みのPest Architecture TestをArchitecture Ruleの中心として利用する。

---

## 64. Architecture Rule例

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

## 65. Architecture RuleとStatic Analysis

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

## 66. Deptrac

MVPではDeptracを採用しない。

---

## 67. 不採用理由

既に、

```text
Pest Architecture Test
```

を採用しており、現在必要なLayer Ruleについては十分表現可能なため。

---

## 68. Tool重複を避ける

以下のように同じRuleを複数Toolで大量管理することを避ける。

```text
Pest Architecture
+
Deptrac
+
独自Script
```

---

## 69. Deptrac再検討条件

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

## 70. Copy / Paste Detector

MVPでは専用Copy / Paste Detectorを採用しない。

---

## 71. Duplicationの確認

以下でまず対応する。

```text
Code Review
IDE
Refactoring
```

CleanCodeをDuplication Detectorとしては扱わない。

Tool追加ありきにしない。

---

## 72. DRY

DRYを目的化しない。

多少のDuplicationより、

```text
Wrong Abstraction
```

を避けることを優先する。

---

## 73. Generic Abstraction

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

## 74. Dead Code

Dead Code Detectionは、

```text
PHPStan
CleanCode
Rector
IDE
Code Review
```

を組み合わせて対応する。

CleanCodeでは、

```text
Unused Formal Parameter
Unused Private Property
Unused Private Method
```

を補助的に監視する。

専用Dead Code ToolはMVPでは追加しない。

---

## 75. Dead Code削除

未使用Codeを、

```text
将来使うかもしれない
```

という理由だけで残さない。

Git Historyを利用できるため不要Codeは削除する。

---

# final

## 76. `final`

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

## 77. finalを強制しすぎない

すべてのClassへ機械的に`final`を付与するRuleまでは設けない。

Design Intentを基準に判断する。

---

# readonly

## 78. readonly

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

## 79. final readonly

特にImmutable DTO等では、

```php
final readonly class
```

を基本形として利用する。

---

# Error Suppression

## 80. Error Suppression Operator

PHPのError Suppression Operator：

```php
@
```

は原則使用しない。

---

## 81. 例外

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

## 82. Dynamic Property

Dynamic Propertyを前提としたCodeを書かない。

Propertyを明示する。

---

## 83. Magic

Domain / Applicationでは、

```text
Magic Property
Dynamic Method
Reflection-based Behavior
```

への依存を極力避ける。

---

## 84. Laravel Magic

Infrastructure / PresentationではLaravel Framework上必要なMagicを許容する。

型解析はLarastanで補助する。

---

# Quality Gate

## 85. Pull Request Quality Gate

Pull Requestでは原則以下のBlocking Checkを実行する。

```text
Pint
PHPStan + Larastan
Pest Architecture Test
Pest Test Suite
OpenAPI Contract Test
```

Complexity / Maintainabilityについては別途Monitoringする。

```text
CleanCode + PHP_CodeSniffer
    → Monitoring
```

---

## 86. Failure Policy

Blocking：

```text
Pint Violation
    → CI Fail

PHPStan Error
    → CI Fail

Architecture Violation
    → CI Fail

Test Failure
    → CI Fail

Contract Test Failure
    → CI Fail
```

Monitoring：

```text
CleanCode Violation
    → Report / Review Signal
    → Merge Blockingにはしない
```

---

## 87. Monitoring結果の放置

MonitoringをNon-blockingとすることは、結果を無視してよいことを意味しない。

継続的または重大なViolationは、

```text
Code Review
Refactoring
Threshold Review
Architecture Review
Issue化
```

等で対応する。

Monitoring結果が大量に常態化してSignalとして機能しなくなる状態を避ける。

---

# Fast Fail

## 88. CI実行順

Fast Feedbackを考慮し、Blocking Checkは概念的には以下を推奨する。

```text
1. Pint --test

2. PHPStan / Larastan

3. Architecture Test

4. Unit Test

5. Integration Test

6. Feature Test

7. Contract Test
```

Complexity MonitoringはBlocking Pipelineと分離して実行できる。

```text
CleanCode / PHPCS
    → Monitoring Job
```

具体的なCI構成はTASK-10および`16_CI・Automation.md`で定義する。

---

## 89. Parallel Execution

独立可能なJobはCI上でParallel実行してよい。

Blocking / Monitoringの責務を維持したうえで実行時間を短縮する。

---

# Composer Scripts

## 90. Tool Commandの統一

Developerが各Toolの細かいCommandを毎回覚える必要がないようComposer Scriptsを利用する。

---

## 91. 標準Command

Backendの標準Commandを以下とする。

```text
composer format
composer lint
composer analyse
composer complexity
composer quality
composer test
```

---

## 92. `composer format`

```text
composer format
    ↓
Laravel Pint
```

Auto Fix用途。

---

## 93. `composer lint`

```text
composer lint
    ↓
Pint --test
```

Formatting Check用途。

Blocking Checkとして扱う。

---

## 94. `composer analyse`

```text
composer analyse
    ↓
PHPStan + Larastan
```

Static Analysis用途。

Blocking Checkとして扱う。

---

## 95. `composer complexity`

```text
composer complexity
    ↓
PHP_CodeSniffer
    ↓
backend/phpcs.xml
    ↓
Selected CleanCode Sniffs
```

Complexity / Maintainability Monitoring用途。

ProjectのComposer Scriptでは、

```text
vendor/bin/phpcs
```

を実行し、`phpcs.xml`の`<file>app</file>`によってBackend Application Codeを対象とする。

---

## 96. `composer quality`

```text
composer quality
    ↓
composer lint
    ↓
composer analyse
```

BlockingなCode Quality CheckをまとめたEntry Pointとする。

`composer complexity`はMonitoringであるため、`composer quality`には含めない。

これにより、

```text
composer quality
    → Blocking

composer complexity
    → Monitoring
```

という責務をCommand Levelでも明確にする。

---

## 97. Test Commandとの分離

`composer quality`はCode Quality Checkに限定する。

Behavior Verificationは、

```bash
composer test
```

で実行する。

Architecture Testを含むTest Suiteの構成についてはBackend Test方針に従う。

---

# Local Development

## 98. Fast Feedback

Local開発ではFull Quality Suiteだけでなく変更対象に絞ったCommandを利用できるようにする。

例：

```text
Pint --dirty
Targeted Pest Test
PHPStan
CleanCode Monitoring
```

---

## 99. Local標準確認

BackendのCode Quality確認はProject RootからDocker経由で実行する。

Blocking：

```bash
docker compose exec backend composer quality
```

Monitoring：

```bash
docker compose exec backend composer complexity
```

必要に応じ個別に、

```bash
docker compose exec backend composer lint
docker compose exec backend composer analyse
```

も利用できる。

---

## 100. Save時Format

EditorでPint相当のFormatをSave時に実行してもよい。

ただしDeveloper Environmentへ強制しすぎない。

CIを最終Quality Gateとする。

---

# Git Hooks

## 101. Git Hook

Git HookはDeveloper Feedback高速化のため利用可能とする。

候補：

```text
Pint
PHPStan
Targeted Test
```

Complexity MonitoringをHookへ追加する場合も、Developer Experienceを著しく損なわない範囲とする。

---

## 102. Git HookをSource of Truthにしない

Git HookはSkip可能なため、

```text
Git Hook
    → Developer Convenience

CI
    → Required Quality Gate / Monitoring
```

とする。

---

## 103. Hook詳細

Git Hook Toolや実行範囲については`14_Developer-Experience.md`で決定する。

---

# Testとの関係

## 104. Static AnalysisとTest

Static Analysisが通ることとBusiness Correctnessは別である。

```text
Static Analysis
    → 型・Code Structure

Test
    → Behavior
```

両方必要。

---

## 105. TestでStatic Analysisを代替しない

例えばNullable Type Errorを、

```text
Testが通っているから問題なし
```

とはしない。

PHPStan Errorとして修正する。

---

## 106. Static AnalysisでTestを代替しない

逆に、

```text
PHPStanが通る
    → Business Ruleも正しい
```

とは考えない。

Domain / Application Testを維持する。

---

# Architectureとの関係

## 107. Domain

Domainでは特に以下を重視する。

```text
strict_types
Native Types
readonly
final
PHPStan
Pest Architecture
Complexity Monitoring
```

Framework-independentな強いType Safetyと明確なDomain Modelを目指す。

---

## 108. Application

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

## 109. Presentation

PresentationではLaravel固有Codeを許容するが、

```text
Thin Controller
Typed Conversion
No Business Rule
```

を維持する。

---

## 110. Infrastructure

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

## 111. 採用技術一覧

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
| PHP_CodeSniffer | CleanCode実行基盤として採用 |
| CleanCode | Complexity / Maintainability Monitoringとして採用 |
| CleanCode Standard全体 | 不採用 |
| Project `phpcs.xml` | 採用 |
| PHPMD | 不採用 |
| PhpMetrics | 不採用 |
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

## 112. Responsibility Matrix

| Concern | Tool |
|---|---|
| PHP Type Safety | PHPStan |
| Laravel Type Analysis | Larastan |
| Formatting | Pint |
| Coding Style | Pint |
| `strict_types` Declaration | Pint |
| Complexity | CleanCode + PHP_CodeSniffer |
| Maintainability | CleanCode + PHP_CodeSniffer |
| Code Smell | CleanCode + PHP_CodeSniffer |
| Partial Unused Code Detection | CleanCode + PHPStan |
| Layer Dependency | Pest Architecture |
| Framework Leak | Pest Architecture |
| Automated Refactoring | Rector |
| Version Upgrade | Rector |
| Business Behavior | Pest |
| API Contract | OpenAPI Contract Test |

---

# CI Quality Pipeline

## 113. Blocking Pipeline

Merge可否を判断するBlocking Pipelineは以下を基本とする。

```text
Source Code
    ↓
Pint
    ↓
PHPStan + Larastan
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

## 114. Monitoring Pipeline

Complexity / MaintainabilityはBlocking Pipelineと責務を分離する。

```text
Source Code
    ↓
PHP_CodeSniffer
    ↓
CleanCode Selected Sniffs
    ↓
Complexity / Maintainability Report
    ↓
Review / Refactoring Signal
```

CleanCode Violationのみを理由としてMergeを禁止しない。

具体的なGitHub Actions上の実装方法はTASK-10で決定する。

---

## 115. Rector

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

## 116. Static Analysis

Backend Static Analysisは、

```text
PHPStan
+
Larastan
```

を中心とする。

新規ProjectであるためBaselineへ依存せず、初期Level 9、最終的にPHPStan Level 10を目標とする。

---

## 117. Formatting

FormattingはLaravel Pintへ統一する。

```text
Laravel Pint
    → Project Formatter
```

とし、PHP CS Fixerを直接二重管理しない。

---

## 118. Maintainability

Complexity / Maintainability / Code Smellは、

```text
PHP_CodeSniffer
    +
CleanCode
    +
backend/phpcs.xml
```

で監視する。

特に、

```text
Controller
Application Handler
Domain Service
Mapper
```

等の責務肥大化を検出する補助として利用する。

CleanCode Standard全体は利用せず、Projectの目的に合うSniffのみを選択する。

また、ComplexityはQualityの絶対評価ではなく、

> Refactoringや責務配置を検討するためのSignal

として扱う。

---

## 119. Blocking / Monitoring

Code Quality Checkを明確に分離する。

```text
Blocking
├── Laravel Pint
└── PHPStan + Larastan

Monitoring
└── CleanCode + PHP_CodeSniffer
```

Composer Scriptsでも、

```text
composer quality
    → Blocking

composer complexity
    → Monitoring
```

として同じ境界を維持する。

---

## 120. Architecture

Architecture DependencyはPest Architecture Testで保証する。

現時点ではDeptracを追加しない。

Complexity ToolへArchitecture Ruleの責務を持たせない。

---

## 121. Automated Refactoring

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

## 122. 最終構成

Backend Code Qualityの標準構成を以下とする。

```text
PHPStan + Larastan
    → Type Safety
    → Blocking

Laravel Pint
    → Formatting
    → Blocking

CleanCode + PHP_CodeSniffer
    → Complexity / Maintainability / Code Smell
    → Monitoring

Pest Architecture Test
    → Architecture Integrity
    → Blocking

Rector
    → Automated Evolution

Pest
    → Behavior Verification
    → Blocking

OpenAPI Contract Test
    → API Contract Verification
    → Blocking
```

---

## 123. 最重要原則

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

また、

```text
Blocking
    → Correctness / Merge Safety

Monitoring
    → Maintainability / Refactoring Signal
```

を区別する。

最終的に、

```text
Format
    ↓
Static Analysis
    ↓
Architecture
    ↓
Tests
    ↓
Contract
```

をBlocking Quality Pipelineとして継続的に実行し、

```text
Complexity / Maintainability
    ↓
Monitoring
    ↓
Review / Refactoring
```

を並行して運用することで、Clean Architecture / DDDをCodebase上でも維持する。
