//
//  DailyLogViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation

@MainActor
class DailyLogViewModel: ObservableObject {
    let dataStore: MyFarmsViewModel

    @Injected private var dailyLogRepo: DailyLogRepositoryProtocol

    init(dataStore: MyFarmsViewModel) {
        self.dataStore = dataStore
    }

    // MARK: - Data Access

    var sales: [SaleRecord] { dataStore.sales }
    var dailyLogs: [DailyLogRecord] { dataStore.dailyLogs }
    func shedName(for shedId: UUID) -> String { dataStore.shedName(for: shedId) }

    // MARK: - Daily Log CRUD

    func addDailyLog(batchId: UUID, shedId: UUID, logDate: String, mortality: Int, feedUsedBags: Double, feedType: String?, medicineUsed: String?, medicineQty: Double, avgWeightKg: Double, notes: String?) async throws {
        let record = DailyLogRecord(
            id: nil, batchId: batchId, shedId: shedId,
            logDate: logDate, mortality: mortality,
            feedUsedKg: feedUsedBags, feedType: feedType,
            medicineUsed: medicineUsed, medicineQty: medicineQty,
            avgWeightKg: avgWeightKg,
            notes: notes
        )
        try await dailyLogRepo.insertLog(record)
        dataStore.loadAll()
    }

    func deleteDailyLog(_ log: DailyLogRecord) async throws {
        guard let id = log.id else { return }
        try await dailyLogRepo.deleteLog(id: id)
        dataStore.loadAll()
    }
}
