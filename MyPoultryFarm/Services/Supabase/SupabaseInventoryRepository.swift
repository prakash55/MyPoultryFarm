//
//  SupabaseInventoryRepository.swift
//  MyPoultryFarm
//

import Foundation
import Supabase

struct SupabaseInventoryRepository: InventoryRepositoryProtocol {
    private let client = SupabaseManager.shared.client

    // MARK: - Get inventory for a shed

    func getInventory(shedId: UUID) async throws -> [InventoryRecord] {
        struct Params: Encodable { let p_shed_id: UUID }
        return try await client.rpcValue(.inventoryGetByShed, params: Params(p_shed_id: shedId))
    }

    // MARK: - Get all inventory across multiple sheds

    func getInventory(shedIds: [UUID]) async throws -> [InventoryRecord] {
        struct Params: Encodable { let p_shed_ids: [UUID] }
        return try await client.rpcValue(.inventoryGetBySheds, params: Params(p_shed_ids: shedIds))
    }

    // MARK: - Get inventory by category across multiple sheds

    func getInventoryByCategory(shedIds: [UUID], category: String) async throws -> [InventoryRecord] {
        struct Params: Encodable {
            let p_shed_ids: [UUID]
            let p_category: String
        }
        return try await client.rpcValue(.inventoryGetByCategory, params: Params(p_shed_ids: shedIds, p_category: category))
    }

    // MARK: - Get single item

    func getInventoryItem(id: UUID) async throws -> InventoryRecord? {
        struct Params: Encodable { let p_id: UUID }
        let records: [InventoryRecord] = try await client.rpcValue(.inventoryGetItem, params: Params(p_id: id))
        return records.first
    }

    // MARK: - Insert item

    @discardableResult
    func insertItem(_ item: InventoryRecord) async throws -> InventoryRecord {
        struct Params: Encodable { let p_item: InventoryRecord }
        let result: [InventoryRecord] = try await client.rpcValue(.inventoryInsertItem, params: Params(p_item: item))
        guard let saved = result.first else {
            throw RepositoryError.insertFailed("Inventory insert returned no rows.")
        }
        return saved
    }

    // MARK: - Update item

    func updateItem(id: UUID, quantity: Double, used: Double) async throws {
        struct Params: Encodable {
            let p_id: UUID
            let p_quantity: Double
            let p_used: Double
        }
        try await client.rpcVoid(.inventoryUpdateItem, params: Params(p_id: id, p_quantity: quantity, p_used: used))
    }

    // MARK: - Delete item

    func deleteItem(id: UUID) async throws {
        struct Params: Encodable { let p_id: UUID }
        try await client.rpcVoid(.inventoryDeleteItem, params: Params(p_id: id))
    }
}
