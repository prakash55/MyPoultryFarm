//
//  FarmDashboardView.swift
//  MyPoultryFarm
//

import SwiftUI

/// Dashboard for a specific farm — shows sheds overview.
struct FarmDashboardView: View {
    @StateObject private var viewModel: DashboardTabViewModel
    let farm: FarmRecord
    let scopeShedIds: Set<UUID>

    init(dataStore: MyFarmsViewModel, farm: FarmRecord, scopeShedIds: Set<UUID>) {
        _viewModel = StateObject(wrappedValue: DashboardTabViewModel(dataStore: dataStore))
        self.farm = farm
        self.scopeShedIds = scopeShedIds
    }

    var body: some View {
        DashboardView(
            viewModel: viewModel,
            scopeShedIds: scopeShedIds,
            scopeLabel: farm.farmName,
            scopeIcon: "house.fill"
        ) {
            if let location = farm.location, !location.isEmpty {
                HStack {
                    Label(location, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            sectionHeader("Sheds")

            let sheds = viewModel.sheds(for: farm)
            if sheds.isEmpty {
                PlaceholderCard(icon: "building.2", title: "No sheds", subtitle: "Add sheds to this farm from the profile page.")
            } else {
                ForEach(sheds) { shed in
                    shedCard(shed: shed)
                }
            }
        }
    }

    private func shedCard(shed: ShedRecord) -> some View {
        let batches = viewModel.batches.filter { $0.shedId == shed.id && $0.isRunning }
        let birdCount = batches.reduce(0) { $0 + $1.computedTotalBirds }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(.orange)
                    .frame(width: 28, height: 28)
                    .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(shed.shedName)
                        .font(.subheadline.weight(.medium))
                    Text("Capacity: \(shed.capacity) birds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !batches.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(batches.count) running")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                        Text("\(birdCount) birds")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(.systemBackground), Color.orange.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange.opacity(0.14), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Label(title, systemImage: "building.2")
                .font(.headline)
                .foregroundStyle(.orange)
            Spacer()
        }
    }
}
