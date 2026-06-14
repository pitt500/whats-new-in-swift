---
layout: default
title: The @diagnose attribute
description: Use Swift 6.4's @diagnose attribute for declaration-level control over compiler warnings.
section: Swift 6.4
section_url: /swift-6.4/
---

{% include breadcrumbs.html %}

<article class="article article-wide" markdown="1">
<p class="eyebrow">Source-level warning control</p>
<h1>The <code>@diagnose</code> attribute</h1>
<p class="page-intro"><code>@diagnose</code> refines compiler warning behavior inside a specific declaration. It lets a focused region of source code be stricter or more permissive than the rest of its module.</p>

<div class="callout"><strong>Think of it as a scoped warning policy.</strong> Choose a diagnostic group, select its behavior, and apply that policy only where it makes sense.</div>

## At a glance

```swift
@diagnose(
    StrictMemorySafety,
    as: error,
    reason: "Security-sensitive boundary"
)
func decodeHeader(_ pointer: UnsafePointer<UInt8>) {
    // StrictMemorySafety warnings are errors throughout
    // this declaration's signature and lexical scope.
}
```

### Parameters

| Parameter | Type | Purpose | Possible values |
| --- | --- | --- | --- |
| Diagnostic group ID | Identifier | Selects the warning group whose behavior changes in this declaration. | See [Documented diagnostic groups](#documented-diagnostic-groups). |
| `as:` | Behavior specifier | Defines how warnings from the selected group are emitted. | `error`, `warning`, or `ignored`. |
| `reason:` | Optional static string literal | Documents why the warning behavior differs in this declaration. | Any string literal without interpolation. |

### Behavior effects

The value passed to `as:` determines the selected group's behavior throughout the declaration:

| Behavior | Effect inside the declaration |
| --- | --- |
| `error` | Promotes warnings in the selected group to errors. |
| `warning` | Emits the selected group as warnings, even when an enclosing or module-wide policy promoted them to errors. |
| `ignored` | Suppresses warnings in the selected group within the declaration. |

## How scope works

The policy covers both the annotated declaration's **signature** and its **lexical scope**. It can be applied to functions, types, extensions, protocols, initializers, subscripts, computed properties, accessors, observers, enum cases, type aliases, associated types, imports, and declarations produced by freestanding declaration macros.

```swift
@diagnose(StrictMemorySafety, as: warning)
struct LegacyDecoder {
    func decode(_ pointer: UnsafePointer<UInt8>) {
        // StrictMemorySafety diagnostics are warnings here.
    }

    @diagnose(
        StrictMemorySafety,
        as: ignored,
        reason: "Input is validated by the caller"
    )
    func decodeTrusted(_ pointer: UnsafePointer<UInt8>) {
        // The nested declaration overrides its enclosing policy.
    }
}
```

Nested declarations can refine an enclosing policy. The innermost policy wins. Multiple attributes on the same declaration are order-sensitive, and the lexically last applicable attribute wins.

## Relationship with build settings

Module-wide flags such as `-warnings-as-errors`, `-Werror <GroupID>`, and `-Wwarning <GroupID>` establish global behavior. `@diagnose` overrides that behavior for its declaration only.

```swift
// The module uses: -warnings-as-errors
@diagnose(
    ErrorInFutureSwiftVersion,
    as: warning,
    reason: "Migration is tracked for this compatibility layer"
)
func compatibilityLayer() {
    // Future-version diagnostics remain visible without failing this build.
}
```

Important limits:

- `@diagnose` controls **warning diagnostics only**. It cannot suppress or change compiler errors.
- `-suppress-warnings` remains module-wide and overrides every `@diagnose` behavior, including `as: error`.
- The attribute does not affect source compatibility, ABI, or deployment targets.
- Attached peer declarations are outside the annotated declaration's lexical scope.

## Common strategies

```swift
// Adopt an opt-in analysis in one sensitive declaration.
@diagnose(StrictMemorySafety, as: error)
func securityBoundary() { ... }

// Preserve visibility without blocking a warnings-as-errors build.
@diagnose(NoUsage, as: warning)
func generatedCompatibilityCode() { ... }

// Document a narrow, temporary exception.
@diagnose(
    PreconcurrencyImport,
    as: ignored,
    reason: "Remove after the dependency completes its migration"
)
import LegacyNetworking
```

Use the smallest useful scope, explain temporary exceptions, and remember that selecting a group changes every warning that belongs to that group inside the declaration.

## Documented diagnostic groups

The table covers every Group ID with a corresponding document in Swift's diagnostic documentation at commit [`aacc248`](https://github.com/swiftlang/swift/tree/aacc24895250c4c91a80009069725074350ac3f5/userdocs/diagnostics). Each ID links to its source document.

The snippets demonstrate how to apply each identifier. Whether a snippet produces a diagnostic depends on the code inside the declaration, compiler version, language mode, enabled features, and build settings. `@diagnose` only affects diagnostics emitted as warnings; it cannot modify compiler errors.

{% include diagnostic-groups-table.html %}

## References

- [SE-0522: Source-Level Control Over Compiler Warnings](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0522-source-warning-control.md)
- [Swift diagnostic documentation](https://github.com/swiftlang/swift/tree/aacc24895250c4c91a80009069725074350ac3f5/userdocs/diagnostics)
- [Swift diagnostic group definitions](https://github.com/swiftlang/swift/blob/aacc24895250c4c91a80009069725074350ac3f5/include/swift/AST/DiagnosticGroups.def)
</article>
