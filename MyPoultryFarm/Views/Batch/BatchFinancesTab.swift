//
//  BatchFinancesTab.swift
//  MyPoultryFarm
//

import SwiftUI

struct BatchFinancesTab: View {
    @ObservedObject var vm: BatchDetailViewModel

    var body: some View {
        VStack(spacing: 14) {
            financialHeroCard
            expenseBreakdownCard

            if vm.batchExpenses.isEmpty {
                emptyState(icon: "arrow.up.circle", message: "No expenses recorded")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Transactions").font(.subheadline.weight(.semibold))
                    ForEach(vm.batchExpenses.sorted(by: { $0.expenseDate > $1.expenseDate })) { expense in
                        expenseRow(expense)
                    }
                }
            }
        }
    }

    // MARK: - Financial Hero Card

    private var financialHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Profit").font(.headline.weight(.semibold)).foregroundStyle(.primary)
                    HStack(alignment: .center, spacing: 6) {
                        Text(vm.currencyText(vm.profit))
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(vm.profit >= 0 ? Color(red: 0.18, green: 0.67, blue: 0.35) : Color(red: 1.0, green: 0.33, blue: 0.31))
                        Image(systemName: vm.profit >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(vm.profit >= 0 ? Color(red: 0.18, green: 0.67, blue: 0.35) : Color(red: 1.0, green: 0.33, blue: 0.31))
                    }
                    Text(vm.profit >= 0 ? "Income is ahead of expenses" : "Expenses are ahead of income")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                ProfitSparklineCard(values: vm.profitTrendValues, color: vm.profit >= 0 ? Color(red: 0.18, green: 0.67, blue: 0.35) : Color(red: 1.0, green: 0.33, blue: 0.31))
                    .frame(width: 128, height: 72)
            }
            HStack(spacing: 12) {
                financialMetricCell(title: "Income", value: vm.currencyText(vm.totalRevenue), accent: Color(red: 0.31, green: 0.82, blue: 0.53), icon: "arrow.up")
                financialMetricCell(title: "Expenses", value: vm.currencyText(vm.totalExpenseAmount), accent: Color(red: 1.0, green: 0.43, blue: 0.43), icon: "arrow.up")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Color(.systemBackground), (vm.profit >= 0 ? Color.green : Color.red).opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.7), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
    }

    private func financialMetricCell(title: String, value: String, accent: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text(value).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.primary)
                Image(systemName: icon).font(.caption2.weight(.bold)).foregroundStyle(accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 2)
    }

    // MARK: - Expense Breakdown Card

    private var expenseBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expenses Breakdown").font(.headline.weight(.semibold))
            ForEach(vm.expenseBreakdownItems) { item in
                expenseBreakdownRow(item)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Color(.systemBackground), Color.red.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.72), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    private func expenseBreakdownRow(_ item: ExpenseBreakdownItem) -> some View {
        let ratio = vm.totalExpenseAmount > 0 ? item.amount / vm.totalExpenseAmount : 0
        return HStack(spacing: 10) {
            Image(systemName: item.icon).font(.caption.weight(.bold)).foregroundStyle(item.color).frame(width: 20)
            Text(item.title).font(.subheadline.weight(.medium)).frame(width: 92, alignment: .leading)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray6))
                    Capsule().fill(LinearGradient(colors: [item.color, item.color.opacity(0.72)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(18, geometry.size.width * ratio))
                }
            }
            .frame(height: 8)
            Text(vm.currencyText(item.amount)).font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(item.amount > 0 ? .primary : .secondary).frame(width: 76, alignment: .trailing)
        }
    }

    // MARK: - Expense Row

    private func expenseRow(_ expense: ExpenseRecord) -> some View {
        HStack(spacing: 10) {
            Image(systemName: vm.expenseIcon(expense.category))
                .font(.caption).foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(vm.expenseColor(expense.category))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category.capitalized).font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
                    Text(vm.shortDate(expense.expenseDate)).font(.caption).foregroundStyle(.secondary)
                    if let desc = expense.description, !desc.isEmpty {
                        Text("· \(desc)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            }
            Spacer()
            Text("₹\(Int(expense.amount))").font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(.systemBackground), vm.expenseColor(expense.category).opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(vm.expenseColor(expense.category).opacity(0.12), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.quaternary)
            Text(message).font(.subheadline).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
    }
}
