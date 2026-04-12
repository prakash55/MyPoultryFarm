//
//  FarmSetupView.swift
//  MyPoultryFarm
//

import SwiftUI

struct FarmSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("🏠 Your Farms")
                    .font(.largeTitle.bold())
                Text("Add your farms and sheds")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Array(viewModel.farms.enumerated()), id: \.element.id) { farmIndex, _ in
                        farmCard(farmIndex: farmIndex)
                    }

                    Button {
                        viewModel.addFarm()
                    } label: {
                        Label("Add Another Farm", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .cornerRadius(12)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Farm Card

    private func farmCard(farmIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Farm header
            HStack {
                Text("Farm \(farmIndex + 1)")
                    .font(.title3.bold())
                Spacer()
                if viewModel.farms.count > 1 {
                    Button(role: .destructive) {
                        viewModel.removeFarm(at: farmIndex)
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline)
                    }
                }
            }

            // Farm fields
            TextField("Farm Name", text: $viewModel.farms[farmIndex].name)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            TextField("Location (optional)", text: $viewModel.farms[farmIndex].location)
                .textContentType(.fullStreetAddress)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            // Sheds
            Text("Sheds")
                .font(.headline)
                .padding(.top, 4)

            ShedListEditor(sheds: $viewModel.farms[farmIndex].sheds)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }
}

#Preview {
    FarmSetupView(viewModel: OnboardingViewModel())
        .padding()
}
