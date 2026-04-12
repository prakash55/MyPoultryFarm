//
//  SummaryTile.swift
//  MyPoultryFarm
//

import SwiftUI

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
                .renderingMode(.template)
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
