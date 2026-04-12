//
//  ShedListEditor.swift
//  MyPoultryFarm
//

import SwiftUI

/// Reusable shed list editor used in onboarding, add farm, and edit farm.
struct ShedListEditor: View {
    @Binding var sheds: [ShedEntry]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(sheds) { shed in
                shedRow(shed: shed)
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

    private func shedRow(shed: ShedEntry) -> some View {
        let index = sheds.firstIndex(where: { $0.id == shed.id })!
        return HStack(spacing: 10) {
            TextField("Shed name", text: $sheds[index].name)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            TextField("Capacity", text: $sheds[index].capacity)
                .keyboardType(.numberPad)
                .frame(width: 90)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            if sheds.count > 1 {
                Button(role: .destructive) {
                    withAnimation { sheds.removeAll { $0.id == shed.id } }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red.opacity(0.6))
                }
            }
        }
    }
}
