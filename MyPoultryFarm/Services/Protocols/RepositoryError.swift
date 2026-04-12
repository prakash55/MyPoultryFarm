//
//  RepositoryError.swift
//  MyPoultryFarm
//

import Foundation

enum RepositoryError: LocalizedError {
    case insertFailed(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .insertFailed(let msg): return msg
        case .notFound(let msg): return msg
        }
    }
}
