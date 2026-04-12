//
//  FarmRepositoryProtocol.swift
//  MyPoultryFarm
//

import Foundation

protocol FarmRepositoryProtocol {
    func getFarms(ownerId: UUID) async throws -> [FarmRecord]
    func getFarm(id: UUID) async throws -> FarmRecord?
    @discardableResult
    func insertFarm(_ farm: FarmRecord) async throws -> FarmRecord
    func updateFarm(id: UUID, name: String, location: String?) async throws
    func deleteFarm(id: UUID) async throws
}
