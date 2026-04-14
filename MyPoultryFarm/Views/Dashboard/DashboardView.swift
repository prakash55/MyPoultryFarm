//
//  DashboardView.swift
//  MyPoultryFarm
//
//  Rich dashboard shell — all metrics, summaries, graphs and FAB.
//  Scope-specific content injected via `content` ViewBuilder.
//

import SwiftUI
import Charts

struct DashboardView<Content: View>: View {
    @ObservedObject var viewModel: DashboardTabViewModel
    let scopeShedIds: Set<UUID>
    let scopeLabel: String
    let scopeIcon: String
    @ViewBuilder let content: () -> Content

    @State private var showAddBatch = false
    @State private var showAddInventory = false
    @State private var showAddSale = false
    @State private var showAddExpense = false
    @State private var isFABExpanded = false

    private var data: ScopeData {
        ScopeData(viewModel: viewModel.dataStore, scopeShedIds: scopeShedIds)
    }

    private var fabItems: [FABItem] {
        [
            FABItem(label: "New Batch",   icon: "arrow.triangle.2.circlepath", color: .green)   { showAddBatch = true },
            FABItem(label: "Inventory",   icon: "shippingbox.fill",            color: .orange)  { showAddInventory = true },
            FABItem(label: "Record Sale", icon: "cart.badge.plus",             color: .blue)    { showAddSale = true },
            FABItem(label: "Add Expense", icon: "indianrupeesign.circle.fill", color: .red)     { showAddExpense = true },
        ]
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    batchHeroCard
                    batchMetricsStrip

                    financesHeroCard
                    expenseBreakdownCard

                    feedHeroCard
                    feedMetricsStrip

                    salesHeroCard
                    salesMetricsStrip

                    // --- Graphs ---
                    if !data.mortalityChartData.isEmpty {
                        BatchLineChart(
                            title: "Mortality Trend",
                            icon: "heart.slash.fill",
                            color: .red,
                            series: data.mortalityChartData,
                            yLabel: "Mortality Count",
                            xLabel: "Day",
                            xDomain: 1...60
                        )
                    }

                    if !data.feedChartData.isEmpty {
                        BatchLineChart(
                            title: "Feed Consumption",
                            icon: "leaf.fill",
                            color: .orange,
                            series: data.feedChartData,
                            yLabel: "Bags / Day",
                            xLabel: "Day",
                            xDomain: 1...60
                        )
                    }

                    if !data.weightChartData.isEmpty {
                        BatchLineChart(
                            title: "Average Weight",
                            icon: "scalemass.fill",
                            color: .blue,
                            series: data.weightChartData,
                            yLabel: "Weight (g)",
                            xLabel: "Day",
                            xDomain: 1...60
                        )
                    }

                    // --- Scope-specific content ---
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }
            .sheet(isPresented: $showAddBatch) {
                AddBatchView(viewModel: BatchViewModel(dataStore: viewModel.dataStore))
            }
            .sheet(isPresented: $showAddInventory) {
                AddInventoryItemView(viewModel: InventoryViewModel(dataStore: viewModel.dataStore))
            }
            .sheet(isPresented: $showAddSale) {
                AddSaleView(viewModel: SalesViewModel(dataStore: viewModel.dataStore))
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(viewModel: ExpenseViewModel(dataStore: viewModel.dataStore))
            }

