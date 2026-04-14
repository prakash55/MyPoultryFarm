//
//  FarmViewModel.swift
//  MyPoultryFarm
//
//  Handles farm-level CRUD only.
//  Shed CRUD is handled by ShedViewModel.
//

import Combine
import Foundation

@MainActor
class FarmViewModel: ObservableObject {
    let dataStore: MyFarmsViewModel

    @Injected private var farmRepo: FarmRepositoryProtocol
    @Injected private var shedRepo: ShedRepositoryProtocol
    @Injected private var authService: AuthServiceProtocol

    init(dataStore: MyFarmsViewModel) {
        self.dataStore = dataStore
    }

    // MARK: - Farm CRUD

    /// Creates a new farm, bulk-inserts its initial sheds, then refreshes the data store.
    func addFarm(name: String, location: String?, sheds: [(name: String, capacity: Int)]) async throws {
        guard let userId = await authService.currentUserId else { return }
        let farmRecord = FarmRecord(id: nil, ownerId: userId, farmName: name, location: location)
        let inserted = try await farmRepo.insertFarm(farmRecord)
        guard let farmId = inserted.id else { return }
        if !sheds.isEmpty {
            let shedRecords = sheds.map {
                ShedRecord(id: nil, farmId: farmId, shedName: $0.name, capacity: $0.capacity)
            }
            try await shedRepo.insertSheds(shedRecords)
        }
        dataStore.loadAll()
    }

    func updateFarm(_ farm: FarmRecord, name: String, location: String?, reload: Bool = true) async throws {
        guard let id = farm.id else { return }
        try await farmRepo.updateFarm(id: id, name: name, location: location)
        if reload { dataStore.loadAll() }
    }

    /// Deletes the farm and cascade-deletes all its sheds, then refreshes.
    func deleteFarm(_ farm: FarmRecord) async throws {
        guard let id = farm.id else { return }
        try await shedRepo.deleteSheds(farmId: id)
        try await farmRepo.deleteFarm(id: id)
        dataStore.loadAll()
    }
}
