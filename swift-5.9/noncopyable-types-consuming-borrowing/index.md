---
layout: default
title: Ownership with Noncopyable Types, borrowing, and consuming
description: Swift 5.9 introduced noncopyable types, borrowing, and consuming so APIs can model one-time values, prevent accidental copies, and make ownership transfer explicit.
section: Swift 5.9
section_url: /swift-5.9/
---

{% include breadcrumbs.html %}

<article class="article" markdown="1">
<p class="eyebrow">Ownership</p>
<h1>Ownership with noncopyable types, <code>borrowing</code>, and <code>consuming</code></h1>
<p class="page-intro">Swift 5.9 added tools for modeling values that should not be copied freely. A value can be borrowed for temporary use, consumed when ownership transfers, or marked as noncopyable so the compiler cannot silently duplicate it.</p>

## The problem

Imagine a ticket for an event.

You can show the ticket at the door more than once. Someone can inspect it, read the seat number, and give it back. But once the ticket is used to enter the event, that same ticket should not be usable again.

That rule is easy to describe in the real world:

```text
Inspecting a ticket should not spend it.
Using a ticket should spend it.
```

With an ordinary Swift value, that rule is not part of the type system. Structs are copyable by default, so a plain `Ticket` can be passed around and duplicated like any other value.

```swift
struct Ticket {
    let id: Int
}
```

That is usually exactly what you want from Swift value types. But for one-time values, copyability can make the model too permissive.

## What ownership means here

In this context, ownership answers a practical question:

```text
Who is allowed to keep using this value?
```

If a function only needs temporary access, it should borrow the value. If a function finishes the value's job, it should consume the value. If a value represents something that must not be duplicated, it can be noncopyable.

For the ticket example:

- inspecting a ticket borrows it;
- using a ticket consumes it;
- making the ticket noncopyable prevents accidental duplicate tickets.

Swift 5.9 gives these ideas names:

```swift
borrowing   // temporary access without taking ownership
consuming   // takes ownership and ends use of the original binding
~Copyable   // prevents implicit copies of the value
```

## A ticket without ownership APIs

Start with a simple model:

```swift
struct Ticket {
    let id: Int
}

struct Inspector {
    let name: String

    func inspect(ticket: Ticket) {
        print("\(name) inspected ticket \(ticket.id).")
    }
}

struct Client {
    let name: String

    func use(ticket: Ticket) {
        print("\(name) used ticket \(ticket.id).")
    }
}
```

This code is simple, readable, and fully valid:

```swift
let inspector = Inspector(name: "Gate Inspector")
let client = Client(name: "Ana")
let ticket = Ticket(id: 42)

inspector.inspect(ticket: ticket)
inspector.inspect(ticket: ticket)

client.use(ticket: ticket)
client.use(ticket: ticket)
```

The problem is not that Swift allows this code to compile. The problem is that the type does not express the rule that the ticket should only be used once.

Because `Ticket` is a normal copyable struct, the compiler cannot reject "this ticket was used in more than one place" or "this ticket was used more than once." The value can be copied, stored, and passed around freely.

Without ownership APIs, you need runtime validation instead:

```swift
struct Ticket {
    let id: Int
}

struct TicketValidator {
    private var usedTicketIDs: Set<Int> = []

    mutating func use(_ ticket: Ticket) throws {
        guard !usedTicketIDs.contains(ticket.id) else {
            throw TicketError.alreadyUsed
        }

        usedTicketIDs.insert(ticket.id)
    }
}

enum TicketError: Error {
    case alreadyUsed
}
```

This can be the right design when ticket validity is truly external state, such as checking a server. But it changes the kind of safety you get. Runtime validation detects the problem later. Ownership annotations can make invalid flows visible at compile time.

## The same ticket with Swift 5.9 ownership

The first step is to make `Ticket` noncopyable:

```swift
struct Ticket: ~Copyable {
    let id: Int
}
```

`~Copyable` means `Ticket` does not conform to the default `Copyable` behavior. Swift cannot silently duplicate it to keep old code working.

> Note: once a type is noncopyable, parameters that use that type need to say how ownership is passed. The common choices are `borrowing`, `consuming`, or `inout`. This is where the API design becomes explicit: each function has to decide whether it only looks at the value, takes it over, or mutates it in place.

With that ownership decision required, inspection is the easiest place to start: it should borrow the ticket.

```swift
struct Inspector {
    let name: String

    func inspect(ticket: borrowing Ticket) {
        print("\(name) inspected ticket \(ticket.id).")
    }
}
```

