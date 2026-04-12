//
//  BatchLineChart.swift
//  MyPoultryFarm
//
//  Reusable multi-line chart for batch comparison (mortality, feed, weight).
//

import SwiftUI
import Charts

struct BatchLineChart: View {
    let title: String
    let icon: String
    let color: Color
    let series: [ScopeData.BatchSeries]
    let yLabel: String
    let xLabel: String

    private let palette: [Color] = [.blue, .green, .orange, .red, .purple, .cyan, .pink, .yellow, .indigo, .mint]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)

            if series.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                Chart {
                    ForEach(Array(series.enumerated()), id: \.element.id) { index, batch in
                        ForEach(batch.points) { point in
                            LineMark(
                                x: .value(xLabel, point.day),
                                y: .value(yLabel, point.value),
                                series: .value("Batch", batch.label)
                            )
                            .foregroundStyle(palette[index % palette.count])
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value(xLabel, point.day),
                                y: .value(yLabel, point.value)
                            )
                            .foregroundStyle(palette[index % palette.count])
                            .symbolSize(20)
                        }
                    }
                }
                .chartXAxisLabel(xLabel)
                .chartYAxisLabel(yLabel)
                .chartLegend(.visible)
                .frame(height: 220)

                // Legend with colors
                legendView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }

    private var legendView: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(series.enumerated()), id: \.element.id) { index, batch in
                HStack(spacing: 4) {
                    Circle()
                        .fill(palette[index % palette.count])
                        .frame(width: 8, height: 8)
                    Text(batch.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// Simple flow layout for legend items
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
