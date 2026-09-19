# コード品質・Developer Experience

## 1. 目的

本ドキュメントでは、FrontendにおけるCode QualityおよびDeveloper Experienceの技術選定・運用方針を定義する。

対象：

- TypeScript
- ESLint
- Formatter
- Import整理
- Dead Code検出
- Unused Dependency検出
- Git Hook
- lint-staged
- Package Script
- Dependency Update
- Generated Code
- Complexity
- Local Development
- CI

横断的なCode Quality Tool選定については `09_コード品質ツール.md`、
Frontend ArchitectureについてはFrontend Architecture、
Testについては `12_テスト.md` に従う。

---

# 2. 基本方針

Frontendでは、

> 人間がレビューすべき問題と、Toolで自動検出・修正できる問題を分離する

ことを基本とする。

Toolで機械的に判断できるものは可能な限り自動化し、
Code Reviewでは、

- Design
- Responsibility
- Naming
- Business Logic
- Maintainability
- Security
- User Experience

など、人間の判断が必要な部分へ集中する。

基本構成：

    Type Safety
        → TypeScript

    Code Quality
        → ESLint

    Formatting
        → Prettier

    Dead Code
        → Knip

    Changed File Check
        → lint-staged

    Git Hook
        → Husky

    Dependency Update
        → Renovate

    Package Management
        → pnpm

    Final Enforcement
        → CI

---

# 3. TypeScript

## 3.1 採用

Frontend / BFFのLanguageとして
**TypeScript** を利用する。

`strict` を有効にする。

---

## 3.2 TypeScriptの責務

TypeScriptは主に、

- Type Safety
- Null Safety
- Function Contract
- Component Props
- Domain / UI Model
- Compile-time Error Detection

を担当する。

---

## 3.3 any

`any` は原則利用しない。

外部から型不明Dataを受け取る場合は
`unknown` を優先する。

    unknown
       ↓
    Validation / Narrowing
       ↓
    Typed Value

とする。

---

## 3.4 Type Assertion

`as` によるType Assertionを
問題回避のDefault手段にしない。

可能な限り、

- Type Guard
- Schema Validation
- Type Inference
- Proper API Type

を利用する。

---

## 3.5 Generated Type

OpenAPI / Orvalから生成できるAPI Typeを
手書きで重複定義しない。

ただし、

    API Type
        ≠
    Form State
        ≠
    UI View Model

である。

必要に応じてBoundaryで変換する。

---

# 4. ESLint

## 4.1 採用

Lint Toolとして
**ESLint** を採用する。

---

## 4.2 責務

ESLintは、

- Bug Risk
- Suspicious Code
- React Rule
- Next.js Rule
- TypeScript Rule
- Project-specific Code Rule

等の検出を担当する。

FormattingはESLintの主責務にしない。

---

## 4.3 Framework Rule

Next.js / React / TypeScriptと
互換性のある公式・標準的なRule Setを優先する。

大量のPluginを最初から導入しない。

---

## 4.4 Rule追加

Ruleは、

> 実際に防ぎたい問題があるか

を基準に追加する。

個人的なCoding Styleを強制するためだけに
大量のCustom Ruleを導入しない。

---

## 4.5 Warning

CIで長期間放置されるWarningを
大量に作らない。

Ruleを有効にする場合は、

- Fixする
- Errorとして扱う
- 明確な理由で無効化する

のいずれかを基本とする。

---

## 4.6 Disable Comment

`eslint-disable` を利用する場合は
可能な限り狭いScopeに限定する。

File全体のDisableを安易に利用しない。

---

# 5. Formatter

## 5.1 採用

Formatterとして
**Prettier** を採用する。

---

## 5.2 責務

PrettierはFormattingのみ担当する。

例えば、

- Indentation
- Line Break
- Quote
- Trailing Comma
- Whitespace

等。

---

## 5.3 ESLintとの分離

基本：

    ESLint
        → Code Quality

    Prettier
        → Formatting

とする。

同じFormatting Ruleを
ESLintとPrettier双方で管理しない。

