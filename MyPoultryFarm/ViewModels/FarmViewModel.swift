//
//  FarmViewModel.swift
//  MyPoultryFarm
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

    func addFarm(name: String, location: String?, sheds: [(name: String, capacity: Int)]) async throws {
        guard let userId = await authService.currentUserId else { return }
        let farmRecord = FarmRecord(id: nil, ownerId: userId, farmName: name, location: location)
        let inserted = try await farmRepo.insertFarm(farmRecord)
        guard let farmId = inserted.id else { return }
        if !sheds.isEmpty {
            let shedRecords = sheds.map { ShedRecord(id: nil, farmId: farmId, shedName: $0.name, capacity: $0.capacity) }
            try await shedRepo.insertSheds(shedRecords)
        }
        dataStore.loadAll()
    }

    func updateFarm(_ farm: FarmRecord, name: String, location: String?) async throws {
        guard let id = farm.id else { return }
        try await farmRepo.updateFarm(id: id, name: name, location: location)
        dataStore.loadAll()
    }

    func deleteFarm(_ farm: FarmRecord) async throws {
        guard let id = farm.id else { return }
        try await shedRepo.deleteSheds(farmId: id)
        try await farmRepo.deleteFarm(id: id)
        dataStore.loadAll()
    }

    // MARK: - Shed CRUD

    func addShed(to farm: FarmRecord, name: String, capacity: Int) async throws {
        guard let farmId = farm.id else { return }
        let shed = ShedRecord(id: nil, farmId: farmId, shedName: name, capacity: capacity)
        try await shedRepo.insertShed(shed)
        dataStore.loadAll()
    }

    func updateShed(_ shed: ShedRecord, name: String, capacity: Int) async throws {
        guard let id = shed.id else { return }
        try await shedRepo.updateShed(id: id, name: name, capacity: capacity)
        dataStore.loadAll()
    }

    func deleteShed(_ shed: ShedRecord) async throws {
        guard let id = shed.id else { return }
        try await shedRepo.deleteShed(id: id)
        dataStore.loadAll()
    }
}
