//
//  DIContainer.swift
//  MyPoultryFarm
//

import Foundation

/// A lightweight dependency injection container using key-based registration.
final class DIContainer {
    static let shared = DIContainer()

    private var factories: [String: () -> Any] = [:]

    private init() {}

    // MARK: - Register

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }

    // MARK: - Resolve

    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let factory = factories[key] else {
            fatalError("No registration found for \(key). Call DIContainer.shared.register(\(key).self) first.")
        }
        guard let instance = factory() as? T else {
            fatalError("Factory for \(key) returned wrong type.")
        }
        return instance
    }
}

// MARK: - @Injected Property Wrapper

@propertyWrapper
struct Injected<T> {
    private var value: T

    init() {
        self.value = DIContainer.shared.resolve(T.self)
    }

    var wrappedValue: T {
        get { value }
        mutating set { value = newValue }
    }
}
