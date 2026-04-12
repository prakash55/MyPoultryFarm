//
//  ShedRecord.swift
//  MyPoultryFarm
//

import Foundation

struct ShedRecord: Codable, Identifiable {
    var id: UUID?
    let farmId: UUID
    let shedName: String
    let capacity: Int

    enum CodingKeys: String, CodingKey {
        case id
        case farmId = "farm_id"
        case shedName = "shed_name"
        case capacity
    }
}
