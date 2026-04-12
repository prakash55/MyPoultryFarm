//
//  BatchesView.swift
//  MyPoultryFarm
//

import SwiftUI

struct BatchesView: View {
    @StateObject private var viewModel: BatchesTabViewModel
    let scopeShedIds: Set<UUID>
    let scopeLabel: String
    let scopeIcon: String

    init(dataStore: MyFarmsViewModel, scopeShedIds: Set<UUID>, scopeLabel: String, scopeIcon: String) {
        _viewModel = StateObject(wrappedValue: BatchesTabViewModel(dataStore: dataStore))
        self.scopeShedIds = scopeShedIds
        self.scopeLabel = scopeLabel
        self.scopeIcon = scopeIcon
    }

    @State private var selectedSegment = 0
    @State private var showAddBatch = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 14) {
                    batchHeroCard
                    segmentPicker

                    if selectedSegment == 0 {
                        runningBatches
                    } else {
                        closedBatches
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 80)
            }
            .background(Color(.systemGroupedBackground))

            addButton
        }
        .sheet(isPresented: $showAddBatch) {
            AddBatchView(viewModel: BatchViewModel(dataStore: viewModel.dataStore))
        }
    }

    // MARK: - Hero Card

    private var batchHeroCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Birds")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                    Text(totalBirds)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(runningBatchesList.count) Running")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(.white.opacity(0.15)))
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle().fill(.white.opacity(0.12)).frame(height: 1).padding(.horizontal, 16)

            HStack(spacing: 0) {
                heroStat(value: birdsLeftCount, label: "Left", icon: "bird.fill", color: .cyan)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: "\(totalMortality)", label: "Deaths", icon: "heart.slash.fill", color: .red)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: "\(totalBirdsSold)", label: "Sold", icon: "cart.fill", color: .yellow)
            }
            .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.42, blue: 0.32),
                         Color(red: 0.12, green: 0.55, blue: 0.42)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func heroStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(["Running", "Closed"], id: \.self) { label in
                let idx = label == "Running" ? 0 : 1
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedSegment = idx }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: idx == 0 ? "arrow.triangle.2.circlepath" : "archivebox.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(label)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(selectedSegment == idx ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedSegment == idx ?
                        Capsule().fill(Color.green) :
                        Capsule().fill(Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Color(.systemGray6)))
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button { showAddBatch = true } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(colors: [.green, .green.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .shadow(color: .green.opacity(0.45), radius: 10, y: 5)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 28)
    }

    // MARK: - Scope Data

    private var scopeBatches: [BatchRecord] {
        viewModel.batches.filter { scopeShedIds.contains($0.shedId) }
    }

    private var runningBatchesList: [BatchRecord] {
        scopeBatches.filter { $0.isRunning }
    }

    private var closedBatchesList: [BatchRecord] {
        scopeBatches.filter { $0.isClosed }
    }

    private var totalBirds: String { "\(runningBatchesList.reduce(0) { $0 + $1.computedTotalBirds })" }

    private var scopeSales: [SaleRecord] {
        viewModel.sales.filter { scopeShedIds.contains($0.shedId) }
    }

    private var totalBirdsSold: Int {
        scopeSales.reduce(0) { $0 + $1.birdCount }
    }

    private var totalMortality: Int {
        let scopeLogs = viewModel.dailyLogs.filter { log in
            runningBatchesList.contains { $0.id == log.batchId }
        }
        return scopeLogs.reduce(0) { $0 + $1.mortality }
    }

    private var birdsLeftValue: Int {
        runningBatchesList.reduce(0) { $0 + $1.computedTotalBirds } - totalBirdsSold - totalMortality
    }

    private var birdsLeftCount: String { "\(max(0, birdsLeftValue))" }

    private func birdsSoldForBatch(_ batch: BatchRecord) -> Int {
        guard let batchId = batch.id else { return 0 }
        return viewModel.sales.filter { $0.batchId == batchId }.reduce(0) { $0 + $1.birdCount }
    }

    private func mortalityForBatch(_ batch: BatchRecord) -> Int {
        guard let batchId = batch.id else { return 0 }
        return viewModel.dailyLogs.filter { $0.batchId == batchId }.reduce(0) { $0 + $1.mortality }
    }

    // MARK: - Running Batches

    private var runningBatches: some View {
        Group {
            if runningBatchesList.isEmpty {
                PlaceholderCard(icon: "tray", title: "No running batches", subtitle: "Start a new batch in one of your sheds.")
            } else {
                ForEach(runningBatchesList) { batch in
                    NavigationLink(value: Route.batchDetail(batch)) {
                        batchCard(batch: batch, isRunning: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Closed Batches

    private var closedBatches: some View {
        Group {
            if closedBatchesList.isEmpty {
                PlaceholderCard(icon: "archivebox", title: "No closed batches", subtitle: "Closed batches will appear here when a batch cycle ends.")
            } else {
                ForEach(closedBatchesList) { batch in
                    NavigationLink(value: Route.batchDetail(batch)) {
                        batchCard(batch: batch, isRunning: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Batch Card

    private func batchCard(batch: BatchRecord, isRunning: Bool) -> some View {
        let sold = birdsSoldForBatch(batch)
        let dead = mortalityForBatch(batch)
        let left = max(0, batch.computedTotalBirds - sold - dead)
        let statusColor: Color = isRunning ? .green : .gray

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(statusColor, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.shedName(for: batch.shedId))
                        .font(.subheadline.weight(.bold))
                    Text("Batch #\(batch.batchNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(isRunning ? "Running" : "Closed")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1), in: Capsule())
            }

            Rectangle().fill(Color(.separator).opacity(0.2)).frame(height: 1)

            HStack(spacing: 0) {
                batchStat(value: "\(batch.computedTotalBirds)", label: "birds", icon: "bird.fill", color: .primary)
                batchStat(value: "\(left)", label: "left", color: .green)
                batchStat(value: "Day \(daysSince(batch.startDate))", label: "", icon: "calendar", color: .secondary)
                if batch.computedTotalCost > 0 {
                    batchStat(value: formatCurrency(batch.computedTotalCost), label: "", icon: "indianrupeesign.circle", color: .secondary)
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.green.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.green.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func batchStat(value: String, label: String, icon: String? = nil, color: Color) -> some View {
        HStack(spacing: 3) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color == .primary ? .gray : color)
            }
            VStack(spacing: 1) {
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func daysSince(_ dateString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 1)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        return "₹\(formatter.string(from: NSNumber(value: abs(value))) ?? "\(Int(abs(value)))")"
    }
}
