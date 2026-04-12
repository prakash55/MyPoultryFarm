//
//  AddDailyLogView.swift
//  MyPoultryFarm
//

import SwiftUI

struct AddDailyLogView: View {
    @ObservedObject var viewModel: DailyLogViewModel
    @Environment(\.dismiss) private var dismiss

    let batch: BatchRecord

    @State private var logDate = Date()
    @State private var mortality = ""
    @State private var feedUsedBags = ""
    @State private var feedType = "starter"
    @State private var medicineUsed = ""
    @State private var medicineQty = ""
    @State private var avgWeightKg = ""
    @State private var notes = ""
    @State private var isSaving = false

    private let feedTypes = ["starter", "grower", "finisher"]

    private var birdsLeft: Int {
        guard let batchId = batch.id else { return 0 }
        let sold = viewModel.sales.filter { $0.batchId == batchId }.reduce(0) { $0 + $1.birdCount }
        let dead = viewModel.dailyLogs.filter { $0.batchId == batchId }.reduce(0) { $0 + $1.mortality }
        return max(0, batch.computedTotalBirds - sold - dead)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(viewModel.shedName(for: batch.shedId))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(batch.displayTitle)
                            .foregroundStyle(.secondary)
                    }
                    DatePicker("Log Date", selection: $logDate, displayedComponents: .date)
                }

                Section("Mortality") {
                    TextField("Birds died today", text: $mortality)
                        .keyboardType(.numberPad)
                    HStack {
                        Image("chicken_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text("Birds Available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(birdsLeft)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(birdsLeft == 0 ? .red : .green)
                    }
                    if let m = Int(mortality), m > birdsLeft {
                        Label("Exceeds available birds (\(birdsLeft))", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Feed Used") {
                    Picker("Feed Type", selection: $feedType) {
                        ForEach(feedTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    TextField("Feed used (bags)", text: $feedUsedBags)
                        .keyboardType(.decimalPad)
                }

                Section("Medicine Used") {
                    TextField("Medicine name", text: $medicineUsed)
                    TextField("Quantity", text: $medicineQty)
                        .keyboardType(.decimalPad)
                }

                Section("Average Bird Weight") {
                    TextField("Avg weight (kg)", text: $avgWeightKg)
                        .keyboardType(.decimalPad)
                }

                Section("Notes (Optional)") {
                    TextField("Any observations", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Summary
                Section("Summary") {
                    if let m = Int(mortality), m > 0 {
                        HStack {
                            Label("Mortality", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Spacer()
                            Text("\(m) birds")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.red)
                        }
                    }
                    if let f = Double(feedUsedBags), f > 0 {
                        HStack {
                            Label("Feed", systemImage: "leaf.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            Text("\(String(format: "%.1f", f)) bags · \(feedType.capitalized)")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                    if !medicineUsed.isEmpty {
                        HStack {
                            Label("Medicine", systemImage: "cross.case.fill")
                                .foregroundStyle(.purple)
                            Spacer()
                            Text("\(medicineUsed)\(medicineQty.isEmpty ? "" : " · \(medicineQty)")")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                    if let w = Double(avgWeightKg), w > 0 {
                        HStack {
                            Label("Avg Weight", systemImage: "scalemass.fill")
                                .foregroundStyle(.teal)
                            Spacer()
                            Text("\(String(format: "%.2f", w)) kg")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }
            .navigationTitle("Daily Log")
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

    private var isValid: Bool {
        let mortalityVal = Int(mortality) ?? 0
        guard mortalityVal <= birdsLeft else { return false }
        return mortalityVal > 0 || (Double(feedUsedBags) ?? 0) > 0 || !medicineUsed.isEmpty || (Double(avgWeightKg) ?? 0) > 0
    }

    private func save() {
        guard let batchId = batch.id else { return }
        isSaving = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: logDate)
        Task {
            try await viewModel.addDailyLog(
                batchId: batchId,
                shedId: batch.shedId,
                logDate: dateStr,
                mortality: Int(mortality) ?? 0,
                feedUsedBags: Double(feedUsedBags) ?? 0,
                feedType: (Double(feedUsedBags) ?? 0) > 0 ? feedType : nil,
                medicineUsed: medicineUsed.isEmpty ? nil : medicineUsed,
                medicineQty: Double(medicineQty) ?? 0,
                avgWeightKg: Double(avgWeightKg) ?? 0,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        }
    }
}
