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
    @State private var selectedSegment = 0

    private var data: ScopeData {
        ScopeData(viewModel: viewModel.dataStore, scopeShedIds: scopeShedIds)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 14) {
                    salesHeroCard
                    metricsStrip
                    segmentedContent
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 80)
            }
            .background(Color(.systemGroupedBackground))

            addButton
        }
        .sheet(isPresented: $showAddSale) {
            AddSaleView(viewModel: SalesViewModel(dataStore: viewModel.dataStore))
        }
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
                VStack(alignment: .trailing, spacing: 6) {
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

                    Text("₹\(Int(data.avgRatePerKg))/kg avg")
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
                heroStat(value: "\(data.totalBirdsSold)", label: "Birds Sold", icon: "bird.fill", color: .orange)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: String(format: "%.0f kg", data.totalWeightSold), label: "Weight", icon: "scalemass.fill", color: .cyan)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: "\(data.birdsLeft)", label: "Birds Left", icon: "bird", color: .yellow)
            }
            .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.46, blue: 0.30),
                         Color(red: 0.12, green: 0.56, blue: 0.38)],
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
            metricPill(title: "Avg Rate", value: "₹\(Int(data.avgRatePerKg))/kg", color: .orange)
            metricPill(title: "Avg Weight", value: avgWeightPerBird, color: .purple)
            metricPill(title: "Sold %", value: soldPercentText, color: .blue)
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

    private var avgWeightPerBird: String {
        guard data.totalBirdsSold > 0 else { return "0 kg" }
        return String(format: "%.1f kg", data.totalWeightSold / Double(data.totalBirdsSold))
    }

    private var soldPercentText: String {
        guard data.totalBirds > 0 else { return "0%" }
        let pct = Double(data.totalBirdsSold) / Double(data.totalBirds) * 100
        return String(format: "%.0f%%", pct)
    }

    // MARK: - Segmented Content

    private var segmentedContent: some View {
        VStack(spacing: 10) {
            segmentPicker
            switch selectedSegment {
            case 0: locationContent
            default: transactionsList
            }
        }
    }

    private var segmentPicker: some View {
        let labels = scopeLevel == .shed ? ["Transactions"] : ["By Location", "Transactions"]
        return HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { idx, label in
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

    // MARK: - Location Content

    @ViewBuilder
    private var locationContent: some View {
        if scopeLevel == .shed {
            transactionsList
        } else if scopeLevel == .overview {
            overviewTreeView
        } else {
            farmShedCards
        }
    }

    private var overviewTreeView: some View {
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
                            .renderingMode(.template)
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

    // MARK: - Farm Shed Cards

    private var farmShedCards: some View {
        let sheds = viewModel.dataStore.allSheds.filter { shed in
            guard let shedId = shed.id else { return false }
            return scopeShedIds.contains(shedId)
        }
        return ForEach(sheds) { shed in
            shedSalesCard(shed: shed)
        }
    }

    private func shedSalesCard(shed: ShedRecord) -> some View {
        let shedSales = data.sales.filter { $0.shedId == shed.id }
        let revenue = shedSales.reduce(0.0) { $0 + $1.totalAmount }
        let birds = shedSales.reduce(0) { $0 + $1.birdCount }
        let weight = shedSales.reduce(0.0) { $0 + $1.totalWeightKg }

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
                    Text("\(shedSales.count) sales")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(formatCurrency(revenue))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.green)
            }

            if !shedSales.isEmpty {
                HStack(spacing: 14) {
                    shedMiniStat(icon: "bird.fill", text: "\(birds) birds", color: .blue)
                    shedMiniStat(icon: "scalemass.fill", text: String(format: "%.0f kg", weight), color: .purple)
                }
                .padding(.leading, 38)
            } else {
                Text("No sales recorded")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 38)
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.green.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.green.opacity(0.14), lineWidth: 1))
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

    // MARK: - Transactions List

    private var transactionsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            if data.sales.isEmpty {
                PlaceholderCard(
                    icon: "cart",
                    title: "No sales yet",
                    subtitle: "Tap + to record a sale."
                )
            } else {
                ForEach(data.sales.sorted(by: { $0.saleDate > $1.saleDate })) { sale in
                    saleTransactionRow(sale)
                }
            }
        }
    }

    private func saleTransactionRow(_ sale: SaleRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "cart.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
                .frame(width: 32, height: 32)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.shedName(for: sale.shedId))
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text("\(sale.birdCount) birds")
                    Text("·")
                    Text("\(String(format: "%.0f", sale.totalWeightKg)) kg")
                    Text("·")
                    Text("₹\(Int(sale.costPerKg))/kg")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(formatCurrency(sale.totalAmount))
                    .font(.subheadline.weight(.bold))
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

    // MARK: - Helpers

    private var addButton: some View {
        Button { showAddSale = true } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(colors: [.green, .green.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .shadow(color: .green.opacity(0.45), radius: 10, y: 5)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 28)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: abs(value))) ?? "\(Int(abs(value)))"
        return value < 0 ? "-₹\(formatted)" : "₹\(formatted)"
    }
}
