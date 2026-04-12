//
//  BatchesTabViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation

@MainActor
class BatchesTabViewModel: ObservableObject {
    let dataStore: MyFarmsViewModel
    private var cancellable: AnyCancellable?

    init(dataStore: MyFarmsViewModel) {
        self.dataStore = dataStore
        cancellable = dataStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }

    // MARK: - Data Access

    var batches: [BatchRecord] { dataStore.batches }
    var sales: [SaleRecord] { dataStore.sales }
    var expenses: [ExpenseRecord] { dataStore.expenses }
    var dailyLogs: [DailyLogRecord] { dataStore.dailyLogs }
    var inventoryItems: [InventoryRecord] { dataStore.inventoryItems }
    var buyers: [BuyerRecord] { dataStore.buyers }
    var allSheds: [ShedRecord] { dataStore.allSheds }

    func shedName(for shedId: UUID) -> String { dataStore.shedName(for: shedId) }
    func farmName(for shed: ShedRecord) -> String { dataStore.farmName(for: shed) }
    func buyerName(for buyerId: UUID?) -> String { dataStore.buyerName(for: buyerId) }
}
