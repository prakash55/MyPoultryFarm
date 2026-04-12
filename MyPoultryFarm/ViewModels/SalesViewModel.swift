//
//  SalesViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation

@MainActor
class SalesViewModel: ObservableObject {
    let dataStore: MyFarmsViewModel

    @Injected private var salesRepo: SalesRepositoryProtocol
    @Injected private var buyerRepo: BuyerRepositoryProtocol
    @Injected private var authService: AuthServiceProtocol

    init(dataStore: MyFarmsViewModel) {
        self.dataStore = dataStore
    }

    // MARK: - Data Access

    var allSheds: [ShedRecord] { dataStore.allSheds }
    var batches: [BatchRecord] { dataStore.batches }
    var buyers: [BuyerRecord] { dataStore.buyers }
    var sales: [SaleRecord] { dataStore.sales }
    var dailyLogs: [DailyLogRecord] { dataStore.dailyLogs }
    func farmName(for shed: ShedRecord) -> String { dataStore.farmName(for: shed) }

    // MARK: - Sale CRUD

    func addSale(shedId: UUID, batchId: UUID?, birdCount: Int, totalWeightKg: Double, costPerKg: Double, saleDate: String, buyerId: UUID?, notes: String?) async throws {
        let totalAmount = totalWeightKg * costPerKg
        let record = SaleRecord(
            id: nil, shedId: shedId, batchId: batchId,
            buyerId: buyerId,
            birdCount: birdCount, totalWeightKg: totalWeightKg,
            costPerKg: costPerKg, totalAmount: totalAmount,
            saleDate: saleDate, notes: notes
        )
        try await salesRepo.insertSale(record)
        dataStore.loadAll()
    }

    func deleteSale(_ sale: SaleRecord) async throws {
        guard let id = sale.id else { return }
        try await salesRepo.deleteSale(id: id)
        dataStore.loadAll()
    }

    // MARK: - Buyer CRUD

    func addBuyer(agencyName: String, handlerName: String?, phone: String?) async throws -> BuyerRecord {
        guard let userId = await authService.currentUserId else {
            throw RepositoryError.insertFailed("No authenticated user.")
        }
        let record = BuyerRecord(
            id: nil, ownerId: userId,
            agencyName: agencyName,
            handlerName: handlerName,
            phone: phone
        )
        let saved = try await buyerRepo.insertBuyer(record)
        dataStore.buyers = try await buyerRepo.getBuyers(ownerId: userId)
        return saved
    }

    func deleteBuyer(_ buyer: BuyerRecord) async throws {
        guard let id = buyer.id else { return }
        try await buyerRepo.deleteBuyer(id: id)
        dataStore.loadAll()
    }

    func buyerName(for buyerId: UUID?) -> String {
        guard let buyerId else { return "–" }
        return dataStore.buyers.first(where: { $0.id == buyerId })?.agencyName ?? "Unknown"
    }
}
