//
//  FarmTreeDropdown.swift
//  MyPoultryFarm
//

import SwiftUI

/// A compact dropdown list for selecting Overview, Farm, or Shed.
/// Designed to work in a popover context. Batches are shown as read-only rows (running only).
struct FarmTreeDropdown: View {
    @ObservedObject var viewModel: MyFarmsViewModel
    @Binding var selection: FarmSelection
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Scope")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    overviewRow

                    ForEach(viewModel.farms) { farm in
                        farmSection(farm: farm)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 10)
            }
            .frame(maxHeight: 400)
        }
        .frame(minWidth: 300)
    }

    // MARK: - Overview

    private var overviewRow: some View {
        Button {
            selection = .overview
            isPresented = false
        } label: {
            HStack(spacing: 10) {
                treeIcon(systemName: "square.grid.2x2", color: .green)
                Text("Overview")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                if selection == .overview { checkmark }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Farm Section

    private func farmSection(farm: FarmRecord) -> some View {
        let sheds = viewModel.sheds(for: farm)
        let isSelected = selection == .farm(farm)

        return VStack(alignment: .leading, spacing: 2) {
            Button {
                selection = .farm(farm)
                isPresented = false
            } label: {
                HStack(spacing: 10) {
                    treeIcon(systemName: "house.fill", color: .green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(farm.farmName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        if let loc = farm.location, !loc.isEmpty {
                            Text(loc)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if !sheds.isEmpty {
                        Text("\(sheds.count) shed\(sheds.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if isSelected { checkmark }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
            }
            .buttonStyle(.plain)

            ForEach(sheds) { shed in
                shedRow(shed: shed)
            }
        }
    }

    // MARK: - Shed Row

    private func shedRow(shed: ShedRecord) -> some View {
        let batches = viewModel.batches.filter { $0.shedId == shed.id! && $0.isRunning }
        let runningCount = batches.count
        let isSelected = selection == .shed(shed)

        return VStack(alignment: .leading, spacing: 2) {
            Button {
                selection = .shed(shed)
                isPresented = false
            } label: {
                HStack(spacing: 10) {
                    treeIcon(systemName: "building.2.fill", color: .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(shed.shedName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                        HStack(spacing: 8) {
                            Text("Cap: \(shed.capacity)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if runningCount > 0 {
                                Text("\(runningCount) running")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    Spacer()
                    if isSelected { checkmark }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
            }
            .buttonStyle(.plain)
            .padding(.leading, 18)

            ForEach(batches.sorted(by: { $0.batchNumber > $1.batchNumber })) { batch in
                batchRow(batch: batch)
            }
        }
    }

    // MARK: - Batch Row (read-only)

    private func batchRow(batch: BatchRecord) -> some View {
        let sold = viewModel.sales.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.birdCount }
        let dead = viewModel.dailyLogs.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.mortality }
        let left = max(0, batch.computedTotalBirds - sold - dead)
        let isSelected: Bool = {
            if case .batch(let b) = selection { return b.id == batch.id }
            return false
        }()

        return Button {
            selection = .batch(batch)
            isPresented = false
        } label: {
            HStack(spacing: 10) {
                treeIcon(systemName: "arrow.triangle.2.circlepath", color: .blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Batch #\(batch.batchNumber)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        Text("\(batch.computedTotalBirds) birds")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(left) left")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
                Spacer()
                if isSelected { checkmark }
            }
            .padding(.vertical, 3)
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
        .padding(.leading, 42)
    }

    // MARK: - Helpers

    private func treeIcon(systemName: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 26, height: 26)
            Image(systemName: systemName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
        }
    }

    private var checkmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.body)
            .foregroundStyle(.green)
    }
}
