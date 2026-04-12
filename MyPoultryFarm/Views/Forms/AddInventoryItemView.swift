//
//  AddInventoryItemView.swift
//  MyPoultryFarm
//

import SwiftUI

struct AddInventoryItemView: View {
    @ObservedObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    let preselectedCategory: String?

    @State private var selectedShedId: UUID?
    @State private var selectedBatchId: UUID?
    @State private var category = "feed"
    @State private var isSaving = false

    private var runningBatches: [BatchRecord] {
        guard let shedId = selectedShedId else { return [] }
        return viewModel.batches.filter { $0.shedId == shedId && $0.isRunning }
    }

    // Feed fields
    @State private var feedType = "starter"
    @State private var numberOfBags = ""
    @State private var costPerBag = ""

    // Medicine fields
    @State private var medicineName = ""
    @State private var medicineQuantity = ""
    @State private var medicineCost = ""

    private let categories = ["feed", "medicine"]
    private let feedTypes = ["starter", "grower", "finisher"]

    init(viewModel: InventoryViewModel, preselectedCategory: String? = nil) {
        self.viewModel = viewModel
        self.preselectedCategory = preselectedCategory
        _category = State(initialValue: preselectedCategory ?? "feed")
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

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat.capitalized).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if category == "feed" {
                    feedSection
                } else {
                    medicineSection
                }

                summarySection
            }
            .navigationTitle("Add Inventory")
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
        }
    }

    // MARK: - Feed Section

    private var feedSection: some View {
        Section("Feed Details") {
            Picker("Feed Type", selection: $feedType) {
                ForEach(feedTypes, id: \.self) { type in
                    Text(type.capitalized).tag(type)
                }
            }
            TextField("Number of Bags", text: $numberOfBags)
                .keyboardType(.numberPad)
            TextField("Cost per Bag (₹)", text: $costPerBag)
                .keyboardType(.decimalPad)
        }
    }

    // MARK: - Medicine Section

    private var medicineSection: some View {
        Section("Medicine Details") {
            TextField("Medicine Name", text: $medicineName)
            TextField("Quantity", text: $medicineQuantity)
                .keyboardType(.decimalPad)
            TextField("Cost (₹)", text: $medicineCost)
                .keyboardType(.decimalPad)
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        Section("Summary") {
            if category == "feed" {
                let bags = Double(numberOfBags) ?? 0
                let cost = Double(costPerBag) ?? 0
                HStack {
                    Text("Feed Type")
                    Spacer()
                    Text(feedType.capitalized)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Bags")
                    Spacer()
                    Text("\(Int(bags))")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Cost")
                    Spacer()
                    Text("₹\(Int(bags * cost))")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
            } else {
                let cost = Double(medicineCost) ?? 0
                HStack {
                    Text("Medicine")
                    Spacer()
                    Text(medicineName.isEmpty ? "–" : medicineName)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Cost")
                    Spacer()
                    Text("₹\(Int(cost))")
                        .font(.headline)
                        .foregroundStyle(.purple)
                }
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        guard selectedShedId != nil else { return false }
        if category == "feed" {
            return (Double(numberOfBags) ?? 0) > 0 && (Double(costPerBag) ?? 0) > 0
        } else {
            return !medicineName.isEmpty && (Double(medicineQuantity) ?? 0) > 0 && (Double(medicineCost) ?? 0) > 0
        }
    }

    // MARK: - Save

    private func save() {
        guard let shedId = selectedShedId else { return }
        isSaving = true
        Task {
            if category == "feed" {
                let bags = Double(numberOfBags) ?? 0
                let costBag = Double(costPerBag) ?? 0
                try await viewModel.addInventoryItem(
                    shedId: shedId, batchId: selectedBatchId,
                    category: "feed",
                    itemName: "\(feedType.capitalized) Feed",
                    feedType: feedType,
                    quantity: bags, unit: "bags",
                    costPerUnit: costBag,
                    totalCost: bags * costBag
                )
            } else {
                let qty = Double(medicineQuantity) ?? 0
                let cost = Double(medicineCost) ?? 0
                try await viewModel.addInventoryItem(
                    shedId: shedId, batchId: selectedBatchId,
                    category: "medicine",
                    itemName: medicineName,
                    feedType: nil,
                    quantity: qty, unit: "units",
                    costPerUnit: qty > 0 ? cost / qty : 0,
                    totalCost: cost
                )
            }
            dismiss()
        }
    }
}
