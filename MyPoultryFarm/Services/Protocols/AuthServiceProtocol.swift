//
//  AuthServiceProtocol.swift
//  MyPoultryFarm
//

import Foundation

/// Abstracts authentication so the app isn't coupled to Supabase Auth.
protocol AuthServiceProtocol {
    /// A unique identifier for the current user, or nil if not signed in.
    var currentUserId: UUID? { get async }

    /// Stream of auth state changes: (isSignedIn, userId, displayName)
    func authStateChanges() -> AsyncStream<(isSignedIn: Bool, userId: UUID?, displayName: String?)>

    func signInWithEmail(email: String, password: String) async throws -> AuthUser
    func signUpWithEmail(email: String, password: String, displayName: String) async throws -> AuthUser
    func signInWithOTP(phone: String) async throws
    func verifyOTP(phone: String, token: String) async throws -> AuthUser
    func signInWithGoogle() async throws
    func signOut() async throws
}
