//
//  MainTabView.swift
//  MyPoultryFarm
//

import SwiftUI

/// The main tabbed view shown after login. Contains a header with farm picker + profile button.
struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var preloadedViewModel: MyFarmsViewModel
    let initialSelection: FarmSelection

    @AppStorage("selectedScope") private var savedSelectionKey: String = "overview"
    @State private var selection: FarmSelection = .overview
    @State private var showMyFarms = false
    @State private var showScopeDrawer = false
    @StateObject private var router = AppRouter()
    @State private var didApplyInitialSelection = false

    private var viewModel: MyFarmsViewModel { preloadedViewModel }

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack(alignment: .leading) {
                Group {
                    switch selection {
                    case .overview:
                        OverviewTabView(viewModel: viewModel, selection: $selection, router: router)
                    case .farm(let farm):
                        FarmTabView(viewModel: viewModel, selection: $selection, farm: farm, router: router)
                    case .shed(let shed):
                        ShedTabView(viewModel: viewModel, selection: $selection, shed: shed, router: router)
                    case .batch:
                        EmptyView()
                    }
                }

                if showScopeDrawer {
                    ScopeSelectionDrawer(
                        viewModel: viewModel,
                        currentSelection: selection,
                        onClose: { withAnimation(.easeInOut(duration: 0.2)) { showScopeDrawer = false } },
                        onSelectOverview: {
                            router.popToRoot()
                            selection = .overview
                            showScopeDrawer = false
                        },
                        onSelectFarm: { farm in
                            router.popToRoot()
                            selection = .farm(farm)
                            showScopeDrawer = false
                        },
                        onSelectShed: { shed in
                            router.popToRoot()
                            selection = .shed(shed)
                            showScopeDrawer = false
                        },
                        onSelectBatch: { shed, batch in
                            router.popToRoot()
                            selection = .shed(shed)
                            router.push(.batchDetail(batch))
                            showScopeDrawer = false
                        }
                    )
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .batchDetail(let batch):
                    BatchDetailView(dataStore: viewModel, batch: batch, authViewModel: authViewModel)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showScopeDrawer = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showScopeDrawer = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: selection.scopeIcon)
                                .font(.caption.weight(.semibold))
                            Text(selection.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    profileButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showMyFarms) {
                viewModel.loadAll()
            } content: {
                MyFarmsView(authViewModel: authViewModel, farmsViewModel: viewModel)
            }
            .alert("Error", isPresented: $preloadedViewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong.")
            }
            .onAppear {
                guard !didApplyInitialSelection else { return }
                applyInitialSelection()
                didApplyInitialSelection = true
            }
            .onChange(of: selection) { _, newValue in
                savedSelectionKey = newValue.storageKey
            }
        }
        .environmentObject(router)
    }

    private func applyInitialSelection() {
        switch initialSelection {
        case .batch(let batch):
            // Restore to the batch's shed scope, then push the detail
            if let shed = viewModel.allSheds.first(where: { $0.id == batch.shedId }) {
                selection = .shed(shed)
            } else {
                selection = .overview
            }
            router.push(.batchDetail(batch))
        default:
            selection = initialSelection
        }
    }

    // MARK: - Profile Button (right side)

    private var profileButton: some View {
        Button {
            showMyFarms = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 34, height: 34)
                Text(avatarInitials)
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
    }

    private var avatarInitials: String {
        let name = viewModel.profile?.fullName ?? ""
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first.map(String.init) }.joined()
        return initials.isEmpty ? "🐔" : initials.uppercased()
    }
}

#Preview {
    MainTabView(authViewModel: AuthViewModel(), preloadedViewModel: MyFarmsViewModel(), initialSelection: .overview)
}
