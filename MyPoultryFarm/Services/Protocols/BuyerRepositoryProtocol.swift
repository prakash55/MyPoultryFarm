//
//  BuyerRepositoryProtocol.swift
//  MyPoultryFarm
//

import Foundation

protocol BuyerRepositoryProtocol {
    func getBuyers(ownerId: UUID) async throws -> [BuyerRecord]
    func getBuyer(id: UUID) async throws -> BuyerRecord?
    @discardableResult
    func insertBuyer(_ buyer: BuyerRecord) async throws -> BuyerRecord
    func updateBuyer(id: UUID, agencyName: String, handlerName: String?, phone: String?) async throws
    func deleteBuyer(id: UUID) async throws
}
