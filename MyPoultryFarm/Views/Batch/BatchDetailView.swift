//
//  BatchDetailView.swift
//  MyPoultryFarm
//

import SwiftUI

// MARK: - Day summary for daily logs

struct DaySummary: Identifiable {
    let id: String // the date string
    let date: String
    let totalMortality: Int
    let totalFeedBags: Double
    let feedTypes: [String]
    let medicines: [(name: String, qty: Double)]
    let avgWeight: Double
    let logCount: Int
    let logs: [DailyLogRecord]
}

struct BatchDetailView: View {
    @StateObject private var viewModel: BatchesTabViewModel
    @EnvironmentObject var router: AppRouter
    let batch: BatchRecord
    @State private var showMyFarms = false

    init(dataStore: MyFarmsViewModel, batch: BatchRecord) {
        _viewModel = StateObject(wrappedValue: BatchesTabViewModel(dataStore: dataStore))
        self.batch = batch
    }

    @State private var showAddLog = false
    @State private var showAddSale = false
    @State private var showAddExpense = false
    @State private var selectedTab = 0 // 0=Logs, 1=Sales, 2=Expenses, 3=Inventory
    @State private var isFABExpanded = false

    private var batchVM: BatchViewModel { BatchViewModel(dataStore: viewModel.dataStore) }

    private let tabs = ["Logs", "Sales", "Expenses", "Inventory"]

    /// Always reflects the latest data from the view model (e.g. auto-close status change)
    private var currentBatch: BatchRecord {
        viewModel.batches.first(where: { $0.id == batch.id }) ?? batch
    }

    private var fabItems: [FABItem] {
        var items: [FABItem] = [
            FABItem(label: "Daily Log",    icon: "list.clipboard",            color: .teal)   { showAddLog = true },
            FABItem(label: "Record Sale",  icon: "cart.badge.plus",           color: .blue)   { showAddSale = true },
            FABItem(label: "Add Expense",  icon: "indianrupeesign.circle",    color: .red)    { showAddExpense = true },
        ]
        items.append(
            FABItem(label: "Close Batch",  icon: "checkmark.seal.fill",       color: .orange) {
                Task { try await batchVM.closeBatch(batch) }
            }
        )
        return items
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    // Combined header + bird overview
                    combinedHeader

                    // Compact P&L strip
                    profitStrip

                    // Segmented picker
                    segmentPicker

                    // Content for selected segment
                    switch selectedTab {
                    case 0: logsTab
                    case 1: salesTab
                    case 2: expensesTab
                    case 3: inventoryTab
                    default: EmptyView()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 90) // space for FAB
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(currentBatch.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    farmPicker
                }
                ToolbarItem(placement: .topBarTrailing) {
                    profileButton
                }
            }
            .sheet(isPresented: $showMyFarms) {
                viewModel.dataStore.loadAll()
            } content: {
                MyFarmsView(authViewModel: AuthViewModel(), farmsViewModel: viewModel.dataStore)
            }

