//
//  SupabaseExpenseRepository.swift
//  MyPoultryFarm
//

import Foundation
import Supabase

struct SupabaseExpenseRepository: ExpenseRepositoryProtocol {
    private let client = SupabaseManager.shared.client

    // MARK: - Get expenses for a shed

    func getExpenses(shedId: UUID) async throws -> [ExpenseRecord] {
        struct Params: Encodable { let p_shed_id: UUID }
        return try await client.rpcValue(.expenseGetByShed, params: Params(p_shed_id: shedId))
    }

    // MARK: - Get expenses across multiple sheds

    func getExpenses(shedIds: [UUID]) async throws -> [ExpenseRecord] {
        struct Params: Encodable { let p_shed_ids: [UUID] }
        return try await client.rpcValue(.expenseGetBySheds, params: Params(p_shed_ids: shedIds))
    }

    // MARK: - Get expenses by category across multiple sheds

    func getExpensesByCategory(shedIds: [UUID], category: String) async throws -> [ExpenseRecord] {
        struct Params: Encodable {
            let p_shed_ids: [UUID]
            let p_category: String
        }
        return try await client.rpcValue(.expenseGetByCategory, params: Params(p_shed_ids: shedIds, p_category: category))
    }

    // MARK: - Get single expense

    func getExpense(id: UUID) async throws -> ExpenseRecord? {
        struct Params: Encodable { let p_id: UUID }
        let records: [ExpenseRecord] = try await client.rpcValue(.expenseGetExpense, params: Params(p_id: id))
        return records.first
    }

    // MARK: - Insert expense

    @discardableResult
    func insertExpense(_ expense: ExpenseRecord) async throws -> ExpenseRecord {
        struct Params: Encodable { let p_expense: ExpenseRecord }
        let result: [ExpenseRecord] = try await client.rpcValue(.expenseInsertExpense, params: Params(p_expense: expense))
        guard let saved = result.first else {
            throw RepositoryError.insertFailed("Expense insert returned no rows.")
        }
        return saved
    }

    // MARK: - Update expense

    func updateExpense(id: UUID, amount: Double, description: String?) async throws {
        struct Params: Encodable {
            let p_id: UUID
            let p_amount: Double
            let p_description: String?
        }
        try await client.rpcVoid(.expenseUpdateExpense, params: Params(p_id: id, p_amount: amount, p_description: description))
    }

    // MARK: - Delete expense

    func deleteExpense(id: UUID) async throws {
        struct Params: Encodable { let p_id: UUID }
        try await client.rpcVoid(.expenseDeleteExpense, params: Params(p_id: id))
    }
}
