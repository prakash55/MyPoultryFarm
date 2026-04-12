//
//  BuyerRecord.swift
//  MyPoultryFarm
//

import Foundation

struct BuyerRecord: Codable, Identifiable {
    var id: UUID?
    let ownerId: UUID
    let agencyName: String
    let handlerName: String?
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case agencyName = "agency_name"
        case handlerName = "handler_name"
        case phone
    }
}
