//
//  BatchRecord.swift
//  MyPoultryFarm
//

import Foundation

enum BatchStatus: String {
    case running
    case closed
}

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

    var batchStatus: BatchStatus { BatchStatus(rawValue: status.lowercased()) ?? .running }
    var isRunning: Bool { batchStatus == .running }
    var isClosed: Bool { batchStatus == .closed }
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
