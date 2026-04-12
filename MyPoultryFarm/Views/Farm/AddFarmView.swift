//
//  AddFarmView.swift
//  MyPoultryFarm
//

import SwiftUI

struct AddFarmView: View {
    @ObservedObject var viewModel: FarmViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var farmName = ""
    @State private var location = ""
    @State private var sheds: [ShedEntry] = [ShedEntry()]
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Farm Details") {
                    TextField("Farm Name", text: $farmName)
                    TextField("Location (optional)", text: $location)
                        .textContentType(.fullStreetAddress)
                }

                Section("Sheds") {
                    ShedListEditor(sheds: $sheds)
                }
            }
            .navigationTitle("Add Farm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(farmName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                let shedTuples = sheds.compactMap { shed -> (name: String, capacity: Int)? in
                    let name = shed.name.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return nil }
                    return (name: name, capacity: Int(shed.capacity) ?? 0)
                }
                try await viewModel.addFarm(
                    name: farmName.trimmingCharacters(in: .whitespaces),
                    location: location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location.trimmingCharacters(in: .whitespaces),
                    sheds: shedTuples
                )
                dismiss()
            } catch {
                isSaving = false
            }
        }
    }
}
