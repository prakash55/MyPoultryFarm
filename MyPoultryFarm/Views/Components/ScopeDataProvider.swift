//
//  ScopeDataProvider.swift
//  MyPoultryFarm
//
//  Centralizes all scope-filtered metrics used by dashboards and tab views.
//

import Foundation

struct ScopeData {
    let viewModel: MyFarmsViewModel
    let scopeShedIds: Set<UUID>

    // MARK: - Batches

    var allBatches: [BatchRecord] {
        viewModel.batches.filter { scopeShedIds.contains($0.shedId) }
    }

    var runningBatches: [BatchRecord] {
        allBatches.filter { $0.status == "running" }
    }

    var closedBatches: [BatchRecord] {
        allBatches.filter { $0.status == "closed" }
    }

    var runningBatchCount: Int { runningBatches.count }

    var totalBirds: Int {
        runningBatches.reduce(0) { $0 + $1.computedTotalBirds }
    }

    // MARK: - Mortality

    var dailyLogs: [DailyLogRecord] {
        viewModel.dailyLogs.filter { scopeShedIds.contains($0.shedId) }
    }

    var totalMortality: Int {
        dailyLogs.reduce(0) { $0 + $1.mortality }
    }

    var mortalityByBatch: [(batch: BatchRecord, mortality: Int)] {
        runningBatches.map { batch in
            let m = viewModel.dailyLogs.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.mortality }
            return (batch, m)
        }.sorted { $0.mortality > $1.mortality }
    }

    var highestMortalityBatch: (batch: BatchRecord, mortality: Int)? {
        mortalityByBatch.first
    }

    // MARK: - Sales

    var sales: [SaleRecord] {
        viewModel.sales.filter { scopeShedIds.contains($0.shedId) }
    }

    var totalBirdsSold: Int {
        sales.reduce(0) { $0 + $1.birdCount }
    }

    var birdsLeft: Int {
        totalBirds - totalBirdsSold - totalMortality
    }

    var totalSalesAmount: Double {
        sales.reduce(0.0) { $0 + $1.totalAmount }
    }

    var totalWeightSold: Double {
        sales.reduce(0.0) { $0 + $1.totalWeightKg }
    }

    var avgRatePerKg: Double {
        totalWeightSold > 0 ? totalSalesAmount / totalWeightSold : 0
    }

    // MARK: - Expenses

    var expenses: [ExpenseRecord] {
        viewModel.expenses.filter { scopeShedIds.contains($0.shedId) }
    }

    var totalExpensesAmount: Double {
        expenses.reduce(0.0) { $0 + $1.amount }
    }

    var profit: Double {
        totalSalesAmount - totalExpensesAmount
    }

    func expensesFor(category: String) -> Double {
        expenses.filter { $0.category == category }.reduce(0.0) { $0 + $1.amount }
    }

    // MARK: - Inventory / Feed

    var inventoryItems: [InventoryRecord] {
        viewModel.inventoryItems.filter { scopeShedIds.contains($0.shedId) }
    }

    var feedItems: [InventoryRecord] {
        inventoryItems.filter { $0.category == "feed" }
    }

    var medicineItems: [InventoryRecord] {
        inventoryItems.filter { $0.category == "medicine" }
    }

    var feedAvailable: Double {
        feedItems.reduce(0.0) { $0 + $1.quantity - $1.used }
    }

    var feedUsed: Double {
        feedItems.reduce(0.0) { $0 + $1.used }
    }

    var totalFeedQuantity: Double {
        feedItems.reduce(0.0) { $0 + $1.quantity }
    }

    var feedCostTotal: Double {
        feedItems.reduce(0.0) { $0 + $1.totalCost }
    }

    var feedConsumptionRatePerDay: Double {
        // Average daily feed used from daily logs
        let totalFeedBags = dailyLogs.reduce(0.0) { $0 + $1.feedUsedKg }
        let uniqueDays = Set(dailyLogs.map { $0.logDate }).count
        return uniqueDays > 0 ? totalFeedBags / Double(uniqueDays) : 0
    }

    var highestFeedConsumptionBatch: (batch: BatchRecord, feedBags: Double)? {
        let results = runningBatches.map { batch in
            let feed = viewModel.dailyLogs.filter { $0.batchId == batch.id }.reduce(0.0) { $0 + $1.feedUsedKg }
            return (batch, feed)
        }.sorted { $0.1 > $1.1 }
        return results.first
    }

    var isFeedLow: Bool {
        // Alert if feed available < 3 days of consumption
        feedConsumptionRatePerDay > 0 && feedAvailable < (feedConsumptionRatePerDay * 3)
    }

    // MARK: - Chart Data: Mortality per batch per day

    struct DayPoint: Identifiable {
        let id = UUID()
        let day: Int
        let value: Double
    }

    struct BatchSeries: Identifiable {
        let id: UUID
        let label: String
        let points: [DayPoint]
    }

    var mortalityChartData: [BatchSeries] {
        runningBatches.compactMap { batch in
            guard let bId = batch.id else { return nil }
            let logs = viewModel.dailyLogs.filter { $0.batchId == bId }.sorted { $0.logDate < $1.logDate }
            guard !logs.isEmpty else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let start = formatter.date(from: batch.startDate) else { return nil }
            var cumulative = 0
            let points = logs.compactMap { log -> DayPoint? in
                guard let logDate = formatter.date(from: log.logDate) else { return nil }
                let day = max(1, Calendar.current.dateComponents([.day], from: start, to: logDate).day ?? 1)
                cumulative += log.mortality
                return DayPoint(day: day, value: Double(cumulative))
            }
            return BatchSeries(id: bId, label: "Batch #\(batch.batchNumber)", points: points)
        }
    }

    var feedChartData: [BatchSeries] {
        runningBatches.compactMap { batch in
            guard let bId = batch.id else { return nil }
            let logs = viewModel.dailyLogs.filter { $0.batchId == bId }.sorted { $0.logDate < $1.logDate }
            guard !logs.isEmpty else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let start = formatter.date(from: batch.startDate) else { return nil }
            var cumulative = 0.0
            let points = logs.compactMap { log -> DayPoint? in
                guard let logDate = formatter.date(from: log.logDate) else { return nil }
                let day = max(1, Calendar.current.dateComponents([.day], from: start, to: logDate).day ?? 1)
                cumulative += log.feedUsedKg
                return DayPoint(day: day, value: cumulative)
            }
            return BatchSeries(id: bId, label: "Batch #\(batch.batchNumber)", points: points)
        }
    }

    var weightChartData: [BatchSeries] {
        runningBatches.compactMap { batch in
            guard let bId = batch.id else { return nil }
            let logs = viewModel.dailyLogs.filter { $0.batchId == bId && $0.avgWeightKg > 0 }.sorted { $0.logDate < $1.logDate }
            guard !logs.isEmpty else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let start = formatter.date(from: batch.startDate) else { return nil }
            let points = logs.compactMap { log -> DayPoint? in
                guard let logDate = formatter.date(from: log.logDate) else { return nil }
                let day = max(1, Calendar.current.dateComponents([.day], from: start, to: logDate).day ?? 1)
                return DayPoint(day: day, value: log.avgWeightKg)
            }
            return BatchSeries(id: bId, label: "Batch #\(batch.batchNumber)", points: points)
        }
    }
}
