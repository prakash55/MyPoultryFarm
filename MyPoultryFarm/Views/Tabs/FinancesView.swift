//
//  FinancesView.swift
//  MyPoultryFarm
//

import SwiftUI

struct FinancesView: View {
    @StateObject private var viewModel: FinancesTabViewModel
    let scopeShedIds: Set<UUID>
    let scopeLabel: String
    let scopeIcon: String
    let scopeLevel: ScopeLevel

    init(dataStore: MyFarmsViewModel, scopeShedIds: Set<UUID>, scopeLabel: String, scopeIcon: String, scopeLevel: ScopeLevel) {
        _viewModel = StateObject(wrappedValue: FinancesTabViewModel(dataStore: dataStore))
        self.scopeShedIds = scopeShedIds
        self.scopeLabel = scopeLabel
        self.scopeIcon = scopeIcon
        self.scopeLevel = scopeLevel
    }

    @State private var selectedSegment = 0
    @State private var showAddExpense = false

    private var data: ScopeData {
        ScopeData(viewModel: viewModel.dataStore, scopeShedIds: scopeShedIds)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    ScopeBanner(label: scopeLabel, icon: scopeIcon)

                    summaryTiles

                    expenseBreakdownCard

                    switch scopeLevel {
                    case .overview:
                        overviewContent
                    case .farm:
                        farmContent
                    case .shed:
                        shedContent
                    }
                }
                .padding()
                .padding(.bottom, 60)
            }

            addButton
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(viewModel: ExpenseViewModel(dataStore: viewModel.dataStore))
        }
    }

    // MARK: - Summary Tiles

    @ViewBuilder
    private var summaryTiles: some View {
        switch scopeLevel {
        case .overview:
            HStack(spacing: 12) {
                SummaryTile(title: "Income", value: "₹\(Int(data.totalSalesAmount))", icon: "arrow.down.circle.fill", color: .green)
                SummaryTile(title: "Expenses", value: "₹\(Int(data.totalExpensesAmount))", icon: "arrow.up.circle.fill", color: .red)
                SummaryTile(title: "Profit", value: "₹\(Int(data.profit))", icon: "indianrupeesign.circle.fill", color: data.profit >= 0 ? .green : .red)
            }
        case .farm:
            HStack(spacing: 12) {
                SummaryTile(title: "Income", value: "₹\(Int(data.totalSalesAmount))", icon: "arrow.down.circle.fill", color: .green)
                SummaryTile(title: "Expenses", value: "₹\(Int(data.totalExpensesAmount))", icon: "arrow.up.circle.fill", color: .red)
            }
            HStack(spacing: 12) {
                SummaryTile(title: "Profit", value: "₹\(Int(data.profit))", icon: "indianrupeesign.circle.fill", color: data.profit >= 0 ? .green : .red)
                SummaryTile(title: "Txns", value: "\(data.sales.count + data.expenses.count)", icon: "list.bullet", color: .gray)
            }
        case .shed:
            HStack(spacing: 12) {
                SummaryTile(title: "Income", value: "₹\(Int(data.totalSalesAmount))", icon: "arrow.down.circle.fill", color: .green)
                SummaryTile(title: "Expenses", value: "₹\(Int(data.totalExpensesAmount))", icon: "arrow.up.circle.fill", color: .red)
            }
            HStack(spacing: 12) {
                SummaryTile(title: "Profit", value: "₹\(Int(data.profit))", icon: "indianrupeesign.circle.fill", color: data.profit >= 0 ? .green : .red)
                SummaryTile(title: "Txns", value: "\(data.sales.count + data.expenses.count)", icon: "list.bullet", color: .gray)
            }
        }
    }

    // MARK: - Expense Breakdown

    private var expenseBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Expense Breakdown")
                .font(.subheadline.weight(.semibold))
            Divider()
            expenseRow("Birds", icon: "bird", color: .green, amount: data.expensesFor(category: "birds"))
            expenseRow("Feed", icon: "leaf.fill", color: .orange, amount: data.expensesFor(category: "feed"))
            expenseRow("Medicine", icon: "cross.case.fill", color: .purple, amount: data.expensesFor(category: "medicine"))
            expenseRow("Labour", icon: "person.2.fill", color: .blue, amount: data.expensesFor(category: "labour"))
            expenseRow("Other", icon: "ellipsis.circle.fill", color: .gray, amount: data.expensesFor(category: "other"))
            Divider()
            HStack {
                Text("Net Profit")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("₹\(Int(data.profit))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(data.profit >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }

    private func expenseRow(_ label: String, icon: String, color: Color, amount: Double) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.caption)
            Spacer()
            Text("₹\(Int(amount))")
                .font(.caption.weight(.medium))
                .foregroundStyle(.red)
        }
    }

    // MARK: - Overview: farm tree with aggregates

    private var overviewContent: some View {
        Group {
            Picker("View", selection: $selectedSegment) {
                Text("By Location").tag(0)
                Text("Income").tag(1)
                Text("Expenses").tag(2)
            }
            .pickerStyle(.segmented)

            switch selectedSegment {
            case 0: treeView
            case 1: incomeList
            default: expenseList
            }
        }
    }

    // MARK: - Farm: per-shed financial summary

    private var farmContent: some View {
        let sheds = viewModel.dataStore.allSheds.filter { scopeShedIds.contains($0.id!) }
        return ForEach(sheds) { shed in
            let shedSales = data.sales.filter { $0.shedId == shed.id }
            let shedExpenses = data.expenses.filter { $0.shedId == shed.id }
            let income = shedSales.reduce(0.0) { $0 + $1.totalAmount }
            let expense = shedExpenses.reduce(0.0) { $0 + $1.amount }
            let profit = income - expense

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 20)
                    Text(shed.shedName)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("₹\(Int(profit))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(profit >= 0 ? .green : .red)
                }

                HStack(spacing: 12) {
                    Label("₹\(Int(income))", systemImage: "arrow.down.circle")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Label("₹\(Int(expense))", systemImage: "arrow.up.circle")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Label("\(shedSales.count + shedExpenses.count) txns", systemImage: "list.bullet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 28)

                // Per-category mini breakdown
                let categories = Dictionary(grouping: shedExpenses, by: { $0.category })
                if !categories.isEmpty {
                    Divider()
                    ForEach(categories.keys.sorted(), id: \.self) { cat in
                        let catAmount = categories[cat]!.reduce(0.0) { $0 + $1.amount }
                        HStack(spacing: 8) {
                            Image(systemName: categoryIcon(cat))
                                .foregroundStyle(categoryColor(cat))
                                .frame(width: 16)
                            Text(cat.capitalized)
                                .font(.caption2)
                            Spacer()
                            Text("₹\(Int(catAmount))")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.red)
                        }
                        .padding(.leading, 28)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
        }
    }

    // MARK: - Shed: direct income + expense lists

    private var shedContent: some View {
        Group {
            Picker("View", selection: $selectedSegment) {
                Text("Income").tag(1)
                Text("Expenses").tag(2)
            }
            .pickerStyle(.segmented)

            switch selectedSegment {
            case 1: incomeList
            default: expenseList
            }
        }
    }

    // MARK: - Tree View

    private var treeView: some View {
        FarmTreeSection(
            viewModel: viewModel.dataStore,
            farms: viewModel.farms,
            scopeShedIds: scopeShedIds,
            farmInfo: { _, farmShedIds in
                let income = data.sales.filter { farmShedIds.contains($0.shedId) }.reduce(0.0) { $0 + $1.totalAmount }
                let expense = data.expenses.filter { farmShedIds.contains($0.shedId) }.reduce(0.0) { $0 + $1.amount }
                let profit = income - expense
                HStack(spacing: 12) {
                    Label("₹\(Int(income))", systemImage: "arrow.down.circle")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Label("₹\(Int(expense))", systemImage: "arrow.up.circle")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Label("₹\(Int(profit))", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption2)
                        .foregroundStyle(profit >= 0 ? .green : .red)
                }
            },
            shedInfo: { shed in
                let income = data.sales.filter { $0.shedId == shed.id }.reduce(0.0) { $0 + $1.totalAmount }
                let expense = data.expenses.filter { $0.shedId == shed.id }.reduce(0.0) { $0 + $1.amount }
                if income > 0 || expense > 0 {
                    Text("In: ₹\(Int(income)) · Out: ₹\(Int(expense))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            },
            batchInfo: { batch in
                let income = data.sales.filter { $0.batchId == batch.id }.reduce(0.0) { $0 + $1.totalAmount }
                let expense = data.expenses.filter { $0.batchId == batch.id }.reduce(0.0) { $0 + $1.amount }
                if income > 0 || expense > 0 {
                    Text("In: ₹\(Int(income)) · Out: ₹\(Int(expense))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        )
    }

    // MARK: - Income List

    private var incomeList: some View {
        Group {
            if data.sales.isEmpty {
                PlaceholderCard(icon: "indianrupeesign.circle", title: "No income", subtitle: "Income records will appear once sales are made.")
            } else {
                ForEach(data.sales) { sale in
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.green)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.shedName(for: sale.shedId))
                                .font(.subheadline.weight(.medium))
                            Text("\(sale.birdCount) birds · \(String(format: "%.1f", sale.totalWeightKg)) kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("₹\(Int(sale.totalAmount))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                }
            }
        }
    }

    // MARK: - Expense List

    private var expenseList: some View {
        Group {
            if data.expenses.isEmpty {
                PlaceholderCard(icon: "arrow.up.circle", title: "No expenses", subtitle: "Expense records will appear once costs are logged.")
            } else {
                ForEach(data.expenses) { expense in
                    HStack(spacing: 12) {
                        Image(systemName: categoryIcon(expense.category))
                            .foregroundStyle(categoryColor(expense.category))
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.category.capitalized)
                                .font(.subheadline.weight(.medium))
                            if let desc = expense.description {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Text("₹\(Int(expense.amount))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                }
            }
        }
    }

    // MARK: - Helpers

    private var addButton: some View {
        Button { showAddExpense = true } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.red)
                .clipShape(Circle())
                .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
        }
        .padding()
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "birds": return "bird"
        case "feed": return "leaf.fill"
        case "medicine": return "cross.case.fill"
        case "labour": return "person.2.fill"
        default: return "ellipsis.circle.fill"
        }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "birds": return .green
        case "feed": return .orange
        case "medicine": return .purple
        case "labour": return .blue
        default: return .gray
        }
    }
}
