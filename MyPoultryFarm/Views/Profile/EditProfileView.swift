//
//  EditProfileView.swift
//  MyPoultryFarm
//

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    init(profileViewModel: ProfileViewModel) {
        self.viewModel = profileViewModel
    }

    @State private var fullName: String = ""
    @State private var phone: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                ProfileFormFields(fullName: $fullName, phone: $phone)
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(fullName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .onAppear {
                fullName = viewModel.profile?.fullName ?? ""
                phone = viewModel.profile?.phone ?? ""
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                try await viewModel.updateProfile(
                    fullName: fullName.trimmingCharacters(in: .whitespaces),
                    phone: phone.trimmingCharacters(in: .whitespaces)
                )
                dismiss()
            } catch {
                isSaving = false
            }
        }
    }
}
