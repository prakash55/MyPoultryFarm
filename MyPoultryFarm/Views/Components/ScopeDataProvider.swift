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
        allBatches.filter { $0.isRunning }
    }

    var closedBatches: [BatchRecord] {
        allBatches.filter { $0.isClosed }
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
        max(0, totalBirds - totalBirdsSold - totalMortality)
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
        expenses.filter { $0.category.lowercased() == category.lowercased() }.reduce(0.0) { $0 + $1.amount }
    }

    // MARK: - Inventory / Feed

    var inventoryItems: [InventoryRecord] {
        viewModel.inventoryItems.filter { scopeShedIds.contains($0.shedId) }
    }

    var feedItems: [InventoryRecord] {
        inventoryItems.filter { $0.isFeed }
    }

    var medicineItems: [InventoryRecord] {
        inventoryItems.filter { $0.isMedicine }
    }

    var totalLoggedFeedUsed: Double {
        dailyLogs.reduce(0.0) { $0 + $1.feedUsedBags }
    }

    var feedAvailable: Double {
        max(0, totalFeedQuantity - totalLoggedFeedUsed)
    }

    var feedUsed: Double {
        totalLoggedFeedUsed
    }

    var totalFeedQuantity: Double {
        feedItems.reduce(0.0) { $0 + $1.quantity }
    }

    func totalFeedQuantity(in shedIds: Set<UUID>) -> Double {
        feedItems
            .filter { shedIds.contains($0.shedId) }
            .reduce(0.0) { $0 + $1.quantity }
    }

    func feedUsed(in shedIds: Set<UUID>) -> Double {
        viewModel.dailyLogs
            .filter { shedIds.contains($0.shedId) }
            .reduce(0.0) { $0 + $1.feedUsedBags }
    }

    func feedAvailable(in shedIds: Set<UUID>) -> Double {
        max(0, totalFeedQuantity(in: shedIds) - feedUsed(in: shedIds))
    }

    var feedCostTotal: Double {
        feedItems.reduce(0.0) { $0 + $1.totalCost }
    }

    var feedConsumptionRatePerDay: Double {
        // Average daily feed used in bags from daily logs.
        let totalFeedBags = dailyLogs.reduce(0.0) { $0 + $1.feedUsedBags }
        let uniqueDays = Set(dailyLogs.map { $0.logDate }).count
        return uniqueDays > 0 ? totalFeedBags / Double(uniqueDays) : 0
    }

    var highestFeedConsumptionBatch: (batch: BatchRecord, feedBags: Double)? {
        let results = runningBatches.map { batch in
            let feed = viewModel.dailyLogs.filter { $0.batchId == batch.id }.reduce(0.0) { $0 + $1.feedUsedBags }
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

            // Sum mortality by relative day in the batch lifecycle.
            var mortalityByDay: [Int: Int] = [:]
            var maxObservedDay = 1

            for log in logs {
                guard let logDate = formatter.date(from: log.logDate) else { continue }
                let day = max(1, (Calendar.current.dateComponents([.day], from: start, to: logDate).day ?? 0) + 1)
                mortalityByDay[day, default: 0] += log.mortality
                maxObservedDay = max(maxObservedDay, day)
            }

            let points = (1...maxObservedDay).map { day in
                DayPoint(day: day, value: Double(mortalityByDay[day, default: 0]))
            }

            return BatchSeries(id: bId, label: batch.batchName ?? "Batch #\(batch.batchNumber)", points: points)
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
                cumulative += log.feedUsedBags
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
