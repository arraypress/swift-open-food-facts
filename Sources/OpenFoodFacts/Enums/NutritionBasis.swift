//
//  NutritionBasis.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What the per-hundred figures are per: grams for solids, millilitres for drinks.
public enum NutritionBasis: String, Sendable, Codable {
    /// Per 100 g.
    case hundredGrams = "100 g"
    /// Per 100 ml.
    case hundredMillilitres = "100 ml"
}
