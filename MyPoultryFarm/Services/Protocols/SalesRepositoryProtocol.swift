//
//  SalesRepositoryProtocol.swift
//  MyPoultryFarm
//

import Foundation

protocol SalesRepositoryProtocol {
    func getSales(shedId: UUID) async throws -> [SaleRecord]
    func getSales(shedIds: [UUID]) async throws -> [SaleRecord]
    func getSale(id: UUID) async throws -> SaleRecord?
    @discardableResult
    func insertSale(_ sale: SaleRecord) async throws -> SaleRecord
    func updateSale(id: UUID, birdCount: Int, totalWeightKg: Double, costPerKg: Double, totalAmount: Double) async throws
    func deleteSale(id: UUID) async throws
}
