//
//  AddBatchView.swift
//  MyPoultryFarm
//

import SwiftUI

struct AddBatchView: View {
    @ObservedObject var viewModel: BatchViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedShedId: UUID?
    @State private var batchName = ""
    @State private var purchasedBirds = ""
    @State private var freeBirds = ""
    @State private var costPerBird = ""
    @State private var startDate = Date()
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Shed") {
                    Picker("Select Shed", selection: $selectedShedId) {
                        Text("Choose a shed").tag(UUID?.none)
                        ForEach(viewModel.allSheds) { shed in
                            Text("\(viewModel.farmName(for: shed)) \u{2013} \(shed.shedName)")
                                .tag(UUID?.some(shed.id!))
                        }
                    }
                }

                Section("Bird Details") {
                    TextField("Batch Name", text: $batchName)
                    TextField("Purchased Birds", text: $purchasedBirds)
                        .keyboardType(.numberPad)
                    TextField("Free Birds", text: $freeBirds)
                        .keyboardType(.numberPad)
                    TextField("Cost per Bird (₹)", text: $costPerBird)
                        .keyboardType(.decimalPad)
                }

                if computedTotal > 0 {
                    Section("Summary") {
                        HStack {
                            Text("Total Birds")
                            Spacer()
                            Text("\(computedTotal)")
                                .font(.headline)
                        }
                        HStack {
                            Text("Purchase Cost")
                            Spacer()
                            Text("₹\(Int(computedCost))")
                                .font(.headline)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section("Start Date") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                Section("Notes (Optional)") {
                    TextField("Any notes about this batch", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Batch")
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
            .alert("Error", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage ?? "Failed to save batch")
            }
        }
    }

    private var purchased: Int { Int(purchasedBirds) ?? 0 }
    private var free: Int { Int(freeBirds) ?? 0 }
    private var cost: Double { Double(costPerBird) ?? 0 }
    private var computedTotal: Int { purchased + free }
    private var computedCost: Double { Double(purchased) * cost }

    private var isValid: Bool {
        selectedShedId != nil && computedTotal > 0
    }

    private func save() {
        guard let shedId = selectedShedId else { return }
        isSaving = true
        errorMessage = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: startDate)
        Task {
            do {
                try await viewModel.addBatch(
                    shedId: shedId,
                    batchName: batchName.isEmpty ? nil : batchName,
                    purchasedBirds: purchased,
                    freeBirds: free,
                    costPerBird: cost,
                    startDate: dateStr,
                    notes: notes.isEmpty ? nil : notes
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSaving = false
                }
            }
        }
    }
}
