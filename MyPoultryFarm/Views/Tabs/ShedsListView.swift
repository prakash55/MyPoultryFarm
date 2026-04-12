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
            VStack(spacing: 16) {
                ScopeBanner(label: farm.farmName, icon: "house.fill")

                if sheds.isEmpty {
                    PlaceholderCard(icon: "building.2", title: "No sheds", subtitle: "Add sheds to this farm from the profile page.")
                } else {
                    ForEach(sheds) { shed in
                        shedCard(shed: shed)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Shed Card

    private func shedCard(shed: ShedRecord) -> some View {
        let batches = viewModel.batches.filter { $0.shedId == shed.id! && $0.status == "running" }

        return VStack(alignment: .leading, spacing: 10) {
            // Shed header — tappable to select shed
            Button {
                selection = .shed(shed)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shed.shedName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Capacity: \(shed.capacity) birds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !batches.isEmpty {
                        Text("\(batches.count) running")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if !batches.isEmpty {
                Divider()

                ForEach(batches.sorted(by: { $0.batchNumber > $1.batchNumber })) { batch in
                    batchRow(batch: batch)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }

    // MARK: - Batch Row

    private func batchRow(batch: BatchRecord) -> some View {
        let sold = viewModel.sales.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.birdCount }
        let dead = viewModel.dailyLogs.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.mortality }
        let left = max(0, batch.computedTotalBirds - sold - dead)

        return NavigationLink(value: Route.batchDetail(batch)) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Batch #\(batch.batchNumber)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("Day \(daysSince(batch.startDate))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(batch.computedTotalBirds) birds · \(left) left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if batch.computedTotalCost > 0 {
                    Text("₹\(Int(batch.computedTotalCost))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.leading, 8)
        }
        .buttonStyle(.plain)
    }

    private func daysSince(_ dateString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 1)
    }
}