The `borrowing` parameter says that `inspect(ticket:)` can read the ticket, but it does not take ownership of it. The caller can keep using the ticket after inspection.

That restriction also applies inside the function. If `inspect(ticket:)` tries to copy or move the borrowed ticket, the compiler rejects it:

```swift
func inspect(ticket: borrowing Ticket) {
    let copiedTicket = ticket // Error
    print(copiedTicket.id)
}
```

This is `borrowing` doing its job. The function can read the ticket, but it cannot take ownership of the ticket by copying or moving it.

Using the ticket should consume it:

```swift
struct Client {
    let name: String

    func use(ticket: consuming Ticket) {
        print("\(name) used ticket \(ticket.id).")
    }
}
```

The `consuming` parameter says that `use(ticket:)` takes ownership of the ticket. After that call, the original binding is no longer available.

Now the intended flow is part of the API:

```swift
let inspector = Inspector(name: "Gate Inspector")
let client = Client(name: "Ana")
let ticket = Ticket(id: 42)

inspector.inspect(ticket: ticket)
inspector.inspect(ticket: ticket)

client.use(ticket: ticket)
```

Inspection can happen multiple times because it borrows the ticket. The client can use the ticket once because using it consumes the ticket.

Trying to inspect after consumption should not compile:

```swift
let inspector = Inspector(name: "Gate Inspector")
let client = Client(name: "Ana")
let ticket = Ticket(id: 42)

client.use(ticket: ticket)
inspector.inspect(ticket: ticket) // Error: ticket was consumed
```

The same applies to consuming the same ticket twice:

```swift
let client = Client(name: "Ana")
let ticket = Ticket(id: 42)

client.use(ticket: ticket)
client.use(ticket: ticket) // Error: ticket was consumed
```

That is the key shift. The one-time rule is no longer just a convention or a runtime check. It is represented in the function signatures.

## Real Use Cases

The ticket example is intentionally small: it teaches the shape of the problem without any framework or infrastructure in the way. In real projects, the same ownership pattern appears whenever a value represents a unique capability or resource, and duplicating it or finishing it more than once would be invalid.

Here are a few places where these APIs start to look less like language theory and more like everyday engineering.

### Open files

An open file descriptor should not be copied accidentally. Reading or writing can borrow the handle; closing it should consume the handle.

```swift
struct OpenFile: ~Copyable {
    let descriptor: Int32
}

struct FileWriter {
    func write(_ text: String, to file: borrowing OpenFile) {
        // Use the descriptor without closing it.
    }

    func close(_ file: consuming OpenFile) {
        // Close the descriptor.
    }
}
```

### Database transactions

A transaction can be inspected or validated many times, but it should be committed or rolled back once.

```swift
struct DatabaseTransaction: ~Copyable {
    let id: UUID
}

struct Database {
    func validate(_ transaction: borrowing DatabaseTransaction) {
        // Check the transaction without ending it.
    }

    func commit(_ transaction: consuming DatabaseTransaction) {
        // Finish the transaction.
    }
}
```

### Temporary access tokens

A token can grant temporary access to a protected resource. Previewing or reading can borrow it; finishing access can consume it.

```swift
struct AccessToken: ~Copyable {
    let value: String
}

struct FileImporter {
    func preview(using token: borrowing AccessToken) {
        // Read using temporary access.
    }

    func finish(using token: consuming AccessToken) {
        // End the access.
    }
}
```

In all three cases, the goal is the same: make it clear which operations merely use a value and which operations end its lifetime.

## Conclusion

Apple introduced these ownership features so Swift APIs can express how values move through a program directly in their signatures. That matters when copying is expensive, impossible, or simply the wrong semantic model for the resource being represented.

Ownership answers: who is allowed to keep using this value?

| Feature | Meaning |
| --- | --- |
| `~Copyable` | The value cannot be implicitly copied. |
| `borrowing` | The function can use the value temporarily without taking ownership. |
| `consuming` | The function takes ownership, ending use of the original binding. |

Use them when a value represents something unique: a ticket, a handle, a transaction, a token, or any resource where "just make another copy" would be the wrong answer. Runtime checks can detect misuse after it happens; ownership annotations can prevent some invalid flows from compiling in the first place.

## References

- [Swift 5.9 Released](https://www.swift.org/blog/swift-5.9-released/)
- [SE-0377: borrowing and consuming parameter ownership modifiers](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0377-parameter-ownership-modifiers.md)
- [SE-0390: Noncopyable structs and enums](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0390-noncopyable-structs-and-enums.md)
- [SE-0366: consume operator to end the lifetime of a variable binding](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0366-move-function.md)
</article>
