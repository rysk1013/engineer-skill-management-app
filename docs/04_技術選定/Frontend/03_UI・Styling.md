# UI・Styling

## 1. 目的

本ドキュメントでは、Engineer Skill Management AppのFrontendにおけるUI・Styling関連の技術・Library選定を管理する。

主に以下を対象とする。

- CSS / Styling
- UI Component
- Primitive / Headless UI
- Icon
- Class Utility
- Theme / Design Token
- Accessibility

UI Componentの配置、責務、Server / Client境界などの設計についてはFrontend Architectureで管理し、本ドキュメントでは具体的に利用する技術・Libraryとその利用方針を扱う。

---

## 2. CSS・Styling

### 2.1 候補

CSS / Stylingの候補として以下を比較する。

- Tailwind CSS
- CSS Modules
- Sass
- styled-components
- Emotion
- Vanilla Extract

---

### 2.2 採用

Tailwind CSS v4を採用する。

FrontendにおけるStylingの基本としてTailwind CSSを利用する。

基本構成は以下とする。

    Application Component
            ↓
      Tailwind CSS v4
            ↓
           CSS

---

### 2.3 採用理由

主な理由は以下とする。

- Next.js / Reactとの親和性が高い
- Utility Classを利用してComponent単位でStyleを管理しやすい
- TypeScript / JSXと組み合わせやすい
- shadcn/uiとの親和性が高い
- Design Tokenと統合しやすい
- Responsive Designを統一的に記述できる
- ComponentとStyleの対応関係を追いやすい
- CSS-in-JS Runtimeを必要としない
- Tailwind CSS v4ではCSS中心のTheme設定が可能
- 本プロジェクトのComposableなUI方針と相性がよい

---

### 2.4 利用方針

Application ComponentのStylingにはTailwind CSSを基本として利用する。

通常のCSSは主に以下で利用する。

- Global Style
- Design Token
- Tailwind CSSとの統合
- Application全体に適用するStyle
- CSSで表現することが適切な共通設定

複数のStyling方式を理由なく併用しない。

---

### 2.5 その他のStyling方式

CSS Modules、Sass、styled-components、Emotion、Vanilla ExtractはMVPでは採用しない。

Tailwind CSSで要件を満たせないことが明確になった場合に、追加導入を検討する。

---

## 3. UI Component

### 3.1 候補

UI Componentの候補として以下を比較する。

- shadcn/ui
- MUI
- Chakra UI
- Mantine

---

### 3.2 採用

shadcn/uiを採用する。

---

### 3.3 採用理由

主な理由は以下とする。

- Tailwind CSSとの親和性が高い
- React / Next.jsと組み合わせやすい
- React 19およびTailwind CSS v4をサポートしている
- ComponentのSource CodeをApplication側で保持できる
- Application固有のDesignへカスタマイズしやすい
- Headless / Composableな構成を取りやすい
- Accessibilityを考慮したPrimitiveを利用できる
- 必要なComponentだけ導入できる
- UI Libraryへの過度なLock-inを避けやすい
- TypeScriptとの親和性が高い

本プロジェクトで定義した、

- Headless / ComposableなLibraryを優先する
- Libraryの責務を重複させない
- 型安全性を重視する
- 必要なLibraryのみ導入する

というFrontend技術選定方針との整合性が高い。

---

### 3.4 Componentの導入方針

shadcn/uiのComponentを一括して導入しない。

必要になったComponentのみ追加する。

例：

    Button
    Input
    Select
    Dialog
    Dropdown Menu
    Table
    Tooltip

        ↓

    必要になった時点で追加

CLIを利用してComponentを追加する。

例：

    pnpm dlx shadcn@latest add button

追加されたComponentはApplicationのSource Codeとして管理する。

---

### 3.5 Componentのカスタマイズ

shadcn/uiから追加されたComponentは、Application側のUI要件に応じてカスタマイズ可能とする。

ただし、Componentごとに場当たり的な変更を行うのではなく、

- Design Token
- Variant
- 共通Component
- Tailwind CSS

を利用して一貫したUIを維持する。

---

### 3.6 その他のUI Component Library

MUI、Chakra UI、Mantineは採用しない。

