//
//  FarmTreeSection.swift
//  MyPoultryFarm
//
//  Reusable tree structure: Farms → Sheds → Batches with per-node info.
//

import SwiftUI

/// A reusable farm → shed → batch tree for Inventory, Sales, Finances tabs.
/// Uses a generic `nodeInfo` closure to show context-specific details per node.
struct FarmTreeSection<FarmInfo: View, ShedInfo: View, BatchInfo: View>: View {
    let viewModel: MyFarmsViewModel
    let farms: [FarmRecord]
    let scopeShedIds: Set<UUID>
    @ViewBuilder let farmInfo: (FarmRecord, Set<UUID>) -> FarmInfo
    @ViewBuilder let shedInfo: (ShedRecord) -> ShedInfo
    @ViewBuilder let batchInfo: (BatchRecord) -> BatchInfo

    var body: some View {
        if farms.isEmpty {
            PlaceholderCard(icon: "house.lodge.fill", title: "No farms", subtitle: "Add farms from your profile to get started.")
        } else {
            ForEach(farms) { farm in
                farmNode(farm: farm)
            }
        }
    }

    private func farmNode(farm: FarmRecord) -> some View {
        let sheds = viewModel.sheds(for: farm).filter { scopeShedIds.contains($0.id!) }
        let farmShedIds = Set(sheds.compactMap { $0.id })

        return VStack(alignment: .leading, spacing: 8) {
            // Farm header
            HStack(spacing: 10) {
                Image(systemName: "house.fill")
                    .foregroundStyle(.green)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(farm.farmName)
                        .font(.subheadline.weight(.semibold))
                    if let loc = farm.location, !loc.isEmpty {
                        Text(loc)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            farmInfo(farm, farmShedIds)

            if !sheds.isEmpty {
                Divider()
                ForEach(sheds) { shed in
                    shedNode(shed: shed)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.green.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }

    private func shedNode(shed: ShedRecord) -> some View {
        let batches = viewModel.batches.filter { $0.shedId == shed.id && $0.isRunning }

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(.orange)
                    .frame(width: 20)
                Text(shed.shedName)
                    .font(.caption.weight(.medium))
                Spacer()
                Text("Cap: \(shed.capacity)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 8)

            shedInfo(shed)
                .padding(.leading, 36)

            ForEach(batches.sorted(by: { $0.batchNumber > $1.batchNumber })) { batch in
                batchNode(batch: batch)
            }
        }
    }

    private func batchNode(batch: BatchRecord) -> some View {
        let sold = viewModel.sales.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.birdCount }
        let dead = viewModel.dailyLogs.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.mortality }
        let left = max(0, batch.computedTotalBirds - sold - dead)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.blue)
                    .frame(width: 16)
                Text("Batch #\(batch.batchNumber)")
                    .font(.caption2.weight(.medium))
                Text("\(batch.computedTotalBirds) birds · \(left) left")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.leading, 36)

            batchInfo(batch)
                .padding(.leading, 60)
        }
    }
}
