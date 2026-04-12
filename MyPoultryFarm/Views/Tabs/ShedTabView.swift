//
//  ShedTabView.swift
//  MyPoultryFarm
//

import SwiftUI

/// TabView for a specific Shed scope.
struct ShedTabView: View {
    @ObservedObject var viewModel: MyFarmsViewModel
    @Binding var selection: FarmSelection
    let shed: ShedRecord
    let router: AppRouter

    private var scopeShedIds: Set<UUID> {
        guard let id = shed.id else { return [] }
        return [id]
    }

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "chart.bar.fill") {
                ShedDashboardView(dataStore: viewModel, shed: shed, scopeShedIds: scopeShedIds)
            }
            Tab("Batches", systemImage: "leaf.fill") {
                BatchesView(dataStore: viewModel, scopeShedIds: scopeShedIds, scopeLabel: shed.shedName, scopeIcon: "building.fill")
            }
            Tab("Inventory", systemImage: "shippingbox.fill") {
                InventoryView(dataStore: viewModel, scopeShedIds: scopeShedIds, scopeLabel: shed.shedName, scopeIcon: "building.fill", scopeLevel: .shed)
            }
            Tab("Sales", systemImage: "cart.fill") {
                SalesView(dataStore: viewModel, scopeShedIds: scopeShedIds, scopeLabel: shed.shedName, scopeIcon: "building.fill", scopeLevel: .shed)
            }
            Tab("Finances", systemImage: "indianrupeesign.circle.fill") {
                FinancesView(dataStore: viewModel, scopeShedIds: scopeShedIds, scopeLabel: shed.shedName, scopeIcon: "building.fill", scopeLevel: .shed)
            }
        }
    }
}
