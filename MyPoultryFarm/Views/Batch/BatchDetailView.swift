//
//  BatchDetailView.swift
//  MyPoultryFarm
//

import SwiftUI

struct BatchDetailView: View {
    @StateObject private var vm: BatchDetailViewModel
    @EnvironmentObject var router: AppRouter
    let batch: BatchRecord
    let authViewModel: AuthViewModel

    @State private var showMyFarms = false
    @State private var showScopeDrawer = false
    @State private var showAddLog = false
    @State private var showAddSale = false
    @State private var showAddExpense = false
    @State private var selectedTab = 0
    @State private var isFABExpanded = false

    init(dataStore: MyFarmsViewModel, batch: BatchRecord, authViewModel: AuthViewModel) {
        _vm = StateObject(wrappedValue: BatchDetailViewModel(dataStore: dataStore, batch: batch))
        self.batch = batch
        self.authViewModel = authViewModel
    }

    private var batchVM: BatchViewModel { BatchViewModel(dataStore: vm.dataStore) }

    private var avatarInitials: String {
        let name = vm.dataStore.profile?.fullName ?? ""
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first.map(String.init) }.joined()
        return initials.isEmpty ? "🐔" : initials.uppercased()
    }

    private var fabItems: [FABItem] {
        var items: [FABItem] = [
            FABItem(label: "Daily Log",    icon: "list.clipboard",         color: .teal)  { showAddLog = true },
            FABItem(label: "Record Sale",  icon: "cart.badge.plus",        color: .blue)  { showAddSale = true },
            FABItem(label: "Add Expense",  icon: "indianrupeesign.circle", color: .red)   { showAddExpense = true },
        ]
        items.append(
            FABItem(label: "Close Batch", icon: "checkmark.seal.fill", color: .orange) {
                Task { try await batchVM.closeBatch(batch) }
            }
        )
        return items
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                Tab("Dashboard", systemImage: "chart.bar.fill", value: 0) {
                    ScrollView {
                        BatchDashboardTab(vm: vm)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 90)
                    }
                    .background(Color(.systemGroupedBackground))
                }
                Tab("Logs", systemImage: "list.clipboard.fill", value: 1) {
                    ScrollView {
                        BatchLogsTab(vm: vm)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 90)
                    }
                    .background(Color(.systemGroupedBackground))
                }
                Tab("Inventory", systemImage: "shippingbox.fill", value: 2) {
                    ScrollView {
                        BatchInventoryTab(vm: vm)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 90)
                    }
                    .background(Color(.systemGroupedBackground))
                }
                Tab("Sales", systemImage: "cart.fill", value: 3) {
                    ScrollView {
                        BatchSalesTab(vm: vm)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 90)
                    }
                    .background(Color(.systemGroupedBackground))
                }
                Tab("Finances", systemImage: "indianrupeesign.circle.fill", value: 4) {
                    ScrollView {
                        BatchFinancesTab(vm: vm)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 90)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle(vm.currentBatch.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showScopeDrawer = true }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showScopeDrawer = true }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption.weight(.semibold))
                            Text(vm.currentBatch.displayTitle)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showMyFarms = true } label: {
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
            }
            .sheet(isPresented: $showMyFarms) {
                vm.dataStore.loadAll()
            } content: {
                MyFarmsView(authViewModel: authViewModel, farmsViewModel: vm.dataStore)
            }

            // FAB — only shown for running batches
            if vm.currentBatch.isRunning {
                FloatingActionButton(items: fabItems, isExpanded: $isFABExpanded)
                    .padding(.bottom, 52)
            }

            if showScopeDrawer {
                ScopeSelectionDrawer(
                    viewModel: vm.dataStore,
                    currentSelection: .batch(vm.currentBatch),
                    onClose: { withAnimation(.easeInOut(duration: 0.2)) { showScopeDrawer = false } },
                    onSelectOverview: { router.popToRoot(); showScopeDrawer = false },
                    onSelectFarm: { _ in router.popToRoot(); showScopeDrawer = false },
                    onSelectShed: { _ in router.popToRoot(); showScopeDrawer = false },
                    onSelectBatch: { _, selectedBatch in
                        router.popToRoot()
                        router.push(.batchDetail(selectedBatch))
                        showScopeDrawer = false
                    }
                )
            }
        }
        .sheet(isPresented: $showAddLog) {
            AddDailyLogView(viewModel: DailyLogViewModel(dataStore: vm.dataStore), batch: batch)
        }
        .sheet(isPresented: $showAddSale) {
            AddSaleView(viewModel: SalesViewModel(dataStore: vm.dataStore), initialShedId: batch.shedId, initialBatchId: batch.id)
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(viewModel: ExpenseViewModel(dataStore: vm.dataStore), initialShedId: batch.shedId, initialBatchId: batch.id)
        }
    }
}