いずれも有力なUI Component Libraryであるが、本プロジェクトではTailwind CSSをStylingの中心とし、Component Source CodeをApplication側で保持できるComposableな構成を優先する。

複数のUI Component Libraryを理由なく併用しない。

---

## 4. Primitive・Headless UI

### 4.1 基本方針

UI ComponentのPrimitive / Headless UIには、shadcn/uiが利用するBase UIを採用する。

追加のHeadless UI Libraryは原則として導入しない。

---

### 4.2 採用

Base UIを採用する。

基本構成は以下とする。

    Application
        ↓
    shadcn/ui
        ↓
      Base UI

ApplicationからBase UIを直接利用することは原則として避け、shadcn/ui Componentを経由して利用する。

---

### 4.3 Base UIを直接利用する場合

以下のようなケースではBase UIを直接利用してApplication固有のComponentを構築してよい。

- shadcn/uiに必要なComponentが存在しない
- shadcn/ui Componentでは要件を満たせない
- Application固有のPrimitive Componentが必要
- Accessibilityを維持しながら独自UIを構築したい

ただし、まずshadcn/uiで実現できないかを確認する。

---

### 4.4 その他のPrimitive Library

Radix UIやHeadless UIなど、その他のPrimitive / Headless UI LibraryはMVPでは採用しない。

Base UIと別のPrimitive Libraryを理由なく混在させない。

Base UIで実現できない要件が明確になった場合に個別に導入を検討する。

---

## 5. Icon

### 5.1 候補

Icon Libraryとして以下を候補とする。

- Lucide
- Tabler Icons
- Phosphor
- Hugeicons
- Remix Icon

---

### 5.2 採用

Lucideを採用する。

Reactでは `lucide-react` を利用する。

    Icon Library
        ↓
      Lucide
        ↓
    lucide-react

---

### 5.3 採用理由

主な理由は以下とする。

- React向けPackageとして `lucide-react` を利用できる
- shadcn/uiとの親和性が高い
- シンプルで統一されたLine Iconを利用できる
- 管理画面を中心としたApplication UIと相性がよい
- 必要なIconをComponentとしてImportできる
- TypeScriptと組み合わせやすい
- 十分な種類のIconが提供されている

---

### 5.4 利用方針

Iconは `lucide-react` から必要なものをImportする。

例：

    import {
      SearchIcon,
      SettingsIcon,
      UserIcon,
    } from "lucide-react"

Application全体で原則としてLucideへ統一する。

複数のIcon Libraryを理由なく併用しない。

Lucideに必要なIconが存在しない場合は、まず既存Iconで代替できないかを検討する。

---

### 5.5 Accessibility

意味を持たない装飾Iconは、Screen Readerへ不要な情報を提供しないようにする。

Iconのみで操作を表現するButtonなどについてはAccessible Nameを提供する。

例：

    <Button aria-label="社員を検索">
      <SearchIcon />
    </Button>

色やIconだけで状態を表現せず、必要に応じてTextやAccessible Labelを併用する。

---

## 6. Class Utility

### 6.1 目的

Tailwind CSSでは、Componentの状態やPropsに応じてClassを動的に組み立てるケースがある。

また、shadcn/ui ComponentのDefault ClassとApplication側から渡された `className` を適切にCompositionする必要がある。

そのためClass Utilityを利用する。

---

### 6.2 候補

以下を候補とする。

- `cn`
- `clsx` + `tailwind-merge`
- `clsx`
- `classnames`
- 自前Utility

---

### 6.3 採用

`cn` を採用する。

基本構成は以下とする。

    Tailwind CSS
         ↓
    Component Class
         ↓
        cn()
         ↓
    Final className

---

### 6.4 採用理由

主な理由は以下とする。

- shadcn/uiの構成と統一できる
- Tailwind CSSとの組み合わせに適している
- Conditional Classを簡潔に記述できる
- ClassのCompositionを統一できる
- Componentから受け取った `className` を扱いやすい
- UI Componentの実装を単純化できる

---

### 6.5 利用方針

Class Nameを動的にCompositionする必要がある場合に `cn` を利用する。

固定Classについては通常の `className` を利用する。

    <div className="flex items-center gap-2">

Class Compositionが不要な場合まで `cn` を利用しない。

---

### 6.6 Variantとの責務分担

