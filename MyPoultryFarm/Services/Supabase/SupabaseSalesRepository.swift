//
//  SupabaseSalesRepository.swift
//  MyPoultryFarm
//

import Foundation
import Supabase

struct SupabaseSalesRepository: SalesRepositoryProtocol {
    private let client = SupabaseManager.shared.client

    // MARK: - Get sales for a shed

    func getSales(shedId: UUID) async throws -> [SaleRecord] {
        struct Params: Encodable { let p_shed_id: UUID }
        return try await client.rpcValue(.salesGetByShed, params: Params(p_shed_id: shedId))
    }

    // MARK: - Get sales across multiple sheds

    func getSales(shedIds: [UUID]) async throws -> [SaleRecord] {
        struct Params: Encodable { let p_shed_ids: [UUID] }
        return try await client.rpcValue(.salesGetBySheds, params: Params(p_shed_ids: shedIds))
    }

    // MARK: - Get single sale

    func getSale(id: UUID) async throws -> SaleRecord? {
        struct Params: Encodable { let p_id: UUID }
        let records: [SaleRecord] = try await client.rpcValue(.salesGetSale, params: Params(p_id: id))
        return records.first
    }

    // MARK: - Insert sale

    @discardableResult
    func insertSale(_ sale: SaleRecord) async throws -> SaleRecord {
        struct Params: Encodable { let p_sale: SaleRecord }
        let result: [SaleRecord] = try await client.rpcValue(.salesInsertSale, params: Params(p_sale: sale))
        guard let saved = result.first else {
            throw RepositoryError.insertFailed("Sale insert returned no rows.")
        }
        return saved
    }

    // MARK: - Update sale

    func updateSale(id: UUID, birdCount: Int, totalWeightKg: Double, costPerKg: Double, totalAmount: Double) async throws {
        struct Params: Encodable {
            let p_id: UUID
            let p_bird_count: Int
            let p_total_weight_kg: Double
            let p_cost_per_kg: Double
            let p_total_amount: Double
        }
        try await client.rpcVoid(
            .salesUpdateSale,
            params: Params(
                p_id: id,
                p_bird_count: birdCount,
                p_total_weight_kg: totalWeightKg,
                p_cost_per_kg: costPerKg,
                p_total_amount: totalAmount
            )
        )
    }

    // MARK: - Delete sale

    func deleteSale(id: UUID) async throws {
        struct Params: Encodable { let p_id: UUID }
        try await client.rpcVoid(.salesDeleteSale, params: Params(p_id: id))
    }
}
