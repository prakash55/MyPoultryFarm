//
//  ProfitSparkline.swift
//  MyPoultryFarm
//

import SwiftUI

struct ProfitSparklineCard: View {
    let values: [Double]
    let color: Color

    private var lineValues: [Double] {
        values.count > 1 ? values : [0, values.first ?? 0]
    }

    var body: some View {
        GeometryReader { geometry in
            let normalizedPoints = SparklineMath.points(for: lineValues, in: geometry.size)
            ZStack {
                HStack(spacing: geometry.size.width / 6) {
                    ForEach(0..<5, id: \.self) { _ in
                        Rectangle().fill(Color.primary.opacity(0.05)).frame(width: 1)
                    }
                }
                .padding(.vertical, 8)

                SparklineAreaShape(points: normalizedPoints)
                    .fill(LinearGradient(colors: [color.opacity(0.18), color.opacity(0.02)], startPoint: .top, endPoint: .bottom))

                SparklineLineShape(points: normalizedPoints)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                if let last = normalizedPoints.last {
                    Circle().fill(color).frame(width: 10, height: 10)
                        .position(last).shadow(color: color.opacity(0.3), radius: 6, y: 2)
                }
            }
        }
    }
}

enum SparklineMath {
    static func points(for values: [Double], in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty, size.width > 0, size.height > 0 else { return [] }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let range = max(maxValue - minValue, 1)
        let horizontalStep = values.count > 1 ? size.width / CGFloat(values.count - 1) : size.width
        return values.enumerated().map { index, value in
            let x = CGFloat(index) * horizontalStep
            let normalized = (value - minValue) / range
            let y = size.height - (CGFloat(normalized) * max(size.height - 8, 1)) - 4
            return CGPoint(x: x, y: y)
        }
    }
}

struct SparklineLineShape: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        return path
    }
}

struct SparklineAreaShape: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first, let last = points.last else { return path }
        path.move(to: CGPoint(x: first.x, y: rect.maxY))
        path.addLine(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        path.addLine(to: CGPoint(x: last.x, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
