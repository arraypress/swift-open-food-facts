//
//  OpenFoodFactsError.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What can go wrong asking Open Food Facts.
public enum OpenFoodFactsError: Error, LocalizedError, Sendable, Equatable {
    /// The text is not a barcode: wrong length, not digits, or a check digit that does not add up.
    case invalidBarcode(String)
    /// A search that cannot be sent — empty text, or a page past the 10,000-result ceiling.
    case invalidQuery(String)
    /// The service answered with an HTTP failure.
    case http(Int)
    /// The service is rate-limiting; retry after this many seconds if it said.
    case rateLimited(retryAfter: Int?)
    /// A response did not have the documented shape.
    case malformed(String)
    /// The request never got an answer: offline, DNS, TLS, a timeout.
    case network(String)
    /// The task was cancelled while waiting.
    case cancelled

    /// A sentence fragment naming the problem.
    public var errorDescription: String? {
        switch self {
        case .invalidBarcode(let why): return "not a barcode: \(why)"
        case .invalidQuery(let why): return "the search cannot be sent: \(why)"
        case .http(let code): return "Open Food Facts answered HTTP \(code)"
        case .rateLimited(let after):
            return "Open Food Facts is rate-limiting" + (after.map { " (retry after \($0)s)" } ?? "")
        case .malformed(let what): return "unexpected response shape: \(what)"
        case .network(let why): return "could not reach Open Food Facts: \(why)"
        case .cancelled: return "cancelled"
        }
    }
}
