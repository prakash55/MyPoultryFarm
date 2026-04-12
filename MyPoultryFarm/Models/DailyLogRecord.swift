//
//  DailyLogRecord.swift
//  MyPoultryFarm
//

import Foundation

struct DailyLogRecord: Codable, Identifiable {
    var id: UUID?
    let batchId: UUID
    let shedId: UUID
    let logDate: String
    let mortality: Int
    let feedUsedKg: Double
    let feedType: String?
    let medicineUsed: String?
    let medicineQty: Double
    let avgWeightKg: Double
    let notes: String?

    var feedUsedBags: Double { feedUsedKg }

    enum CodingKeys: String, CodingKey {
        case id
        case batchId = "batch_id"
        case shedId = "shed_id"
        case logDate = "log_date"
        case mortality
        case feedUsedKg = "feed_used_kg"
        case feedType = "feed_type"
        case medicineUsed = "medicine_used"
        case medicineQty = "medicine_qty"
        case avgWeightKg = "avg_weight_kg"
        case notes
    }
}
