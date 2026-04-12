//
//  OverviewTabView.swift
//  MyPoultryFarm
//

import SwiftUI

/// TabView for the "Overview" scope — all-farms aggregate.
struct OverviewTabView: View {
    @ObservedObject var viewModel: MyFarmsViewModel
    @Binding var selection: FarmSelection
    let router: AppRouter

    private var scopeShedIds: Set<UUID> {
        Set(viewModel.allSheds.compactMap { $0.id })
    }

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "chart.bar.fill") {
                OverviewDashboardView(dataStore: viewModel, scopeShedIds: scopeShedIds)
            }
            Tab("Farms", systemImage: "house.fill") {
                FarmsListView(dataStore: viewModel, selection: $selection)
            }
            Tab("Inventory", systemImage: "shippingbox.fill") {
                InventoryView(dataStore: viewModel, scopeShedIds: scopeShedIds, scopeLabel: "All Farms", scopeIcon: "square.grid.2x2", scopeLevel: .overview)
            }
            Tab("Sales", systemImage: "cart.fill") {
                SalesView(dataStore: viewModel, scopeShedIds: scopeShedIds, scopeLabel: "All Farms", scopeIcon: "square.grid.2x2", scopeLevel: .overview)
            }
            Tab("Finances", systemImage: "indianrupeesign.circle.fill") {
                FinancesView(dataStore: viewModel, scopeShedIds: scopeShedIds, scopeLabel: "All Farms", scopeIcon: "square.grid.2x2", scopeLevel: .overview)
            }
        }
    }
}
