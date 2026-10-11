//
//  SearchEnvelope.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The search service's body.
struct SearchEnvelope: Decodable {
    let hits: [[String: JSONValue]]
    let count: Int?
    let is_count_exact: Bool?
    let page: Int?
    let page_count: Int?
}
