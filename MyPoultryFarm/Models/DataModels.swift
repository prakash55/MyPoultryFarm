//
//  DataModels.swift
//  MyPoultryFarm
//

import Foundation

// MARK: - BatchRecord

struct BatchRecord: Codable, Identifiable {
    var id: UUID?
    let shedId: UUID
    let batchNumber: Int
    let batchName: String?
    let purchasedBirds: Int
    let freeBirds: Int
    let costPerBird: Double
    let totalBirds: Int?
    let totalCost: Double?
    let startDate: String
    let endDate: String?
    let status: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case shedId = "shed_id"
        case batchNumber = "batch_number"
        case batchName = "batch_name"
        case purchasedBirds = "purchased_birds"
        case freeBirds = "free_birds"
        case costPerBird = "cost_per_bird"
        case totalBirds = "total_birds"
        case totalCost = "total_cost"
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case notes
    }

    /// Computed total for local use (before server-side generated column returns)
    var computedTotalBirds: Int { totalBirds ?? (purchasedBirds + freeBirds) }
    var computedTotalCost: Double { totalCost ?? (Double(purchasedBirds) * costPerBird) }
    var displayTitle: String {
        if let name = batchName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return "Batch #\(batchNumber) - \(name)"
        }
        return "Batch #\(batchNumber)"
    }

    /// Custom encoding: skip generated columns (total_birds, total_cost) when they are nil (i.e. on insert)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(shedId, forKey: .shedId)
        try container.encode(batchNumber, forKey: .batchNumber)
        try container.encodeIfPresent(batchName, forKey: .batchName)
        try container.encode(purchasedBirds, forKey: .purchasedBirds)
        try container.encode(freeBirds, forKey: .freeBirds)
        try container.encode(costPerBird, forKey: .costPerBird)
        // Skip totalBirds and totalCost — they are GENERATED ALWAYS columns in Postgres
        try container.encode(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

// MARK: - InventoryRecord

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
}

// MARK: - BuyerRecord

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

// MARK: - SaleRecord

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

// MARK: - ExpenseRecord

struct ExpenseRecord: Codable, Identifiable {
    var id: UUID?
    let shedId: UUID
    let batchId: UUID?
    let category: String
    let amount: Double
    let description: String?
    let expenseDate: String

    enum CodingKeys: String, CodingKey {
        case id
        case shedId = "shed_id"
        case batchId = "batch_id"
        case category
        case amount
        case description
        case expenseDate = "expense_date"
    }
}

// MARK: - DailyLogRecord

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
