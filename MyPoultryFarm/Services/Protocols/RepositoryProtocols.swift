//
//  RepositoryProtocols.swift
//  MyPoultryFarm
//
//  Abstract interfaces for data access. Swap implementations
//  (Supabase, Firebase, CoreData, REST, etc.) without changing ViewModels.
//

import Foundation

// MARK: - ProfileRepositoryProtocol

protocol ProfileRepositoryProtocol {
    func getProfile(userId: UUID) async throws -> ProfileRecord?
    func upsertProfile(_ profile: ProfileRecord) async throws
    func updateName(userId: UUID, fullName: String) async throws
    func updatePhone(userId: UUID, phone: String) async throws
    func markOnboardingComplete(userId: UUID) async throws
    func isOnboardingCompleted(userId: UUID) async throws -> Bool
}

// MARK: - FarmRepositoryProtocol

protocol FarmRepositoryProtocol {
    func getFarms(ownerId: UUID) async throws -> [FarmRecord]
    func getFarm(id: UUID) async throws -> FarmRecord?
    @discardableResult
    func insertFarm(_ farm: FarmRecord) async throws -> FarmRecord
    func updateFarm(id: UUID, name: String, location: String?) async throws
    func deleteFarm(id: UUID) async throws
}

// MARK: - ShedRepositoryProtocol

protocol ShedRepositoryProtocol {
    func getSheds(farmId: UUID) async throws -> [ShedRecord]
    func getShed(id: UUID) async throws -> ShedRecord?
    @discardableResult
    func insertShed(_ shed: ShedRecord) async throws -> ShedRecord
    @discardableResult
    func insertSheds(_ sheds: [ShedRecord]) async throws -> [ShedRecord]
    func updateShed(id: UUID, name: String, capacity: Int) async throws
    func deleteShed(id: UUID) async throws
    func deleteSheds(farmId: UUID) async throws
}

// MARK: - AuthServiceProtocol

/// Abstracts authentication so the app isn't coupled to Supabase Auth.
protocol AuthServiceProtocol {
    /// A unique identifier for the current user, or nil if not signed in.
    var currentUserId: UUID? { get async }

    /// Stream of auth state changes: (isSignedIn, userId, displayName)
    func authStateChanges() -> AsyncStream<(isSignedIn: Bool, userId: UUID?, displayName: String?)>

    func signInWithEmail(email: String, password: String) async throws -> AuthUser
    func signUpWithEmail(email: String, password: String, displayName: String) async throws -> AuthUser
    func signInWithOTP(phone: String) async throws
    func verifyOTP(phone: String, token: String) async throws -> AuthUser
    func signInWithGoogle() async throws
    func signOut() async throws
}

/// A lightweight user representation returned by AuthService.
struct AuthUser {
    let id: UUID
    let email: String?
    let phone: String?
    let displayName: String?
}

// MARK: - BatchRepositoryProtocol

protocol BatchRepositoryProtocol {
    func getBatches(shedId: UUID) async throws -> [BatchRecord]
    func getBatches(shedIds: [UUID]) async throws -> [BatchRecord]
    func getBatchesByStatus(shedIds: [UUID], status: String) async throws -> [BatchRecord]
    func getBatch(id: UUID) async throws -> BatchRecord?
    @discardableResult
    func insertBatch(_ batch: BatchRecord) async throws -> BatchRecord
    func updateBatch(id: UUID, purchasedBirds: Int, freeBirds: Int, costPerBird: Double, status: String, endDate: String?) async throws
    func deleteBatch(id: UUID) async throws
}

// MARK: - InventoryRepositoryProtocol

protocol InventoryRepositoryProtocol {
    func getInventory(shedId: UUID) async throws -> [InventoryRecord]
    func getInventory(shedIds: [UUID]) async throws -> [InventoryRecord]
    func getInventoryByCategory(shedIds: [UUID], category: String) async throws -> [InventoryRecord]
    func getInventoryItem(id: UUID) async throws -> InventoryRecord?
    @discardableResult
    func insertItem(_ item: InventoryRecord) async throws -> InventoryRecord
    func updateItem(id: UUID, quantity: Double, used: Double) async throws
    func deleteItem(id: UUID) async throws
}

// MARK: - SalesRepositoryProtocol

protocol SalesRepositoryProtocol {
    func getSales(shedId: UUID) async throws -> [SaleRecord]
    func getSales(shedIds: [UUID]) async throws -> [SaleRecord]
    func getSale(id: UUID) async throws -> SaleRecord?
    @discardableResult
    func insertSale(_ sale: SaleRecord) async throws -> SaleRecord
    func updateSale(id: UUID, birdCount: Int, totalWeightKg: Double, costPerKg: Double, totalAmount: Double) async throws
    func deleteSale(id: UUID) async throws
}

// MARK: - ExpenseRepositoryProtocol

protocol ExpenseRepositoryProtocol {
    func getExpenses(shedId: UUID) async throws -> [ExpenseRecord]
    func getExpenses(shedIds: [UUID]) async throws -> [ExpenseRecord]
    func getExpensesByCategory(shedIds: [UUID], category: String) async throws -> [ExpenseRecord]
    func getExpense(id: UUID) async throws -> ExpenseRecord?
    @discardableResult
    func insertExpense(_ expense: ExpenseRecord) async throws -> ExpenseRecord
    func updateExpense(id: UUID, amount: Double, description: String?) async throws
    func deleteExpense(id: UUID) async throws
}

// MARK: - BuyerRepositoryProtocol

protocol BuyerRepositoryProtocol {
    func getBuyers(ownerId: UUID) async throws -> [BuyerRecord]
    func getBuyer(id: UUID) async throws -> BuyerRecord?
    @discardableResult
    func insertBuyer(_ buyer: BuyerRecord) async throws -> BuyerRecord
    func updateBuyer(id: UUID, agencyName: String, handlerName: String?, phone: String?) async throws
    func deleteBuyer(id: UUID) async throws
}

// MARK: - DailyLogRepositoryProtocol

protocol DailyLogRepositoryProtocol {
    func getLogs(batchId: UUID) async throws -> [DailyLogRecord]
    func getLogs(shedIds: [UUID]) async throws -> [DailyLogRecord]
    @discardableResult
    func insertLog(_ log: DailyLogRecord) async throws -> DailyLogRecord
    func deleteLog(id: UUID) async throws
}
