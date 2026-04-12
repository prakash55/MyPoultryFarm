//
//  AddBuyerView.swift
//  MyPoultryFarm
//

import SwiftUI

struct AddBuyerView: View {
    @ObservedObject var viewModel: SalesViewModel
    @Environment(\.dismiss) private var dismiss

    let onSave: (BuyerRecord) -> Void

    @State private var agencyName = ""
    @State private var handlerName = ""
    @State private var phone = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Agency Details") {
                    TextField("Agency Name", text: $agencyName)
                    TextField("Handler Name", text: $handlerName)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("New Buyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(agencyName.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            let saved = try await viewModel.addBuyer(
                agencyName: agencyName,
                handlerName: handlerName.isEmpty ? nil : handlerName,
                phone: phone.isEmpty ? nil : phone
            )
            onSave(saved)
            dismiss()
        }
    }
}
