//
//  EditFarmView.swift
//  MyPoultryFarm
//

import SwiftUI

struct EditFarmView: View {
    @ObservedObject var viewModel: FarmViewModel
    @StateObject private var shedViewModel: ShedViewModel
    @Environment(\.dismiss) private var dismiss

    let farm: FarmRecord
    let existingSheds: [ShedRecord]

    @State private var farmName: String
    @State private var location: String
    @State private var sheds: [ShedEntry]
    @State private var isSaving = false
    @State private var showDeleteConfirm = false

    init(viewModel: FarmViewModel, farm: FarmRecord, existingSheds: [ShedRecord]) {
        self.viewModel = viewModel
        self.farm = farm
        self.existingSheds = existingSheds
        _shedViewModel = StateObject(wrappedValue: ShedViewModel(dataStore: viewModel.dataStore))
        _farmName = State(initialValue: farm.farmName)
        _location = State(initialValue: farm.location ?? "")
        let initialSheds = existingSheds.map {
            ShedEntry(existingId: $0.id, name: $0.shedName, capacity: "\($0.capacity)")
        }
        _sheds = State(initialValue: initialSheds.isEmpty ? [ShedEntry()] : initialSheds)
    }

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

                Section {
                    Button("Delete Farm", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Edit Farm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(farmName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .confirmationDialog(
                "Delete this farm and all its sheds?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Farm", role: .destructive) { deleteFarm() }
            }
        }
    }

    // MARK: - Actions

    private func save() {
        isSaving = true
        Task {
            do {
                // 1. Update farm details
                try await viewModel.updateFarm(
                    farm,
                    name: farmName.trimmingCharacters(in: .whitespaces),
                    location: location.trimmingCharacters(in: .whitespaces).isEmpty
                        ? nil
                        : location.trimmingCharacters(in: .whitespaces),
                    reload: false
                )

                // 2. Apply shed creates / updates / deletes in one pass
                try await shedViewModel.applyChanges(
                    newEntries: sheds,
                    originalSheds: existingSheds,
                    farm: farm
                )

                dismiss()
            } catch {
                isSaving = false
            }
        }
    }

    private func deleteFarm() {
        Task {
            try? await viewModel.deleteFarm(farm)
            dismiss()
        }
    }
}
