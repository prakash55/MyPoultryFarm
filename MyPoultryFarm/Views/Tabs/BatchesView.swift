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
                VStack(spacing: 16) {
                    ScopeBanner(label: scopeLabel, icon: scopeIcon)

                    // Summary tiles
                    HStack(spacing: 12) {
                        SummaryTile(title: "Running", value: runningCount, icon: "arrow.triangle.2.circlepath", color: .green)
                        SummaryTile(title: "Birds", value: totalBirds, icon: "bird.fill", color: .blue)
                        SummaryTile(title: "Left", value: birdsLeftCount, icon: "bird", color: .purple)
                    }

                    // Segment picker
                    Picker("Filter", selection: $selectedSegment) {
                        Text("Running").tag(0)
                        Text("Closed").tag(1)
                    }
                    .pickerStyle(.segmented)

                    // Batch list
                    if selectedSegment == 0 {
                        runningBatches
                    } else {
                        closedBatches
                    }
                }
                .padding()
                .padding(.bottom, 60)
            }

            addButton
        }
        .sheet(isPresented: $showAddBatch) {
            AddBatchView(viewModel: BatchViewModel(dataStore: viewModel.dataStore))
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button { showAddBatch = true } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.green)
                .clipShape(Circle())
                .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
        }
        .padding()
    }

    // MARK: - Scope Data

    private var scopeBatches: [BatchRecord] {
        viewModel.batches.filter { scopeShedIds.contains($0.shedId) }
    }

    private var runningBatchesList: [BatchRecord] {
        scopeBatches.filter { $0.status == "running" }
    }

    private var closedBatchesList: [BatchRecord] {
        scopeBatches.filter { $0.status == "closed" }
    }

    private var runningCount: String { "\(runningBatchesList.count)" }
    private var totalBirds: String { "\(runningBatchesList.reduce(0) { $0 + $1.computedTotalBirds })" }
    private var closedCount: String { "\(closedBatchesList.count)" }

    private var scopeSales: [SaleRecord] {
        viewModel.sales.filter { scopeShedIds.contains($0.shedId) }
    }

    private var totalBirdsSold: Int {
        scopeSales.reduce(0) { $0 + $1.birdCount }
    }

    private var birdsLeftValue: Int {
        runningBatchesList.reduce(0) { $0 + $1.computedTotalBirds } - totalBirdsSold
    }

    private var birdsLeftCount: String { "\(birdsLeftValue)" }

    private func birdsSoldForBatch(_ batch: BatchRecord) -> Int {
        guard let batchId = batch.id else { return 0 }
        return viewModel.sales.filter { $0.batchId == batchId }.reduce(0) { $0 + $1.birdCount }
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.shedName(for: batch.shedId))
                        .font(.headline)
                    Text("Batch #\(batch.batchNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(isRunning ? "Running" : "Closed")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isRunning ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                    .foregroundStyle(isRunning ? .green : .gray)
                    .cornerRadius(8)
            }

            Divider()

            HStack(spacing: 20) {
                Label("\(batch.computedTotalBirds) birds", systemImage: "bird.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(batch.computedTotalBirds - birdsSoldForBatch(batch)) left", systemImage: "bird")
                    .font(.caption)
                    .foregroundStyle(.purple)
                Label("Day \(daysSince(batch.startDate))", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if batch.computedTotalCost > 0 {
                    Label("₹\(Int(batch.computedTotalCost))", systemImage: "indianrupeesign.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }

    // MARK: - Helpers

    private func daysSince(_ dateString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 1)
    }
}
