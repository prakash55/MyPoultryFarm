//
//  InventoryRecord.swift
//  MyPoultryFarm
//

import Foundation

struct InventoryRecord: Codable, Identifiable {
    var id: UUID?
    let shedId: UUID
    let batchId: UUID?
    let category: String
    let itemName: String
    let feedType: String?
    let quantity: Double
    let used: Double
    let unit: String
    let costPerUnit: Double
    let totalCost: Double

    enum CodingKeys: String, CodingKey {
        case id
        case shedId = "shed_id"
        case batchId = "batch_id"
        case category
        case itemName = "item_name"
        case feedType = "feed_type"
        case quantity
        case used
        case unit
        case costPerUnit = "cost_per_unit"
        case totalCost = "total_cost"
    }

    var isFeed: Bool { category.lowercased() == "feed" }
    var isMedicine: Bool { category.lowercased() == "medicine" }
}