---

## 5.4 Formatting Discussion

Code Reviewで、

- Space
- Line Break
- Quote Style

等のFormatting Discussionを
原則行わない。

Formatterの結果をProject Standardとする。

---

## 5.5 Biome

Biomeは有力なAlternativeだが、
本ProjectのMVPでは採用しない。

Next.js / React / TypeScript Ecosystemとの統合、
既存Tooling、
Lint Ruleの柔軟性を考慮し、

    ESLint
      +
    Prettier

を採用する。

将来的にToolchain簡素化の価値が高くなった場合は
Biomeへの統合を再評価できる。

---

# 6. Import整理

## 6.1 基本方針

Importは、

- Editor
- ESLint
- Formatter
- TypeScript

の標準機能を可能な限り活用する。

Import整理専用Toolを
MVP開始時点では追加しない。

---

## 6.2 Import Order

細かすぎるImport Order Ruleを
Project Qualityの中心にしない。

必要な場合のみ、

    External
    Internal
    Relative

程度の読みやすいRuleを導入する。

---

## 6.3 Absolute Import

Projectで定義したAliasを利用し、
深いRelative Importを避ける。

例えば：

    @/features/employee/...
    @/components/...
    @/lib/...

ただしArchitecture Boundaryを
Aliasで隠蔽しない。

---

## 6.4 Barrel Export

`index.ts` によるBarrel Exportを
無条件に導入しない。

Barrelによって、

- Dependencyが見えにくくなる
- Circular Dependency
- Unnecessary Import
- Bundleへの影響

が発生する場合があるため、
Public APIとして意味がある場所に限定する。

---

# 7. 未使用Code・Dependency検出

## 7.1 採用

Dead Code / Unused Dependency検出として
**Knip** を採用する。

---

## 7.2 対象

Knipでは主に、

- Unused File
- Unused Export
- Unused Dependency
- Unused Dev Dependency

を検出する。

---

## 7.3 TypeScript / ESLintとの役割分担

    TypeScript
        → Type / Local Code

    ESLint
        → File内Code Quality

    Knip
        → Project全体のDead Code / Dependency

とする。

---

## 7.4 False Positive

Framework ConventionやGenerated Codeにより
False Positiveが発生する場合は、
Knip Configurationで明示的に扱う。

Checkそのものを無効化するのではなく、
理由のあるExceptionを設定する。

---

# 8. Git Hook

## 8.1 採用

Git Hook管理には
**Husky** を採用する。

---

## 8.2 基本方針

Git Hookでは
軽量なCheckのみ実行する。

Commit操作を極端に遅くしない。

---

## 8.3 Pre-commit

Pre-commitでは主に
変更Fileを対象として、

    Format
      ↓
    Lint

を実行する。

---

## 8.4 実行しないもの

Pre-commitで毎回、

- Full Test
- E2E
- Storybook Build
- Full Production Build

を実行しない。

重いCheckはCIへ任せる。

---

## 8.5 Hookは最終防衛ではない

Git HookはDeveloper Experience向上のための
Early Feedbackとして利用する。

最終的なQuality GateはCIとする。

---

# 9. lint-staged

## 9.1 採用

変更Fileに対するCheckには
**lint-staged** を採用する。

---

## 9.2 基本構成

概念：

    git commit
       ↓
    Husky
       ↓
    lint-staged
       ↓
    Prettier
       ↓
    ESLint

---

## 9.3 対象

Staged Fileだけを処理する。

Project全体を毎回Checkしない。

---

## 9.4 Auto Fix

安全に自動修正できるものは
Pre-commitでAuto Fixしてよい。

ただしBusiness Logicを変更するような
危険な自動修正へ依存しない。

---

# 10. Package Manager・Script

## 10.1 Package Manager

Package Managerは
`02_基本技術・Runtime.md` で決定した
**pnpm** を利用する。

---

## 10.2 Script

DeveloperがTool固有Commandを
大量に覚えなくてよいよう、
`package.json` ScriptをProject Interfaceとする。

