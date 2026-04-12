//
//  SupabaseRPC.swift
//  MyPoultryFarm
//

import Foundation
import Supabase

enum SupabaseRPC: String {
    // Profile
    case profileGetProfile = "profile_get_profile"
    case profileUpsert = "profile_upsert"
    case profileUpdateName = "profile_update_name"
    case profileUpdatePhone = "profile_update_phone"
    case profileMarkOnboardingComplete = "profile_mark_onboarding_complete"
    case profileIsOnboardingCompleted = "profile_is_onboarding_completed"

    // Farm
    case farmGetFarms = "farm_get_farms"
    case farmGetFarm = "farm_get_farm"
    case farmInsertFarm = "farm_insert_farm"
    case farmUpdateFarm = "farm_update_farm"
    case farmDeleteFarm = "farm_delete_farm"

    // Shed
    case shedGetSheds = "shed_get_sheds"
    case shedGetShed = "shed_get_shed"
    case shedInsertShed = "shed_insert_shed"
    case shedInsertSheds = "shed_insert_sheds"
    case shedUpdateShed = "shed_update_shed"
    case shedDeleteShed = "shed_delete_shed"
    case shedDeleteSheds = "shed_delete_sheds"

    // Batch
    case batchGetBatchesByShed = "batch_get_batches_by_shed"
    case batchGetBatchesBySheds = "batch_get_batches_by_sheds"
    case batchGetBatchesByStatus = "batch_get_batches_by_status"
    case batchGetBatch = "batch_get_batch"
    case batchInsertBatch = "batch_insert_batch"
    case batchUpdateBatch = "batch_update_batch"
    case batchDeleteBatch = "batch_delete_batch"

    // Inventory
    case inventoryGetByShed = "inventory_get_by_shed"
    case inventoryGetBySheds = "inventory_get_by_sheds"
    case inventoryGetByCategory = "inventory_get_by_category"
    case inventoryGetItem = "inventory_get_item"
    case inventoryInsertItem = "inventory_insert_item"
    case inventoryUpdateItem = "inventory_update_item"
    case inventoryDeleteItem = "inventory_delete_item"

    // Sales
    case salesGetByShed = "sales_get_by_shed"
    case salesGetBySheds = "sales_get_by_sheds"
    case salesGetSale = "sales_get_sale"
    case salesInsertSale = "sales_insert_sale"
    case salesUpdateSale = "sales_update_sale"
    case salesDeleteSale = "sales_delete_sale"

    // Expense
    case expenseGetByShed = "expense_get_by_shed"
    case expenseGetBySheds = "expense_get_by_sheds"
    case expenseGetByCategory = "expense_get_by_category"
    case expenseGetExpense = "expense_get_expense"
    case expenseInsertExpense = "expense_insert_expense"
    case expenseUpdateExpense = "expense_update_expense"
    case expenseDeleteExpense = "expense_delete_expense"

    // Buyer
    case buyerGetBuyers = "buyer_get_buyers"
    case buyerGetBuyer = "buyer_get_buyer"
    case buyerInsertBuyer = "buyer_insert_buyer"
    case buyerUpdateBuyer = "buyer_update_buyer"
    case buyerDeleteBuyer = "buyer_delete_buyer"

    // Daily log
    case dailyLogGetByBatch = "daily_log_get_by_batch"
    case dailyLogGetBySheds = "daily_log_get_by_sheds"
    case dailyLogInsert = "daily_log_insert"
    case dailyLogDelete = "daily_log_delete"
}

extension SupabaseClient {
    func rpcValue<Params: Encodable, Output: Decodable>(_ function: SupabaseRPC, params: Params) async throws -> Output {
        try await rpc(function.rawValue, params: params)
            .execute()
            .value
    }

    func rpcValue<Output: Decodable>(_ function: SupabaseRPC) async throws -> Output {
        try await rpc(function.rawValue)
            .execute()
            .value
    }

    func rpcVoid<Params: Encodable>(_ function: SupabaseRPC, params: Params) async throws {
        _ = try await rpc(function.rawValue, params: params)
            .execute()
    }

    func rpcVoid(_ function: SupabaseRPC) async throws {
        _ = try await rpc(function.rawValue)
            .execute()
    }
}
