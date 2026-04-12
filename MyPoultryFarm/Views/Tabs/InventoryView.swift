//
//  InventoryView.swift
//  MyPoultryFarm
//

import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel: InventoryTabViewModel
    let scopeShedIds: Set<UUID>
    let scopeLabel: String
    let scopeIcon: String
    let scopeLevel: ScopeLevel

    init(dataStore: MyFarmsViewModel, scopeShedIds: Set<UUID>, scopeLabel: String, scopeIcon: String, scopeLevel: ScopeLevel) {
        _viewModel = StateObject(wrappedValue: InventoryTabViewModel(dataStore: dataStore))
        self.scopeShedIds = scopeShedIds
        self.scopeLabel = scopeLabel
        self.scopeIcon = scopeIcon
        self.scopeLevel = scopeLevel
    }

    @State private var selectedCategory = 0
    @State private var showAddItem = false
    @State private var selectedSegment = 0

    private var data: ScopeData {
        ScopeData(viewModel: viewModel.dataStore, scopeShedIds: scopeShedIds)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 14) {
                    inventoryHeroCard

                    if data.isFeedLow {
                        lowStockAlert
                    }

                    metricsStrip

                    categoryPicker
                    segmentedContent
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 80)
            }
            .background(Color(.systemGroupedBackground))

            addButton
        }
        .sheet(isPresented: $showAddItem) {
            AddInventoryItemView(
                viewModel: InventoryViewModel(dataStore: viewModel.dataStore),
                preselectedCategory: selectedCategory == 0 ? "feed" : "medicine"
            )
        }
    }

    // MARK: - Hero Inventory Card

    private var inventoryHeroCard: some View {
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
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(data.feedItems.count + data.medicineItems.count) Items")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.15)))

                    Text("₹\(formatCurrency(data.feedCostTotal)) invested")
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
                heroStat(value: "\(Int(data.totalFeedQuantity))", label: "Total Stock", icon: "cube.box.fill", color: .cyan)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: "\(Int(data.feedUsed))", label: "Used", icon: "arrow.uturn.down", color: .yellow)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: String(format: "%.1f/day", data.feedConsumptionRatePerDay), label: "Rate", icon: "chart.bar.fill", color: .mint)
            }
            .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.60, green: 0.35, blue: 0.08),
                         Color(red: 0.75, green: 0.50, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

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

    // MARK: - Metrics Strip

    private var metricsStrip: some View {
        HStack(spacing: 10) {
            metricPill(title: "Feed Cost", value: "₹\(formatCurrency(data.feedCostTotal))", color: .red)
            metricPill(title: "Medicine", value: "₹\(formatCurrency(data.medicineItems.reduce(0.0) { $0 + $1.totalCost }))", color: .purple)
            metricPill(title: "Days Left", value: daysLeftText, color: data.isFeedLow ? .red : .green)
        }
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

    private var daysLeftText: String {
        guard data.feedConsumptionRatePerDay > 0 else { return "∞" }
        let days = Int(data.feedAvailable / data.feedConsumptionRatePerDay)
        return "\(days) days"
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

    // MARK: - Segmented Content

    private var segmentedContent: some View {
        let items = selectedCategory == 0 ? data.feedItems : data.medicineItems
        return VStack(spacing: 10) {
            if scopeLevel != .shed {
                locationSegmentPicker
            }
            switch scopeLevel == .shed ? 1 : selectedSegment {
            case 0: locationView(items: items)
            default: itemsList(items: items)
            }
        }
    }

    private var locationSegmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(["By Location", "All Items"], id: \.self) { label in
                let idx = label == "By Location" ? 0 : 1
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

    // MARK: - Location View

    @ViewBuilder
    private func locationView(items: [InventoryRecord]) -> some View {
        if scopeLevel == .overview {
            overviewContent(items: items)
        } else {
            farmContent(items: items)
        }
    }

    private func overviewContent(items: [InventoryRecord]) -> some View {
        FarmTreeSection(
            viewModel: viewModel.dataStore,
            farms: viewModel.farms,
            scopeShedIds: scopeShedIds,
            farmInfo: { _, farmShedIds in
                let farmItems = items.filter { farmShedIds.contains($0.shedId) }
                let qty = availableQuantity(for: farmItems, shedIds: Set(farmShedIds))
                let cost = farmItems.reduce(0.0) { $0 + $1.totalCost }
                HStack(spacing: 12) {
                    Label("\(Int(qty)) avail", systemImage: "shippingbox.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Label("₹\(Int(cost))", systemImage: "indianrupeesign.circle")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            },
            shedInfo: { shed in
                let shedItems = items.filter { $0.shedId == shed.id }
                let qty = shed.id.map { availableQuantity(for: shedItems, shedIds: [$0]) } ?? 0
                if !shedItems.isEmpty {
                    Text("\(Int(qty)) avail · \(shedItems.count) items")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            },
            batchInfo: { batch in
                let batchItems = items.filter { $0.batchId == batch.id }
                if !batchItems.isEmpty {
                    Text("\(batchItems.count) items · ₹\(Int(batchItems.reduce(0.0) { $0 + $1.totalCost }))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        )
    }

    // MARK: - Farm Shed Cards

    private func farmContent(items: [InventoryRecord]) -> some View {
        let sheds = viewModel.dataStore.allSheds.filter { shed in
            guard let shedId = shed.id else { return false }
            return scopeShedIds.contains(shedId)
        }
        return ForEach(sheds) { shed in
            shedInventoryCard(shed: shed, items: items.filter { $0.shedId == shed.id })
        }
    }

    private func shedInventoryCard(shed: ShedRecord, items: [InventoryRecord]) -> some View {
        let qty = shed.id.map { availableQuantity(for: items, shedIds: [$0]) } ?? 0
        let cost = items.reduce(0.0) { $0 + $1.totalCost }

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
                    Text("Cap: \(shed.capacity) · \(items.count) items")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("₹\(formatCurrency(cost))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.red)
            }

            if items.isEmpty {
                Text("No items recorded")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 38)
            } else {
                HStack(spacing: 14) {
                    shedMiniStat(icon: "shippingbox.fill", text: "\(Int(qty)) avail", color: .orange)
                    shedMiniStat(icon: "list.bullet", text: "\(items.count) items", color: .blue)
                }
                .padding(.leading, 38)
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.orange.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.orange.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
    }

    private func shedMiniStat(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Items List

    private func itemsList(items: [InventoryRecord]) -> some View {
        Group {
            if items.isEmpty {
                PlaceholderCard(
                    icon: "shippingbox",
                    title: selectedCategory == 0 ? "No feed items" : "No medicine items",
                    subtitle: "Tap + to add inventory."
                )
            } else {
                ForEach(items.sorted(by: { $0.itemName.lowercased() < $1.itemName.lowercased() })) { item in
                    itemCard(item)
                }
            }
        }
    }

    private func itemCard(_ item: InventoryRecord) -> some View {
        let left = max(0, item.quantity - item.used)
        let usageRatio = item.quantity > 0 ? item.used / item.quantity : 0
        let catColor: Color = item.isFeed ? .orange : .purple

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: item.isFeed ? "leaf.fill" : "cross.case.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(catColor)
                    .frame(width: 30, height: 30)
                    .background(catColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.itemName)
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 6) {
                        Text(viewModel.shedName(for: item.shedId))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let batchId = item.batchId,
                           let batch = viewModel.batches.first(where: { $0.id == batchId }) {
                            Text("· Batch #\(batch.batchNumber)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                Text("₹\(formatCurrency(item.totalCost))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
            }

            // Usage bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule()
                        .fill(LinearGradient(colors: [catColor, catColor.opacity(0.65)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * usageRatio))
                }
            }
            .frame(height: 6)

            HStack(spacing: 14) {
                itemStat(icon: "shippingbox.fill", text: "\(Int(item.quantity)) \(item.unit)", color: .blue)
                itemStat(icon: "arrow.uturn.down", text: "\(Int(item.used)) used", color: .gray)
                itemStat(icon: "checkmark.circle.fill", text: "\(Int(left)) left", color: .green)
            }
        }
        .padding(12)
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.orange.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.orange.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }

    private func itemStat(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func availableQuantity(for items: [InventoryRecord], shedIds: Set<UUID>) -> Double {
        if selectedCategory == 0 {
            return data.feedAvailable(in: shedIds)
        }
        return items.reduce(0.0) { $0 + max(0, $1.quantity - $1.used) }
    }

    private var lowStockAlert: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color.red, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text("Low Stock Warning")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
                Text("Feed stock is below 3 days of consumption")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.red.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var addButton: some View {
        Button { showAddItem = true } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(colors: [.orange, .orange.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .shadow(color: .orange.opacity(0.45), radius: 10, y: 5)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 28)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: abs(value))) ?? "\(Int(abs(value)))"
    }
}
