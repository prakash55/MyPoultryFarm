//
//  MyFarmsView.swift
//  MyPoultryFarm
//

import SwiftUI

struct MyFarmsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showEditProfile = false
    @State private var editingFarm: FarmRecord?
    @State private var showAddFarm = false
    @State private var showLogoutConfirmation = false

    // Init with shared ViewModel (used from MainTabView)
    init(authViewModel: AuthViewModel, farmsViewModel: MyFarmsViewModel) {
        self.authViewModel = authViewModel
        _viewModel = StateObject(wrappedValue: ProfileViewModel(dataStore: farmsViewModel))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading…")
                } else if viewModel.farms.isEmpty && viewModel.profile == nil {
                    emptyState
                } else {
                    mainContent
                }
            }
            .navigationTitle("My Farms")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong.")
            }
            .alert("Log out?", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("You will need to sign in again to access your farm data.")
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(profileViewModel: viewModel)
            }
            .sheet(item: $editingFarm) { farm in
                EditFarmView(
                    viewModel: FarmViewModel(dataStore: viewModel.dataStore),
                    farm: farm,
                    existingSheds: viewModel.sheds(for: farm)
                )
            }
            .sheet(isPresented: $showAddFarm) {
                AddFarmView(viewModel: FarmViewModel(dataStore: viewModel.dataStore))
            }
            .onAppear {
                viewModel.loadAll()
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Farmer profile card
                profileCard

                // Summary tiles
                summaryRow

                // Farm cards
                ForEach(viewModel.farms) { farm in
                    farmCard(farm: farm)
                }

                // Add farm button
                Button {
                    showAddFarm = true
                } label: {
                    Label("Add Farm", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .cornerRadius(12)
                }

                logoutSection
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.green.opacity(0.15), Color.blue.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 6)

            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Text(avatarInitials)
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.profile?.fullName ?? "Farmer")
                        .font(.title3.bold())
                    Text("Farm Owner")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                    if let phone = viewModel.profile?.phone, !phone.isEmpty {
                        Label(phone, systemImage: "phone.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    showEditProfile = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }

    private var avatarInitials: String {
        let name = viewModel.profile?.fullName ?? ""
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first.map(String.init) }.joined()
        return initials.isEmpty ? "🐔" : initials.uppercased()
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        HStack(spacing: 12) {
            summaryTile(
                title: "Farms",
                value: "\(viewModel.farms.count)",
                icon: "house.fill",
                color: .green
            )
            summaryTile(
                title: "Total Sheds",
                value: "\(viewModel.shedsByFarm.values.flatMap { $0 }.count)",
                icon: "building.2.fill",
                color: .orange
            )
            summaryTile(
                title: "Capacity",
                value: "\(viewModel.shedsByFarm.values.flatMap { $0 }.reduce(0) { $0 + $1.capacity })",
                icon: "bird.fill",
                color: .blue
            )
        }
    }

    // MARK: - Summary Tile

    private func summaryTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Farm Card

    private func farmCard(farm: FarmRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Farm header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(farm.farmName)
                        .font(.title3.bold())
                    if let location = farm.location, !location.isEmpty {
                        Label(location, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    editingFarm = farm
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
            }

            Divider()

            // Shed details
            let sheds = viewModel.sheds(for: farm)
            if sheds.isEmpty {
                Text("No sheds added")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sheds) { shed in
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        Text(shed.shedName)
                            .font(.subheadline)
                        Spacer()
                        Text("\(shed.capacity) birds")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Capacity summary for this farm
                HStack {
                    Spacer()
                    Text("Total: \(viewModel.totalCapacity(for: farm)) birds")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "house.lodge.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green.opacity(0.4))
            Text("No farms yet")
                .font(.title2.bold())
            Text("Your farms will appear here after setup.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            logoutSection
            Spacer()
        }
    }

    // MARK: - Logout

    private var logoutSection: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.red)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 6)
    }
}

#Preview {
    MyFarmsView(authViewModel: AuthViewModel(), farmsViewModel: MyFarmsViewModel())
}
