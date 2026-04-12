//
//  ExpenseRecord.swift
//  MyPoultryFarm
//

import Foundation

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
