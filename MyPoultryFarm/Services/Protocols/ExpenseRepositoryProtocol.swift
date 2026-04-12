//
//  ExpenseRepositoryProtocol.swift
//  MyPoultryFarm
//

import Foundation

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