例：

    pnpm dev
    pnpm build
    pnpm lint
    pnpm format
    pnpm format:check
    pnpm typecheck
    pnpm test
    pnpm test:e2e
    pnpm storybook
    pnpm storybook:build
    pnpm knip
    pnpm api:generate

実際のScript名はRepository内で統一する。

---

## 10.3 Tool直接実行

README / CI / Team Documentationでは
可能な限りProject Scriptを利用する。

例えば、

    pnpm lint

を標準とし、
Developerごとに異なるESLint CLI Optionを
直接実行する運用を避ける。

---

# 11. Dependency Update

## 11.1 採用

Dependency Update Automationには
**Renovate** を採用する。

---

## 11.2 対象

主に、

- npm Dependency
- pnpm
- Node.js
- GitHub Actions
- Docker Image

等の更新を自動検出する。

Repository全体のDependency Update方針と
整合させる。

---

## 11.3 Auto Merge

すべてのDependency Updateを
無条件にAuto Mergeしない。

Riskに応じて、

- Patch
- Minor
- Major
- Development Dependency
- Production Dependency

を区別する。

---

## 11.4 Major Update

Major Updateは、

- Migration Guide
- Breaking Changes
- Next.js Compatibility
- React Compatibility
- Generated Codeへの影響

等を確認して更新する。

---

## 11.5 Update頻度

Dependency Update PRが大量発生しないよう
必要に応じてGrouping / Scheduleを設定する。

---

## 11.6 Lockfile

`pnpm-lock.yaml` をCommitする。

Dependency Update時は
ManifestとLockfileを同一PRで更新する。

---

# 12. Editor Independence

## 12.1 基本方針

Code Quality Toolを
特定Editorへ依存させない。

VS Code / Neovim / Zed等、
どのEditorからでも同じ結果になる構成とする。

---

## 12.2 Source of Truth

Source of Truthは、

- Repository Configuration
- package.json Script
- CI

とする。

Editor Settingを
唯一のQuality Enforcement手段にしない。

---

## 12.3 Editor Integration

Editor側では、

- ESLint
- Prettier
- TypeScript

のIntegrationを利用してよい。

ただしEditor Extensionがなくても
CLI / CIで同じCheckを実行できるようにする。

---

# 13. Local Development Command

## 13.1 基本方針

日常開発で利用するCommandを
少数のProject Scriptへ統一する。

---

## 13.2 Development

基本：

    pnpm dev

---

## 13.3 Quality Check

開発中：

    pnpm lint
    pnpm typecheck
    pnpm test

必要に応じて：

    pnpm format
    pnpm knip

を利用する。

---

## 13.4 Full Check

Pull Request前に実行できる
統合Commandを用意してよい。

例えば：

    pnpm check

内部：

    format:check
        ↓
    lint
        ↓
    typecheck
        ↓
    test
        ↓
    knip

ただしE2E等の重い処理は
別Commandへ分離してよい。

---

# 14. CIとの責務分担

## 14.1 基本方針

    Editor
        → Immediate Feedback

    Git Hook
        → Changed File Early Check

    Local Command
        → Developer Check

    CI
        → Repository-wide Final Check

とする。

---

## 14.2 CI

CIでは最低限、

- Install
- Format Check
- Lint
- Type Check
- Unit / Component Test
- Dead Code Check
- OpenAPI Generated Code Check
- Storybook Build

を実行する。

E2EはTest Strategyに従い
別Jobとして実行できる。

---

## 14.3 CIでAuto Fixしない

CIは原則として
Source CodeをAuto Fixしない。

問題を検出してFailureとする。

修正はDeveloper側で行う。

---

## 14.4 LocalとCI

LocalとCIで
異なるQuality Ruleを使用しない。

同じConfiguration / Scriptを利用する。

---

# 15. Generated Codeの扱い

## 15.1 対象

主にOpenAPI / Orvalによる
Generated Codeを対象とする。

---

## 15.2 原則

