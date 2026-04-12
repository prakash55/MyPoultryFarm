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
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

/// Reusable summary tile used across all tabs.
struct SummaryTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @ViewBuilder
    private var tileIcon: some View {
        if icon == "chicken_icon" {
            Image(icon)
                .renderingMode(Image.TemplateRenderingMode.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(color)
        } else {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                tileIcon
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
                Spacer()
            }

            Text(value)
                .font(.title3.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.16), lineWidth: 1)
                )
        )
    }
}

/// Reusable placeholder for empty/coming-soon states.
struct PlaceholderCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 64, height: 64)
                .background(Color.green.opacity(0.14), in: RoundedRectangle(cornerRadius: 18))
            Text(title)
                .font(.headline.weight(.semibold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.green.opacity(0.16), lineWidth: 1)
                )
        )
    }
}
