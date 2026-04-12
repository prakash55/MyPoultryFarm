//
//  SupabaseBatchRepository.swift
//  MyPoultryFarm
//

import Foundation
import Supabase

struct SupabaseBatchRepository: BatchRepositoryProtocol {
    private let client = SupabaseManager.shared.client

    // MARK: - Get batches for a shed

    func getBatches(shedId: UUID) async throws -> [BatchRecord] {
        struct Params: Encodable { let p_shed_id: UUID }
        return try await client.rpcValue(.batchGetBatchesByShed, params: Params(p_shed_id: shedId))
    }

    // MARK: - Get all batches across multiple sheds

    func getBatches(shedIds: [UUID]) async throws -> [BatchRecord] {
        struct Params: Encodable { let p_shed_ids: [UUID] }
        return try await client.rpcValue(.batchGetBatchesBySheds, params: Params(p_shed_ids: shedIds))
    }

    // MARK: - Get batches by status across multiple sheds

    func getBatchesByStatus(shedIds: [UUID], status: String) async throws -> [BatchRecord] {
        struct Params: Encodable {
            let p_shed_ids: [UUID]
            let p_status: String
        }
        return try await client.rpcValue(.batchGetBatchesByStatus, params: Params(p_shed_ids: shedIds, p_status: status))
    }

    // MARK: - Get single batch

    func getBatch(id: UUID) async throws -> BatchRecord? {
        struct Params: Encodable { let p_id: UUID }
        let records: [BatchRecord] = try await client.rpcValue(.batchGetBatch, params: Params(p_id: id))
        return records.first
    }

    // MARK: - Insert batch

    @discardableResult
    func insertBatch(_ batch: BatchRecord) async throws -> BatchRecord {
        struct Params: Encodable { let p_batch: BatchRecord }
        let result: [BatchRecord] = try await client.rpcValue(.batchInsertBatch, params: Params(p_batch: batch))
        guard let saved = result.first else {
            throw RepositoryError.insertFailed("Batch insert returned no rows.")
        }
        return saved
    }

    // MARK: - Update batch

    func updateBatch(id: UUID, purchasedBirds: Int, freeBirds: Int, costPerBird: Double, status: String, endDate: String?) async throws {
        struct Params: Encodable {
            let p_id: UUID
            let p_purchased_birds: Int
            let p_free_birds: Int
            let p_cost_per_bird: Double
            let p_status: String
            let p_end_date: String?
        }
        try await client.rpcVoid(
            .batchUpdateBatch,
            params: Params(
                p_id: id,
                p_purchased_birds: purchasedBirds,
                p_free_birds: freeBirds,
                p_cost_per_bird: costPerBird,
                p_status: status,
                p_end_date: endDate
            )
        )
    }

    // MARK: - Delete batch

    func deleteBatch(id: UUID) async throws {
        struct Params: Encodable { let p_id: UUID }
        try await client.rpcVoid(.batchDeleteBatch, params: Params(p_id: id))
    }
}
