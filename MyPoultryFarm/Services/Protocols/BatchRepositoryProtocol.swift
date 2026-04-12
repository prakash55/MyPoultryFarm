//
//  BatchRepositoryProtocol.swift
//  MyPoultryFarm
//

import Foundation

protocol BatchRepositoryProtocol {
    func getBatches(shedId: UUID) async throws -> [BatchRecord]
    func getBatches(shedIds: [UUID]) async throws -> [BatchRecord]
    func getBatchesByStatus(shedIds: [UUID], status: String) async throws -> [BatchRecord]
    func getBatch(id: UUID) async throws -> BatchRecord?
    @discardableResult
    func insertBatch(_ batch: BatchRecord) async throws -> BatchRecord
    func updateBatch(id: UUID, purchasedBirds: Int, freeBirds: Int, costPerBird: Double, status: String, endDate: String?) async throws
    func deleteBatch(id: UUID) async throws
}
