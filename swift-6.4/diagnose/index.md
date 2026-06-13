---
layout: default
title: The @diagnose attribute
description: Use Swift 6.4's @diagnose attribute to control specific warning groups inside a declaration.
section: Swift 6.4
section_url: /swift-6.4/
---

{% include breadcrumbs.html %}

<article class="article" markdown="1">
<p class="eyebrow">Compiler diagnostics</p>
<h1>The <code>@diagnose</code> attribute</h1>
<p class="page-intro"><code>@diagnose</code> gives you fine-grained control over a diagnostic group within one declaration. It can suppress a warning, keep it as a warning, or promote it to an error without changing the behavior of the rest of your project.</p>

<div class="callout">
  <strong>Use narrow scopes and explain exceptions.</strong> Suppressing a useful warning can hide migration work, so attach a <code>reason:</code> and keep the attributed declaration focused.
</div>

## The problem it solves

Projects often need to use a deprecated API temporarily while a migration is underway. Disabling deprecation warnings for the whole target removes useful feedback everywhere. With `@diagnose`, you can silence only the known use:

```swift
@available(iOS, deprecated: 18.0)
@available(macOS, deprecated: 15.0)
func calculateSomething() -> Int {
    print("Deprecated!")
    return 0
}

@diagnose(
    DeprecatedDeclaration,
    as: ignored,
    reason: "Maintain until end of release"
)
func complexOperation() {
    let value = calculateSomething()
    print("Complex result is", value)
}
```

`calculateSomething()` remains deprecated everywhere else. Only deprecated-declaration warnings produced inside `complexOperation()` are ignored.

## Syntax

```swift
@diagnose(
    <DiagnosticGroup>,
    as: <Behavior>,
    reason: "<Optional explanation>"
)
```

- **Diagnostic group:** A compiler-defined identifier such as `DeprecatedDeclaration`.
- **Behavior:** Exactly one of `ignored`, `warning`, or `error`.
- **Reason:** An optional string literal that records why the behavior changed.

## Behaviors

<table class="severity-table">
  <thead>
    <tr>
      <th>Behavior</th>
      <th>Effect inside the declaration</th>
      <th>Useful when</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>ignored</code></td>
      <td>Suppresses warnings in the selected group, including when the project treats warnings as errors.</td>
      <td>A known issue needs a temporary, documented exception.</td>
    </tr>
    <tr>
      <td><code>warning</code></td>
      <td>Keeps diagnostics in the selected group as warnings, even when they were promoted to errors elsewhere.</td>
      <td>A migration should remain visible without blocking the build.</td>
    </tr>
    <tr>
      <td><code>error</code></td>
      <td>Promotes warnings in the selected group to errors.</td>
      <td>A sensitive declaration needs stricter enforcement.</td>
    </tr>
  </tbody>
</table>

## More focused examples

### Keep deprecations visible without blocking the build

If the project enables warnings as errors, one migration boundary can continue to emit ordinary warnings:

```swift
@diagnose(
    DeprecatedDeclaration,
    as: warning,
    reason: "Migration tracked separately"
)
func compatibilityLayer() {
    _ = calculateSomething()
}
```

### Audit unsafe APIs in a security-sensitive function

`StrictMemorySafety` warnings are disabled by default. Enable them as errors in code that deserves an especially careful audit:

```swift
@diagnose(
    StrictMemorySafety,
    as: error,
    reason: "Security-sensitive parsing boundary"
)
func parseTrustedHeader(_ pointer: UnsafePointer<UInt8>) {
    // Uses that trigger StrictMemorySafety diagnostics
    // must be acknowledged or resolved before this compiles.
}
```

### Fix future errors today

Make warnings that are scheduled to become errors in a future Swift language mode block the build now:

```swift
@diagnose(
    ErrorInFutureSwiftVersion,
    as: error,
    reason: "Keep this module ready for the next language mode"
)
func forwardLookingCode() {
    // Future-mode errors are enforced here today.
}
```

## Diagnostic groups

`DeprecatedDeclaration` is only one diagnostic group. Other useful examples include:

- `StrictMemorySafety` for uses of language constructs and APIs that can undermine memory safety.
- `ErrorInFutureSwiftVersion` for warnings that become errors in a future Swift language mode.
- `UnnecessaryEffectMarker` for unnecessary effect markers.
- `UselessAvailabilityCheck` for availability checks that do not affect execution.

The set of groups evolves with the compiler. Use Swift's [generated diagnostic group index](https://github.com/swiftlang/swift/blob/aacc24895250c4c91a80009069725074350ac3f5/userdocs/diagnostics/diagnostic-groups.md) and [group definitions](https://github.com/swiftlang/swift/blob/aacc24895250c4c91a80009069725074350ac3f5/include/swift/AST/DiagnosticGroups.def) as the canonical references.

## Scope and good practice

- Put `@diagnose` on the smallest declaration that needs different diagnostic behavior.
- Include a clear `reason:` when ignoring or downgrading a warning.
- Track temporary suppressions so they can be removed after migration.
- Prefer fixing the underlying warning when the cost is reasonable.
- Remember that changing a group's behavior affects all diagnostics in that group inside the declaration.

## Full example

The repository includes a [single Swift source file](https://github.com/{{ site.repository }}/blob/main/examples/DiagnoseExamples.swift) with the deprecation examples from this guide.

## References

- [Swift compiler test for `@diagnose`](https://github.com/swiftlang/swift/blob/aacc24895250c4c91a80009069725074350ac3f5/test/attr/diagnose.swift)
- [Swift parser tests for valid behaviors and `reason:`](https://github.com/swiftlang/swift/blob/aacc24895250c4c91a80009069725074350ac3f5/test/Parse/diagnose_attribute.swift)
- [DeprecatedDeclaration diagnostic group documentation](https://github.com/swiftlang/swift/blob/aacc24895250c4c91a80009069725074350ac3f5/userdocs/diagnostics/deprecated-declaration.md)
</article>
