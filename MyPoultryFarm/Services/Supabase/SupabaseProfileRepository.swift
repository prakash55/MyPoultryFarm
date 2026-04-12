//
//  SupabaseProfileRepository.swift
//  MyPoultryFarm
//

import Foundation
import Supabase

struct SupabaseProfileRepository: ProfileRepositoryProtocol {
    private let client = SupabaseManager.shared.client

    // MARK: - Get profile by user ID

    func getProfile(userId: UUID) async throws -> ProfileRecord? {
        struct Params: Encodable { let p_user_id: UUID }
        let records: [ProfileRecord] = try await client.rpcValue(.profileGetProfile, params: Params(p_user_id: userId))
        return records.first
    }

    // MARK: - Create or update profile (upsert)

    func upsertProfile(_ profile: ProfileRecord) async throws {
        struct Params: Encodable { let p_profile: ProfileRecord }
        try await client.rpcVoid(.profileUpsert, params: Params(p_profile: profile))
    }

    // MARK: - Update specific fields

    func updateName(userId: UUID, fullName: String) async throws {
        struct Params: Encodable {
            let p_user_id: UUID
            let p_full_name: String
        }
        try await client.rpcVoid(.profileUpdateName, params: Params(p_user_id: userId, p_full_name: fullName))
    }

    func updatePhone(userId: UUID, phone: String) async throws {
        struct Params: Encodable {
            let p_user_id: UUID
            let p_phone: String
        }
        try await client.rpcVoid(.profileUpdatePhone, params: Params(p_user_id: userId, p_phone: phone))
    }

    func markOnboardingComplete(userId: UUID) async throws {
        struct Params: Encodable { let p_user_id: UUID }
        try await client.rpcVoid(.profileMarkOnboardingComplete, params: Params(p_user_id: userId))
    }

    // MARK: - Check onboarding status

    func isOnboardingCompleted(userId: UUID) async throws -> Bool {
        struct Params: Encodable { let p_user_id: UUID }
        let result: Bool = try await client.rpcValue(.profileIsOnboardingCompleted, params: Params(p_user_id: userId))
        return result
    }
}
