//
//  BatchInventoryTab.swift
//  MyPoultryFarm
//

import SwiftUI

struct BatchInventoryTab: View {
    @ObservedObject var vm: BatchDetailViewModel
    @State private var selectedCategory = 0

    var body: some View {
        VStack(spacing: 14) {
            inventoryHeroCard
            metricsStrip
            categoryPicker

            let items = selectedCategory == 0
                ? vm.batchInventory.filter { $0.isFeed }
                : vm.batchInventory.filter { $0.isMedicine }

            if items.isEmpty {
                emptyState(icon: "shippingbox", message: selectedCategory == 0 ? "No feed items" : "No medicine items")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Items")
                        .font(.subheadline.weight(.semibold))
                    ForEach(items) { item in
                        itemRow(item)
                    }
                }
            }
        }
    }

    // MARK: - Hero Card

    private var inventoryHeroCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Feed Available")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                    Text(vm.quantityText(vm.totalFeedAvailable, unit: vm.feedInventoryUnit))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(vm.batchInventory.count) Items")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.15)))

                    Text("\(vm.currencyText(vm.totalFeedInventoryCost)) invested")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 16)

            HStack(spacing: 0) {
                heroStat(value: vm.quantityText(vm.totalFeedStock, unit: vm.feedInventoryUnit), label: "Total Stock", icon: "cube.box.fill", color: .cyan)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: vm.quantityText(vm.totalFeedUsed, unit: vm.feedInventoryUnit), label: "Used", icon: "arrow.uturn.down", color: .yellow)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: vm.inventoryStatusText, label: "Status", icon: vm.totalFeedAvailable > 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill", color: vm.totalFeedAvailable > 0 ? .mint : .red)
            }
            .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.60, green: 0.35, blue: 0.08), Color(red: 0.75, green: 0.50, blue: 0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func heroStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundStyle(color)
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Metrics Strip

    private var metricsStrip: some View {
        let medCost = vm.batchInventory.filter { $0.isMedicine }.reduce(0.0) { $0 + $1.totalCost }
        return HStack(spacing: 10) {
            metricPill(title: "Feed Cost", value: vm.currencyText(vm.totalFeedInventoryCost), color: .red)
            metricPill(title: "Medicine", value: vm.currencyText(medCost), color: .purple)
            metricPill(title: "Day Rate", value: vm.currencyText(vm.averageDailyFeedCost), color: .blue)
        }
    }

    private func metricPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.caption.weight(.bold)).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.7)
            Text(title).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(color.opacity(0.15), lineWidth: 1))
        )
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        HStack(spacing: 0) {
            ForEach(["Feed", "Medicine"], id: \.self) { label in
                let idx = label == "Feed" ? 0 : 1
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = idx }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: idx == 0 ? "leaf.fill" : "cross.case.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(label)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(selectedCategory == idx ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedCategory == idx ?
                        Capsule().fill(Color.orange) :
                        Capsule().fill(Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Color(.systemGray6)))
    }

    // MARK: - Item Row

    private func itemRow(_ item: InventoryRecord) -> some View {
        let color: Color = item.isFeed ? .orange : .purple
        return HStack(spacing: 12) {
            Image(systemName: item.isFeed ? "leaf.fill" : "cross.case.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.itemName)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
                    Text("\(Int(item.quantity)) \(item.unit)").font(.caption2).foregroundStyle(.secondary)
                    if let ft = item.feedType {
                        Text("· \(ft.capitalized)").font(.caption2).foregroundStyle(.orange)
                    }
                    if item.used > 0 {
                        Text("· \(Int(item.quantity - item.used)) left").font(.caption2).foregroundStyle(.purple)
                    }
                }
            }
            Spacer()
            Text(vm.currencyText(item.totalCost))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(12)
        .background(
            LinearGradient(colors: [Color(.systemBackground), color.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.quaternary)
            Text(message).font(.subheadline).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
    }
}
