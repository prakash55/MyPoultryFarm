//
//  OverviewDashboardView.swift
//  MyPoultryFarm
//

import SwiftUI

/// Dashboard for "Overview" scope — shows all-farms summary with farm overview cards.
struct OverviewDashboardView: View {
    @StateObject private var viewModel: DashboardTabViewModel
    let scopeShedIds: Set<UUID>

    init(dataStore: MyFarmsViewModel, scopeShedIds: Set<UUID>) {
        _viewModel = StateObject(wrappedValue: DashboardTabViewModel(dataStore: dataStore))
        self.scopeShedIds = scopeShedIds
    }

    var body: some View {
        DashboardView(
            viewModel: viewModel,
            scopeShedIds: scopeShedIds,
            scopeLabel: "All Farms",
            scopeIcon: "square.grid.2x2"
        ) {
            sectionHeader("Your Farms")

            if viewModel.farms.isEmpty {
                PlaceholderCard(icon: "house.lodge.fill", title: "No farms yet", subtitle: "Add farms from your profile to get started.")
            } else {
                ForEach(viewModel.farms) { farm in
                    farmOverviewCard(farm: farm)
                }
            }
        }
    }

    private func farmOverviewCard(farm: FarmRecord) -> some View {
        let sheds = viewModel.sheds(for: farm)
        let shedIds = Set(sheds.compactMap { $0.id })
        let batchCount = viewModel.batches.filter { shedIds.contains($0.shedId) && $0.status == "running" }.count
        let birdCount = viewModel.batches.filter { shedIds.contains($0.shedId) && $0.status == "running" }.reduce(0) { $0 + $1.computedTotalBirds }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(farm.farmName)
                        .font(.headline.weight(.semibold))
                    if let location = farm.location, !location.isEmpty {
                        Label(location, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(sheds.count)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.orange)
                    Text("Sheds")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !sheds.isEmpty {
                Divider()
                HStack(spacing: 16) {
                    Label("\(batchCount) batches", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(.green)
                    HStack(spacing: 4) {
                        Image("chicken_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                        Text("\(birdCount) birds")
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                    Spacer()
                    Text("Cap: \(viewModel.totalCapacity(for: farm))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.14), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Label(title, systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.green)
            Spacer()
        }
    }
}
