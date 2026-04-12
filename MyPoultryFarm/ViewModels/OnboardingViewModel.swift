//
//  OnboardingViewModel.swift
//  MyPoultryFarm
//

import Combine
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Onboarding step

    enum Step: Int, CaseIterable {
        case profile = 0
        case farms = 1
    }

    @Published var currentStep: Step = .profile
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Profile fields

    @Published var fullName: String = ""
    @Published var phone: String = ""

    // MARK: - Farms (each farm has its own sheds)

    @Published var farms: [FarmEntry] = [FarmEntry()]

    // MARK: - Completion callback

    var onComplete: (() -> Void)?

    @Injected private var profileRepo: ProfileRepositoryProtocol
    @Injected private var farmRepo: FarmRepositoryProtocol
    @Injected private var shedRepo: ShedRepositoryProtocol
    @Injected private var authService: AuthServiceProtocol

    // MARK: - Navigation

    var isFirstStep: Bool { currentStep == .profile }
    var isLastStep: Bool { currentStep == .farms }

    var stepProgress: Double {
        Double(currentStep.rawValue + 1) / Double(Step.allCases.count)
    }

    func next() {
        guard validateCurrentStep() else { return }
        if let nextStep = Step(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.3)) { self.currentStep = nextStep }
        }
    }

    func back() {
        if let prevStep = Step(rawValue: currentStep.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.3)) { self.currentStep = prevStep }
        }
    }

    // MARK: - Farm management

    func addFarm() {
        withAnimation { farms.append(FarmEntry()) }
    }

    func removeFarm(at index: Int) {
        guard farms.count > 1 else { return }
        withAnimation { farms.remove(at: index) }
    }

    // MARK: - Validation

    func validateCurrentStep() -> Bool {
        switch currentStep {
        case .profile:
            guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
                showErrorMsg("Please enter your name.")
                return false
            }
        case .farms:
            for (fi, farm) in farms.enumerated() {
                if farm.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    showErrorMsg("Farm \(fi + 1) needs a name.")
                    return false
                }
                for shed in farm.sheds {
                    if shed.name.trimmingCharacters(in: .whitespaces).isEmpty {
                        showErrorMsg("Each shed in \"\(farm.name)\" must have a name.")
                        return false
                    }
                    guard let cap = Int(shed.capacity), cap > 0 else {
                        showErrorMsg("Enter a valid capacity for shed \"\(shed.name)\" in \"\(farm.name)\".")
                        return false
                    }
                }
            }
        }
        return true
    }

    // MARK: - Save to Supabase

    func finish() {
        guard validateCurrentStep() else { return }

        isLoading = true
        Task {
            do {
                guard let userId = await authService.currentUserId else {
                    showErrorMsg("Not authenticated.")
                    isLoading = false
                    return
                }

                // 1. Upsert profile
                let profile = ProfileRecord(
                    id: userId,
                    fullName: fullName,
                    phone: phone.isEmpty ? nil : phone,
                    onboardingCompleted: true
                )
                try await profileRepo.upsertProfile(profile)

                // 2. Insert each farm with its sheds
                for farmEntry in farms {
                    let farm = FarmRecord(
                        id: nil,
                        ownerId: userId,
                        farmName: farmEntry.name,
                        location: farmEntry.location.isEmpty ? nil : farmEntry.location
                    )
                    let savedFarm = try await farmRepo.insertFarm(farm)

                    guard let farmId = savedFarm.id else { continue }

                    let shedRecords = farmEntry.sheds.map { entry in
                        ShedRecord(
                            id: nil,
                            farmId: farmId,
                            shedName: entry.name,
                            capacity: Int(entry.capacity) ?? 0
                        )
                    }
                    try await shedRepo.insertSheds(shedRecords)
                }

                isLoading = false
                onComplete?()

            } catch {
                isLoading = false
                showErrorMsg(error.localizedDescription)
            }
        }
    }

    // MARK: - Helpers

    private func showErrorMsg(_ msg: String) {
        errorMessage = msg
        showError = true
    }
}
