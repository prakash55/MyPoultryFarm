//
//  BatchDetailViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation
import SwiftUI

// MARK: - Supporting Models

struct DaySummary: Identifiable {
    let id: String
    let date: String
    let totalMortality: Int
    let totalFeedBags: Double
    let feedTypes: [String]
    let medicines: [(name: String, qty: Double)]
    let avgWeight: Double
    let logCount: Int
    let logs: [DailyLogRecord]
}

struct ExpenseBreakdownItem: Identifiable {
    let category: String
    let title: String
    let icon: String
    let color: Color
    let amount: Double
    var id: String { category }
}

// MARK: - BatchDetailViewModel

@MainActor
class BatchDetailViewModel: ObservableObject {
    let dataStore: MyFarmsViewModel
    let batch: BatchRecord
    private var cancellable: AnyCancellable?

    // MARK: - Cached Formatters

    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()
    private static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()
    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f
    }()
    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0; f.groupingSeparator = ","; return f
    }()

    init(dataStore: MyFarmsViewModel, batch: BatchRecord) {
        self.dataStore = dataStore
        self.batch = batch
        cancellable = dataStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }

    // MARK: - Live Batch

    var currentBatch: BatchRecord {
        dataStore.batches.first(where: { $0.id == batch.id }) ?? batch
    }

    // MARK: - Filtered Data

    var batchSales: [SaleRecord] {
        guard let batchId = batch.id else { return [] }
        return dataStore.sales.filter { $0.batchId == batchId }
    }

    var batchExpenses: [ExpenseRecord] {
        guard let batchId = batch.id else { return [] }
        return dataStore.expenses.filter { $0.batchId == batchId }
    }

    var batchInventory: [InventoryRecord] {
        guard let batchId = batch.id else { return [] }
        return dataStore.inventoryItems.filter { $0.batchId == batchId }
    }

    var batchLogs: [DailyLogRecord] {
        guard let batchId = batch.id else { return [] }
        return dataStore.dailyLogs.filter { $0.batchId == batchId }
    }

    // MARK: - Bird Stats

    var totalMortality: Int { batchLogs.reduce(0) { $0 + $1.mortality } }
    var birdsSold: Int { batchSales.reduce(0) { $0 + $1.birdCount } }
    var birdsLeft: Int { max(0, batch.computedTotalBirds - birdsSold - totalMortality) }

    // MARK: - Financial Stats

    var totalRevenue: Double { batchSales.reduce(0.0) { $0 + $1.totalAmount } }
    var totalExpenseAmount: Double { batchExpenses.reduce(0.0) { $0 + $1.amount } }
    var totalWeightSold: Double { batchSales.reduce(0.0) { $0 + $1.totalWeightKg } }
    var profit: Double { totalRevenue - totalExpenseAmount }

    // MARK: - Feed / Inventory Stats

    var feedInventoryItems: [InventoryRecord] {
        batchInventory.filter { $0.category.lowercased() == "feed" }
    }
    var totalFeedStock: Double { feedInventoryItems.reduce(0.0) { $0 + $1.quantity } }
    var totalFeedUsed: Double { batchLogs.reduce(0.0) { $0 + $1.feedUsedBags } }
    var totalFeedAvailable: Double { max(0, totalFeedStock - totalFeedUsed) }
    var totalFeedInventoryCost: Double { feedInventoryItems.reduce(0.0) { $0 + $1.totalCost } }
    var medicineExpenseAmount: Double { expenseTotal(for: ["medicine"]) }
    var feedExpenseAmount: Double { expenseTotal(for: ["feed"]) }
    var averageDailyFeedCost: Double {
        guard dayCount > 0 else { return 0 }
        return feedExpenseAmount / Double(dayCount)
    }

    var feedInventoryUnit: String {
        let units = Set(feedInventoryItems.map { $0.unit.lowercased() }.filter { !$0.isEmpty })
        if units.count == 1, let unit = units.first { return unit }
        return feedInventoryItems.isEmpty ? "bags" : "units"
    }

    var inventoryStatusText: String { totalFeedAvailable > 0 ? "In Stock" : "Out of Stock" }
    var inventoryStatusColor: Color { totalFeedAvailable > 0 ? Color(red: 0.31, green: 0.82, blue: 0.53) : .red }

    // MARK: - Day / Percent Stats

    var dayCount: Int {
        guard let start = Self.isoDateFormatter.date(from: batch.startDate) else { return 0 }
        let end: Date
        if let endStr = currentBatch.endDate, let d = Self.isoDateFormatter.date(from: endStr) { end = d } else { end = Date() }
        return max(1, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1)
    }

    var soldPercent: Double {
        guard batch.computedTotalBirds > 0 else { return 0 }
        return Double(birdsSold) / Double(batch.computedTotalBirds)
    }

    var mortalityPercent: Double {
        guard batch.computedTotalBirds > 0 else { return 0 }
        return Double(totalMortality) / Double(batch.computedTotalBirds)
    }

    // MARK: - Expense Breakdown

    var expenseBreakdownItems: [ExpenseBreakdownItem] {
        let knownCategories = ["birds", "bird_purchase", "purchase", "feed", "medicine", "labour", "labor"]
        let birdsAmount = expenseTotal(for: ["birds", "bird_purchase", "purchase"])
        let feedAmount = expenseTotal(for: ["feed"])
        let medicineAmount = expenseTotal(for: ["medicine"])
        let labourAmount = expenseTotal(for: ["labour", "labor"])
        let otherAmount = batchExpenses
            .filter { !knownCategories.contains($0.category.lowercased()) }
            .reduce(0.0) { $0 + $1.amount }

        return [
            ExpenseBreakdownItem(category: "birds", title: "Bird Purchase", icon: "bird.fill", color: Color(red: 0.31, green: 0.82, blue: 0.53), amount: birdsAmount),
            ExpenseBreakdownItem(category: "feed", title: "Feed", icon: "leaf.fill", color: Color(red: 1.0, green: 0.73, blue: 0.28), amount: feedAmount),
            ExpenseBreakdownItem(category: "medicine", title: "Medicine", icon: "cross.case.fill", color: Color(red: 0.67, green: 0.27, blue: 0.94), amount: medicineAmount),
            ExpenseBreakdownItem(category: "labour", title: "Labour", icon: "person.2.fill", color: Color(red: 0.23, green: 0.59, blue: 0.96), amount: labourAmount),
            ExpenseBreakdownItem(category: "other", title: "Other", icon: "ellipsis", color: Color(red: 0.63, green: 0.64, blue: 0.70), amount: otherAmount),
        ]
    }

    // MARK: - Profit Trend

    var profitTrendValues: [Double] {
        let formatter = Self.isoDateFormatter
        let saleEntries = batchSales.compactMap { sale -> (Date, Double)? in
            guard let date = formatter.date(from: sale.saleDate) else { return nil }
            return (date, sale.totalAmount)
        }
        let expenseEntries = batchExpenses.compactMap { expense -> (Date, Double)? in
            guard let date = formatter.date(from: expense.expenseDate) else { return nil }
            return (date, -expense.amount)
        }
        let entries = (saleEntries + expenseEntries).sorted { lhs, rhs in
            if lhs.0 == rhs.0 { return lhs.1 < rhs.1 }
            return lhs.0 < rhs.0
        }
        guard !entries.isEmpty else { return [0] }
        var runningTotal = 0.0
        return entries.map { _, delta in runningTotal += delta; return runningTotal }
    }

    // MARK: - Day Summaries

    var daySummaries: [DaySummary] {
        let grouped = Dictionary(grouping: batchLogs, by: \.logDate)
        return grouped.map { date, logs in
            let meds: [(name: String, qty: Double)] = logs.compactMap { log in
                guard let name = log.medicineUsed, !name.isEmpty else { return nil }
                return (name: name, qty: log.medicineQty)
            }
            let feedTypeSet = Set(logs.compactMap(\.feedType))
            let weightLogs = logs.filter { $0.avgWeightKg > 0 }
            let avgWt = weightLogs.isEmpty ? 0 : weightLogs.reduce(0.0) { $0 + $1.avgWeightKg } / Double(weightLogs.count)
            return DaySummary(
                id: date, date: date,
                totalMortality: logs.reduce(0) { $0 + $1.mortality },
                totalFeedBags: logs.reduce(0.0) { $0 + $1.feedUsedBags },
                feedTypes: Array(feedTypeSet).sorted(),
                medicines: meds, avgWeight: avgWt,
                logCount: logs.count, logs: logs
            )
        }
        .sorted { $0.date > $1.date }
    }

    // MARK: - Helpers

    func expenseTotal(for categories: [String]) -> Double {
        let keys = Set(categories.map { $0.lowercased() })
        return batchExpenses.filter { keys.contains($0.category.lowercased()) }.reduce(0.0) { $0 + $1.amount }
    }

    func shedName(for shedId: UUID) -> String { dataStore.shedName(for: shedId) }
    func buyerName(for buyerId: UUID?) -> String { dataStore.buyerName(for: buyerId) }

    // MARK: - Formatters

    func formattedDate(_ s: String) -> String {
        guard let d = Self.isoDateFormatter.date(from: s) else { return s }
        return Self.mediumDateFormatter.string(from: d)
    }

    func shortDate(_ s: String) -> String {
        guard let d = Self.isoDateFormatter.date(from: s) else { return s }
        return Self.shortDateFormatter.string(from: d)
    }

    func relativeDay(_ s: String) -> String {
        guard let d = Self.isoDateFormatter.date(from: s) else { return s }
        guard let start = Self.isoDateFormatter.date(from: batch.startDate) else { return shortDate(s) }
        let day = Calendar.current.dateComponents([.day], from: start, to: d).day ?? 0
        return "Day \(day + 1)"
    }

    func currencyText(_ amount: Double, showSign: Bool = false) -> String {
        let formatted = Self.currencyFormatter.string(from: NSNumber(value: abs(amount))) ?? String(Int(abs(amount)))
        if amount < 0 { return "-₹\(formatted)" }
        if showSign { return "+₹\(formatted)" }
        return "₹\(formatted)"
    }

    func quantityText(_ value: Double, unit: String) -> String {
        let amount: String
        if value == value.rounded() { amount = String(Int(value)) }
        else { amount = String(format: "%.1f", value) }
        return "\(amount) \(unit)"
    }

    func expenseIcon(_ cat: String) -> String {
        switch cat {
        case "feed": return "leaf.fill"
        case "medicine": return "cross.case.fill"
        case "labour": return "person.2.fill"
        case "birds": return "bird.fill"
        default: return "ellipsis.circle.fill"
        }
    }

    func expenseColor(_ cat: String) -> Color {
        switch cat {
        case "feed": return .orange
        case "medicine": return .purple
        case "labour": return .blue
        case "birds": return .green
        default: return .gray
        }
    }
}
