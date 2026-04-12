//
//  BatchSalesTab.swift
//  MyPoultryFarm
//

import SwiftUI

struct BatchSalesTab: View {
    @ObservedObject var vm: BatchDetailViewModel

    var body: some View {
        VStack(spacing: 14) {
            salesHeroCard
            metricsStrip

            if vm.batchSales.isEmpty {
                emptyState(icon: "cart", message: "No sales recorded yet")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Transactions")
                        .font(.subheadline.weight(.semibold))
                    ForEach(vm.batchSales.sorted(by: { $0.saleDate > $1.saleDate })) { sale in
                        saleRow(sale)
                    }
                }
            }
        }
    }

    // MARK: - Hero Card

    private var salesHeroCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Revenue")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                    Text(vm.currencyText(vm.totalRevenue))
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
                        Text("\(vm.batchSales.count) Sales")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.15)))

                    if vm.totalWeightSold > 0 {
                        Text("₹\(Int(vm.totalRevenue / vm.totalWeightSold))/kg avg")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.55))
                    }
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
                heroStat(value: "\(vm.birdsSold)", label: "Birds Sold", icon: "bird.fill", color: .orange)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: String(format: "%.0f kg", vm.totalWeightSold), label: "Weight", icon: "scalemass.fill", color: .cyan)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: "\(vm.birdsLeft)", label: "Birds Left", icon: "bird", color: .yellow)
            }
            .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.46, blue: 0.30), Color(red: 0.12, green: 0.56, blue: 0.38)],
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
        let avgRate = vm.totalWeightSold > 0 ? vm.totalRevenue / vm.totalWeightSold : 0
        let avgWeight = vm.birdsSold > 0 ? vm.totalWeightSold / Double(vm.birdsSold) : 0
        let soldPct = vm.batch.computedTotalBirds > 0
            ? String(format: "%.0f%%", Double(vm.birdsSold) / Double(vm.batch.computedTotalBirds) * 100) : "0%"

        return HStack(spacing: 10) {
            metricPill(title: "Avg Rate", value: "₹\(Int(avgRate))/kg", color: .orange)
            metricPill(title: "Avg Weight", value: String(format: "%.1f kg", avgWeight), color: .purple)
            metricPill(title: "Sold %", value: soldPct, color: .blue)
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

    // MARK: - Sale Row

    private func saleRow(_ sale: SaleRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.left")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
                .frame(width: 32, height: 32)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(sale.birdCount) birds · \(String(format: "%.1f", sale.totalWeightKg)) kg")
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
                    Text("₹\(Int(sale.costPerKg))/kg")
                        .font(.caption2).foregroundStyle(.secondary)
                    if let buyerId = sale.buyerId {
                        Text("· \(vm.buyerName(for: buyerId))")
                            .font(.caption2).foregroundStyle(.blue).lineLimit(1)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(vm.currencyText(sale.totalAmount))
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.green)
                Text(vm.shortDate(sale.saleDate))
                    .font(.system(size: 9, weight: .medium)).foregroundStyle(.tertiary)
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

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.quaternary)
            Text(message).font(.subheadline).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
    }
}
