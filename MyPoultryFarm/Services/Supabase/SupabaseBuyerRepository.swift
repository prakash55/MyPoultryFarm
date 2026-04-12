//
//  SupabaseBuyerRepository.swift
//  MyPoultryFarm
//

import Foundation
import Supabase

struct SupabaseBuyerRepository: BuyerRepositoryProtocol {
    private let client = SupabaseManager.shared.client

    func getBuyers(ownerId: UUID) async throws -> [BuyerRecord] {
        struct Params: Encodable { let p_owner_id: UUID }
        return try await client.rpcValue(.buyerGetBuyers, params: Params(p_owner_id: ownerId))
    }

    func getBuyer(id: UUID) async throws -> BuyerRecord? {
        struct Params: Encodable { let p_id: UUID }
        let records: [BuyerRecord] = try await client.rpcValue(.buyerGetBuyer, params: Params(p_id: id))
        return records.first
    }

    @discardableResult
    func insertBuyer(_ buyer: BuyerRecord) async throws -> BuyerRecord {
        struct Params: Encodable { let p_buyer: BuyerRecord }
        let result: [BuyerRecord] = try await client.rpcValue(.buyerInsertBuyer, params: Params(p_buyer: buyer))
        guard let saved = result.first else {
            throw RepositoryError.insertFailed("Buyer insert returned no rows.")
        }
        return saved
    }

    func updateBuyer(id: UUID, agencyName: String, handlerName: String?, phone: String?) async throws {
        struct Params: Encodable {
            let p_id: UUID
            let p_agency_name: String
            let p_handler_name: String?
            let p_phone: String?
        }
        try await client.rpcVoid(
            .buyerUpdateBuyer,
            params: Params(p_id: id, p_agency_name: agencyName, p_handler_name: handlerName, p_phone: phone)
        )
    }

    func deleteBuyer(id: UUID) async throws {
        struct Params: Encodable { let p_id: UUID }
        try await client.rpcVoid(.buyerDeleteBuyer, params: Params(p_id: id))
    }
}
