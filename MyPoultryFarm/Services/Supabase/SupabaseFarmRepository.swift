//
//  SupabaseFarmRepository.swift
//  MyPoultryFarm
//

import Foundation
import Supabase

struct SupabaseFarmRepository: FarmRepositoryProtocol {
    private let client = SupabaseManager.shared.client

    // MARK: - Get all farms for a user

    func getFarms(ownerId: UUID) async throws -> [FarmRecord] {
        struct Params: Encodable { let p_owner_id: UUID }
        return try await client.rpcValue(.farmGetFarms, params: Params(p_owner_id: ownerId))
    }

    // MARK: - Get single farm by ID

    func getFarm(id: UUID) async throws -> FarmRecord? {
        struct Params: Encodable { let p_id: UUID }
        let records: [FarmRecord] = try await client.rpcValue(.farmGetFarm, params: Params(p_id: id))
        return records.first
    }

    // MARK: - Insert a new farm and return the saved record

    @discardableResult
    func insertFarm(_ farm: FarmRecord) async throws -> FarmRecord {
        struct Params: Encodable { let p_farm: FarmRecord }
        let result: [FarmRecord] = try await client.rpcValue(.farmInsertFarm, params: Params(p_farm: farm))
        guard let saved = result.first else {
            throw RepositoryError.insertFailed("Farm insert returned no rows.")
        }
        return saved
    }

    // MARK: - Update farm

    func updateFarm(id: UUID, name: String, location: String?) async throws {
        struct Params: Encodable {
            let p_id: UUID
            let p_name: String
            let p_location: String?
        }
        try await client.rpcVoid(.farmUpdateFarm, params: Params(p_id: id, p_name: name, p_location: location))
    }

    // MARK: - Delete farm (cascades to sheds)

    func deleteFarm(id: UUID) async throws {
        struct Params: Encodable { let p_id: UUID }
        try await client.rpcVoid(.farmDeleteFarm, params: Params(p_id: id))
    }
}
