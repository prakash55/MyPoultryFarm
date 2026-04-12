//
//  ProfileRecord.swift
//  MyPoultryFarm
//

import Foundation

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
