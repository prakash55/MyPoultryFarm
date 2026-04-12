//
//  BatchDashboardTab.swift
//  MyPoultryFarm
//

import SwiftUI

struct BatchDashboardTab: View {
    @ObservedObject var vm: BatchDetailViewModel

    var body: some View {
        VStack(spacing: 14) {
            combinedHeader
            financialHeroCard
            expenseBreakdownCard
            inventoryOverviewCard
        }
    }

    // MARK: - Combined Header + Birds

    private var combinedHeader: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: vm.currentBatch.isRunning
                        ? [Color.green.opacity(0.85), Color.green.opacity(0.45)]
                        : [Color.gray.opacity(0.6), Color.gray.opacity(0.3)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 100)
                .overlay(alignment: .topTrailing) {
                    Text(vm.currentBatch.isRunning ? "RUNNING" : "CLOSED")
                        .font(.caption.weight(.black))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(12)
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.shedName(for: vm.batch.shedId))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        Text(vm.batch.displayTitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Day \(vm.dayCount)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text(vm.formattedDate(vm.batch.startDate))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(16)
            }

            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(Color(.systemGray5), lineWidth: 7).frame(width: 56, height: 56)
                    Circle().trim(from: 0, to: vm.soldPercent)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .frame(width: 56, height: 56).rotationEffect(.degrees(-90))
                    Circle().trim(from: vm.soldPercent, to: min(1.0, vm.soldPercent + vm.mortalityPercent))
                        .stroke(Color.red.opacity(0.7), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .frame(width: 56, height: 56).rotationEffect(.degrees(-90))
                    Text("\(vm.birdsLeft)").font(.caption.weight(.bold)).foregroundStyle(.purple)
                }

                VStack(spacing: 6) {
                    HStack(spacing: 0) {
                        statPill(value: "\(vm.batch.computedTotalBirds)", label: "Total", color: .blue)
                        statPill(value: "\(vm.batch.purchasedBirds)", label: "Bought", color: .primary)
                    }
                    HStack(spacing: 0) {
                        statPill(value: "\(vm.birdsSold)", label: "Sold", color: .orange)
                        statPill(value: "\(vm.totalMortality)", label: "Died", color: .red)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(14)
            .background(Color(.systemBackground))

            if let notes = vm.batch.notes, !notes.isEmpty {
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
            RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.7)).frame(width: 3, height: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.subheadline.weight(.bold))
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Inventory Overview Card

    private var inventoryOverviewCard: some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return VStack(alignment: .leading, spacing: 12) {
            Label("Feed & Inventory", systemImage: "leaf.fill")
                .font(.headline.weight(.semibold)).foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.53))
            LazyVGrid(columns: columns, spacing: 10) {
                inventoryMetricCard(icon: "shippingbox.fill", iconTint: Color(red: 1.0, green: 0.63, blue: 0.22), title: "Stock",
                    primary: vm.quantityText(vm.totalFeedStock, unit: vm.feedInventoryUnit), secondary: vm.currencyText(vm.totalFeedInventoryCost), secondaryTint: .secondary, badge: nil, badgeTint: nil)
                inventoryMetricCard(icon: "leaf.fill", iconTint: Color(red: 0.31, green: 0.82, blue: 0.53), title: "Available",
                    primary: vm.quantityText(vm.totalFeedAvailable, unit: vm.feedInventoryUnit),
                    secondary: vm.totalFeedAvailable > 0 ? "Ready for use" : "Reorder feed to continue logs", secondaryTint: .secondary, badge: vm.inventoryStatusText, badgeTint: vm.inventoryStatusColor)
                inventoryMetricCard(icon: "cube.fill", iconTint: Color(red: 0.60, green: 0.62, blue: 0.70), title: "Used",
                    primary: vm.quantityText(vm.totalFeedUsed, unit: vm.feedInventoryUnit),
                    secondary: "Feed Cost: \(vm.currencyText(vm.feedExpenseAmount))", secondaryTint: .secondary, badge: nil, badgeTint: nil)
                inventoryMetricCard(icon: "chart.bar.fill", iconTint: Color(red: 0.23, green: 0.59, blue: 0.96), title: "Day Rate",
                    primary: vm.currencyText(vm.averageDailyFeedCost),
                    secondary: "Medicine: \(vm.currencyText(vm.medicineExpenseAmount))", secondaryTint: .secondary, badge: nil, badgeTint: nil)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Color(.systemBackground), Color.green.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.72), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    private func inventoryMetricCard(icon: String, iconTint: Color, title: String, primary: String, secondary: String, secondaryTint: Color, badge: String?, badgeTint: Color?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(iconTint.opacity(0.14)).frame(width: 30, height: 30)
                    .overlay { Image(systemName: icon).font(.caption.weight(.semibold)).foregroundStyle(iconTint) }
                Text(title).font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
                if let badge, let badgeTint {
                    HStack(spacing: 5) {
                        Circle().fill(badgeTint).frame(width: 6, height: 6)
                        Text(badge).font(.caption2.weight(.semibold))
                    }.foregroundStyle(badgeTint)
                }
            }
            Text(primary).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            Text(secondary).font(.caption).foregroundStyle(secondaryTint).lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading).padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LinearGradient(colors: [Color.white.opacity(0.95), Color(.systemGray6).opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)))
    }
}
