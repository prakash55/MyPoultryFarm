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
            LinearGradient(
                colors: [Color.green.opacity(0.08), Color.orange.opacity(0.05), Color(.systemGroupedBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ScopeBanner(label: scopeLabel, icon: scopeIcon)

                    // --- Batch Info ---
                    batchInfoSection

                    // --- Finances Summary ---
                    financesSummaryCard

                    // --- Feed / Inventory Info ---
                    feedInfoSection

                    // --- Sale Summary ---
                    saleSummaryCard

                    // --- Graphs ---
                    if !data.mortalityChartData.isEmpty {
                        BatchLineChart(
                            title: "Mortality Trend",
                            icon: "heart.slash.fill",
                            color: .red,
                            series: data.mortalityChartData,
                            yLabel: "Cumulative Deaths",
                            xLabel: "Day"
                        )
                    }

                    if !data.feedChartData.isEmpty {
                        BatchLineChart(
                            title: "Feed Consumption",
                            icon: "leaf.fill",
                            color: .orange,
                            series: data.feedChartData,
                            yLabel: "Cumulative Feed (bags)",
                            xLabel: "Day"
                        )
                    }

                    if !data.weightChartData.isEmpty {
                        BatchLineChart(
                            title: "Average Weight",
                            icon: "scalemass.fill",
                            color: .blue,
                            series: data.weightChartData,
                            yLabel: "Weight (kg)",
                            xLabel: "Day"
                        )
                    }

                    // --- Scope-specific content ---
                    content()
                }
                .padding()
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

    // MARK: - Batch Info

    private var batchInfoSection: some View {
        dashboardCard(accent: .green) {
            sectionTitle("Batch Info", icon: "arrow.triangle.2.circlepath", tint: .green)

            HStack(spacing: 12) {
                SummaryTile(title: "Running", value: "\(data.runningBatchCount)", icon: "arrow.triangle.2.circlepath", color: .green)
                SummaryTile(title: "Birds", value: "\(data.totalBirds)", icon: "chicken_icon", color: .blue)
                SummaryTile(title: "Left", value: "\(data.birdsLeft)", icon: "bird", color: .purple)
            }

            HStack(spacing: 12) {
                SummaryTile(title: "Deaths", value: "\(data.totalMortality)", icon: "heart.slash.fill", color: .red)
                SummaryTile(title: "Sold", value: "\(data.totalBirdsSold)", icon: "cart.fill", color: .orange)
                SummaryTile(title: "Closed", value: "\(data.closedBatches.count)", icon: "checkmark.circle.fill", color: .gray)
            }

            if let top = data.highestMortalityBatch, top.mortality > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Top mortality: B#\(top.batch.batchNumber) · \(top.mortality)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Finances Summary

    private var financesSummaryCard: some View {
        dashboardCard(accent: .blue) {
            sectionTitle("Finances", icon: "indianrupeesign.circle.fill", tint: .blue)

            HStack(spacing: 12) {
                SummaryTile(title: "Income", value: "₹\(Int(data.totalSalesAmount))", icon: "arrow.down.circle.fill", color: .green)
                SummaryTile(title: "Expenses", value: "₹\(Int(data.totalExpensesAmount))", icon: "arrow.up.circle.fill", color: .red)
                SummaryTile(title: "Profit", value: "₹\(Int(data.profit))", icon: "chart.line.uptrend.xyaxis", color: data.profit >= 0 ? .green : .red)
            }

            VStack(spacing: 6) {
                financeRow("Bird Purchase", amount: data.expensesFor(category: "birds"), icon: "bird", color: .green)
                financeRow("Feed", amount: data.expensesFor(category: "feed"), icon: "leaf.fill", color: .orange)
                financeRow("Medicine", amount: data.expensesFor(category: "medicine"), icon: "cross.case.fill", color: .purple)
                financeRow("Labour", amount: data.expensesFor(category: "labour"), icon: "person.2.fill", color: .blue)
                financeRow("Other", amount: data.expensesFor(category: "other"), icon: "ellipsis.circle.fill", color: .gray)
            }
        }
    }

    private func financeRow(_ label: String, amount: Double, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.caption.weight(.medium))
            Spacer()
            Text("₹\(Int(amount))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(amount == 0 ? Color.secondary : Color.red)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Feed Info

    private var feedInfoSection: some View {
        dashboardCard(accent: .orange) {
            sectionTitle("Feed & Inventory", icon: "leaf.fill", tint: .orange)

            HStack(spacing: 12) {
                SummaryTile(title: "Stock", value: "\(Int(data.totalFeedQuantity)) bags", icon: "shippingbox.fill", color: .orange)
                SummaryTile(title: "Used", value: "\(Int(data.feedUsed)) bags", icon: "shippingbox", color: .gray)
                SummaryTile(title: "Avail", value: "\(Int(data.feedAvailable)) bags", icon: "leaf.fill", color: .green)
            }

            HStack(spacing: 12) {
                SummaryTile(title: "Feed ₹", value: "₹\(Int(data.feedCostTotal))", icon: "indianrupeesign.circle", color: .red)
                SummaryTile(title: "Day Rate", value: "\(String(format: "%.1f", data.feedConsumptionRatePerDay)) bags", icon: "chart.bar.fill", color: .blue)
                SummaryTile(title: "Medicine", value: "₹\(Int(data.medicineItems.reduce(0.0) { $0 + $1.totalCost }))", icon: "cross.case.fill", color: .purple)
            }

            if let top = data.highestFeedConsumptionBatch, top.feedBags > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("Top feed: B#\(top.batch.batchNumber) · \(String(format: "%.1f", top.feedBags)) bags")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if data.isFeedLow {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Feed stock low — less than 3 days remaining!")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
                .padding(10)
                .background(Color.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Sale Summary

    private var saleSummaryCard: some View {
        dashboardCard(accent: .teal) {
            sectionTitle("Sales Summary", icon: "cart.fill", tint: .teal)

            HStack(spacing: 12) {
                SummaryTile(title: "Revenue", value: "₹\(Int(data.totalSalesAmount))", icon: "indianrupeesign.circle.fill", color: .green)
                SummaryTile(title: "Birds Sold", value: "\(data.totalBirdsSold)", icon: "chicken_icon", color: .blue)
                SummaryTile(title: "Avg Rate", value: "₹\(Int(data.avgRatePerKg))/kg", icon: "tag.fill", color: .orange)
            }

            HStack {
                compactStat(title: "Total Weight", value: "\(String(format: "%.1f", data.totalWeightSold)) kg", tint: .blue)
                Spacer()
                compactStat(title: "Transactions", value: "\(data.sales.count)", tint: .primary)
                Spacer()
                compactStat(title: "Birds Left", value: "\(data.birdsLeft)", tint: .purple)
            }
        }
    }

    // MARK: - UI Helpers

    private func sectionTitle(_ title: String, icon: String, tint: Color) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(tint)
            Spacer()
        }
        .padding(.bottom, 2)
    }

    private func compactStat(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func dashboardCard<Inner: View>(accent: Color, @ViewBuilder content: () -> Inner) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accent.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}
