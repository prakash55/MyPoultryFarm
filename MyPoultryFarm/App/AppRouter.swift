//
//  AppRouter.swift
//  MyPoultryFarm
//

import SwiftUI
import Combine

/// Defines all push-navigation destinations in the app.
enum Route: Hashable {
    case batchDetail(BatchRecord)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .batchDetail(let b): hasher.combine(b.id)
        }
    }

    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.batchDetail(let a), .batchDetail(let b)):
            return a.id == b.id
        }
    }
}

/// Centralized navigation controller for the app.
@MainActor
class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
