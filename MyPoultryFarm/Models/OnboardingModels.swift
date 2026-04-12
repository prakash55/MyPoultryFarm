//
//  OnboardingModels.swift
//  MyPoultryFarm
//

import Foundation

// MARK: - Codable models matching Supabase tables

struct ProfileRecord: Codable {
    let id: UUID
    let fullName: String
    let phone: String?
    let onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case phone
        case onboardingCompleted = "onboarding_completed"
    }
}

struct FarmRecord: Codable, Identifiable {
    var id: UUID?
    let ownerId: UUID
    let farmName: String
    let location: String?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case farmName = "farm_name"
        case location
    }
}

struct ShedRecord: Codable, Identifiable {
    var id: UUID?
    let farmId: UUID
    let shedName: String
    let capacity: Int

    enum CodingKeys: String, CodingKey {
        case id
        case farmId = "farm_id"
        case shedName = "shed_name"
        case capacity
    }
}

// MARK: - Local UI models used during onboarding

struct ShedEntry: Identifiable {
    let id = UUID()
    var existingId: UUID? = nil  // non-nil when editing an existing DB shed
    var name: String = ""
    var capacity: String = ""
}

struct FarmEntry: Identifiable {
    let id = UUID()
    var name: String = ""
    var location: String = ""
    var sheds: [ShedEntry] = [ShedEntry()]
}