Generated Codeは
手動編集しない。

    OpenAPI
       ↓
    Orval
       ↓
    Generated Code

をSourceとする。

---

## 15.3 Directory

Generated Codeは
専用Directoryへ配置する。

Handwritten Codeと
混在させない。

---

## 15.4 Lint / Format

Generated Codeへ
Handwritten Codeと同一のRuleを
無理に適用しない。

必要に応じて、

- ESLint対象外
- Prettier対象外
- Knip Exception

等を明示する。

---

## 15.5 Generated Code Check

CIでは、

    OpenAPI
       ↓
    Generate
       ↓
    git diff

を実行し、
Generated Codeが最新か確認する。

CIからGenerated Codeを
Auto Commitしない。

---

# 16. Complexity・Maintainability

## 16.1 基本方針

Complexity Metricだけを
Code Qualityとして扱わない。

MetricはRefactoring Candidateを
発見する補助指標として利用する。

---

## 16.2 注意する兆候

例えば、

- 巨大Component
- 巨大Hook
- Deep Nesting
- 長いConditional
- 多すぎるProps
- 複数責務を持つFunction
- Feature間の強いCoupling
- Circular Dependency

などをReview対象とする。

---

## 16.3 Complexity

Complexity Thresholdを導入する場合は
Project実績を確認してから設定する。

初期段階から
厳しすぎるThresholdを設定しない。

---

## 16.4 Component分割

Line Countだけを理由に
Componentを分割しない。

Responsibility / Change Reason / Reusabilityを基準にする。

---

## 16.5 Abstraction

重複を1回見つけただけで
即座にGeneric Abstractionを作らない。

実際の共通性が確認できてから
抽象化する。

---

## 16.6 Dependency Boundary

Architecture上のDependency Ruleを
Toolで自動検証する価値が出た場合は、
専用Lint Rule / Boundary Tool導入を検討する。

MVP開始時点では
不要なArchitecture Toolを増やさない。

---

# 17. 採用技術一覧

| 分類 | 採用技術 / 方針 |
|---|---|
| Language / Type Safety | TypeScript strict |
| Lint | ESLint |
| Formatter | Prettier |
| Dead Code / Dependency | Knip |
| Git Hook | Husky |
| Staged File Check | lint-staged |
| Package Manager | pnpm |
| Dependency Update | Renovate |
| Project Command | package.json scripts |
| Generated API Code | Orval |
| Final Quality Gate | CI |
| Editor | 非依存 |
| Complexity | 補助指標として利用 |

---

## 17.1 Tool Responsibility

    TypeScript
        → Type Safety

    ESLint
        → Code Quality

    Prettier
        → Formatting

    Knip
        → Dead Code / Unused Dependency

    Husky
        → Git Hook

    lint-staged
        → Changed File Check

    Renovate
        → Dependency Update

    pnpm
        → Package Management

    CI
        → Final Enforcement

---

## 17.2 MVPで採用しないもの

| 技術 / 方針 | 理由 |
|---|---|
| Biome | ESLint + Prettierを採用 |
| 複数Formatter | 責務重複 |
| ESLintによるFormatting統一 | Prettierへ分離 |
| Import整理専用Tool | MVPでは不要 |
| 巨大Custom ESLint Rule Set | Maintenance Costが高い |
| Editor依存Lint | Reproducibilityが低い |
| Pre-commit Full Test | Commitが遅くなる |
| Pre-commit E2E | Costが高い |
| Pre-commit Production Build | CIへ任せる |
| CI Auto Fix / Auto Commit | CIは検証を担当 |
| Generated Code手動編集 | Regenerationで失われる |
| 100% Complexity Rule | Metric目的化を避ける |
| 無条件Dependency Auto Merge | Update Riskがある |
| 早すぎるArchitecture Tool導入 | MVPでは過剰 |

---

# 18. 決定事項

Frontend Code Quality / Developer Experience Stackとして、

- TypeScript
- ESLint
- Prettier
- Knip
- Husky
- lint-staged
- pnpm
- Renovate
- CI

