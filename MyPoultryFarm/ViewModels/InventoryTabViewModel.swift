//
//  InventoryTabViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation

@MainActor
class InventoryTabViewModel: ObservableObject {
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
    var inventoryItems: [InventoryRecord] { dataStore.inventoryItems }
    var dailyLogs: [DailyLogRecord] { dataStore.dailyLogs }
    var allSheds: [ShedRecord] { dataStore.allSheds }
    var shedsByFarm: [UUID: [ShedRecord]] { dataStore.shedsByFarm }

    func shedName(for shedId: UUID) -> String { dataStore.shedName(for: shedId) }
    func farmName(for shed: ShedRecord) -> String { dataStore.farmName(for: shed) }
}
