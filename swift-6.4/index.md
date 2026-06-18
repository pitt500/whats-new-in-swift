---
layout: default
title: What's New in Swift 6.4
description: Explore highlighted language and tooling changes introduced with Swift 6.4.
---

{% include breadcrumbs.html %}

<section class="hero">
  <p class="eyebrow">Swift 6.4</p>
  <h1>What's new in Swift 6.4</h1>
  <p>Explore focused improvements to Swift's language and compiler, with concise explanations and practical examples.</p>
</section>

<section class="section">
  <p class="eyebrow">Highlighted features</p>
  <div class="grid">
    <a class="card" href="{{ '/swift-6.4/diagnose/' | relative_url }}">
      <span class="number">01 · Compiler diagnostics</span>
      <h3><code>@diagnose</code></h3>
      <p>Ignore, enable, or promote specific warning groups inside a declaration.</p>
    </a>
    <a class="card" href="{{ '/swift-6.4/optional-any-some/' | relative_url }}">
      <span class="number">02 · Type syntax</span>
      <h3>Optional <code>any</code> and <code>some</code></h3>
      <p>Write optional existential and opaque types without extra parentheses.</p>
    </a>
    <a class="card" href="{{ '/swift-6.4/async-defer/' | relative_url }}">
      <span class="number">03 · Concurrency</span>
      <h3>Async calls in <code>defer</code></h3>
      <p>Call asynchronous functions while performing deferred cleanup.</p>
    </a>
    <a class="card" href="{{ '/swift-6.4/unhandled-task-errors/' | relative_url }}">
      <span class="number">04 · Concurrency</span>
      <h3>Warnings for unhandled task errors</h3>
      <p>Catch errors that could otherwise be silently ignored inside an unstructured task.</p>
    </a>
    <a class="card" href="{{ '/swift-6.4/any-apple-os-availability/' | relative_url }}">
      <span class="number">05 · Availability</span>
      <h3><code>anyAppleOS</code> availability</h3>
      <p>Mark APIs as available across all Apple platforms with one shared OS version.</p>
    </a>
    <a class="card" href="{{ '/swift-6.4/module-selectors/' | relative_url }}">
      <span class="number">06 · Name lookup</span>
      <h3>Module selectors</h3>
      <p>Disambiguate declarations when a module and a type share the same name.</p>
    </a>
  </div>
</section>