を利用する。

基本構成：

    Developer
       ↓
    Editor Feedback
       ↓
    Git Hook
       ↓
    lint-staged
       ↓
    Pull Request
       ↓
    CI
       ↓
    Quality Gate

各Tool：

    TypeScript
        → Type Safety

    ESLint
        → Code Quality

    Prettier
        → Formatting

    Knip
        → Dead Code

    Husky + lint-staged
        → Pre-commit Early Feedback

    Renovate
        → Dependency Maintenance

    CI
        → Final Enforcement

以下をProject標準方針とする。

1. TypeScript strictを利用する。
2. `any` を原則利用しない。
3. Unknown Dataには `unknown` を優先する。
4. Type Assertionを問題回避のDefault手段にしない。
5. Generated API Typeを手書きで重複定義しない。
6. API Type / Form State / View Modelを必要に応じて分離する。
7. LintにはESLintを利用する。
8. ESLintはCode Qualityを担当する。
9. FormattingにはPrettierを利用する。
10. ESLintとPrettierの責務を分離する。
11. BiomeはMVPでは採用しない。
12. Import整理専用ToolはMVPでは導入しない。
13. 深いRelative Importを避け、Project Aliasを適切に利用する。
14. Barrel Exportを無条件に利用しない。
15. Dead Code / Unused Dependency検出にはKnipを利用する。
16. KnipのFalse Positiveは明示的なConfigurationで扱う。
17. Git Hook管理にはHuskyを利用する。
18. Staged File Checkにはlint-stagedを利用する。
19. Pre-commitでは軽量Checkのみ実行する。
20. Pre-commitでFull Testを実行しない。
21. Pre-commitでE2Eを実行しない。
22. Pre-commitでProduction Buildを実行しない。
23. Git Hookを最終Quality Gateにしない。
24. Final Quality GateはCIとする。
25. Package Managerにはpnpmを利用する。
26. Developer向けCommandはpackage.json Scriptへ統一する。
27. Tool固有CLIをDocumentationの主要Interfaceにしない。
28. Dependency Update AutomationにはRenovateを利用する。
29. Dependency Updateを無条件Auto Mergeしない。
30. Major UpdateではBreaking Changeを確認する。
31. Dependency Update PRは必要に応じてGroupingする。
32. `pnpm-lock.yaml` をCommitする。
33. Code Qualityを特定Editorへ依存させない。
34. Repository Configuration / CLI / CIをSource of Truthとする。
35. Editor IntegrationはImmediate Feedbackとして利用する。
36. LocalとCIで同じQuality Configurationを利用する。
37. 必要に応じて `pnpm check` のような統合Commandを用意する。
38. CIでFormat Checkを実行する。
39. CIでLintを実行する。
40. CIでType Checkを実行する。
41. CIでUnit / Component Testを実行する。
42. CIでDead Code Checkを実行する。
43. CIでGenerated Codeの同期を確認する。
44. CIでStorybook Buildを確認する。
45. CIは原則Source CodeをAuto Fixしない。
46. Generated Codeは専用Directoryへ隔離する。
47. Generated Codeを手動編集しない。
48. Generated CodeへHandwritten Codeと同じRuleを無理に適用しない。
49. Generated CodeはCIで再生成して差分を確認する。
50. CIからGenerated CodeをAuto Commitしない。
51. Complexity MetricをQualityそのものとして扱わない。
52. ComplexityはRefactoring Candidate発見の補助指標とする。
53. Line CountだけでComponentを分割しない。
54. Responsibility / Change ReasonをComponent分割の基準とする。
55. 早すぎるGeneric Abstractionを避ける。
56. Architecture Boundary自動検証Toolは必要性が生じてから導入する。
57. Toolを増やす場合は既存Toolとの責務重複を確認する。
58. 自動化可能な問題はToolへ任せ、Code ReviewをDesign / Business Logic / Maintainabilityへ集中させる。

以上を `Frontend/13_コード品質・Developer-Experience.md` の決定版とする。
