//
//  ExpenseViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation

@MainActor
class ExpenseViewModel: ObservableObject {
    let dataStore: MyFarmsViewModel

    @Injected private var expenseRepo: ExpenseRepositoryProtocol

    init(dataStore: MyFarmsViewModel) {
        self.dataStore = dataStore
    }

    // MARK: - Data Access

    var allSheds: [ShedRecord] { dataStore.allSheds }
    var batches: [BatchRecord] { dataStore.batches }
    func farmName(for shed: ShedRecord) -> String { dataStore.farmName(for: shed) }

    // MARK: - Expense CRUD

    func addExpense(shedId: UUID, batchId: UUID?, category: String, amount: Double, description: String?, expenseDate: String) async throws {
        let record = ExpenseRecord(
            id: nil, shedId: shedId, batchId: batchId,
            category: category, amount: amount,
            description: description, expenseDate: expenseDate
        )
        try await expenseRepo.insertExpense(record)
        dataStore.loadAll()
    }

    func deleteExpense(_ expense: ExpenseRecord) async throws {
        guard let id = expense.id else { return }
        try await expenseRepo.deleteExpense(id: id)
        dataStore.loadAll()
    }
}
