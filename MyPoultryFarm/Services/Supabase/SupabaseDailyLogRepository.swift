//
//  SupabaseDailyLogRepository.swift
//  MyPoultryFarm
//

import Foundation
import Supabase

struct SupabaseDailyLogRepository: DailyLogRepositoryProtocol {
    private let client = SupabaseManager.shared.client

    func getLogs(batchId: UUID) async throws -> [DailyLogRecord] {
        struct Params: Encodable { let p_batch_id: UUID }
        return try await client.rpcValue(.dailyLogGetByBatch, params: Params(p_batch_id: batchId))
    }

    func getLogs(shedIds: [UUID]) async throws -> [DailyLogRecord] {
        struct Params: Encodable { let p_shed_ids: [UUID] }
        return try await client.rpcValue(.dailyLogGetBySheds, params: Params(p_shed_ids: shedIds))
    }

    @discardableResult
    func insertLog(_ log: DailyLogRecord) async throws -> DailyLogRecord {
        struct Params: Encodable { let p_log: DailyLogRecord }
        let rows: [DailyLogRecord] = try await client.rpcValue(.dailyLogInsert, params: Params(p_log: log))
        guard let saved = rows.first else {
            throw RepositoryError.insertFailed("Daily log insert returned no rows.")
        }
        return saved
    }

    func deleteLog(id: UUID) async throws {
        struct Params: Encodable { let p_id: UUID }
        try await client.rpcVoid(.dailyLogDelete, params: Params(p_id: id))
    }
}
