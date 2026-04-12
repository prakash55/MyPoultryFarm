//
//  FarmRecord.swift
//  MyPoultryFarm
//

import Foundation

struct FarmRecord: Codable, Identifiable {
    var id: UUID?
    let ownerId: UUID
    let farmName: String
    let location: String?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case farmName = "farm_name"
        case location
    }
}
