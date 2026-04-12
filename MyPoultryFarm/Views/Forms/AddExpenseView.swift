//
//  AddExpenseView.swift
//  MyPoultryFarm
//

import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    var initialShedId: UUID? = nil
    var initialBatchId: UUID? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var selectedShedId: UUID?
    @State private var selectedBatchId: UUID?
    @State private var category = "feed"
    @State private var amount = ""
    @State private var description = ""
    @State private var expenseDate = Date()
    @State private var isSaving = false

    private let categories = ["feed", "medicine", "labour", "birds", "other"]

    private var runningBatches: [BatchRecord] {
        guard let shedId = selectedShedId else { return [] }
        return viewModel.batches.filter { $0.shedId == shedId && $0.isRunning }
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

                Section("Expense Details") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat.capitalized).tag(cat)
                        }
                    }
                    TextField("Amount (₹)", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $expenseDate, displayedComponents: .date)
                }

                Section("Description (Optional)") {
                    TextField("What was this expense for?", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Expense")
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
        selectedShedId != nil && (Double(amount) ?? 0) > 0
    }

    private func save() {
        guard let shedId = selectedShedId, let amt = Double(amount) else { return }
        isSaving = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: expenseDate)
        Task {
            try await viewModel.addExpense(
                shedId: shedId, batchId: selectedBatchId,
                category: category,
                amount: amt,
                description: description.isEmpty ? nil : description,
                expenseDate: dateStr
            )
            dismiss()
        }
    }
}
