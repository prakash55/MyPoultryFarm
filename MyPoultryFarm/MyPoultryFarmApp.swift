//
//  MyPoultryFarmApp.swift
//  MyPoultryFarm
//
//  Created by Prakash on 10/04/26.
//

import SwiftUI

@main
struct MyPoultryFarmApp: App {

    init() {
        Self.registerDependencies()
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }

    /// Register all service implementations in the DI container.
    /// Swap Supabase implementations for another backend here.
    private static func registerDependencies() {
        let container = DIContainer.shared
        container.register(AuthServiceProtocol.self) { SupabaseAuthService() }
        container.register(ProfileRepositoryProtocol.self) { SupabaseProfileRepository() }
        container.register(FarmRepositoryProtocol.self) { SupabaseFarmRepository() }
        container.register(ShedRepositoryProtocol.self) { SupabaseShedRepository() }
        container.register(BatchRepositoryProtocol.self) { SupabaseBatchRepository() }
        container.register(InventoryRepositoryProtocol.self) { SupabaseInventoryRepository() }
        container.register(SalesRepositoryProtocol.self) { SupabaseSalesRepository() }
        container.register(ExpenseRepositoryProtocol.self) { SupabaseExpenseRepository() }
        container.register(BuyerRepositoryProtocol.self) { SupabaseBuyerRepository() }
        container.register(DailyLogRepositoryProtocol.self) { SupabaseDailyLogRepository() }
    }
}
