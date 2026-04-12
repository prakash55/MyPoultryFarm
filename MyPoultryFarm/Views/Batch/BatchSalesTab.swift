//
//  BatchSalesTab.swift
//  MyPoultryFarm
//

import SwiftUI

struct BatchSalesTab: View {
    @ObservedObject var vm: BatchDetailViewModel

    var body: some View {
        VStack(spacing: 12) {
            if !vm.batchSales.isEmpty {
                HStack(spacing: 0) {
                    miniStat(icon: "bird.fill", value: "\(vm.birdsSold)", label: "Birds", color: .orange)
                    miniDivider
                    miniStat(icon: "scalemass.fill", value: "\(String(format: "%.0f", vm.totalWeightSold)) kg", label: "Weight", color: .blue)
                    miniDivider
                    miniStat(icon: "indianrupeesign.circle.fill", value: "₹\(Int(vm.totalRevenue))", label: "Revenue", color: .green)
                    if vm.totalWeightSold > 0 {
                        miniDivider
                        let avgRate = vm.totalRevenue / vm.totalWeightSold
                        miniStat(icon: "chart.line.uptrend.xyaxis", value: "₹\(Int(avgRate))", label: "Avg/kg", color: .teal)
                    }
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [Color(.systemBackground), Color.green.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.14), lineWidth: 1))
                )
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }

            if vm.batchSales.isEmpty {
                emptyState(icon: "cart", message: "No sales recorded yet")
            } else {
                ForEach(vm.batchSales) { sale in
                    saleRow(sale)
                }
            }
        }
    }

    // MARK: - Helpers

    private var miniDivider: some View { Divider().frame(height: 24) }

    private func miniStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.caption2).foregroundStyle(color)
                Text(value).font(.subheadline.weight(.bold)).foregroundStyle(color)
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func saleRow(_ sale: SaleRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(vm.shortDate(sale.saleDate))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.green.opacity(0.1)).foregroundStyle(.green)
                    .clipShape(Capsule())
                Spacer()
                Text("₹\(Int(sale.totalAmount))").font(.subheadline.weight(.bold)).foregroundStyle(.green)
            }

            HStack(spacing: 12) {
                Label("\(sale.birdCount) birds", systemImage: "bird").font(.subheadline)
                Label("\(String(format: "%.1f", sale.totalWeightKg)) kg", systemImage: "scalemass").font(.subheadline)
                Label("₹\(Int(sale.costPerKg))/kg", systemImage: "indianrupeesign").font(.subheadline)
            }
            .foregroundStyle(.secondary)

            if let buyerId = sale.buyerId {
                Label(vm.buyerName(for: buyerId), systemImage: "building.2").font(.subheadline).foregroundStyle(.blue)
            }

            if let notes = sale.notes, !notes.isEmpty {
                Text(notes).font(.caption).foregroundStyle(.tertiary).lineLimit(1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(.systemBackground), Color.green.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.12), lineWidth: 1))
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
