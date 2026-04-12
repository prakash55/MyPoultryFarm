//
//  ProfileRepositoryProtocol.swift
//  MyPoultryFarm
//

import Foundation

protocol ProfileRepositoryProtocol {
    func getProfile(userId: UUID) async throws -> ProfileRecord?
    func upsertProfile(_ profile: ProfileRecord) async throws
    func updateName(userId: UUID, fullName: String) async throws
    func updatePhone(userId: UUID, phone: String) async throws
    func markOnboardingComplete(userId: UUID) async throws
    func isOnboardingCompleted(userId: UUID) async throws -> Bool
}
