---
layout: default
title: Borrow and mutate accessors
description: Swift 6.4 adds borrow and mutate accessors for reading and modifying stored values in place without unnecessary copies.
section: Swift 6.4
section_url: /swift-6.4/
---

{% include breadcrumbs.html %}

<article class="article" markdown="1">
<p class="eyebrow">In-place property access</p>
<h1><code>borrow</code> and <code>mutate</code> accessors</h1>
<p class="page-intro">Swift 6.4 introduces borrowing accessors for computed properties and subscripts. They let an API provide temporary access to existing storage instead of returning and replacing independent values.</p>

## How `get` and `set` work

Consider a container that exposes a large stored value through a computed property:

```swift
struct Storage {
    var numbers: [Int]

    init(elementCount: Int) {
        numbers = Array(repeating: 0, count: elementCount)
    }
}

struct CopyingBox {
    private var storage: Storage

    init(_ value: Storage) {
        storage = value
    }

    var value: Storage {
        get { storage }
        set { storage = newValue }
    }
}
```

A `get` accessor produces a value for the caller to use. Depending on the type, the operation, and compiler optimizations, producing that value may require a copy.

A `set` accessor receives a new value and replaces the previous one. When code modifies part of a computed property:

```swift
box.value.numbers[index] += 1
```

the operation can be understood conceptually as a read-modify-write cycle:

```swift
var temporary = box.value
temporary.numbers[index] += 1
box.value = temporary
```

The getter produces the value, the caller modifies a temporary, and the setter stores the updated value.

This model is useful and normally performs well. Standard-library types such as `Array`, `String`, and `Dictionary` can share internal storage through copy-on-write, and the optimizer can eliminate some unnecessary copies. However, when a large value must actually be copied, a small mutation can become unexpectedly expensive.

## Measuring the read-modify-write cost

The following benchmark stores 400 million `Int` values (approximately 3.2 GB on a 64-bit platform) and performs 50 small mutations:

```swift
@inline(never)
func testGetSet(
    _ box: inout CopyingBox,
    iterations: Int
) {
    let count = box.value.numbers.count

    for iteration in 0..<iterations {
        box.value.numbers[iteration % count] += 1
    }
}

let elementCount = 400_000_000
let iterations = 50

var copyingBox = CopyingBox(
    Storage(elementCount: elementCount)
)

let getSetTime = measure {
    testGetSet(
        &copyingBox,
        iterations: iterations
    )
}
```

`@inline(never)` and the access pattern are intentional: they make the read-modify-write behavior easier to observe instead of allowing the optimizer to collapse the entire benchmark into a simpler operation.

One run produced:

```text
Stored value: 400,000,000 Ints (~3,200 MB)
Small mutations: 50

get / set: 6.80 s
```

> This is an illustrative microbenchmark, not a universal prediction. Results depend on the compiler, optimization settings, hardware, memory pressure, and surrounding code. The 3.2 GB input also requires substantial memory, especially while both benchmark variants and temporary copies are alive.

## Borrowing the existing storage

The same property can use `borrow` and `mutate`:

```swift
struct BorrowingBox {
    private var storage: Storage

    init(_ value: Storage) {
        storage = value
    }

    var value: Storage {
        borrow {
            return storage
        }

        mutate {
            return &storage
        }
    }
}
```

The caller still uses the property normally:

```swift
box.value.numbers[index] += 1
```

What changes is how the property provides access.

### `borrow`

`borrow` provides temporary, read-only access to the value already stored inside the container:

```swift
borrow {
    return storage
}
```

It does not produce an independent value for the caller. While that borrow is active, Swift's exclusivity rules prevent incompatible mutations of the container.

### `mutate`

`mutate` provides temporary, exclusive read-write access to the original storage:

```swift
mutate {
    return &storage
}
```

The ampersand indicates that the accessor exposes the stored value for in-place mutation. This access behaves similarly to an `inout` access: no other code can access the same storage incompatibly until the mutation ends.

Using the same benchmark structure:

```swift
@inline(never)
func testBorrowMutate(
    _ box: inout BorrowingBox,
    iterations: Int
) {
    let count = box.value.numbers.count

    for iteration in 0..<iterations {
        box.value.numbers[iteration % count] += 1
    }
}
```

