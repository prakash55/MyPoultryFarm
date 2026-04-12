//
//  InventoryRepositoryProtocol.swift
//  MyPoultryFarm
//

import Foundation

protocol InventoryRepositoryProtocol {
    func getInventory(shedId: UUID) async throws -> [InventoryRecord]
    func getInventory(shedIds: [UUID]) async throws -> [InventoryRecord]
    func getInventoryByCategory(shedIds: [UUID], category: String) async throws -> [InventoryRecord]
    func getInventoryItem(id: UUID) async throws -> InventoryRecord?
    @discardableResult
    func insertItem(_ item: InventoryRecord) async throws -> InventoryRecord
    func updateItem(id: UUID, quantity: Double, used: Double) async throws
    func deleteItem(id: UUID) async throws
}
