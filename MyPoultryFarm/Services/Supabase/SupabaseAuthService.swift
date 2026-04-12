//
//  SupabaseAuthService.swift
//  MyPoultryFarm
//

import Auth
import Foundation
import Supabase

struct SupabaseAuthService: AuthServiceProtocol {
    private let client = SupabaseManager.shared.client

    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }

    func authStateChanges() -> AsyncStream<(isSignedIn: Bool, userId: UUID?, displayName: String?)> {
        AsyncStream { continuation in
            Task {
                for await (event, session) in client.auth.authStateChanges {
                    switch event {
                    case .initialSession, .signedIn:
                        let name = session?.user.userMetadata["display_name"]?.stringValue
                            ?? session?.user.email
                            ?? session?.user.phone
                        continuation.yield((
                            isSignedIn: session != nil,
                            userId: session?.user.id,
                            displayName: name
                        ))
                    case .signedOut:
                        continuation.yield((isSignedIn: false, userId: nil, displayName: nil))
                    default:
                        break
                    }
                }
                continuation.finish()
            }
        }
    }

    func signInWithEmail(email: String, password: String) async throws -> AuthUser {
        let session = try await client.auth.signIn(email: email, password: password)
        return authUser(from: session.user)
    }

    func signUpWithEmail(email: String, password: String, displayName: String) async throws -> AuthUser {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["display_name": .string(displayName)]
        )
        guard let user = response.session?.user else {
            // email confirmation required — return a stub
            return AuthUser(id: response.user.id, email: email, phone: nil, displayName: displayName)
        }
        return authUser(from: user)
    }

    func signInWithOTP(phone: String) async throws {
        try await client.auth.signInWithOTP(phone: phone)
    }

    func verifyOTP(phone: String, token: String) async throws -> AuthUser {
        let session = try await client.auth.verifyOTP(phone: phone, token: token, type: .sms)
        return authUser(from: session.user)
    }

    func signInWithGoogle() async throws {
        try await client.auth.signInWithOAuth(provider: .google)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Helper

    private func authUser(from user: User) -> AuthUser {
        AuthUser(
            id: user.id,
            email: user.email,
            phone: user.phone,
            displayName: user.userMetadata["display_name"]?.stringValue
        )
    }
}
