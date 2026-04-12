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
                    Text("🐔")
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

/// The main app view that handles auth state routing.
struct MainView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var viewModel = MyFarmsViewModel()
    @AppStorage("selectedScope") private var savedSelectionKey: String = "overview"
    @State private var initialSelection: FarmSelection = .overview
    @State private var dataReady = false

    var body: some View {
        Group {
            if authViewModel.isCheckingSession {
                ProgressView()
            } else if authViewModel.isAuthenticated && authViewModel.needsOnboarding {
                OnboardingContainerView(prefillName: authViewModel.userName) {
                    authViewModel.completeOnboarding()
                }
            } else if authViewModel.isAuthenticated {
                if dataReady {
                    MainTabView(authViewModel: authViewModel, preloadedViewModel: viewModel, initialSelection: initialSelection)
                } else {
                    ProgressView("Loading farms…")
                        .onAppear {
                            viewModel.loadAll()
                        }
                        .onReceive(viewModel.$isLoading) { loading in
                            guard !dataReady, !loading else { return }
                            initialSelection = FarmSelection.from(storageKey: savedSelectionKey, viewModel: viewModel)
                            dataReady = true
                        }
                }
            } else {
                LoginView(viewModel: authViewModel)
                    .onAppear {
                        dataReady = false
                        viewModel.clearAllData()
                    }
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .animation(.easeInOut, value: authViewModel.needsOnboarding)
    }
}

#Preview {
    SplashView()
}