            FloatingActionButton(items: fabItems, isExpanded: $isFABExpanded)
        }
    }

    // MARK: - Batch Hero Card

    private var batchHeroCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Birds")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                    Text("\(data.totalBirds)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(data.runningBatchCount) Running")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.15)))

                    if data.closedBatches.count > 0 {
                        Text("\(data.closedBatches.count) Closed")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle().fill(.white.opacity(0.12)).frame(height: 1).padding(.horizontal, 16)

            batchHeroStats
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.42, blue: 0.32),
                         Color(red: 0.12, green: 0.55, blue: 0.42)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var batchHeroStats: some View {
        HStack(spacing: 0) {
            heroStat(value: "\(data.birdsLeft)", label: "Left", icon: "bird.fill", color: .cyan)
            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
            heroStat(value: "\(data.totalMortality)", label: "Deaths", icon: "heart.slash.fill", color: .red)
            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
            heroStat(value: "\(data.totalBirdsSold)", label: "Sold", icon: "cart.fill", color: .yellow)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Batch Metrics Strip

    private var batchMetricsStrip: some View {
        VStack(spacing: 0) {
            if let top = data.highestMortalityBatch, top.mortality > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("Top mortality: B#\(top.batch.batchNumber) · \(top.mortality)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.red.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.red.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Finances Hero Card

    private var financesHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Net Profit")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .center, spacing: 6) {
                        Image(systemName: data.profit >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(data.profit >= 0 ? .green : .red)
                        Text(formatCurrency(data.profit))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(data.profit >= 0 ? Color(red: 0.15, green: 0.68, blue: 0.38) : .red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                Spacer()
                profitRing
            }

            Rectangle().fill(Color(.separator).opacity(0.3)).frame(height: 1)

            HStack(spacing: 0) {
                financialMetricCell(title: "Income", value: formatCurrency(data.totalSalesAmount), color: .green)
                Rectangle().fill(Color(.separator).opacity(0.3)).frame(width: 1, height: 32)
                financialMetricCell(title: "Expenses", value: formatCurrency(data.totalExpensesAmount), color: .red)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color.green.opacity(0.06)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private var profitRing: some View {
        let total = data.totalSalesAmount + data.totalExpensesAmount
        let incomePct = total > 0 ? data.totalSalesAmount / total : 0.5
        return ZStack {
            Circle()
                .stroke(Color.red.opacity(0.18), lineWidth: 6)
                .frame(width: 52, height: 52)
            Circle()
                .trim(from: 0, to: incomePct)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 52, height: 52)
                .rotationEffect(.degrees(-90))
            Text("\(Int(incomePct * 100))%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }

    private func financialMetricCell(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Expense Breakdown Card

    private var expenseBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Expense Breakdown")
                .font(.subheadline.weight(.semibold))

            expenseBarRow(label: "Bird Purchase", amount: data.expensesFor(category: "birds"), icon: "bird", color: Color(red: 0.31, green: 0.82, blue: 0.53))
            expenseBarRow(label: "Feed", amount: data.expensesFor(category: "feed"), icon: "leaf.fill", color: Color(red: 1.0, green: 0.73, blue: 0.28))
            expenseBarRow(label: "Medicine", amount: data.expensesFor(category: "medicine"), icon: "cross.case.fill", color: Color(red: 0.67, green: 0.27, blue: 0.94))
            expenseBarRow(label: "Labour", amount: data.expensesFor(category: "labour"), icon: "person.2.fill", color: Color(red: 0.23, green: 0.59, blue: 0.96))
            expenseBarRow(label: "Other", amount: data.expensesFor(category: "other"), icon: "ellipsis.circle.fill", color: Color(red: 0.63, green: 0.64, blue: 0.70))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color(.systemBackground), Color.red.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
    }

    private func expenseBarRow(label: String, amount: Double, icon: String, color: Color) -> some View {
        let maxAmount = max(
            data.expensesFor(category: "birds"),
            data.expensesFor(category: "feed"),
            data.expensesFor(category: "medicine"),
            data.expensesFor(category: "labour"),
            data.expensesFor(category: "other"),
            1
        )
        let ratio = amount / maxAmount

        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.caption.weight(.medium))
                    Spacer()
                    Text(formatCurrency(amount))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5))
                        Capsule()
                            .fill(LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(4, geo.size.width * ratio))
                    }
                }
                .frame(height: 5)
            }
        }
    }

    // MARK: - Feed Hero Card

    private var feedHeroCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Feed Available")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                    Text("\(Int(data.feedAvailable)) bags")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(formatCurrency(data.feedCostTotal))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.white.opacity(0.15)))

                    if let top = data.highestFeedConsumptionBatch, top.feedBags > 0 {
                        Text("Top: B#\(top.batch.batchNumber) · \(String(format: "%.1f", top.feedBags))")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle().fill(.white.opacity(0.12)).frame(height: 1).padding(.horizontal, 16)

            feedHeroStats
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.60, green: 0.35, blue: 0.08),
                         Color(red: 0.75, green: 0.50, blue: 0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var feedHeroStats: some View {
        HStack(spacing: 0) {
            heroStat(value: "\(Int(data.totalFeedQuantity))", label: "Stock", icon: "cube.box.fill", color: .cyan)
            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
            heroStat(value: "\(Int(data.feedUsed))", label: "Used", icon: "arrow.uturn.down", color: .yellow)
            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
            heroStat(value: String(format: "%.1f/d", data.feedConsumptionRatePerDay), label: "Rate", icon: "chart.bar.fill", color: .mint)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Feed Metrics Strip

    private var feedMetricsStrip: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                metricPill(title: "Feed Cost", value: formatCurrency(data.feedCostTotal), color: .red)
                metricPill(title: "Medicine", value: formatCurrency(data.medicineItems.reduce(0.0) { $0 + $1.totalCost }), color: .purple)
                metricPill(title: "Days Left", value: feedDaysLeftText, color: data.isFeedLow ? .red : .green)
            }

            if data.isFeedLow {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("Feed stock low — less than 3 days remaining!")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.red.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.red.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
    }

    private var feedDaysLeftText: String {
        guard data.feedConsumptionRatePerDay > 0 else { return "∞" }
        let days = Int(data.feedAvailable / data.feedConsumptionRatePerDay)
        return "\(days) days"
    }

    // MARK: - Sales Hero Card

    private var salesHeroCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Revenue")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                    Text(formatCurrency(data.totalSalesAmount))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(data.sales.count) Sales")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(.white.opacity(0.15)))
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle().fill(.white.opacity(0.12)).frame(height: 1).padding(.horizontal, 16)

            salesHeroStats
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.46, blue: 0.30),
                         Color(red: 0.12, green: 0.56, blue: 0.38)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var salesHeroStats: some View {
        HStack(spacing: 0) {
            heroStat(value: "\(data.totalBirdsSold)", label: "Sold", icon: "bird.fill", color: .cyan)
            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
            heroStat(value: "\(String(format: "%.0f", data.totalWeightSold)) kg", label: "Weight", icon: "scalemass.fill", color: .yellow)
            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
            heroStat(value: "\(data.birdsLeft)", label: "Left", icon: "bird", color: .mint)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Sales Metrics Strip

    private var salesMetricsStrip: some View {
        HStack(spacing: 10) {
            metricPill(title: "Avg Rate", value: "₹\(Int(data.avgRatePerKg))/kg", color: .orange)
            metricPill(title: "Total Weight", value: "\(String(format: "%.1f", data.totalWeightSold)) kg", color: .blue)
            metricPill(title: "Birds Left", value: "\(data.birdsLeft)", color: .purple)
        }
    }

    // MARK: - Shared Helpers

    private func heroStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private func metricPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func formatCurrency(_ value: Double) -> String {
        let isNeg = value < 0
        let abs = abs(value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: abs)) ?? "\(Int(abs))"
        return "\(isNeg ? "-" : "")₹\(formatted)"
    }
}
