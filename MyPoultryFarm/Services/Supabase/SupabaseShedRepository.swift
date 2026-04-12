//
//  SupabaseShedRepository.swift
//  MyPoultryFarm
//

import Foundation
import Supabase

struct SupabaseShedRepository: ShedRepositoryProtocol {
    private let client = SupabaseManager.shared.client

    // MARK: - Get all sheds for a farm

    func getSheds(farmId: UUID) async throws -> [ShedRecord] {
        struct Params: Encodable { let p_farm_id: UUID }
        return try await client.rpcValue(.shedGetSheds, params: Params(p_farm_id: farmId))
    }

    // MARK: - Get single shed by ID

    func getShed(id: UUID) async throws -> ShedRecord? {
        struct Params: Encodable { let p_id: UUID }
        let records: [ShedRecord] = try await client.rpcValue(.shedGetShed, params: Params(p_id: id))
        return records.first
    }

    // MARK: - Insert a single shed

    @discardableResult
    func insertShed(_ shed: ShedRecord) async throws -> ShedRecord {
        struct Params: Encodable { let p_shed: ShedRecord }
        let result: [ShedRecord] = try await client.rpcValue(.shedInsertShed, params: Params(p_shed: shed))
        guard let saved = result.first else {
            throw RepositoryError.insertFailed("Shed insert returned no rows.")
        }
        return saved
    }

    // MARK: - Insert multiple sheds at once

    @discardableResult
    func insertSheds(_ sheds: [ShedRecord]) async throws -> [ShedRecord] {
        struct Params: Encodable { let p_sheds: [ShedRecord] }
        return try await client.rpcValue(.shedInsertSheds, params: Params(p_sheds: sheds))
    }

    // MARK: - Update shed

    func updateShed(id: UUID, name: String, capacity: Int) async throws {
        struct Params: Encodable {
            let p_id: UUID
            let p_name: String
            let p_capacity: Int
        }
        try await client.rpcVoid(.shedUpdateShed, params: Params(p_id: id, p_name: name, p_capacity: capacity))
    }

    // MARK: - Delete shed

    func deleteShed(id: UUID) async throws {
        struct Params: Encodable { let p_id: UUID }
        try await client.rpcVoid(.shedDeleteShed, params: Params(p_id: id))
    }

    // MARK: - Delete all sheds for a farm

    func deleteSheds(farmId: UUID) async throws {
        struct Params: Encodable { let p_farm_id: UUID }
        try await client.rpcVoid(.shedDeleteSheds, params: Params(p_farm_id: farmId))
    }
}
