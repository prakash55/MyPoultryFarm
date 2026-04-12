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
    @StateObject private var router = AppRouter()
    @State private var didApplyInitialSelection = false

    private var viewModel: MyFarmsViewModel { preloadedViewModel }

    var body: some View {
        NavigationStack(path: $router.path) {
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
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .batchDetail(let batch):
                    BatchDetailView(dataStore: viewModel, batch: batch)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    farmPicker
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

    // MARK: - Farm Picker (left side)

    private var farmPicker: some View {
        Menu {
            Button {
                selection = .overview
            } label: {
                Label("Overview", systemImage: "square.grid.2x2")
            }

            Divider()

            ForEach(viewModel.farms) { farm in
                Menu {
                    Button {
                        selection = .farm(farm)
                    } label: {
                        Label("All \(farm.farmName)", systemImage: "house.fill")
                    }

                    Divider()

                    ForEach(viewModel.sheds(for: farm)) { shed in
                        let batches = viewModel.batches.filter { $0.shedId == shed.id && $0.status == "running" }

                        if batches.isEmpty {
                            Button {
                                selection = .shed(shed)
                            } label: {
                                Label(shed.shedName, systemImage: "building.2.fill")
                            }
                        } else {
                            Menu {
                                Button {
                                    selection = .shed(shed)
                                } label: {
                                    Label("All \(shed.shedName)", systemImage: "building.2.fill")
                                }

                                Divider()

                                ForEach(batches.sorted(by: { $0.batchNumber > $1.batchNumber })) { batch in
                                    Button {
                                        router.popToRoot()
                                        selection = .shed(shed)
                                        router.push(.batchDetail(batch))
                                    } label: {
                                        Label(batch.displayTitle, systemImage: "arrow.triangle.2.circlepath")
                                    }
                                }
                            } label: {
                                Label(shed.shedName, systemImage: "building.2.fill")
                            }
                        }
                    }
                } label: {
                    Label(farm.farmName, systemImage: "house.fill")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selection.scopeIcon)
                    .font(.subheadline)
                Text(selection.title)
                    .font(.headline)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.primary)
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
