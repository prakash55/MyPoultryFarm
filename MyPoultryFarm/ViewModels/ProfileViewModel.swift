//
//  ProfileViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    let dataStore: MyFarmsViewModel
    private var cancellable: AnyCancellable?

    init(dataStore: MyFarmsViewModel) {
        self.dataStore = dataStore
        cancellable = dataStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }

    // MARK: - Data Access

    var profile: ProfileRecord? { dataStore.profile }
    var farms: [FarmRecord] { dataStore.farms }
    var shedsByFarm: [UUID: [ShedRecord]] { dataStore.shedsByFarm }
    var isLoading: Bool { dataStore.isLoading }
    var showError: Bool {
        get { dataStore.showError }
        set { dataStore.showError = newValue }
    }
    var errorMessage: String? { dataStore.errorMessage }

    func sheds(for farm: FarmRecord) -> [ShedRecord] { dataStore.sheds(for: farm) }
    func totalCapacity(for farm: FarmRecord) -> Int { dataStore.totalCapacity(for: farm) }
    func loadAll() { dataStore.loadAll() }

    // MARK: - Profile Update

    func updateProfile(fullName: String, phone: String) async throws {
        try await dataStore.updateProfile(fullName: fullName, phone: phone)
    }
}
