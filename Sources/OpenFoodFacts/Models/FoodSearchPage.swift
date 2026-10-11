//
//  FoodSearchPage.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One page of search results.
public struct FoodSearchPage: Sendable, Codable {

    /// The products on this page.
    public let products: [FoodProduct]

    /// How many products match — exact only when `isTotalExact`; the service
    /// stops counting at 10,000.
    public let total: Int

    /// Whether `total` is exact.
    public let isTotalExact: Bool

    /// This page, from 1.
    public let page: Int

    /// How many pages there are at this page size.
    public let pageCount: Int
}
