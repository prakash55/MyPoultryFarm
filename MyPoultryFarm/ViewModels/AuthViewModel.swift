//
//  AuthViewModel.swift
//  MyPoultryFarm
//

import Combine
import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {

    // MARK: - Published State

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var isCheckingSession = true
    @Published var needsOnboarding = false
    @Published var selectedAuthMethod: LoginMethod = .email

    // Login fields
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var loginPhone = ""
    @Published var loginOTP = ""

    // Sign-up fields
    @Published var signUpName = ""
    @Published var signUpEmail = ""
    @Published var signUpPassword = ""
    @Published var signUpConfirmPassword = ""
    @Published var signUpPhone = ""
    @Published var signUpOTP = ""

    @Published var errorMessage: String?
    @Published var showError = false
    @Published var userName: String = "Farmer"

    // MARK: - Dependencies

    @Injected private var profileRepo: ProfileRepositoryProtocol
    @Injected private var authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        listenForAuthChanges()
    }

    // MARK: - Auth State Listener

    private func listenForAuthChanges() {
        Task {
            for await state in authService.authStateChanges() {
                switch state.isSignedIn {
                case true:
                    isAuthenticated = true
                    isLoading = false
                    userName = state.displayName ?? "Farmer"
                    if let uid = state.userId {
                        await checkOnboardingStatus(userId: uid)
                    }
                    // Only clear checking on first event
                    isCheckingSession = false
                case false:
                    isAuthenticated = false
                    isLoading = false
                    userName = "Farmer"
                    isCheckingSession = false
                }
            }
        }
    }

    // MARK: - Onboarding Check

    func checkOnboardingStatus(userId: UUID) async {
        do {
            let completed = try await profileRepo.isOnboardingCompleted(userId: userId)
            needsOnboarding = !completed
        } catch {
            needsOnboarding = true
        }
    }

    func completeOnboarding() {
        needsOnboarding = false
    }

    // MARK: - Login with Email

    func loginWithEmail() {
        guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
            showErrorMessage("Please enter email and password.")
            return
        }
        isLoading = true
        Task {
            do {
                let user = try await authService.signInWithEmail(email: loginEmail, password: loginPassword)
                isAuthenticated = true
                isLoading = false
                userName = user.email ?? "Farmer"
            } catch {
                isLoading = false
                showErrorMessage(error.localizedDescription)
            }
        }
    }

    // MARK: - Login with Phone (via OTP)

    func loginWithPhone() {
        guard !loginPhone.isEmpty, !loginOTP.isEmpty else {
            showErrorMessage("Please enter phone number and OTP.")
            return
        }
        isLoading = true
        Task {
            do {
                let user = try await authService.verifyOTP(phone: loginPhone, token: loginOTP)
                isAuthenticated = true
                isLoading = false
                userName = user.email ?? user.phone ?? "Farmer"
            } catch {
                isLoading = false
                showErrorMessage(error.localizedDescription)
            }
        }
    }

    func sendPhoneOTP() {
        guard !loginPhone.isEmpty else {
            showErrorMessage("Please enter a phone number.")
            return
        }
        Task {
            do {
                try await authService.signInWithOTP(phone: loginPhone)
            } catch {
                showErrorMessage(error.localizedDescription)
            }
        }
    }

    // MARK: - Login with Google

    func loginWithGoogle() {
        isLoading = true
        Task {
            do {
                try await authService.signInWithGoogle()
                isAuthenticated = true
                isLoading = false
            } catch {
                isLoading = false
                showErrorMessage(error.localizedDescription)
            }
        }
    }

    // MARK: - Sign Up with Email

    func signUpWithEmail() {
        guard !signUpName.isEmpty else {
            showErrorMessage("Please enter your name.")
            return
        }
        guard !signUpEmail.isEmpty else {
            showErrorMessage("Please enter an email address.")
            return
        }
        guard signUpPassword.count >= 6 else {
            showErrorMessage("Password must be at least 6 characters.")
            return
        }
        guard signUpPassword == signUpConfirmPassword else {
            showErrorMessage("Passwords do not match.")
            return
        }
        isLoading = true
        Task {
            do {
                let user = try await authService.signUpWithEmail(
                    email: signUpEmail,
                    password: signUpPassword,
                    displayName: signUpName
                )
                userName = user.displayName ?? signUpName
                isAuthenticated = true
                isLoading = false
            } catch {
                isLoading = false
                showErrorMessage(error.localizedDescription)
            }
        }
    }

    // MARK: - Sign Up with Phone

    func signUpWithPhone() {
        guard !signUpName.isEmpty else {
            showErrorMessage("Please enter your name.")
            return
        }
        guard !signUpPhone.isEmpty, !signUpOTP.isEmpty else {
            showErrorMessage("Please enter phone number and OTP.")
            return
        }
        isLoading = true
        Task {
            do {
                _ = try await authService.verifyOTP(phone: signUpPhone, token: signUpOTP)
                isAuthenticated = true
                isLoading = false
                userName = signUpName
            } catch {
                isLoading = false
                showErrorMessage(error.localizedDescription)
            }
        }
    }

    func sendSignUpPhoneOTP() {
        guard !signUpPhone.isEmpty else {
            showErrorMessage("Please enter a phone number.")
            return
        }
        Task {
            do {
                try await authService.signInWithOTP(phone: signUpPhone)
            } catch {
                showErrorMessage(error.localizedDescription)
            }
        }
    }

    // MARK: - Sign Up with Google

    func signUpWithGoogle() {
        loginWithGoogle()
    }

    // MARK: - Logout

    func logout() {
        Task {
            do {
                try await authService.signOut()
                isAuthenticated = false
                clearFields()
            } catch {
                showErrorMessage(error.localizedDescription)
            }
        }
    }

    // MARK: - Helpers

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func clearFields() {
        loginEmail = ""
        loginPassword = ""
        loginPhone = ""
        loginOTP = ""
        signUpName = ""
        signUpEmail = ""
        signUpPassword = ""
        signUpConfirmPassword = ""
        signUpPhone = ""
        signUpOTP = ""
        userName = "Farmer"
    }
}

// MARK: - Login Method Picker

enum LoginMethod {
    case email
    case phone
}
