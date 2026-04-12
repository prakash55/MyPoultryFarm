//
//  OnboardingModels.swift
//  MyPoultryFarm
//

import Foundation

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
