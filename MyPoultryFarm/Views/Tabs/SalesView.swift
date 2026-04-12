//
//  SalesView.swift
//  MyPoultryFarm
//

import SwiftUI

struct SalesView: View {
    @StateObject private var viewModel: SalesTabViewModel
    let scopeShedIds: Set<UUID>
    let scopeLabel: String
    let scopeIcon: String
    let scopeLevel: ScopeLevel

    init(dataStore: MyFarmsViewModel, scopeShedIds: Set<UUID>, scopeLabel: String, scopeIcon: String, scopeLevel: ScopeLevel) {
        _viewModel = StateObject(wrappedValue: SalesTabViewModel(dataStore: dataStore))
        self.scopeShedIds = scopeShedIds
        self.scopeLabel = scopeLabel
        self.scopeIcon = scopeIcon
        self.scopeLevel = scopeLevel
    }

    @State private var showAddSale = false

    private var data: ScopeData {
        ScopeData(viewModel: viewModel.dataStore, scopeShedIds: scopeShedIds)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    ScopeBanner(label: scopeLabel, icon: scopeIcon)

                    summaryTiles

                    switch scopeLevel {
                    case .overview:
                        overviewContent
                        salesTransactionsSection(sales: data.sales)
                    case .farm:
                        farmContent
                        salesTransactionsSection(sales: data.sales)
                    case .shed:
                        shedContent
                        salesTransactionsSection(sales: data.sales)
                    }
                }
                .padding()
                .padding(.bottom, 60)
            }

            addButton
        }
        .sheet(isPresented: $showAddSale) {
            AddSaleView(viewModel: SalesViewModel(dataStore: viewModel.dataStore))
        }
    }

    // MARK: - Summary Tiles

    @ViewBuilder
    private var summaryTiles: some View {
        switch scopeLevel {
        case .overview:
            HStack(spacing: 12) {
                SummaryTile(title: "Revenue", value: "₹\(Int(data.totalSalesAmount))", icon: "indianrupeesign.circle.fill", color: .green)
                SummaryTile(title: "Sold", value: "\(data.totalBirdsSold)", icon: "chicken_icon", color: .blue)
                SummaryTile(title: "Avg/kg", value: "₹\(Int(data.avgRatePerKg))/kg", icon: "tag.fill", color: .orange)
            }
            HStack(spacing: 12) {
                SummaryTile(title: "Weight", value: "\(String(format: "%.1f", data.totalWeightSold)) kg", icon: "scalemass.fill", color: .purple)
                SummaryTile(title: "Txns", value: "\(data.sales.count)", icon: "list.bullet", color: .gray)
                SummaryTile(title: "Left", value: "\(data.birdsLeft)", icon: "bird", color: .purple)
            }
        case .farm:
            HStack(spacing: 12) {
                SummaryTile(title: "Revenue", value: "₹\(Int(data.totalSalesAmount))", icon: "indianrupeesign.circle.fill", color: .green)
                SummaryTile(title: "Sold", value: "\(data.totalBirdsSold)", icon: "chicken_icon", color: .blue)
            }
            HStack(spacing: 12) {
                SummaryTile(title: "Avg/kg", value: "₹\(Int(data.avgRatePerKg))/kg", icon: "tag.fill", color: .orange)
                SummaryTile(title: "Left", value: "\(data.birdsLeft)", icon: "bird", color: .purple)
            }
        case .shed:
            HStack(spacing: 12) {
                SummaryTile(title: "Revenue", value: "₹\(Int(data.totalSalesAmount))", icon: "indianrupeesign.circle.fill", color: .green)
                SummaryTile(title: "Sold", value: "\(data.totalBirdsSold)", icon: "chicken_icon", color: .blue)
            }
            HStack(spacing: 12) {
                SummaryTile(title: "Avg/kg", value: "₹\(Int(data.avgRatePerKg))/kg", icon: "tag.fill", color: .orange)
                SummaryTile(title: "Weight", value: "\(String(format: "%.1f", data.totalWeightSold)) kg", icon: "scalemass.fill", color: .purple)
            }
        }
    }

    // MARK: - Overview: farm tree with aggregates

    private var overviewContent: some View {
        Group {
            sectionHeader("Sales by Location")

            FarmTreeSection(
                viewModel: viewModel.dataStore,
                farms: viewModel.farms,
                scopeShedIds: scopeShedIds,
                farmInfo: { _, farmShedIds in
                    let farmSales = data.sales.filter { farmShedIds.contains($0.shedId) }
                    let revenue = farmSales.reduce(0.0) { $0 + $1.totalAmount }
                    let birds = farmSales.reduce(0) { $0 + $1.birdCount }
                    HStack(spacing: 12) {
                        Label("₹\(Int(revenue))", systemImage: "indianrupeesign.circle")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        HStack(spacing: 4) {
                            Image("chicken_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 11, height: 11)
                            Text("\(birds) birds")
                        }
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    }
                },
                shedInfo: { shed in
                    let shedSales = data.sales.filter { $0.shedId == shed.id }
                    if !shedSales.isEmpty {
                        let revenue = shedSales.reduce(0.0) { $0 + $1.totalAmount }
                        Text("₹\(Int(revenue)) · \(shedSales.count) sales")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                },
                batchInfo: { batch in
                    let batchSales = data.sales.filter { $0.batchId == batch.id }
                    if !batchSales.isEmpty {
                        let revenue = batchSales.reduce(0.0) { $0 + $1.totalAmount }
                        let birds = batchSales.reduce(0) { $0 + $1.birdCount }
                        Text("\(birds) birds · ₹\(Int(revenue))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            )
        }
    }

    // MARK: - Farm: per-shed breakdown with sale cards

    private var farmContent: some View {
        let sheds = viewModel.dataStore.allSheds.filter { scopeShedIds.contains($0.id!) }
        return ForEach(sheds) { shed in
            let shedSales = data.sales.filter { $0.shedId == shed.id }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 20)
                    Text(shed.shedName)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if !shedSales.isEmpty {
                        let revenue = shedSales.reduce(0.0) { $0 + $1.totalAmount }
                        Text("₹\(Int(revenue))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }

                if shedSales.isEmpty {
                    Text("No sales")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 28)
                } else {
                    let birds = shedSales.reduce(0) { $0 + $1.birdCount }
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image("chicken_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 11, height: 11)
                            Text("\(birds) birds")
                        }
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        Label("\(shedSales.count) sales", systemImage: "list.bullet")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 28)

                    ForEach(shedSales.prefix(5)) { sale in
                        saleCard(sale: sale)
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

    // MARK: - Shed: flat sales list

    private var shedContent: some View {
        Group {
            if data.sales.isEmpty {
                PlaceholderCard(
                    icon: "cart",
                    title: "No sales yet",
                    subtitle: "Tap + to record a sale for this shed."
                )
            }
        }
    }

    // MARK: - Transactions List

    @ViewBuilder
    private func salesTransactionsSection(sales: [SaleRecord]) -> some View {
        sectionHeader("Sale Transactions (\(sales.count))")

        if sales.isEmpty {
            PlaceholderCard(
                icon: "cart",
                title: "No sale transactions",
                subtitle: "Record a sale to see transaction entries here."
            )
        } else {
            ForEach(sales.sorted(by: { $0.saleDate > $1.saleDate })) { sale in
                saleCard(sale: sale)
            }
        }
    }

    // MARK: - Shared

    private func saleCard(sale: SaleRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "cart.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.shedName(for: sale.shedId))
                    .font(.subheadline.weight(.medium))
                Text("\(sale.birdCount) birds · \(String(format: "%.1f", sale.totalWeightKg)) kg @ ₹\(Int(sale.costPerKg))/kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if sale.buyerId != nil {
                    Text(viewModel.buyerName(for: sale.buyerId))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
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

    private var addButton: some View {
        Button { showAddSale = true } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.green)
                .clipShape(Circle())
                .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
        }
        .padding()
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
}
