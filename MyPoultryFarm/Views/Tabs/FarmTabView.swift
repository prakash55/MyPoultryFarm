//
//  FarmTabView.swift
//  MyPoultryFarm
//

import SwiftUI

/// TabView for a specific Farm scope.
struct FarmTabView: View {
    @ObservedObject var viewModel: MyFarmsViewModel
    @Binding var selection: FarmSelection
    let farm: FarmRecord
    let router: AppRouter

    private var scopeShedIds: Set<UUID> {
        let sheds = viewModel.allSheds.filter { $0.farmId == farm.id }
        return Set(sheds.compactMap { $0.id })
    }

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "chart.bar.fill") {
                FarmDashboardView(dataStore: viewModel, farm: farm, scopeShedIds: scopeShedIds)
            }
            Tab("Sheds", systemImage: "building.fill") {
                ShedsListView(dataStore: viewModel, farm: farm, selection: $selection)
            }
            Tab("Inventory", systemImage: "shippingbox.fill") {
                InventoryView(dataStore: viewModel, scopeShedIds: scopeShedIds, scopeLabel: farm.farmName, scopeIcon: "house.fill", scopeLevel: .farm)
            }
            Tab("Sales", systemImage: "cart.fill") {
                SalesView(dataStore: viewModel, scopeShedIds: scopeShedIds, scopeLabel: farm.farmName, scopeIcon: "house.fill", scopeLevel: .farm)
            }
            Tab("Finances", systemImage: "indianrupeesign.circle.fill") {
                FinancesView(dataStore: viewModel, scopeShedIds: scopeShedIds, scopeLabel: farm.farmName, scopeIcon: "house.fill", scopeLevel: .farm)
            }
        }
    }
}
