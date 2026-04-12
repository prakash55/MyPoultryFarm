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
                VStack(spacing: 14) {
                    financialHeroCard
                    expenseBreakdownCard
                    segmentedTransactions
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 80)
            }
            .background(Color(.systemGroupedBackground))

            addButton
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(viewModel: ExpenseViewModel(dataStore: viewModel.dataStore))
        }
    }

    // MARK: - Financial Hero Card

    private var financialHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Net Profit")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .center, spacing: 6) {
                        Text(formatCurrencyFull(data.profit))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(data.profit >= 0 ? Color(red: 0.18, green: 0.67, blue: 0.35) : Color(red: 1.0, green: 0.33, blue: 0.31))
                        Image(systemName: data.profit >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(data.profit >= 0 ? Color(red: 0.18, green: 0.67, blue: 0.35) : Color(red: 1.0, green: 0.33, blue: 0.31))
                    }
                    Text("\(data.sales.count + data.expenses.count) transactions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                // Profit indicator ring
                profitRing
            }

            HStack(spacing: 12) {
                financialMetricCell(
                    title: "Income",
                    value: formatCurrencyFull(data.totalSalesAmount),
                    accent: Color(red: 0.31, green: 0.82, blue: 0.53),
                    icon: "arrow.down.left"
                )
                financialMetricCell(
                    title: "Expenses",
                    value: formatCurrencyFull(data.totalExpensesAmount),
                    accent: Color(red: 1.0, green: 0.43, blue: 0.43),
                    icon: "arrow.up.right"
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            (data.profit >= 0 ? Color.green : Color.red).opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
    }

    private var profitRing: some View {
        let total = max(data.totalSalesAmount + data.totalExpensesAmount, 1)
        let incomeRatio = data.totalSalesAmount / total
        return ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 6)
                .frame(width: 56, height: 56)
            Circle()
                .trim(from: 0, to: incomeRatio)
                .stroke(Color(red: 0.31, green: 0.82, blue: 0.53), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: incomeRatio, to: 1.0)
                .stroke(Color(red: 1.0, green: 0.43, blue: 0.43).opacity(0.7), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(-90))
            Text("\(Int(incomeRatio * 100))%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }

    private func financialMetricCell(title: String, value: String, accent: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
    }

    // MARK: - Expense Breakdown (matching BatchDetailView)

    private var expenseBreakdownCard: some View {
        let categories: [(String, String, String, Color)] = [
            ("birds", "Bird Purchase", "bird.fill", Color(red: 0.31, green: 0.82, blue: 0.53)),
            ("feed", "Feed", "leaf.fill", Color(red: 1.0, green: 0.73, blue: 0.28)),
            ("medicine", "Medicine", "cross.case.fill", Color(red: 0.67, green: 0.27, blue: 0.94)),
            ("labour", "Labour", "person.2.fill", Color(red: 0.23, green: 0.59, blue: 0.96)),
            ("other", "Other", "ellipsis.circle.fill", Color(red: 0.63, green: 0.64, blue: 0.70))
        ]
        return VStack(alignment: .leading, spacing: 12) {
            Text("Expenses Breakdown")
                .font(.subheadline.weight(.semibold))

            ForEach(categories, id: \.0) { cat in
                let amount = data.expensesFor(category: cat.0)
                expenseBarRow(title: cat.1, icon: cat.2, color: cat.3, amount: amount)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color.red.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    private func expenseBarRow(title: String, icon: String, color: Color, amount: Double) -> some View {
        let total = max(data.totalExpensesAmount, 1)
        let ratio = amount / total

        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 20)

            Text(title)
                .font(.caption.weight(.medium))
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray6))
                    Capsule()
                        .fill(LinearGradient(colors: [color, color.opacity(0.72)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * ratio))
                }
            }
            .frame(height: 8)

            Text(formatCurrencyFull(amount))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(amount > 0 ? .primary : .secondary)
                .frame(minWidth: 50, alignment: .trailing)
        }
    }

    // MARK: - Segmented Transactions

    private var segmentedTransactions: some View {
        VStack(spacing: 10) {
            transactionPicker

            switch selectedSegment {
            case 0:
                if scopeLevel == .overview { treeView } else { farmContent }
            case 1: incomeList
            default: expenseList
            }
        }
    }

    private var transactionPicker: some View {
        HStack(spacing: 0) {
            ForEach(Array(segmentLabels.enumerated()), id: \.offset) { idx, label in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedSegment = idx }
                } label: {
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedSegment == idx ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedSegment == idx ?
                            Capsule().fill(Color.green) :
                            Capsule().fill(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Color(.systemGray6)))
    }

    private var segmentLabels: [String] {
        switch scopeLevel {
        case .overview: return ["By Location", "Income", "Expenses"]
        case .farm: return ["By Shed", "Income", "Expenses"]
        case .shed: return ["Income", "Expenses"]
        }
    }

    // MARK: - Farm Shed Cards

    private var farmContent: some View {
        let sheds = viewModel.dataStore.allSheds.filter { shed in
            guard let shedId = shed.id else { return false }
            return scopeShedIds.contains(shedId)
        }
        return ForEach(sheds) { shed in
            shedFinanceCard(shed: shed)
        }
    }

    private func shedFinanceCard(shed: ShedRecord) -> some View {
        let shedSales = data.sales.filter { $0.shedId == shed.id }
        let shedExpenses = data.expenses.filter { $0.shedId == shed.id }
        let income = shedSales.reduce(0.0) { $0 + $1.totalAmount }
        let expense = shedExpenses.reduce(0.0) { $0 + $1.amount }
        let profit = income - expense

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "building.2.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(shed.shedName)
                        .font(.subheadline.weight(.semibold))
                    Text("\(shedSales.count + shedExpenses.count) transactions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(formatCurrencyFull(profit))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(profit >= 0 ? .green : .red)
            }

            HStack(spacing: 14) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.left")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.green)
                    Text("In: \(formatCurrencyFull(income))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.red)
                    Text("Out: \(formatCurrencyFull(expense))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 38)

            let categories = Dictionary(grouping: shedExpenses, by: { $0.category })
            if !categories.isEmpty {
                Divider()
                ForEach(categories.keys.sorted(), id: \.self) { cat in
                    let catAmt = categories[cat]!.reduce(0.0) { $0 + $1.amount }
                    HStack(spacing: 6) {
                        Circle()
                            .fill(categoryColor(cat))
                            .frame(width: 6, height: 6)
                        Text(cat.capitalized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatCurrencyFull(catAmt))
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.leading, 38)
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.red.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.red.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
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
                    incomeRow(sale)
                }
            }
        }
    }

    private func incomeRow(_ sale: SaleRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.left")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
                .frame(width: 32, height: 32)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.shedName(for: sale.shedId))
                    .font(.subheadline.weight(.medium))
                Text("\(sale.birdCount) birds · \(String(format: "%.0f", sale.totalWeightKg)) kg")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrencyFull(sale.totalAmount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                Text(sale.saleDate)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.green.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.green.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }

    // MARK: - Expense List

    private var expenseList: some View {
        Group {
            if data.expenses.isEmpty {
                PlaceholderCard(icon: "arrow.up.circle", title: "No expenses", subtitle: "Expense records will appear once costs are logged.")
            } else {
                ForEach(data.expenses) { expense in
                    expenseRowCard(expense)
                }
            }
        }
    }

    private func expenseRowCard(_ expense: ExpenseRecord) -> some View {
        let color = categoryColor(expense.category)
        return HStack(spacing: 12) {
            Image(systemName: categoryIcon(expense.category))
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category.capitalized)
                    .font(.subheadline.weight(.medium))
                if let desc = expense.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrencyFull(expense.amount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                Text(expense.expenseDate)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.red.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.red.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }

    // MARK: - Helpers

    private var addButton: some View {
        Button { showAddExpense = true } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(colors: [.red, .red.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .shadow(color: .red.opacity(0.45), radius: 10, y: 5)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 28)
    }

    private func formatCurrencyFull(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: abs(value))) ?? "\(Int(abs(value)))"
        return value < 0 ? "-₹\(formatted)" : "₹\(formatted)"
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "birds": return "bird.fill"
        case "feed": return "leaf.fill"
        case "medicine": return "cross.case.fill"
        case "labour": return "person.2.fill"
        default: return "ellipsis.circle.fill"
        }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "birds": return Color(red: 0.31, green: 0.82, blue: 0.53)
        case "feed": return Color(red: 1.0, green: 0.73, blue: 0.28)
        case "medicine": return Color(red: 0.67, green: 0.27, blue: 0.94)
        case "labour": return Color(red: 0.23, green: 0.59, blue: 0.96)
        default: return Color(red: 0.63, green: 0.64, blue: 0.70)
        }
    }
}

