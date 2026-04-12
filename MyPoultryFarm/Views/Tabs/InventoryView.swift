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

    private var data: ScopeData {
        ScopeData(viewModel: viewModel.dataStore, scopeShedIds: scopeShedIds)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    ScopeBanner(label: scopeLabel, icon: scopeIcon)

                    // Summary tiles
                    summaryTiles

                    if data.isFeedLow {
                        lowStockAlert
                    }

                    // Category picker
                    Picker("Category", selection: $selectedCategory) {
                        Text("Feed").tag(0)
                        Text("Medicine").tag(1)
                    }
                    .pickerStyle(.segmented)

                    let items = selectedCategory == 0 ? data.feedItems : data.medicineItems

                    switch scopeLevel {
                    case .overview:
                        overviewContent(items: items)
                        inventoryTransactionsSection(items: items)
                    case .farm:
                        farmContent(items: items)
                        inventoryTransactionsSection(items: items)
                    case .shed:
                        shedContent(items: items)
                        inventoryTransactionsSection(items: items)
                    }
                }
                .padding()
                .padding(.bottom, 60)
            }

            addButton
        }
        .sheet(isPresented: $showAddItem) {
            AddInventoryItemView(
                viewModel: InventoryViewModel(dataStore: viewModel.dataStore),
                preselectedCategory: selectedCategory == 0 ? "feed" : "medicine"
            )
        }
    }

    // MARK: - Summary Tiles

    @ViewBuilder
    private var summaryTiles: some View {
        switch scopeLevel {
        case .overview:
            HStack(spacing: 12) {
                SummaryTile(title: "Feed", value: "\(Int(data.feedAvailable)) bags", icon: "leaf.fill", color: .orange)
                SummaryTile(title: "Feed ₹", value: "₹\(Int(data.feedCostTotal))", icon: "indianrupeesign.circle.fill", color: .red)
                SummaryTile(title: "Medicine", value: "₹\(Int(data.medicineItems.reduce(0.0) { $0 + $1.totalCost }))", icon: "cross.case.fill", color: .purple)
            }
            HStack(spacing: 12) {
                SummaryTile(title: "Stock", value: "\(Int(data.totalFeedQuantity)) bags", icon: "shippingbox.fill", color: .blue)
                SummaryTile(title: "Used", value: "\(Int(data.feedUsed)) bags", icon: "shippingbox", color: .gray)
                SummaryTile(title: "Day Rate", value: "\(String(format: "%.1f", data.feedConsumptionRatePerDay)) bags", icon: "chart.bar.fill", color: .green)
            }
        case .farm:
            HStack(spacing: 12) {
                SummaryTile(title: "Feed", value: "\(Int(data.feedAvailable)) bags", icon: "leaf.fill", color: .orange)
                SummaryTile(title: "Feed ₹", value: "₹\(Int(data.feedCostTotal))", icon: "indianrupeesign.circle.fill", color: .red)
            }
            HStack(spacing: 12) {
                SummaryTile(title: "Used", value: "\(Int(data.feedUsed)) bags", icon: "shippingbox", color: .gray)
                SummaryTile(title: "Day Rate", value: "\(String(format: "%.1f", data.feedConsumptionRatePerDay)) bags", icon: "chart.bar.fill", color: .green)
            }
        case .shed:
            HStack(spacing: 12) {
                SummaryTile(title: "Feed", value: "\(Int(data.feedAvailable)) bags", icon: "leaf.fill", color: .orange)
                SummaryTile(title: "Used", value: "\(Int(data.feedUsed)) bags", icon: "shippingbox", color: .gray)
            }
            HStack(spacing: 12) {
                SummaryTile(title: "Feed ₹", value: "₹\(Int(data.feedCostTotal))", icon: "indianrupeesign.circle.fill", color: .red)
                SummaryTile(title: "Day Rate", value: "\(String(format: "%.1f", data.feedConsumptionRatePerDay)) bags", icon: "chart.bar.fill", color: .green)
            }
        }
    }

    // MARK: - Overview: per-farm breakdown

    private func overviewContent(items: [InventoryRecord]) -> some View {
        FarmTreeSection(
            viewModel: viewModel.dataStore,
            farms: viewModel.farms,
            scopeShedIds: scopeShedIds,
            farmInfo: { _, farmShedIds in
                let farmItems = items.filter { farmShedIds.contains($0.shedId) }
                let qty = farmItems.reduce(0.0) { $0 + $1.quantity - $1.used }
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
                let qty = shedItems.reduce(0.0) { $0 + $1.quantity - $1.used }
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

    // MARK: - Farm: per-shed breakdown with item counts

    private func farmContent(items: [InventoryRecord]) -> some View {
        let sheds = viewModel.dataStore.allSheds.filter { scopeShedIds.contains($0.id!) }
        return ForEach(sheds) { shed in
            let shedItems = items.filter { $0.shedId == shed.id }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 20)
                    Text(shed.shedName)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("Cap: \(shed.capacity)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if shedItems.isEmpty {
                    Text("No items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 28)
                } else {
                    let qty = shedItems.reduce(0.0) { $0 + $1.quantity - $1.used }
                    let cost = shedItems.reduce(0.0) { $0 + $1.totalCost }
                    HStack(spacing: 12) {
                        Label("\(Int(qty)) avail", systemImage: "shippingbox.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Label("₹\(Int(cost))", systemImage: "indianrupeesign.circle")
                            .font(.caption2)
                            .foregroundStyle(.red)
                        Label("\(shedItems.count) items", systemImage: "list.bullet")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 28)

                    ForEach(shedItems) { item in
                        inventoryItemRow(item: item)
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

    // MARK: - Shed: flat item list

    private func shedContent(items: [InventoryRecord]) -> some View {
        Group {
            if items.isEmpty {
                PlaceholderCard(
                    icon: "shippingbox",
                    title: selectedCategory == 0 ? "No feed items" : "No medicine items",
                    subtitle: "Tap + to add inventory for this shed."
                )
            } else {
                ForEach(items) { item in
                    inventoryItemRow(item: item)
                }
            }
        }
    }

    // MARK: - Shared item row

    private func inventoryItemRow(item: InventoryRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.itemName)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("₹\(Int(item.totalCost))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }
            HStack(spacing: 12) {
                Label("\(Int(item.quantity)) \(item.unit)", systemImage: "shippingbox.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Label("\(Int(item.used)) used", systemImage: "shippingbox")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Label("\(Int(item.quantity - item.used)) left", systemImage: "checkmark.circle")
                    .font(.caption2)
                    .foregroundStyle(.green)
                if let feedType = item.feedType {
                    Text(feedType)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    // MARK: - Transactions List

    @ViewBuilder
    private func inventoryTransactionsSection(items: [InventoryRecord]) -> some View {
        sectionHeader("Inventory Transactions (\(items.count))")

        if items.isEmpty {
            PlaceholderCard(
                icon: "shippingbox",
                title: selectedCategory == 0 ? "No feed transactions" : "No medicine transactions",
                subtitle: "Add inventory to see transaction entries here."
            )
        } else {
            ForEach(items.sorted(by: { $0.itemName.lowercased() < $1.itemName.lowercased() })) { item in
                inventoryTransactionRow(item: item)
            }
        }
    }

    private func inventoryTransactionRow(item: InventoryRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.itemName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("₹\(Int(item.totalCost))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
            }

            HStack(spacing: 10) {
                Label(viewModel.shedName(for: item.shedId), systemImage: "building.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let batchId = item.batchId,
                   let batch = viewModel.batches.first(where: { $0.id == batchId }) {
                    Label("Batch #\(batch.batchNumber)", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Label("\(Int(item.quantity)) \(item.unit)", systemImage: "shippingbox.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Label("\(Int(item.used)) used", systemImage: "shippingbox")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Label("\(Int(item.quantity - item.used)) left", systemImage: "checkmark.circle")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
    }

    // MARK: - Helpers

    private var lowStockAlert: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text("Feed stock low — less than 3 days remaining!")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }

    private var addButton: some View {
        Button { showAddItem = true } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.orange)
                .clipShape(Circle())
                .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
        }
        .padding()
    }
}
