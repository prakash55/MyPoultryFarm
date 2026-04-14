//
//  ShedViewModel.swift
//  MyPoultryFarm
//
//  Dedicated ViewModel for shed CRUD operations.
//  Shed model (ShedRecord) lives in Models/ShedRecord.swift.
//  UI-only model (ShedEntry) lives in Models/OnboardingModels.swift.
//

import Combine
import Foundation

@MainActor
class ShedViewModel: ObservableObject {

    let dataStore: MyFarmsViewModel

    @Injected private var shedRepo: ShedRepositoryProtocol

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    init(dataStore: MyFarmsViewModel) {
        self.dataStore = dataStore
    }

    // MARK: - Data Access

    func sheds(for farm: FarmRecord) -> [ShedRecord] {
        dataStore.sheds(for: farm)
    }

    // MARK: - Add

    func addShed(to farm: FarmRecord, name: String, capacity: Int, reload: Bool = true) async throws {
        guard let farmId = farm.id else { return }
        let shed = ShedRecord(id: nil, farmId: farmId, shedName: name, capacity: capacity)
        try await shedRepo.insertShed(shed)
        if reload { dataStore.loadAll() }
    }

    // MARK: - Update

    func updateShed(_ shed: ShedRecord, name: String, capacity: Int, reload: Bool = true) async throws {
        guard let id = shed.id else { return }
        try await shedRepo.updateShed(id: id, name: name, capacity: capacity)
        if reload { dataStore.loadAll() }
    }

    // MARK: - Delete

    func deleteShed(id: UUID, farmId: UUID, reload: Bool = true) async throws {
        try await shedRepo.deleteShed(id: id)
        if reload { dataStore.loadAll() }
    }

    func deleteShed(_ shed: ShedRecord, reload: Bool = true) async throws {
        guard let id = shed.id else { return }
        try await shedRepo.deleteShed(id: id)
        if reload { dataStore.loadAll() }
    }

    // MARK: - Batch apply from ShedEntry list (used by EditFarmView)

    /// Diffs the new shed entries against the original shed records and applies
    /// the necessary creates, updates, and deletes. Calls `dataStore.loadAll()`
    /// once at the end rather than after each individual operation.
    func applyChanges(
        newEntries: [ShedEntry],
        originalSheds: [ShedRecord],
        farm: FarmRecord
    ) async throws {
        guard let farmId = farm.id else { return }

        let currentIds = Set(newEntries.compactMap(\.existingId))
        let originalIds = Set(originalSheds.compactMap(\.id))

        // Delete sheds that were removed from the list
        for removedId in originalIds.subtracting(currentIds) {
            try await shedRepo.deleteShed(id: removedId)
        }

        // Update existing sheds / insert new ones
        for entry in newEntries {
            let name = entry.name.trimmingCharacters(in: .whitespaces)
            let capacity = Int(entry.capacity) ?? 0
            guard !name.isEmpty else { continue }

            if let existingId = entry.existingId {
                try await shedRepo.updateShed(id: existingId, name: name, capacity: capacity)
            } else {
                let newShed = ShedRecord(id: nil, farmId: farmId, shedName: name, capacity: capacity)
                try await shedRepo.insertShed(newShed)
            }
        }

        dataStore.loadAll()
    }
}
