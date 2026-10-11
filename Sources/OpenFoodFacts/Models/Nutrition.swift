//
//  Nutrition.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A product's nutrition: per 100 g or 100 ml always, per serving when the pack gives one.
public struct Nutrition: Sendable, Codable, Equatable {

    /// Whether the per-hundred figures are per 100 g or per 100 ml.
    public let basis: NutritionBasis

    /// Per 100 g or 100 ml.
    public let perHundred: Nutrients

    /// Per serving, when known.
    public let perServing: Nutrients?
}
