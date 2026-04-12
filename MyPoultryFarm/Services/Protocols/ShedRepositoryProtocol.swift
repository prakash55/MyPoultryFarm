//
//  ShedRepositoryProtocol.swift
//  MyPoultryFarm
//

import Foundation

protocol ShedRepositoryProtocol {
    func getSheds(farmId: UUID) async throws -> [ShedRecord]
    func getShed(id: UUID) async throws -> ShedRecord?
    @discardableResult
    func insertShed(_ shed: ShedRecord) async throws -> ShedRecord
    @discardableResult
    func insertSheds(_ sheds: [ShedRecord]) async throws -> [ShedRecord]
    func updateShed(id: UUID, name: String, capacity: Int) async throws
    func deleteShed(id: UUID) async throws
    func deleteSheds(farmId: UUID) async throws
}
