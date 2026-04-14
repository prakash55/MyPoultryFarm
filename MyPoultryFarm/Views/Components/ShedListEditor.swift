//
//  ShedListEditor.swift
//  MyPoultryFarm
//
//  Reusable shed list editor used in onboarding, add farm, and edit farm.
//  Binds to [ShedEntry] — a UI-only model (Models/OnboardingModels.swift).
//  Actual persistence is handled by ShedViewModel.
//

import SwiftUI

struct ShedListEditor: View {
    @Binding var sheds: [ShedEntry]

    var body: some View {
        VStack(spacing: 10) {
            ForEach($sheds) { $shed in
                HStack(spacing: 10) {
                    TextField("Shed name", text: $shed.name)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    TextField("Capacity", text: $shed.capacity)
                        .keyboardType(.numberPad)
                        .frame(width: 90)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    Button {
                        removeShed(shed.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                withAnimation { sheds.append(ShedEntry()) }
            } label: {
                Label("Add Shed", systemImage: "plus")
                    .font(.caption.weight(.medium))
            }
            .tint(.green)
        }
    }

    private func removeShed(_ shedID: UUID) {
        sheds.removeAll { $0.id == shedID }
    }
}
