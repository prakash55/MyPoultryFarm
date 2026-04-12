//
//  ShedDashboardView.swift
//  MyPoultryFarm
//

import SwiftUI

/// Dashboard for a specific shed — shows running batches overview.
struct ShedDashboardView: View {
    @StateObject private var viewModel: DashboardTabViewModel
    let shed: ShedRecord
    let scopeShedIds: Set<UUID>

    init(dataStore: MyFarmsViewModel, shed: ShedRecord, scopeShedIds: Set<UUID>) {
        _viewModel = StateObject(wrappedValue: DashboardTabViewModel(dataStore: dataStore))
        self.shed = shed
        self.scopeShedIds = scopeShedIds
    }

    var body: some View {
        DashboardView(
            viewModel: viewModel,
            scopeShedIds: scopeShedIds,
            scopeLabel: shed.shedName,
            scopeIcon: "building.2"
        ) {
            sectionHeader("Running Batches")

            let batches = viewModel.batches.filter { $0.shedId == shed.id && $0.isRunning }
            if batches.isEmpty {
                PlaceholderCard(icon: "arrow.triangle.2.circlepath", title: "No running batches", subtitle: "Start a new batch to see details here.")
            } else {
                ForEach(batches.sorted(by: { $0.batchNumber > $1.batchNumber })) { batch in
                    batchCard(batch: batch)
                }
            }
        }
    }

    private func batchCard(batch: BatchRecord) -> some View {
        let sold = viewModel.sales.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.birdCount }
        let dead = viewModel.dailyLogs.filter { $0.batchId == batch.id }.reduce(0) { $0 + $1.mortality }
        let left = max(0, batch.computedTotalBirds - sold - dead)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.green)
                    .frame(width: 28, height: 28)
                    .background(Color.green.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Batch #\(batch.batchNumber)")
                            .font(.subheadline.weight(.medium))
                        Text("Day \(daysSince(batch.startDate))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(batch.computedTotalBirds) birds · \(left) left · \(dead) dead")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if sold > 0 {
                    Text("\(sold) sold")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(.systemBackground), Color.green.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.14), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func daysSince(_ dateString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 1)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Label(title, systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)
                .foregroundStyle(.green)
            Spacer()
        }
    }
}
