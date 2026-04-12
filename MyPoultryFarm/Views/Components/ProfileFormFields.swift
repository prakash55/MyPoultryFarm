//
//  ProfileFormFields.swift
//  MyPoultryFarm
//

import SwiftUI

/// Reusable profile fields used in both onboarding and edit profile.
struct ProfileFormFields: View {
    @Binding var fullName: String
    @Binding var phone: String

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Full Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. Prakash Kumar", text: $fullName)
                    .textContentType(.name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Phone Number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. +91 9876543210", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
    }
}
