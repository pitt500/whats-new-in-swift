---
layout: default
title: Async calls in defer
description: Swift 6.4 allows async function calls inside defer blocks.
section: Swift 6.4
section_url: /swift-6.4/
---

{% include breadcrumbs.html %}

<article class="article" markdown="1">
<p class="eyebrow">Asynchronous cleanup</p>
<h1>Async calls in <code>defer</code></h1>
<p class="page-intro">Swift 6.4 allows a <code>defer</code> block to call asynchronous functions, making it easier to guarantee async cleanup when leaving a scope.</p>

## Before Swift 6.4

In Swift 6.3 and earlier, using `await` inside a `defer` block produced a compiler error:

```swift
func performOperation() async {
    defer {
        await flush() // Error: 'async' call cannot occur in a defer body
    }

    // Perform work...
}
```

## Swift 6.4

An async function can now suspend while running its deferred cleanup:

```swift
func performOperation() async {
    defer {
        await flush()
    }

    // Perform work...
}
```

The deferred block still runs when its surrounding scope exits, but it can now await asynchronous cleanup before the function returns.

## Reference

- [What's new in Swift - WWDC26](https://developer.apple.com/videos/play/wwdc2026/262)
</article>
