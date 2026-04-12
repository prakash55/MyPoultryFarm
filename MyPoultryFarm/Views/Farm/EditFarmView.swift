//
//  EditFarmView.swift
//  MyPoultryFarm
//

import SwiftUI

struct EditFarmView: View {
    @ObservedObject var viewModel: FarmViewModel
    @Environment(\.dismiss) private var dismiss

    let farm: FarmRecord
    let existingSheds: [ShedRecord]

    @State private var farmName: String = ""
    @State private var location: String = ""
    @State private var sheds: [ShedEntry] = []
    @State private var isSaving = false
    @State private var showDeleteConfirm = false

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
            .confirmationDialog("Delete this farm and all its sheds?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Farm", role: .destructive) { deleteFarm() }
            }
            .onAppear {
                farmName = farm.farmName
                location = farm.location ?? ""
                sheds = existingSheds.map {
                    ShedEntry(existingId: $0.id, name: $0.shedName, capacity: "\($0.capacity)")
                }
                if sheds.isEmpty {
                    sheds.append(ShedEntry())
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                // Update farm details
                try await viewModel.updateFarm(
                    farm,
                    name: farmName.trimmingCharacters(in: .whitespaces),
                    location: location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location.trimmingCharacters(in: .whitespaces)
                )

                // Determine shed changes
                let currentIds = Set(sheds.compactMap(\.existingId))
                let originalIds = Set(existingSheds.compactMap(\.id))

                // Delete removed sheds
                for removedId in originalIds.subtracting(currentIds) {
                    try await viewModel.deleteShed(ShedRecord(id: removedId, farmId: farm.id!, shedName: "", capacity: 0))
                }

                // Update existing & add new sheds
                for shed in sheds {
                    let name = shed.name.trimmingCharacters(in: .whitespaces)
                    let cap = Int(shed.capacity) ?? 0
                    guard !name.isEmpty else { continue }

                    if let existingId = shed.existingId {
                        try await viewModel.updateShed(
                            ShedRecord(id: existingId, farmId: farm.id!, shedName: name, capacity: cap),
                            name: name,
                            capacity: cap
                        )
                    } else {
                        try await viewModel.addShed(to: farm, name: name, capacity: cap)
                    }
                }

                viewModel.dataStore.loadAll()
                dismiss()
            } catch {
                isSaving = false
            }
        }
    }

    private func deleteFarm() {
        Task {
            do {
                try await viewModel.deleteFarm(farm)
                dismiss()
            } catch {
                // handled by viewModel.showError
            }
        }
    }
}