            // FAB — only shown for running batches
            if currentBatch.status == "running" {
                FloatingActionButton(items: fabItems, isExpanded: $isFABExpanded)
            }
        }
        .sheet(isPresented: $showAddLog) {
            AddDailyLogView(viewModel: DailyLogViewModel(dataStore: viewModel.dataStore), batch: batch)
        }
        .sheet(isPresented: $showAddSale) {
            AddSaleView(viewModel: SalesViewModel(dataStore: viewModel.dataStore), initialShedId: batch.shedId, initialBatchId: batch.id)
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(viewModel: ExpenseViewModel(dataStore: viewModel.dataStore), initialShedId: batch.shedId, initialBatchId: batch.id)
        }
    }

    // MARK: - Computed Data

    private var batchSales: [SaleRecord] {
        guard let batchId = batch.id else { return [] }
        return viewModel.sales.filter { $0.batchId == batchId }
    }

    private var batchExpenses: [ExpenseRecord] {
        guard let batchId = batch.id else { return [] }
        return viewModel.expenses.filter { $0.batchId == batchId }
    }

    private var batchInventory: [InventoryRecord] {
        guard let batchId = batch.id else { return [] }
        return viewModel.inventoryItems.filter { $0.batchId == batchId }
    }

    private var batchLogs: [DailyLogRecord] {
        guard let batchId = batch.id else { return [] }
        return viewModel.dailyLogs.filter { $0.batchId == batchId }
    }

    private var totalMortality: Int {
        batchLogs.reduce(0) { $0 + $1.mortality }
    }

    private var birdsSold: Int {
        batchSales.reduce(0) { $0 + $1.birdCount }
    }

    private var birdsLeft: Int {
        max(0, batch.computedTotalBirds - birdsSold - totalMortality)
    }

    private var totalRevenue: Double {
        batchSales.reduce(0.0) { $0 + $1.totalAmount }
    }

    private var totalExpenseAmount: Double {
        batchExpenses.reduce(0.0) { $0 + $1.amount }
    }

    private var totalWeightSold: Double {
        batchSales.reduce(0.0) { $0 + $1.totalWeightKg }
    }

    private var profit: Double {
        totalRevenue - totalExpenseAmount
    }

    private var dayCount: Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let start = fmt.date(from: batch.startDate) else { return 0 }
        let end: Date
        if let endStr = currentBatch.endDate, let d = fmt.date(from: endStr) { end = d } else { end = Date() }
        return max(1, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1)
    }

    private var soldPercent: Double {
        guard batch.computedTotalBirds > 0 else { return 0 }
        return Double(birdsSold) / Double(batch.computedTotalBirds)
    }

    private var mortalityPercent: Double {
        guard batch.computedTotalBirds > 0 else { return 0 }
        return Double(totalMortality) / Double(batch.computedTotalBirds)
    }

    private var daySummaries: [DaySummary] {
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
                id: date,
                date: date,
                totalMortality: logs.reduce(0) { $0 + $1.mortality },
                totalFeedBags: logs.reduce(0.0) { $0 + $1.feedUsedKg },
                feedTypes: Array(feedTypeSet).sorted(),
                medicines: meds,
                avgWeight: avgWt,
                logCount: logs.count,
                logs: logs
            )
        }
        .sorted { $0.date > $1.date }
    }

    // MARK: - Formatters

    private func formattedDate(_ s: String) -> String {
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"
        guard let d = inFmt.date(from: s) else { return s }
        let outFmt = DateFormatter(); outFmt.dateStyle = .medium
        return outFmt.string(from: d)
    }

    private func shortDate(_ s: String) -> String {
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"
        guard let d = inFmt.date(from: s) else { return s }
        let outFmt = DateFormatter(); outFmt.dateFormat = "d MMM"
        return outFmt.string(from: d)
    }

    private func relativeDay(_ s: String) -> String {
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"
        guard let d = inFmt.date(from: s) else { return s }
        guard let start = inFmt.date(from: batch.startDate) else { return shortDate(s) }
        let day = Calendar.current.dateComponents([.day], from: start, to: d).day ?? 0
        return "Day \(day + 1)"
    }

    private func expenseIcon(_ cat: String) -> String {
        switch cat {
        case "feed": return "leaf.fill"
        case "medicine": return "cross.case.fill"
        case "labour": return "person.2.fill"
        case "birds": return "bird.fill"
        default: return "ellipsis.circle.fill"
        }
    }

    private func expenseColor(_ cat: String) -> Color {
        switch cat {
        case "feed": return .orange
        case "medicine": return .purple
        case "labour": return .blue
        case "birds": return .cyan
        default: return .gray
        }
    }

    // MARK: - Header Toolbar Items

    private var farmPicker: some View {
        Menu {
            Button {
                router.popToRoot()
            } label: {
                Label("Overview", systemImage: "square.grid.2x2")
            }

            Divider()

            ForEach(viewModel.dataStore.farms) { farm in
                Menu {
                    Button {
                        router.popToRoot()
                    } label: {
                        Label("All \(farm.farmName)", systemImage: "house.fill")
                    }

                    Divider()

                    ForEach(viewModel.dataStore.sheds(for: farm)) { shed in
                        Button {
                            router.popToRoot()
                        } label: {
                            Label(shed.shedName, systemImage: "building.2.fill")
                        }
                    }
                } label: {
                    Label(farm.farmName, systemImage: "house.fill")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "building.2.fill")
                    .font(.subheadline)
                Text(viewModel.dataStore.allSheds.first(where: { $0.id == batch.shedId })?.shedName ?? "Shed")
                    .font(.headline)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.primary)
        }
    }

    private var profileButton: some View {
        Button {
            showMyFarms = true
        } label: {
            Image(systemName: "person.crop.circle")
                .font(.title3)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Combined Header + Birds

    private var combinedHeader: some View {
        VStack(spacing: 0) {
            // Gradient banner with batch info
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: currentBatch.status == "running"
                        ? [Color.green.opacity(0.85), Color.green.opacity(0.45)]
                        : [Color.gray.opacity(0.6), Color.gray.opacity(0.3)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 100)
                .overlay(alignment: .topTrailing) {
                    Text(currentBatch.status == "running" ? "RUNNING" : "CLOSED")
                        .font(.caption.weight(.black))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(12)
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.shedName(for: batch.shedId))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        Text(batch.displayTitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Day \(dayCount)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text(formattedDate(batch.startDate))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(16)
            }

            // Bird overview strip
            HStack(spacing: 16) {
                // Mini ring
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 7)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: soldPercent)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: soldPercent, to: min(1.0, soldPercent + mortalityPercent))
                        .stroke(Color.red.opacity(0.7), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    Text("\(birdsLeft)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.purple)
                }

                // Stats grid
                VStack(spacing: 6) {
                    HStack(spacing: 0) {
                        statPill(value: "\(batch.computedTotalBirds)", label: "Total", color: .blue)
                        statPill(value: "\(batch.purchasedBirds)", label: "Bought", color: .primary)
                    }
                    HStack(spacing: 0) {
                        statPill(value: "\(birdsSold)", label: "Sold", color: .orange)
                        statPill(value: "\(totalMortality)", label: "Died", color: .red)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(14)
            .background(Color(.systemBackground))

            if let notes = batch.notes, !notes.isEmpty {
                HStack {
                    Image(systemName: "note.text").font(.caption2).foregroundStyle(.secondary)
                    Text(notes).font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Color(.systemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .padding(.top, 8)
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.7))
                .frame(width: 3, height: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.subheadline.weight(.bold))
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Profit Strip

    private var profitStrip: some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text("₹\(Int(totalRevenue))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.green)
                Text("Revenue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 28)

            VStack(spacing: 2) {
                Text("₹\(Int(totalExpenseAmount))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.red)
                Text("Expenses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 28)

            VStack(spacing: 2) {
                Text(profit >= 0 ? "+₹\(Int(profit))" : "−₹\(Int(abs(profit)))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(profit >= 0 ? .green : .red)
                Text("Profit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            if totalWeightSold > 0 {
                Divider().frame(height: 28)
                VStack(spacing: 2) {
                    Text("\(String(format: "%.0f", totalWeightSold)) kg")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.blue)
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        HStack(spacing: 6) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                let count = tabCount(index)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
                } label: {
                    VStack(spacing: 3) {
                        Text(tab)
                            .font(.subheadline.weight(selectedTab == index ? .bold : .medium))
                        if count > 0 {
                            Text("\(count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selectedTab == index ? tabColor(index) : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == index ? tabColor(index).opacity(0.12) : Color.clear)
                    .foregroundStyle(selectedTab == index ? tabColor(index) : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func tabCount(_ index: Int) -> Int {
        switch index {
        case 0: return batchLogs.count
        case 1: return batchSales.count
        case 2: return batchExpenses.count
        case 3: return batchInventory.count
        default: return 0
        }
    }

    private func tabColor(_ index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .green
        case 2: return .red
        case 3: return .orange
        default: return .primary
        }
    }

    // MARK: - Logs Tab

    private var logsTab: some View {
        VStack(spacing: 12) {
            // Summary card
            if !batchLogs.isEmpty {
                HStack(spacing: 0) {
                    miniStat(icon: "exclamationmark.triangle.fill", value: "\(totalMortality)", label: "Died", color: .red)
                    miniDivider
                    miniStat(icon: "leaf.fill", value: "\(String(format: "%.0f", batchLogs.reduce(0.0) { $0 + $1.feedUsedKg })) bags", label: "Feed", color: .orange)
                    miniDivider
                    let medCount = batchLogs.filter { $0.medicineUsed != nil && !($0.medicineUsed?.isEmpty ?? true) }.count
                    miniStat(icon: "cross.case.fill", value: "\(medCount)", label: "Meds", color: .purple)
                    let weightLogs = batchLogs.filter { $0.avgWeightKg > 0 }
                    if !weightLogs.isEmpty {
                        miniDivider
                        let latestWeight = weightLogs.sorted(by: { $0.logDate > $1.logDate }).first!.avgWeightKg
                        miniStat(icon: "scalemass.fill", value: "\(String(format: "%.2f", latestWeight)) kg", label: "Wt", color: .teal)
                    }
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }

            // Full list of day cards
            if daySummaries.isEmpty {
                emptyState(icon: "list.clipboard", message: "No daily logs yet")
            } else {
                ForEach(daySummaries) { day in
                    dayCard(day)
                }
            }
        }
    }

    private var miniDivider: some View {
        Divider().frame(height: 24)
    }

    private func miniStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.caption2).foregroundStyle(color)
                Text(value).font(.subheadline.weight(.bold)).foregroundStyle(color)
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func dayCard(_ day: DaySummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(relativeDay(day.date))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.blue)
                Text("·").foregroundStyle(.secondary)
                Text(shortDate(day.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if day.logCount > 1 {
                    Text("(\(day.logCount) entries)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }

            HStack(spacing: 16) {
                if day.totalMortality > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.caption2).foregroundStyle(.red)
                        Text("\(day.totalMortality) died").font(.subheadline.weight(.medium)).foregroundStyle(.red)
                    }
                }
                if day.totalFeedBags > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill").font(.caption2).foregroundStyle(.orange)
                        Text("\(String(format: "%.1f", day.totalFeedBags)) bags").font(.subheadline.weight(.medium))
                        if !day.feedTypes.isEmpty {
                            Text(day.feedTypes.map { $0.capitalized }.joined(separator: ", "))
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
                Spacer()
            }

            if !day.medicines.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "cross.case.fill").font(.caption2).foregroundStyle(.purple)
                    let medText = day.medicines.map { "\($0.name)\($0.qty > 0 ? " (\(String(format: "%.0f", $0.qty)))" : "")" }
                    Text(medText.joined(separator: ", "))
                        .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
            }

            if day.avgWeight > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "scalemass.fill").font(.caption2).foregroundStyle(.teal)
                    Text("\(String(format: "%.2f", day.avgWeight)) kg avg")
                        .font(.subheadline.weight(.medium)).foregroundStyle(.teal)
                }
            }

            let dayNotes = day.logs.compactMap(\.notes).filter { !$0.isEmpty }
            if !dayNotes.isEmpty {
                Text(dayNotes.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.tertiary).lineLimit(1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Sales Tab

    private var salesTab: some View {
        VStack(spacing: 12) {
            // Summary card
            if !batchSales.isEmpty {
                HStack(spacing: 0) {
                    miniStat(icon: "bird.fill", value: "\(birdsSold)", label: "Birds", color: .orange)
                    miniDivider
                    miniStat(icon: "scalemass.fill", value: "\(String(format: "%.0f", totalWeightSold)) kg", label: "Weight", color: .blue)
                    miniDivider
                    miniStat(icon: "indianrupeesign.circle.fill", value: "₹\(Int(totalRevenue))", label: "Revenue", color: .green)
                    if totalWeightSold > 0 {
                        miniDivider
                        let avgRate = totalRevenue / totalWeightSold
                        miniStat(icon: "chart.line.uptrend.xyaxis", value: "₹\(Int(avgRate))", label: "Avg/kg", color: .teal)
                    }
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.green.opacity(0.14), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }

            // Full list
            if batchSales.isEmpty {
                emptyState(icon: "cart", message: "No sales recorded yet")
            } else {
                ForEach(batchSales) { sale in
                    saleRow(sale)
                }
            }
        }
    }

    private func saleRow(_ sale: SaleRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(shortDate(sale.saleDate))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.green.opacity(0.1))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
                Spacer()
                Text("₹\(Int(sale.totalAmount))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.green)
            }

            HStack(spacing: 12) {
                Label("\(sale.birdCount) birds", systemImage: "bird").font(.subheadline)
                Label("\(String(format: "%.1f", sale.totalWeightKg)) kg", systemImage: "scalemass").font(.subheadline)
                Label("₹\(Int(sale.costPerKg))/kg", systemImage: "indianrupeesign").font(.subheadline)
            }
            .foregroundStyle(.secondary)

            if let buyerId = sale.buyerId {
                Label(viewModel.buyerName(for: buyerId), systemImage: "building.2")
                    .font(.subheadline).foregroundStyle(.blue)
            }

            if let notes = sale.notes, !notes.isEmpty {
                Text(notes).font(.caption).foregroundStyle(.tertiary).lineLimit(1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Expenses Tab

    private var expensesTab: some View {
        VStack(spacing: 12) {
            // Summary card with stacked bar
            if !batchExpenses.isEmpty {
                VStack(spacing: 10) {
                    HStack {
                        Text("Total")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("₹\(Int(totalExpenseAmount))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.red)
                    }

                    // Stacked bar
                    let grouped = Dictionary(grouping: batchExpenses, by: \.category)
                    if totalExpenseAmount > 0 {
                        GeometryReader { geo in
                            HStack(spacing: 2) {
                                ForEach(grouped.keys.sorted(), id: \.self) { cat in
                                    let catTotal = grouped[cat]?.reduce(0.0) { $0 + $1.amount } ?? 0
                                    let ratio = catTotal / totalExpenseAmount
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(expenseColor(cat))
                                        .frame(width: max(4, geo.size.width * ratio))
                                }
                            }
                        }
                        .frame(height: 8)
                        .clipShape(Capsule())
                    }

                    // Category pills
                    HStack(spacing: 0) {
                        let sortedCats = grouped.keys.sorted {
                            (grouped[$0]?.reduce(0.0) { $0 + $1.amount } ?? 0) >
                            (grouped[$1]?.reduce(0.0) { $0 + $1.amount } ?? 0)
                        }
                        ForEach(sortedCats.prefix(4), id: \.self) { cat in
                            let catTotal = grouped[cat]?.reduce(0.0) { $0 + $1.amount } ?? 0
                            VStack(spacing: 2) {
                                Text("₹\(Int(catTotal))")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(expenseColor(cat))
                                Text(cat.capitalized)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.12), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }

            // Full list
            if batchExpenses.isEmpty {
                emptyState(icon: "arrow.up.circle", message: "No expenses recorded")
            } else {
                ForEach(batchExpenses.sorted(by: { $0.expenseDate > $1.expenseDate })) { expense in
                    expenseRow(expense)
                }
            }
        }
    }

    private func expenseRow(_ expense: ExpenseRecord) -> some View {
        HStack(spacing: 10) {
            Image(systemName: expenseIcon(expense.category))
                .font(.caption).foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(expenseColor(expense.category))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category.capitalized)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
                    Text(shortDate(expense.expenseDate))
                        .font(.caption).foregroundStyle(.secondary)
                    if let desc = expense.description, !desc.isEmpty {
                        Text("· \(desc)")
                            .font(.caption).foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Text("₹\(Int(expense.amount))")
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Inventory Tab

    private var inventoryTab: some View {
        VStack(spacing: 12) {
            if !batchInventory.isEmpty {
                HStack(spacing: 0) {
                    let feedItems = batchInventory.filter { $0.category == "feed" }
                    let medItems = batchInventory.filter { $0.category == "medicine" }
                    miniStat(icon: "leaf.fill", value: "\(feedItems.count)", label: "Feed", color: .orange)
                    miniDivider
                    miniStat(icon: "cross.case.fill", value: "\(medItems.count)", label: "Medicine", color: .purple)
                    miniDivider
                    miniStat(icon: "indianrupeesign.circle.fill", value: "₹\(Int(batchInventory.reduce(0.0) { $0 + $1.totalCost }))", label: "Cost", color: .red)
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.purple.opacity(0.12), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }

            if batchInventory.isEmpty {
                emptyState(icon: "shippingbox", message: "No inventory linked")
            } else {
                let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(batchInventory) { item in
                        inventoryTile(item)
                    }
                }
            }
        }
    }

    private func inventoryTile(_ item: InventoryRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: item.category == "feed" ? "leaf.fill" : "cross.case.fill")
                    .font(.subheadline).foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(item.category == "feed" ? Color.orange : Color.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Spacer()
                Text("₹\(Int(item.totalCost))")
                    .font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            Text(item.itemName).font(.subheadline.weight(.semibold)).lineLimit(1)
            if let ft = item.feedType {
                Text(ft.capitalized).font(.caption).foregroundStyle(.orange)
            }
            HStack {
                Text("\(Int(item.quantity)) \(item.unit)").font(.caption).foregroundStyle(.secondary)
                Spacer()
                if item.used > 0 {
                    Text("\(Int(item.quantity - item.used)) left").font(.caption.weight(.medium)).foregroundStyle(.purple)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke((item.category == "feed" ? Color.orange : Color.purple).opacity(0.16), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Button {
            Task { try await batchVM.closeBatch(batch) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill").font(.title3)
                Text("Close Batch").font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(LinearGradient(colors: [.orange, .orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
        }
    }

    // MARK: - Empty State

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.quaternary)
            Text(message).font(.subheadline).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Batch Logs List View

struct BatchLogsListView: View {
    @ObservedObject var viewModel: BatchesTabViewModel
    let batch: BatchRecord
    let daySummaries: [DaySummary]

    var body: some View {
        List {
            ForEach(daySummaries) { day in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(relativeDay(day.date))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.blue)
                            Spacer()
                            Text(formattedDate(day.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if day.logCount > 1 {
                            Text("\(day.logCount) entries")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        if day.totalMortality > 0 {
                            Label("\(day.totalMortality) died", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.red)
                        }

                        if day.totalFeedBags > 0 {
                            HStack(spacing: 4) {
                                Label("\(String(format: "%.1f", day.totalFeedBags)) bags feed", systemImage: "leaf.fill")
                                    .font(.subheadline)
                                if !day.feedTypes.isEmpty {
                                    Text("(\(day.feedTypes.map { $0.capitalized }.joined(separator: ", ")))")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }

                        ForEach(day.medicines.indices, id: \.self) { i in
                            let med = day.medicines[i]
                            Label("\(med.name)\(med.qty > 0 ? " – \(String(format: "%.0f", med.qty))" : "")", systemImage: "cross.case.fill")
                                .font(.subheadline)
                                .foregroundStyle(.purple)
                        }

                        if day.avgWeight > 0 {
                            Label("\(String(format: "%.2f", day.avgWeight)) kg avg weight", systemImage: "scalemass.fill")
                                .font(.subheadline)
                                .foregroundStyle(.teal)
                        }

                        let dayNotes = day.logs.compactMap(\.notes).filter { !$0.isEmpty }
                        if !dayNotes.isEmpty {
                            Text(dayNotes.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Daily Logs")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func relativeDay(_ s: String) -> String {
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"
        guard let d = inFmt.date(from: s), let start = inFmt.date(from: batch.startDate) else { return s }
        let day = Calendar.current.dateComponents([.day], from: start, to: d).day ?? 0
        return "Day \(day + 1)"
    }

    private func formattedDate(_ s: String) -> String {
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"
        guard let d = inFmt.date(from: s) else { return s }
        let outFmt = DateFormatter(); outFmt.dateStyle = .medium
        return outFmt.string(from: d)
    }
}

// MARK: - Batch Sales List View

struct BatchSalesListView: View {
    @ObservedObject var viewModel: BatchesTabViewModel
    let batch: BatchRecord
    let sales: [SaleRecord]

    private var totalRevenue: Double { sales.reduce(0.0) { $0 + $1.totalAmount } }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(sales.count) sale\(sales.count == 1 ? "" : "s")")
                            .font(.subheadline.weight(.medium))
                        Text("\(sales.reduce(0) { $0 + $1.birdCount }) birds · \(String(format: "%.1f", sales.reduce(0.0) { $0 + $1.totalWeightKg })) kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("₹\(Int(totalRevenue))")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.green)
                }
            }

            ForEach(sales) { sale in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(formattedDate(sale.saleDate))
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("₹\(Int(sale.totalAmount))")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.green)
                        }

                        HStack(spacing: 16) {
                            Label("\(sale.birdCount) birds", systemImage: "bird")
                                .font(.subheadline)
                            Label("\(String(format: "%.1f", sale.totalWeightKg)) kg", systemImage: "scalemass")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)

                        Text("₹\(Int(sale.costPerKg))/kg")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.blue)

                        if let buyerId = sale.buyerId {
                            Label(viewModel.buyerName(for: buyerId), systemImage: "building.2")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }

                        if let notes = sale.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Sales")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedDate(_ s: String) -> String {
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"
        guard let d = inFmt.date(from: s) else { return s }
        let outFmt = DateFormatter(); outFmt.dateStyle = .medium
        return outFmt.string(from: d)
    }
}

// MARK: - Batch Expenses List View

struct BatchExpensesListView: View {
    @ObservedObject var viewModel: BatchesTabViewModel
    let batch: BatchRecord
    let expenses: [ExpenseRecord]

    private var totalAmount: Double { expenses.reduce(0.0) { $0 + $1.amount } }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(expenses.count) expense\(expenses.count == 1 ? "" : "s")")
                            .font(.subheadline.weight(.medium))
                        let cats = Set(expenses.map(\.category))
                        Text(cats.sorted().map { $0.capitalized }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("₹\(Int(totalAmount))")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.red)
                }
            }

            let grouped = Dictionary(grouping: expenses, by: \.category)
            let sortedCats = grouped.keys.sorted {
                (grouped[$0]?.reduce(0.0) { $0 + $1.amount } ?? 0) >
                (grouped[$1]?.reduce(0.0) { $0 + $1.amount } ?? 0)
            }

            ForEach(sortedCats, id: \.self) { cat in
                let items = grouped[cat] ?? []
                let catTotal = items.reduce(0.0) { $0 + $1.amount }

                Section(header: HStack {
                    Image(systemName: expenseIcon(cat))
                        .foregroundStyle(expenseColor(cat))
                    Text(cat.capitalized)
                    Spacer()
                    Text("₹\(Int(catTotal))")
                        .foregroundStyle(expenseColor(cat))
                }) {
                    ForEach(items) { expense in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formattedDate(expense.expenseDate))
                                    .font(.subheadline.weight(.medium))
                                if let desc = expense.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("₹\(Int(expense.amount))")
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Expenses")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedDate(_ s: String) -> String {
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"
        guard let d = inFmt.date(from: s) else { return s }
        let outFmt = DateFormatter(); outFmt.dateStyle = .medium
        return outFmt.string(from: d)
    }

    private func expenseIcon(_ cat: String) -> String {
        switch cat {
        case "feed": return "leaf.fill"
        case "medicine": return "cross.case.fill"
        case "labour": return "person.2.fill"
        case "birds": return "bird.fill"
        default: return "ellipsis.circle.fill"
        }
    }

    private func expenseColor(_ cat: String) -> Color {
        switch cat {
        case "feed": return .orange
        case "medicine": return .purple
        case "labour": return .blue
        case "birds": return .cyan
        default: return .gray
        }
    }
}
