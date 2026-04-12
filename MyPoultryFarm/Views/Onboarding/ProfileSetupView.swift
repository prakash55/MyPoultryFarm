//
//  ProfileSetupView.swift
//  MyPoultryFarm
//

import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("👋 Welcome!")
                    .font(.largeTitle.bold())
                Text("Tell us a little about yourself")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProfileFormFields(fullName: $viewModel.fullName, phone: $viewModel.phone)

            Spacer()
        }
    }
}

#Preview {
    ProfileSetupView(viewModel: OnboardingViewModel())
        .padding()
}
