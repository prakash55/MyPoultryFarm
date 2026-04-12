//
//  SaleRecord.swift
//  MyPoultryFarm
//

import Foundation

struct SaleRecord: Codable, Identifiable {
    var id: UUID?
    let shedId: UUID
    let batchId: UUID?
    let buyerId: UUID?
    let birdCount: Int
    let totalWeightKg: Double
    let costPerKg: Double
    let totalAmount: Double
    let saleDate: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case shedId = "shed_id"
        case batchId = "batch_id"
        case buyerId = "buyer_id"
        case birdCount = "bird_count"
        case totalWeightKg = "total_weight_kg"
        case costPerKg = "cost_per_kg"
        case totalAmount = "total_amount"
        case saleDate = "sale_date"
        case notes
    }
}
