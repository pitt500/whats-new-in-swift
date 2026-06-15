---
layout: default
title: Warnings for unhandled task errors
description: Swift 6.4 warns when errors thrown inside an unstructured task could be silently ignored.
section: Swift 6.4
section_url: /swift-6.4/
---

{% include breadcrumbs.html %}

<article class="article" markdown="1">
<p class="eyebrow">Safer concurrency</p>
<h1>Warnings for unhandled task errors</h1>
<p class="page-intro">Swift 6.4 warns when an error thrown inside an unstructured <code>Task</code> could be silently ignored, helping you catch potential bugs before they ship.</p>

## Before Swift 6.4

In Swift 6.3 and earlier, this task could throw an error without producing a warning when its result was discarded:

```swift
func doSomething() {
    Task {
        try await myAsyncThrowableMethod()
    }
}
```

## Swift 6.4

The compiler now warns about the potentially unhandled error:

```swift
func doSomething() {
    Task { // Warning: task may produce an unhandled error
        try await myAsyncThrowableMethod()
    }
}
```

Handle the error inside the task with `do` and `catch`, or keep and consume the task's result when appropriate.

## Reference

- [What's new in Swift - WWDC26](https://developer.apple.com/videos/play/wwdc2026/262)
</article>
