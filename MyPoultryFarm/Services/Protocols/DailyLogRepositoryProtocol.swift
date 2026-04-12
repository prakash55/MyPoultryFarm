//
//  DailyLogRepositoryProtocol.swift
//  MyPoultryFarm
//

import Foundation

protocol DailyLogRepositoryProtocol {
    func getLogs(batchId: UUID) async throws -> [DailyLogRecord]
    func getLogs(shedIds: [UUID]) async throws -> [DailyLogRecord]
    @discardableResult
    func insertLog(_ log: DailyLogRecord) async throws -> DailyLogRecord
    func deleteLog(id: UUID) async throws
}
