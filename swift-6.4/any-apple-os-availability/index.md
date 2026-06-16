---
layout: default
title: anyAppleOS availability
description: Swift 6.4 adds anyAppleOS for @available when all Apple platforms share the same version.
section: Swift 6.4
section_url: /swift-6.4/
---

{% include breadcrumbs.html %}

<article class="article" markdown="1">
<p class="eyebrow">Simpler availability</p>
<h1><code>anyAppleOS</code> availability</h1>
<p class="page-intro">Swift 6.4 adds <code>anyAppleOS</code> to the <code>@available</code> attribute, letting you describe APIs that become available across all Apple platforms at the same OS version.</p>

## Before Swift 6.4

Availability often had to list every Apple platform individually, and each platform could have a different version number:

```swift
@available(
    iOS 18,
    macOS 15,
    tvOS 18,
    watchOS 11,
    visionOS 2,
    *
)
func myMethod() {
    print("Subscribe!")
}
```

That gets harder to scan as more platforms are added.

## Swift 6.4

With Apple's newer year-based OS versioning, APIs that become available on all Apple platforms in the same release can use one shared value:

```swift
@available(
    anyAppleOS 26,
    *
)
func myMethod() {
    print("Subscribe!")
}
```

Use `anyAppleOS` when the same availability version applies to all Apple platforms. If a platform needs a different version, keep listing the platforms explicitly.

## Reference

- [What's new in Swift - WWDC26](https://developer.apple.com/videos/play/wwdc2026/262)
</article>
