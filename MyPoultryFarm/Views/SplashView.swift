//
//  SplashView.swift
//  MyPoultryFarm
//
//  Created by Prakash on 12/04/26.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        if isActive {
            MainView()
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.green.opacity(0.3), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image("chicken_icon")
                        .font(.system(size: 100))
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)

                    Text("MyPoultryFarm")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.green.opacity(0.9))
                        .opacity(textOpacity)

                    Text("Smart Farm Management")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .opacity(textOpacity)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    iconScale = 1.0
                    iconOpacity = 1.0
                }
                withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
                    textOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
