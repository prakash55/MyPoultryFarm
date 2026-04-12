//
//  FarmTreePicker.swift
//  MyPoultryFarm
//

import SwiftUI

/// A single-list tree picker: Overview → Farm → Shed → Batch.
/// Tapping any row selects it and dismisses the sheet.
struct FarmTreePicker: View {
    @ObservedObject var viewModel: MyFarmsViewModel
    @Binding var selection: FarmSelection
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                // Overview row
                overviewRow

                // Farm tree
                ForEach(viewModel.farms) { farm in
                    farmSection(farm: farm)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Scope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }

    // MARK: - Overview

    private var overviewRow: some View {
        Button {
            selection = .overview
            isPresented = false
        } label: {
            HStack(spacing: 12) {
                treeIcon(systemName: "square.grid.2x2", color: .green)
                Text("Overview")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                if selection == .overview {
                    checkmark
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Farm Section

    private func farmSection(farm: FarmRecord) -> some View {
        let sheds = viewModel.sheds(for: farm)
        let isSelected = selection == .farm(farm)

        return Section {
            // Farm row
            Button {
                selection = .farm(farm)
                isPresented = false
            } label: {
                HStack(spacing: 12) {
                    treeIcon(systemName: "house.fill", color: .green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(farm.farmName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        if let loc = farm.location, !loc.isEmpty {
                            Text(loc)
                                .font(.caption)
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
                .padding(.vertical, 2)
            }

            // Sheds (indented)
            ForEach(sheds) { shed in
                shedRow(shed: shed, farm: farm)
            }
        }
    }

    // MARK: - Shed Row

    private func shedRow(shed: ShedRecord, farm: FarmRecord) -> some View {
        let batches = viewModel.batches.filter { $0.shedId == shed.id! && $0.isRunning }
        let runningCount = batches.count
        let isSelected = selection == .shed(shed)

        return Group {
            // Shed row
            Button {
                selection = .shed(shed)
                isPresented = false
            } label: {
                HStack(spacing: 12) {
                    treeIcon(systemName: "building.2.fill", color: .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(shed.shedName)
                            .font(.subheadline.weight(.medium))
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
                .padding(.vertical, 2)
            }
            .padding(.leading, 20)

            // Batches (further indented)
            ForEach(batches.sorted(by: { $0.batchNumber > $1.batchNumber })) { batch in
                batchRow(batch: batch)
            }
        }
    }

    // MARK: - Batch Row

    private func batchRow(batch: BatchRecord) -> some View {
        let isRunning = batch.isRunning
        let sold = viewModel.sales.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.birdCount }
        let dead = viewModel.dailyLogs.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.mortality }
        let left = max(0, batch.computedTotalBirds - sold - dead)

        return HStack(spacing: 12) {
            treeIcon(
                systemName: isRunning ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill",
                color: isRunning ? .blue : .gray
            )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Batch #\(batch.batchNumber)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(isRunning ? "RUNNING" : "CLOSED")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(isRunning ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                        .foregroundStyle(isRunning ? .green : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                HStack(spacing: 8) {
                    Text("\(batch.computedTotalBirds) birds")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if isRunning {
                        Text("\(left) left")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.leading, 44)
    }

    // MARK: - Helpers

    private func treeIcon(systemName: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 30, height: 30)
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
