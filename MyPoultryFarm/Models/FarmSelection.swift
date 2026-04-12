//
//  FarmSelection.swift
//  MyPoultryFarm
//

import Foundation

/// The level of the current selection scope.
enum ScopeLevel {
    case overview, farm, shed
}

/// Represents the current farm/shed/batch selection scope.
enum FarmSelection: Hashable {
    case overview
    case farm(FarmRecord)
    case shed(ShedRecord)
    case batch(BatchRecord)

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .farm(let f): return f.farmName
        case .shed(let s): return s.shedName
        case .batch(let b): return "Batch #\(b.batchNumber)"
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .overview: hasher.combine("overview")
        case .farm(let f): hasher.combine(f.id)
        case .shed(let s): hasher.combine(s.id)
        case .batch(let b): hasher.combine(b.id)
        }
    }

    static func == (lhs: FarmSelection, rhs: FarmSelection) -> Bool {
        switch (lhs, rhs) {
        case (.overview, .overview): return true
        case (.farm(let a), .farm(let b)): return a.id == b.id
        case (.shed(let a), .shed(let b)): return a.id == b.id
        case (.batch(let a), .batch(let b)): return a.id == b.id
        default: return false
        }
    }

    // MARK: - Persistence

    var storageKey: String {
        switch self {
        case .overview: return "overview"
        case .farm(let f): return "farm:\(f.id?.uuidString ?? "")"
        case .shed(let s): return "shed:\(s.id?.uuidString ?? "")"
        case .batch(let b): return "batch:\(b.id?.uuidString ?? "")"
        }
    }

    static func from(storageKey: String, viewModel: MyFarmsViewModel) -> FarmSelection {
        let parts = storageKey.split(separator: ":", maxSplits: 1)
        guard parts.count == 2, let uuid = UUID(uuidString: String(parts[1])) else {
            return .overview
        }
        switch String(parts[0]) {
        case "farm":
            if let farm = viewModel.farms.first(where: { $0.id == uuid }) {
                return .farm(farm)
            }
        case "shed":
            if let shed = viewModel.allSheds.first(where: { $0.id == uuid }) {
                return .shed(shed)
            }
        case "batch":
            if let batch = viewModel.batches.first(where: { $0.id == uuid }) {
                return .batch(batch)
            }
        default: break
        }
        return .overview
    }
}
