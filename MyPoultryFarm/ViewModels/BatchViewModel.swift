//
//  BatchViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation

@MainActor
class BatchViewModel: ObservableObject {
    let dataStore: MyFarmsViewModel

    @Injected private var batchRepo: BatchRepositoryProtocol

    init(dataStore: MyFarmsViewModel) {
        self.dataStore = dataStore
    }

    // MARK: - Data Access

    var allSheds: [ShedRecord] { dataStore.allSheds }
    var batches: [BatchRecord] { dataStore.batches }
    func farmName(for shed: ShedRecord) -> String { dataStore.farmName(for: shed) }

    // MARK: - Batch CRUD

    func addBatch(shedId: UUID, batchName: String?, purchasedBirds: Int, freeBirds: Int, costPerBird: Double, startDate: String, notes: String?) async throws {
        let existing = dataStore.batches.filter { $0.shedId == shedId }
        let nextNumber = (existing.map(\.batchNumber).max() ?? 0) + 1
        let record = BatchRecord(
            id: nil, shedId: shedId, batchNumber: nextNumber,
            batchName: batchName,
            purchasedBirds: purchasedBirds, freeBirds: freeBirds,
            costPerBird: costPerBird, totalBirds: nil, totalCost: nil,
            startDate: startDate, endDate: nil,
            status: "running", notes: notes
        )
        _ = try await batchRepo.insertBatch(record)
        dataStore.loadAll()
    }

    func closeBatch(_ batch: BatchRecord) async throws {
        guard let id = batch.id else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        try await batchRepo.updateBatch(id: id, purchasedBirds: batch.purchasedBirds, freeBirds: batch.freeBirds, costPerBird: batch.costPerBird, status: "closed", endDate: today)
        dataStore.loadAll()
    }

    func deleteBatch(_ batch: BatchRecord) async throws {
        guard let id = batch.id else { return }
        try await batchRepo.deleteBatch(id: id)
        dataStore.loadAll()
    }
}
