@available(iOS, deprecated: 18.0)
@available(macOS, deprecated: 15.0)
func calculateSomething() -> Int {
    print("Deprecated!")
    return 0
}

// Suppress a known deprecation at one carefully chosen boundary.
@diagnose(
    DeprecatedDeclaration,
    as: ignored,
    reason: "Maintain until end of release"
)
func complexOperation() {
    let value = calculateSomething()
    print("Complex result is", value)
}

// Keep the migration visible without blocking a warnings-as-errors build.
@diagnose(
    DeprecatedDeclaration,
    as: warning,
    reason: "Migration tracked separately"
)
func compatibilityLayer() {
    _ = calculateSomething()
}

// Make deprecation warnings fail the build in this declaration.
@diagnose(
    DeprecatedDeclaration,
    as: error,
    reason: "New code must not use deprecated APIs"
)
func modernOperation() {
    _ = calculateSomething() // Error: 'calculateSomething()' is deprecated
}

