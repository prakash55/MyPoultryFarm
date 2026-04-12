//
//  AuthUser.swift
//  MyPoultryFarm
//

import Foundation

/// A lightweight user representation returned by AuthService.
struct AuthUser {
    let id: UUID
    let email: String?
    let phone: String?
    let displayName: String?
}
