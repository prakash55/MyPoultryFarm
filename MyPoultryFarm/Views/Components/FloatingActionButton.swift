//
//  FloatingActionButton.swift
//  MyPoultryFarm
//

import SwiftUI

// MARK: - FAB Item Model

struct FABItem: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void
}

// MARK: - Floating Action Button

/// A reusable expanding FAB that shows animated action items when tapped.
/// Wrap your view's body in a ZStack and place this as the last child so it
/// floats above all content.
struct FloatingActionButton: View {
    let items: [FABItem]
    @Binding var isExpanded: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            // Dim backdrop — tap to collapse
            if isExpanded {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        collapse()
                    }
                    .transition(.opacity)
                    .zIndex(1)
            }

            // Action items + main button
            VStack(alignment: .trailing, spacing: 14) {

                // Items appear staggered from bottom to top
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    fabActionRow(item: item, index: index)
                }

                // Main "+" button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        isExpanded.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 58, height: 58)
                            .shadow(color: .green.opacity(0.45), radius: 10, y: 5)

                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(isExpanded ? 45 : 0))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                    }
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 28)
            .zIndex(2)
        }
    }

    // MARK: - Action Row

    private func fabActionRow(item: FABItem, index: Int) -> some View {
        HStack(spacing: 12) {
            // Label pill
            Text(item.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                )

            // Icon circle
            ZStack {
                Circle()
                    .fill(item.color)
                    .frame(width: 46, height: 46)
                    .shadow(color: item.color.opacity(0.4), radius: 6, y: 3)
                Image(systemName: item.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .opacity(isExpanded ? 1 : 0)
        .scaleEffect(isExpanded ? 1 : 0.6, anchor: .bottomTrailing)
        .offset(y: isExpanded ? 0 : 16)
        .animation(
            .spring(response: 0.38, dampingFraction: 0.72)
                .delay(isExpanded ? Double(items.count - 1 - index) * 0.055 : 0),
            value: isExpanded
        )
        .onTapGesture {
            collapse()
            // Small delay lets collapse animate before sheet appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                item.action()
            }
        }
    }

    private func collapse() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
}
