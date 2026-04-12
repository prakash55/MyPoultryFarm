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
    let xDomain: ClosedRange<Int>?

    init(
        title: String,
        icon: String,
        color: Color,
        series: [ScopeData.BatchSeries],
        yLabel: String,
        xLabel: String,
        xDomain: ClosedRange<Int>? = nil
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.series = series
        self.yLabel = yLabel
        self.xLabel = xLabel
        self.xDomain = xDomain
    }

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
                .ifLet(xDomain) { chart, domain in
                    chart.chartXScale(domain: domain)
                }
                .chartLegend(.visible)
                .frame(height: 220)

                // Legend with colors
                legendView
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.12), lineWidth: 1))
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

private extension View {
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}
