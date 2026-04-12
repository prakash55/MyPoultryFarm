//
//  MyFarmsViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation

@MainActor
class MyFarmsViewModel: ObservableObject {

    // MARK: - Published State

    @Published var profile: ProfileRecord?
    @Published var farms: [FarmRecord] = []
    @Published var shedsByFarm: [UUID: [ShedRecord]] = [:]
    @Published var batches: [BatchRecord] = []
    @Published var inventoryItems: [InventoryRecord] = []
    @Published var sales: [SaleRecord] = []
    @Published var expenses: [ExpenseRecord] = []
    @Published var buyers: [BuyerRecord] = []
    @Published var dailyLogs: [DailyLogRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Repositories

    @Injected private var profileRepo: ProfileRepositoryProtocol
    @Injected private var farmRepo: FarmRepositoryProtocol
    @Injected private var shedRepo: ShedRepositoryProtocol
    @Injected private var authService: AuthServiceProtocol
    @Injected private var batchRepo: BatchRepositoryProtocol
    @Injected private var inventoryRepo: InventoryRepositoryProtocol
    @Injected private var salesRepo: SalesRepositoryProtocol
    @Injected private var expenseRepo: ExpenseRepositoryProtocol
    @Injected private var buyerRepo: BuyerRepositoryProtocol
    @Injected private var dailyLogRepo: DailyLogRepositoryProtocol

    var currentUserId: UUID? {
        get async { await authService.currentUserId }
    }

    // MARK: - Load All Data

    func loadAll() {
        isLoading = true
        Task {
            do {
                guard let userId = await authService.currentUserId else { return }

                profile = try await profileRepo.getProfile(userId: userId)
                buyers = try await buyerRepo.getBuyers(ownerId: userId)

                let loadedFarms = try await farmRepo.getFarms(ownerId: userId)
                farms = loadedFarms

                var shedsMap: [UUID: [ShedRecord]] = [:]
                await withTaskGroup(of: (UUID, [ShedRecord])?.self) { group in
                    for farm in loadedFarms {
                        if let farmId = farm.id {
                            group.addTask { [shedRepo] in
                                guard let sheds = try? await shedRepo.getSheds(farmId: farmId) else { return nil }
                                return (farmId, sheds)
                            }
                        }
                    }
                    for await result in group {
                        if let (farmId, sheds) = result {
                            shedsMap[farmId] = sheds
                        }
                    }
                }
                shedsByFarm = shedsMap

                let allShedIds = shedsMap.values.flatMap { $0 }.compactMap { $0.id }
                if !allShedIds.isEmpty {
                    batches = try await batchRepo.getBatches(shedIds: allShedIds)
                    inventoryItems = try await inventoryRepo.getInventory(shedIds: allShedIds)
                    sales = try await salesRepo.getSales(shedIds: allShedIds)
                    expenses = try await expenseRepo.getExpenses(shedIds: allShedIds)
                    dailyLogs = try await dailyLogRepo.getLogs(shedIds: allShedIds)
                } else {
                    batches = []
                    inventoryItems = []
                    sales = []
                    expenses = []
                    dailyLogs = []
                }

                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Clear All Data

    func clearAllData() {
        profile = nil
        farms = []
        shedsByFarm = [:]
        batches = []
        inventoryItems = []
        sales = []
        expenses = []
        buyers = []
        dailyLogs = []
        isLoading = false
        errorMessage = nil
        showError = false
    }

    // MARK: - Computed Helpers

    func shedName(for shedId: UUID) -> String {
        for sheds in shedsByFarm.values {
            if let shed = sheds.first(where: { $0.id == shedId }) {
                return shed.shedName
            }
        }
        return "Unknown"
    }

    func farmName(for shed: ShedRecord) -> String {
        for farm in farms {
            if let farmId = farm.id, shedsByFarm[farmId]?.contains(where: { $0.id == shed.id }) == true {
                return farm.farmName
            }
        }
        return ""
    }

    func totalSheds(for farm: FarmRecord) -> Int {
        guard let id = farm.id else { return 0 }
        return shedsByFarm[id]?.count ?? 0
    }

    func totalCapacity(for farm: FarmRecord) -> Int {
        guard let id = farm.id else { return 0 }
        return shedsByFarm[id]?.reduce(0) { $0 + $1.capacity } ?? 0
    }

    func sheds(for farm: FarmRecord) -> [ShedRecord] {
        guard let id = farm.id else { return [] }
        return shedsByFarm[id] ?? []
    }

    var allSheds: [ShedRecord] {
        shedsByFarm.values.flatMap { $0 }
    }

    // MARK: - Profile

    func updateProfile(fullName: String, phone: String) async throws {
        guard let userId = await authService.currentUserId else { return }
        try await profileRepo.updateName(userId: userId, fullName: fullName)
        try await profileRepo.updatePhone(userId: userId, phone: phone)
        profile = try await profileRepo.getProfile(userId: userId)
    }

    func buyerName(for buyerId: UUID?) -> String {
        guard let buyerId else { return "–" }
        return buyers.first(where: { $0.id == buyerId })?.agencyName ?? "Unknown"
    }
}