one run produced:

```text
get / set:       6.80 s
borrow / mutate: 0.29 µs
```

The important distinction is not the exact ratio. With `get` and `set`, avoiding a copy may depend on optimization. With `borrow` and `mutate`, access to the existing storage is part of the property's semantics.

## Accessor rules

A property that declares `mutate` must also declare `borrow`:

```swift
var value: Storage {
    borrow { storage }
    mutate { &storage }
}
```

Swift does not allow write-only properties, and matching read and write access scopes give callers consistent behavior.

A borrowing property cannot mix `borrow` with another read accessor such as `get` or `yielding borrow`. Similarly, `mutate` cannot coexist with `yielding mutate` or `yielding borrow` on the same property.

Borrowing accessors can also be protocol requirements:

```swift
protocol BorrowingContainer {
    associatedtype Element

    var element: Element {
        borrow mutate
    }
}
```

They can be used for computed properties and subscripts, and they enable access to noncopyable values that a regular getter could not return by copying.

## Stable storage is required

A borrowing accessor can only expose a value whose lifetime Swift can guarantee for the duration of the access.

Returning an existing stored property is valid:

```swift
struct Container {
    private var storage: Storage

    var value: Storage {
        borrow {
            return storage
        }
    }
}
```

Returning a local or newly constructed temporary is not:

```swift
var value: Storage {
    borrow {
        let temporary = Storage(elementCount: 100)
        return temporary // Error: local value does not outlive the accessor
    }
}

var anotherValue: Storage {
    borrow {
        return Storage(elementCount: 100) // Error: temporary value
    }
}
```

A regular `get` accessor remains the correct choice when a property needs to calculate or construct a new value.

## Exclusivity

Borrowing is safe because Swift restricts conflicting access while the loan is active.

During a read-only borrow, the owner cannot be mutated incompatibly:

```swift
use(container.value)

func use(_ value: borrowing Storage) {
    // `value` can be read here.
    // The owning container cannot be mutated while this access is active.
}
```

During a mutable borrow, access is exclusive:

```swift
modify(&container.value)

func modify(_ value: inout Storage) {
    value.numbers[0] += 1
    // No competing access to the same container is allowed here.
}
```

For a borrowing subscript, the access applies to the entire containing value. For example, two simultaneous mutable accesses to different elements of the same value are not allowed:

```swift
swap(&container[0], &container[1]) // Error: overlapping access
```

## When to use them

`borrow` and `mutate` do not replace `get` and `set`. Traditional accessors remain simpler and more flexible for most properties, especially when values are small, copies are inexpensive, or the property constructs a result dynamically.

Borrowing accessors are most useful when:

- a container exposes a large stored value;
- repeated read-modify-write operations cause measurable copying;
- a collection or wrapper needs to expose noncopyable elements;
- in-place access is important in performance-sensitive or embedded code;
- an API should guarantee storage access instead of relying on the optimizer to remove copies.

Measure real code before changing an existing API. Switching between traditional and borrowing accessors can also affect source and ABI compatibility.

## Current limitations

The most important restrictions in Swift 6.4 are:

- The returned value must come from stable storage; it cannot be a local or constructed temporary.
- `borrow` and `mutate` cannot currently implement properties of classes or actors.
- A mutable global variable cannot be borrowed or mutated through these accessors.
- A `mutate` accessor must be accompanied by `borrow`.
- Borrowed and mutable accesses remain subject to Swift's exclusivity rules.
- The current implementation does not support every control-flow shape, including accessors with multiple `return` statements.

Classes and actors require runtime exclusivity checks both before and after a property access. Borrowing accessors do not provide a way to execute accessor code after the client's access ends, so they cannot currently satisfy that requirement.

## Summary

```text
get      produces a value
borrow   lends read-only access to an existing value

set      replaces a value
mutate   lends exclusive access to modify an existing value in place
```

For ordinary properties, continue using `get` and `set`. Reach for `borrow` and `mutate` when copying is expensive or impossible and the property can safely expose stable storage.

## References

- [SE-0507: Borrow and Mutate Accessors](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0507-borrow-accessors.md)
- [What's new in Swift - WWDC26](https://developer.apple.com/videos/play/wwdc2026/262)
</article>
