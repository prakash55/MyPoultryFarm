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
            VStack(spacing: 14) {
                if viewModel.farms.isEmpty {
                    PlaceholderCard(icon: "house.lodge.fill", title: "No farms yet", subtitle: "Add farms from your profile to get started.")
                } else {
                    ForEach(viewModel.farms) { farm in
                        farmCard(farm: farm)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Farm Card

    private func farmCard(farm: FarmRecord) -> some View {
        let sheds = viewModel.sheds(for: farm)
        let totalBirds = sheds.reduce(0) { total, shed in
            total + viewModel.batches.filter { $0.shedId == shed.id && $0.isRunning }.reduce(0) { $0 + $1.computedTotalBirds }
        }

        return VStack(alignment: .leading, spacing: 0) {
            // Farm Header
            Button { selection = .farm(farm) } label: {
                HStack(spacing: 12) {
                    Image(systemName: "house.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(farm.farmName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                        if let location = farm.location, !location.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 8))
                                Text(location)
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(sheds.count)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.green)
                        Text("Sheds")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)

            if !sheds.isEmpty {
                Rectangle().fill(Color(.separator).opacity(0.2)).frame(height: 1).padding(.horizontal, 14)

                VStack(spacing: 0) {
                    ForEach(sheds) { shed in
                        shedRow(shed: shed)
                    }
                }
                .padding(.vertical, 6)
            }

            // Bottom summary strip
            if totalBirds > 0 {
                HStack(spacing: 10) {
                    farmMiniStat(icon: "building.2.fill", text: "\(sheds.count) sheds", color: .orange)
                    farmMiniStat(icon: "bird.fill", text: "\(totalBirds) birds", color: .blue)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.green.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.green.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func farmMiniStat(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Shed Row

    private func shedRow(shed: ShedRecord) -> some View {
        let batches = viewModel.batches.filter { $0.shedId == shed.id && $0.isRunning }

        return VStack(alignment: .leading, spacing: 4) {
            Button { selection = .shed(shed) } label: {
                HStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.orange)
                        .frame(width: 24, height: 24)
                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

                    Text(shed.shedName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Cap: \(shed.capacity)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if !batches.isEmpty {
                        Text("\(batches.count) running")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)

            ForEach(batches.sorted(by: { $0.batchNumber > $1.batchNumber })) { batch in
                batchRow(batch: batch)
            }
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
                    Text("Batch #\(batch.batchNumber)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(batch.computedTotalBirds) birds · \(left) left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.leading, 24)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
