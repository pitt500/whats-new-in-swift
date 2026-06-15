---
layout: default
title: Optional any and some types
description: Swift 6.4 removes unnecessary parentheses around optional any and some types.
section: Swift 6.4
section_url: /swift-6.4/
---

{% include breadcrumbs.html %}

<article class="article" markdown="1">
<p class="eyebrow">Cleaner type syntax</p>
<h1>Optional <code>any</code> and <code>some</code> types</h1>
<p class="page-intro">Swift 6.4 removes the need for extra parentheses when making an <code>any</code> existential or <code>some</code> opaque type optional.</p>

## Before Swift 6.4

In Swift 6.3 and earlier, the optional marker had to apply to a parenthesized `any` or `some` type:

```swift
let error: (any Error)?

protocol Vehicle {}

struct Garage {
    var vehicle: (some Vehicle)?
}
```

Without the parentheses, the compiler produced a syntax error.

## Swift 6.4

The same optional types can now be written directly:

```swift
let error: any Error?

protocol Vehicle {}

struct Garage {
    var vehicle: some Vehicle?
}
```

This is a syntax improvement only. The optional still wraps the complete existential or opaque type; the meaning of the type has not changed.

## Reference

- [What's new in Swift - WWDC26](https://developer.apple.com/videos/play/wwdc2026/262)
</article>
