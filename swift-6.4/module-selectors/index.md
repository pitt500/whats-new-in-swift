---
layout: default
title: Module selectors
description: Swift 6.4 adds module selectors to disambiguate declarations when a module and a type share the same name.
section: Swift 6.4
section_url: /swift-6.4/
---

{% include breadcrumbs.html %}

<article class="article" markdown="1">
<p class="eyebrow">Name disambiguation</p>
<h1>Module selectors</h1>
<p class="page-intro">Swift 6.4 introduces the module selector syntax <code>ModuleName::Declaration</code>, which explicitly selects a declaration from a specific module.</p>

## The problem

Consider a module named `Animal`. The following declarations are part of that module:

```swift
// Animal module

public struct Animal {
    public init() {}
}

public struct Fox {
    public let name: String
    public let habitat: String

    public init(name: String, habitat: String) {
        self.name = name
        self.habitat = habitat
    }
}
```

In a different module, importing `Animal` makes both public types available:

```swift
// Application module

import Animal

let animal = Animal()
let fox = Animal.Fox( // Error: Type 'Animal' has no member 'Fox'
    name: "Juniper",
    habitat: "the redwood forest"
)
```

In `Animal()`, the name refers to the `Animal` type. That type then shadows the module with the same name, so `Animal.Fox` is interpreted as a lookup for a nested `Fox` type inside the `Animal` struct.

## Previous solution

One workaround was to use scoped imports and reference the types without the module name:

```swift
import struct Animal.Animal
import struct Animal.Fox

let animal = Animal()
let fox = Fox(
    name: "Juniper",
    habitat: "the redwood forest"
)
```

## Swift 6.4

A module selector uses `::` to state that the name on its left is a module:

```swift
import Animal

let animal = Animal()
let fox = Animal::Fox(
    name: "Juniper",
    habitat: "the redwood forest"
)
```

`Animal()` still refers to the type, while `Animal::Fox` explicitly selects `Fox` from the `Animal` module. Only declarations imported and accessible in the current file can be selected.

## References

- [What's new in Swift - WWDC26](https://developer.apple.com/videos/play/wwdc2026/262)
- [SE-0491: Module selectors for name disambiguation](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0491-module-selectors.md)
</article>
