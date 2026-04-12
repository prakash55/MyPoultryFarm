//
//  SelectionContextHelper.swift
//  MyPoultryFarm
//

import SwiftUI

/// Shared helpers for selection-aware tab views.
extension FarmSelection {
    var scopeLabel: String {
        switch self {
        case .overview: return "All Farms"
        case .farm(let f): return f.farmName
        case .shed(let s): return s.shedName
        case .batch(let b): return "Batch #\(b.batchNumber)"
        }
    }

    var scopeIcon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .farm: return "house.fill"
        case .shed: return "building.2"
        case .batch: return "arrow.triangle.2.circlepath"
        }
    }
}

/// A reusable scope banner shown at the top of each tab.
struct ScopeBanner: View {
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.green)
            Text(label)
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(.systemBackground), Color.green.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ScopeSelectorButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal")
                    .font(.subheadline.weight(.semibold))
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.primary)
        }
    }
}

struct ScopeSelectionDrawer: View {
    let viewModel: MyFarmsViewModel
    let currentSelection: FarmSelection
    let onClose: () -> Void
    let onSelectOverview: () -> Void
    let onSelectFarm: (FarmRecord) -> Void
    let onSelectShed: (ShedRecord) -> Void
    let onSelectBatch: (ShedRecord, BatchRecord) -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            drawerPanel
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
    }

    private var drawerPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                drawerHeader
                scopeButton(
                    title: "Overview",
                    subtitle: "All farms",
                    icon: "square.grid.2x2",
                    isSelected: isSelected(.overview),
                    action: onSelectOverview
                )
                farmList
            }
            .padding(18)
        }
        .frame(maxHeight: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
        .padding(.leading, 12)
        .padding(.vertical, 12)
    }

    private var drawerHeader: some View {
        HStack {
            Text("Select Scope")
                .font(.headline.weight(.semibold))
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
        }
    }

    private var farmList: some View {
        ForEach(viewModel.farms) { farm in
            VStack(alignment: .leading, spacing: 8) {
                scopeButton(
                    title: farm.farmName,
                    subtitle: "Farm overview",
                    icon: "house.fill",
                    isSelected: isSelected(.farm(farm)),
                    action: { onSelectFarm(farm) }
                )
                ForEach(viewModel.sheds(for: farm)) { shed in
                    shedRow(shed: shed)
                }
            }
        }
    }

    private func shedRow(shed: ShedRecord) -> some View {
        let batches = viewModel.batches
            .filter { $0.shedId == shed.id && $0.isRunning }
            .sorted(by: { $0.batchNumber > $1.batchNumber })
        return VStack(alignment: .leading, spacing: 6) {
            scopeButton(
                title: shed.shedName,
                subtitle: "Shed details",
                icon: "building.2.fill",
                isSelected: isSelected(.shed(shed)),
                indentation: 18,
                action: { onSelectShed(shed) }
            )
            ForEach(batches) { batch in
                scopeButton(
                    title: batch.displayTitle,
                    subtitle: "Running batch",
                    icon: "arrow.triangle.2.circlepath",
                    isSelected: isSelected(.batch(batch)),
                    indentation: 36,
                    action: { onSelectBatch(shed, batch) }
                )
            }
        }
    }

    private func scopeButton(
        title: String,
        subtitle: String,
        icon: String,
        isSelected: Bool,
        indentation: CGFloat = 0,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .green)
                    .frame(width: 28, height: 28)
                    .background((isSelected ? Color.green : Color.green.opacity(0.12)), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : .primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.green : Color(.secondarySystemBackground))
            )
            .padding(.leading, indentation)
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ selection: FarmSelection) -> Bool {
        currentSelection == selection
    }
}
