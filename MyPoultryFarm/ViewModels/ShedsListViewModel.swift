//
//  ShedsListViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation

@MainActor
class ShedsListViewModel: ObservableObject {
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
    var dailyLogs: [DailyLogRecord] { dataStore.dailyLogs }

    func sheds(for farm: FarmRecord) -> [ShedRecord] { dataStore.sheds(for: farm) }
}