`cn` はClass NameのCompositionを担当する。

ComponentのVariant管理とは責務を分ける。

    Variant Utility
          ↓
    Component Variant

    cn
          ↓
    Class Composition

Variant管理が必要なComponentについては、shadcn/uiのComponent構成およびVariant Utilityを利用する。

---

### 6.7 その他のClass Utility

`clsx`、`tailwind-merge`、`classnames` をApplication側で別のClass Utilityとして併用しない。

独自のClass Composition Utilityも原則として作成しない。

---

## 7. Theme・Design Token

### 7.1 基本方針

ThemeおよびDesign Tokenは、

    Tailwind CSS v4
          +
    CSS Variables

を利用して管理する。

Theme管理専用の追加LibraryはMVPでは導入しない。

---

### 7.2 Design Token

主に以下をDesign Tokenの対象とする。

- Color
- Typography
- Spacing
- Radius
- Shadow
- Breakpoint

ただし、すべてのCSS値をDesign Token化することを目的としない。

Application全体で共通の意味を持つ値を中心に管理する。

---

### 7.3 Semantic Token

Colorについては、可能な限り具体的な色名ではなくSemanticなTokenを利用する。

例：

    background
    foreground
    primary
    secondary
    muted
    accent
    destructive
    border
    input
    ring

基本構成は以下とする。

    Component
        ↓
    Semantic Token
        ↓
    Actual Color

Application全体で意味を持つ色をComponent側へ直接埋め込むことは原則として避ける。

---

### 7.4 Tailwind CSSとの統合

Tailwind CSS v4のTheme機能を利用し、Tailwind UtilityとDesign Tokenを連携させる。

Theme設定はCSSを中心として管理する。

JavaScript / TypeScript側にTheme設定を重複して保持しない。

---

### 7.5 shadcn/uiとの統合

shadcn/ui ComponentもApplicationのDesign Tokenを利用する。

    Design Token
          ↓
    Tailwind CSS
          ↓
      shadcn/ui
          ↓
      Component

shadcn/uiから追加したComponentごとに独自のColor Systemを作成しない。

---

### 7.6 Dark Mode

Dark Modeへ対応可能なToken構造とする。

Light / DarkそれぞれでComponentのClassを大量に分岐させるのではなく、Semantic Tokenの値をThemeごとに変更できる構成とする。

ただし、

    Dark Modeへ対応可能な設計

と

    Dark Mode切り替え機能を提供する

ことは分離して考える。

MVPでDark Mode切り替え機能を提供するかどうかはUI要件に基づいて別途決定する。

Theme切り替え専用Libraryは必要性が明確になるまで導入しない。

---

### 7.7 Design Tokenの追加基準

新しいDesign Tokenは以下を基準として追加する。

1. Application全体で共通の意味を持つか
2. 複数Componentで利用されるか
3. Theme変更時に一括して変更する必要があるか
4. UIの一貫性を維持するために必要か

Design Tokenを増やしすぎない。

---

## 8. Accessibility

### 8.1 基本方針

AccessibilityはUI Libraryだけに依存せず、Application全体で担保する。

基本構成は以下とする。

    Semantic HTML
          +
       Base UI
          +
      shadcn/ui
          +
    Application実装
          ↓
    Accessibility

Accessibility専用のUI Libraryを追加することはMVPでは原則として行わない。

---

### 8.2 Semantic HTML

可能な限りSemantic HTMLを利用する。

例：

    button
    input
    label
    nav
    main
    header
    section
    table

クリック可能な要素を単純な `div` や `span` で実装することは避ける。

---

### 8.3 Base UI・shadcn/ui

Keyboard NavigationやFocus Managementなど複雑なInteractionについては、Base UIが提供するAccessibility機能を活用する。

shadcn/ui ComponentをAccessibility対応の土台として利用する。

ただし、Componentを導入しただけでApplication全体のAccessibilityが保証されるわけではない。

Application側でも以下を適切に実装する。

- Label
- Description
- Accessible Name
- Error Message
- Focus Order
- Keyboard Operation
- Loading State
- Disabled State

---

### 8.4 ARIA

ARIAはSemantic HTMLで表現できない場合に利用する。

