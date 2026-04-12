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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
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
            VStack(spacing: 14) {
                profileHeroCard
                summaryStrip

                ForEach(viewModel.farms) { farm in
                    farmCard(farm: farm)
                }

                addFarmButton
                logoutSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Profile Hero Card

    private var profileHeroCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Text(avatarInitials)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.profile?.fullName ?? "Farmer")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Farm Owner")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    if let phone = viewModel.profile?.phone, !phone.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 9))
                            Text(phone)
                                .font(.caption)
                        }
                        .foregroundStyle(.white.opacity(0.55))
                    }
                }

                Spacer()

                Button { showEditProfile = true } label: {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.18), in: Circle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.42, blue: 0.32),
                         Color(red: 0.12, green: 0.55, blue: 0.42)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var avatarInitials: String {
        let name = viewModel.profile?.fullName ?? ""
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first.map(String.init) }.joined()
        return initials.isEmpty ? "🐔" : initials.uppercased()
    }

    // MARK: - Summary Strip

    private var summaryStrip: some View {
        HStack(spacing: 10) {
            summaryPill(
                title: "Farms",
                value: "\(viewModel.farms.count)",
                color: .green
            )
            summaryPill(
                title: "Sheds",
                value: "\(viewModel.shedsByFarm.values.flatMap { $0 }.count)",
                color: .orange
            )
            summaryPill(
                title: "Capacity",
                value: "\(viewModel.shedsByFarm.values.flatMap { $0 }.reduce(0) { $0 + $1.capacity })",
                color: .blue
            )
        }
    }

    private func summaryPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Farm Card

    private func farmCard(farm: FarmRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "house.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.green, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(farm.farmName)
                        .font(.subheadline.weight(.bold))
                    if let location = farm.location, !location.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin")
                                .font(.system(size: 8))
                            Text(location)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { editingFarm = farm } label: {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                        .frame(width: 28, height: 28)
                        .background(Color.green.opacity(0.1), in: Circle())
                }
            }

            let sheds = viewModel.sheds(for: farm)
            if sheds.isEmpty {
                Text("No sheds added")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 40)
            } else {
                Rectangle()
                    .fill(Color(.separator).opacity(0.2))
                    .frame(height: 1)

                ForEach(sheds) { shed in
                    HStack(spacing: 10) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.orange)
                            .frame(width: 24, height: 24)
                            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        Text(shed.shedName)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(shed.capacity) birds")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Spacer()
                    Text("Total: \(viewModel.totalCapacity(for: farm)) birds")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.green.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.green.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Add Farm Button

    private var addFarmButton: some View {
        Button { showAddFarm = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.subheadline.weight(.bold))
                Text("Add Farm")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.green)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.green.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
            )
        }
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
        Button { showLogoutConfirmation = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.caption.weight(.bold))
                Text("Log Out")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.red)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.red.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.red.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }
}
