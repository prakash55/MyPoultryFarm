//
//  DashboardTabViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation

@MainActor
class DashboardTabViewModel: ObservableObject {
    let dataStore: MyFarmsViewModel
    private var cancellable: AnyCancellable?

    init(dataStore: MyFarmsViewModel) {
        self.dataStore = dataStore
        cancellable = dataStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }

    // MARK: - Data Access

    var farms: [FarmRecord] { dataStore.farms }
    var batches: [BatchRecord] { dataStore.batches }
    var sales: [SaleRecord] { dataStore.sales }
    var expenses: [ExpenseRecord] { dataStore.expenses }
    var dailyLogs: [DailyLogRecord] { dataStore.dailyLogs }
    var inventoryItems: [InventoryRecord] { dataStore.inventoryItems }
    var allSheds: [ShedRecord] { dataStore.allSheds }

    func shedName(for shedId: UUID) -> String { dataStore.shedName(for: shedId) }
    func farmName(for shed: ShedRecord) -> String { dataStore.farmName(for: shed) }
    func sheds(for farm: FarmRecord) -> [ShedRecord] { dataStore.sheds(for: farm) }
    func totalCapacity(for farm: FarmRecord) -> Int { dataStore.totalCapacity(for: farm) }
    func buyerName(for buyerId: UUID?) -> String { dataStore.buyerName(for: buyerId) }
}
