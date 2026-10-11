//
//  ProductEnvelope.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The product endpoint's body. `status` is 1 with a product, 0 without one.
struct ProductEnvelope: Decodable, Sendable {
    let status: Int?
    let product: [String: JSONValue]?
}
