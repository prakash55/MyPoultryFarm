//
//  InventoryViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation

@MainActor
class InventoryViewModel: ObservableObject {
    let dataStore: MyFarmsViewModel

    @Injected private var inventoryRepo: InventoryRepositoryProtocol
    @Injected private var expenseRepo: ExpenseRepositoryProtocol

    init(dataStore: MyFarmsViewModel) {
        self.dataStore = dataStore
    }

    // MARK: - Data Access

    var allSheds: [ShedRecord] { dataStore.allSheds }
    var batches: [BatchRecord] { dataStore.batches }
    func farmName(for shed: ShedRecord) -> String { dataStore.farmName(for: shed) }

    // MARK: - Inventory CRUD

    func addInventoryItem(shedId: UUID, batchId: UUID?, category: String, itemName: String, feedType: String?, quantity: Double, unit: String, costPerUnit: Double, totalCost: Double) async throws {
        let record = InventoryRecord(
            id: nil, shedId: shedId, batchId: batchId,
            category: category, itemName: itemName,
            feedType: feedType,
            quantity: quantity, used: 0, unit: unit,
            costPerUnit: costPerUnit, totalCost: totalCost
        )
        try await inventoryRepo.insertItem(record)

        if totalCost > 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let today = formatter.string(from: Date())
            let desc: String
            if category == "feed" {
                desc = "\(feedType?.capitalized ?? "Feed") – \(Int(quantity)) bags @ ₹\(Int(costPerUnit))/bag"
            } else {
                desc = "\(itemName) – qty \(Int(quantity))"
            }
            let expense = ExpenseRecord(
                id: nil, shedId: shedId, batchId: batchId,
                category: category,
                amount: totalCost,
                description: desc,
                expenseDate: today
            )
            try await expenseRepo.insertExpense(expense)
        }
        dataStore.loadAll()
    }

    func deleteInventoryItem(_ item: InventoryRecord) async throws {
        guard let id = item.id else { return }
        try await inventoryRepo.deleteItem(id: id)
        dataStore.loadAll()
    }
}
