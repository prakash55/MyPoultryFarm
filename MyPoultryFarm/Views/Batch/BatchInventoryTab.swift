//
//  BatchInventoryTab.swift
//  MyPoultryFarm
//

import SwiftUI

struct BatchInventoryTab: View {
    @ObservedObject var vm: BatchDetailViewModel

    var body: some View {
        VStack(spacing: 12) {
            if !vm.batchInventory.isEmpty {
                HStack(spacing: 0) {
                    let feedItems = vm.batchInventory.filter { $0.isFeed }
                    let medItems = vm.batchInventory.filter { $0.isMedicine }
                    miniStat(icon: "leaf.fill", value: "\(feedItems.count)", label: "Feed", color: .orange)
                    miniDivider
                    miniStat(icon: "cross.case.fill", value: "\(medItems.count)", label: "Medicine", color: .purple)
                    miniDivider
                    miniStat(icon: "indianrupeesign.circle.fill", value: "₹\(Int(vm.batchInventory.reduce(0.0) { $0 + $1.totalCost }))", label: "Cost", color: .red)
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [Color(.systemBackground), Color(red: 0.75, green: 0.50, blue: 0.15).opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.15), lineWidth: 1))
                )
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }

            if vm.batchInventory.isEmpty {
                emptyState(icon: "shippingbox", message: "No inventory linked")
            } else {
                let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(vm.batchInventory) { item in
                        inventoryTile(item)
                    }
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

    private func inventoryTile(_ item: InventoryRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: item.isFeed ? "leaf.fill" : "cross.case.fill")
                    .font(.subheadline).foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(item.isFeed ? Color.orange : Color.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Spacer()
                Text("₹\(Int(item.totalCost))").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            Text(item.itemName).font(.subheadline.weight(.semibold)).lineLimit(1)
            if let ft = item.feedType {
                Text(ft.capitalized).font(.caption).foregroundStyle(.orange)
            }
            HStack {
                Text("\(Int(item.quantity)) \(item.unit)").font(.caption).foregroundStyle(.secondary)
                Spacer()
                if item.used > 0 {
                    Text("\(Int(item.quantity - item.used)) left").font(.caption.weight(.medium)).foregroundStyle(.purple)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color(.systemBackground), (item.isFeed ? Color.orange : Color.purple).opacity(0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke((item.isFeed ? Color.orange : Color.purple).opacity(0.16), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.quaternary)
            Text(message).font(.subheadline).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
    }
}
