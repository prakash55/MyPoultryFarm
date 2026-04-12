//
//  AddSaleView.swift
//  MyPoultryFarm
//

import SwiftUI

struct AddSaleView: View {
    @ObservedObject var viewModel: SalesViewModel
    var initialShedId: UUID? = nil
    var initialBatchId: UUID? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var selectedShedId: UUID?
    @State private var selectedBatchId: UUID?
    @State private var birdCount = ""
    @State private var totalWeightKg = ""
    @State private var costPerKg = ""
    @State private var saleDate = Date()
    @State private var selectedBuyerId: UUID?
    @State private var notes = ""
    @State private var isSaving = false
    @State private var showAddBuyer = false

    private var runningBatches: [BatchRecord] {
        guard let shedId = selectedShedId else { return [] }
        return viewModel.batches.filter { $0.shedId == shedId && $0.isRunning }
    }

    private var birdsLeftForSelectedBatch: Int? {
        guard let batchId = selectedBatchId,
              let batch = viewModel.batches.first(where: { $0.id == batchId }) else { return nil }
        let sold = viewModel.sales.filter { $0.batchId == batchId }.reduce(0) { $0 + $1.birdCount }
        let dead = viewModel.dailyLogs.filter { $0.batchId == batchId }.reduce(0) { $0 + $1.mortality }
        return max(0, batch.computedTotalBirds - sold - dead)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Shed") {
                    Picker("Select Shed", selection: $selectedShedId) {
                        Text("Choose a shed").tag(UUID?.none)
                        ForEach(viewModel.allSheds) { shed in
                            Text("\(viewModel.farmName(for: shed)) – \(shed.shedName)")
                                .tag(UUID?.some(shed.id!))
                        }
                    }
                    .onChange(of: selectedShedId) { selectedBatchId = nil }
                }

                if !runningBatches.isEmpty {
                    Section("Batch") {
                        Picker("Select Batch", selection: $selectedBatchId) {
                            Text("None").tag(UUID?.none)
                            ForEach(runningBatches) { batch in
                                Text("\(batch.displayTitle) - \(batch.computedTotalBirds) birds")
                                    .tag(UUID?.some(batch.id!))
                            }
                        }
                    }
                }

                Section("Sale Details") {
                    TextField("Number of Birds", text: $birdCount)
                        .keyboardType(.numberPad)
                    if let left = birdsLeftForSelectedBatch {
                        HStack {
                            Image("chicken_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                            Text("Birds Available")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(left)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(left == 0 ? .red : .green)
                        }
                        if let count = Int(birdCount), count > left {
                            Label("Exceeds available birds (\(left))", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    TextField("Total Weight (kg)", text: $totalWeightKg)
                        .keyboardType(.decimalPad)
                    TextField("Cost per kg (₹)", text: $costPerKg)
                        .keyboardType(.decimalPad)
                    DatePicker("Sale Date", selection: $saleDate, displayedComponents: .date)
                }

                if let weight = Double(totalWeightKg), let rate = Double(costPerKg), weight > 0, rate > 0 {
                    Section("Summary") {
                        HStack {
                            Text("Birds")
                            Spacer()
                            Text(birdCount.isEmpty ? "–" : birdCount)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Weight")
                            Spacer()
                            Text("\(String(format: "%.1f", weight)) kg")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Total Amount")
                            Spacer()
                            Text("₹\(Int(weight * rate))")
                                .font(.headline)
                                .foregroundStyle(.green)
                        }
                    }
                }

                Section {
                    Picker("Select Buyer", selection: $selectedBuyerId) {
                        Text("None").tag(UUID?.none)
                        ForEach(viewModel.buyers) { buyer in
                            VStack(alignment: .leading) {
                                Text(buyer.agencyName)
                                if let handler = buyer.handlerName, !handler.isEmpty {
                                    Text(handler)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(UUID?.some(buyer.id!))
                        }
                    }

                    Button {
                        showAddBuyer = true
                    } label: {
                        Label("Add New Buyer", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Buyer")
                }

                Section("Notes (Optional)") {
                    TextField("Any notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Record Sale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid || isSaving)
                }
            }
            .sheet(isPresented: $showAddBuyer) {
                AddBuyerView(viewModel: viewModel) { newBuyer in
                    selectedBuyerId = newBuyer.id
                }
            }
            .onAppear {
                if selectedShedId == nil, let id = initialShedId {
                    selectedShedId = id
                }
                if selectedBatchId == nil, let id = initialBatchId {
                    selectedBatchId = id
                }
            }
        }
    }

    private var isValid: Bool {
        guard selectedShedId != nil,
              let count = Int(birdCount), count > 0,
              (Double(totalWeightKg) ?? 0) > 0,
              (Double(costPerKg) ?? 0) > 0 else { return false }
        if let left = birdsLeftForSelectedBatch {
            return count <= left
        }
        return true
    }

    private func save() {
        guard let shedId = selectedShedId,
              let count = Int(birdCount),
              let weight = Double(totalWeightKg),
              let rate = Double(costPerKg) else { return }
        isSaving = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: saleDate)
        Task {
            try await viewModel.addSale(
                shedId: shedId, batchId: selectedBatchId,
                birdCount: count,
                totalWeightKg: weight, costPerKg: rate,
                saleDate: dateStr,
                buyerId: selectedBuyerId,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        }
    }
}
