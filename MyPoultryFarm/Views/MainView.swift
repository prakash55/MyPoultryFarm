//
//  MainView.swift
//  MyPoultryFarm
//

import SwiftUI

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
