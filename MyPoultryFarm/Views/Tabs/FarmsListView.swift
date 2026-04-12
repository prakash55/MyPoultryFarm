//
//  FarmsListView.swift
//  MyPoultryFarm
//

import SwiftUI

/// Shows all farms with nested sheds and running batches. Tapping navigates to detail.
struct FarmsListView: View {
    @StateObject private var viewModel: FarmsListViewModel
    @Binding var selection: FarmSelection

    init(dataStore: MyFarmsViewModel, selection: Binding<FarmSelection>) {
        _viewModel = StateObject(wrappedValue: FarmsListViewModel(dataStore: dataStore))
        _selection = selection
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScopeBanner(label: "All Farms", icon: "square.grid.2x2")

                if viewModel.farms.isEmpty {
                    PlaceholderCard(icon: "house.lodge.fill", title: "No farms yet", subtitle: "Add farms from your profile to get started.")
                } else {
                    ForEach(viewModel.farms) { farm in
                        farmCard(farm: farm)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Farm Card

    private func farmCard(farm: FarmRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Farm header — tappable to select farm
            Button {
                selection = .farm(farm)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(farm.farmName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let location = farm.location, !location.isEmpty {
                            Label(location, systemImage: "mappin")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(viewModel.sheds(for: farm).count)")
                            .font(.title3.bold())
                            .foregroundStyle(.orange)
                        Text("Sheds")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            let sheds = viewModel.sheds(for: farm)
            if !sheds.isEmpty {
                Divider()

                ForEach(sheds) { shed in
                    shedRow(shed: shed)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }

    // MARK: - Shed Row

    private func shedRow(shed: ShedRecord) -> some View {
        let batches = viewModel.batches.filter { $0.shedId == shed.id! && $0.status == "running" }

        return VStack(alignment: .leading, spacing: 6) {
            Button {
                selection = .shed(shed)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    Text(shed.shedName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Cap: \(shed.capacity)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if !batches.isEmpty {
                        Text("\(batches.count) running")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            // Running batches under this shed
            ForEach(batches.sorted(by: { $0.batchNumber > $1.batchNumber })) { batch in
                batchRow(batch: batch)
            }
        }
        .padding(.leading, 8)
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
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Batch #\(batch.batchNumber)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("\(batch.computedTotalBirds) birds · \(left) left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.leading, 26)
        }
        .buttonStyle(.plain)
    }
}
