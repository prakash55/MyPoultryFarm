//
//  ShedsListView.swift
//  MyPoultryFarm
//

import SwiftUI

/// Shows all sheds for the selected farm, with nested running batches.
struct ShedsListView: View {
    @StateObject private var viewModel: ShedsListViewModel
    let farm: FarmRecord
    @Binding var selection: FarmSelection

    init(dataStore: MyFarmsViewModel, farm: FarmRecord, selection: Binding<FarmSelection>) {
        _viewModel = StateObject(wrappedValue: ShedsListViewModel(dataStore: dataStore))
        self.farm = farm
        _selection = selection
    }

    private var sheds: [ShedRecord] {
        viewModel.sheds(for: farm)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if sheds.isEmpty {
                    PlaceholderCard(icon: "building.2", title: "No sheds", subtitle: "Add sheds to this farm from the profile page.")
                } else {
                    ForEach(sheds) { shed in
                        shedCard(shed: shed)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Shed Card

    private func shedCard(shed: ShedRecord) -> some View {
        let batches = viewModel.batches.filter { $0.shedId == shed.id && $0.isRunning }
        let totalBirds = batches.reduce(0) { $0 + $1.computedTotalBirds }

        return VStack(alignment: .leading, spacing: 0) {
            // Shed header
            Button { selection = .shed(shed) } label: {
                HStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(shed.shedName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("Capacity: \(shed.capacity) birds")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !batches.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(batches.count)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.green)
                            Text("running")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)

            if !batches.isEmpty {
                Rectangle().fill(Color(.separator).opacity(0.2)).frame(height: 1).padding(.horizontal, 14)

                VStack(spacing: 2) {
                    ForEach(batches.sorted(by: { $0.batchNumber > $1.batchNumber })) { batch in
                        batchRow(batch: batch)
                    }
                }
                .padding(.vertical, 6)
            }

            // Bottom summary
            if totalBirds > 0 {
                HStack(spacing: 10) {
                    shedMiniStat(icon: "bird.fill", text: "\(totalBirds) birds", color: .blue)
                    shedMiniStat(icon: "arrow.triangle.2.circlepath", text: "\(batches.count) batches", color: .green)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.orange.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.orange.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func shedMiniStat(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Batch Row

    private func batchRow(batch: BatchRecord) -> some View {
        let sold = viewModel.sales.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.birdCount }
        let dead = viewModel.dailyLogs.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.mortality }
        let left = max(0, batch.computedTotalBirds - sold - dead)

        return NavigationLink(value: Route.batchDetail(batch)) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.blue)
                    .frame(width: 22, height: 22)
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Batch #\(batch.batchNumber)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Day \(daysSince(batch.startDate))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        Text("\(batch.computedTotalBirds) birds")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text("\(left) left")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
                Spacer()
                if batch.computedTotalCost > 0 {
                    Text(formatCurrency(batch.computedTotalCost))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.leading, 16)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func daysSince(_ dateString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 1)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        return "₹\(formatter.string(from: NSNumber(value: abs(value))) ?? "\(Int(abs(value)))")"
    }
}