基本方針は以下とする。

    Semantic HTMLで実現可能
            ↓
        HTMLを利用

    Semantic HTMLだけでは不足
            ↓
       ARIAを追加

不要な `role` や `aria-*` 属性を大量に追加しない。

---

### 8.5 Form

Form Controlには利用者が入力内容を理解できるLabelを提供する。

PlaceholderのみをLabelの代替として利用しない。

Validation Errorがある場合は、入力項目とError Messageの関係を適切に表現する。

---

### 8.6 Keyboard・Focus

MouseだけでなくKeyboardでも主要な操作を実行できるようにする。

特に以下を確認する。

- Tabで操作対象へ移動できる
- Enter / Spaceで操作できる
- Dialogから適切にFocusが戻る
- MenuをKeyboardで操作できる
- Focus Trapが必要なUIで適切に動作する

Keyboard操作時に現在のFocus位置が視覚的に確認できるようにする。

Focus Ringを理由なく削除しない。

---

### 8.7 Color・Contrast

情報をColorだけで表現しない。

必要に応じて、

    Icon
      +
    Text
      +
    Color

など複数の手段を組み合わせる。

ForegroundとBackgroundのContrastを考慮し、Theme変更によってContrastが大きく崩れない構成とする。

---

### 8.8 Loading・Error

LoadingやErrorをVisualだけに依存して伝えない。

必要に応じてAccessible StatusやTextを利用する。

Error Messageは可能な範囲で、

- 何が失敗したか
- 利用者が次に何をすればよいか

を理解できる内容とする。

---

### 8.9 Table

Table形式のデータには可能な限りSemanticなHTML Tableを利用する。

主に以下を適切に利用する。

- `table`
- `thead`
- `tbody`
- `th`
- `td`

Layout目的ではTableを利用しない。

---

### 8.10 Testing

Accessibilityは実装時だけでなくTestおよびReviewでも確認する。

主に以下を確認する。

- Semantic HTML
- Keyboard操作
- Accessible Name
- Focus
- Browser Accessibility Tree
- Automated Accessibility Test

具体的なTest Toolについては `12_テスト.md` で選定する。

Automated TestだけでAccessibilityを完全に保証できないため、Manual Testも併用する。

---

## 9. 採用技術一覧

UI・Stylingでは以下の技術・Libraryを採用する。

| 分類 | 採用技術・Library | 主な責務 |
|---|---|---|
| CSS / Styling | Tailwind CSS v4 | Styling / Utility CSS |
| UI Component | shadcn/ui | Application UI Component |
| Primitive / Headless UI | Base UI | Accessible UI Primitive |
| Icon | Lucide / `lucide-react` | Icon |
| Class Utility | `cn` | Class Name Composition |
| Theme | Tailwind CSS v4 + CSS Variables | Theme / Design Token |
| Accessibility | Semantic HTML + Base UI + shadcn/ui | Accessible UIの基盤 |

---

## 10. 決定事項

FrontendのUI・Stylingは以下を基本構成とする。

    Next.js + React
           |
           v
    Application UI
           |
      +----+----------------------+
      |                           |
      v                           v
    shadcn/ui                   Lucide
      |                           |
      v                           v
    Base UI                  lucide-react
      |
      v
    Tailwind CSS v4
      |
      v
    CSS Variables
      |
      v
    Design Token

          +

         cn
          |
          v
    Class Composition

採用する主要技術は以下とする。

    Styling
        ↓
    Tailwind CSS v4

    UI Component
        ↓
    shadcn/ui

    Primitive
        ↓
    Base UI

    Icon
        ↓
    Lucide / lucide-react

    Class Utility
        ↓
    cn

    Theme
        ↓
    Tailwind CSS v4 + CSS Variables

    Accessibility
        ↓
    Semantic HTML + Base UI + shadcn/ui

複数のStyling System、UI Component Library、Primitive Library、Icon Libraryを理由なく併用しない。

追加Libraryについては、

1. Next.js / React / Tailwind CSSの標準機能で実現できないか
2. shadcn/ui / Base UIで実現できないか
3. 既存Libraryと責務が重複しないか
4. MVPで本当に必要か

を確認した上で導入する。

将来利用する可能性だけを理由としてLibraryを追加せず、必要性が明確になった時点で追加を検討する。
