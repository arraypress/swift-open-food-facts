//
//  Nutrients.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Nutrient amounts for one basis — per 100 g/ml or per serving. Masses are in
/// GRAMS whatever unit the pack used (Open Food Facts normalises salt and sodium
/// from mg to g); energy in kilocalories and kilojoules. `nil` is "not given",
/// never zero.
public struct Nutrients: Sendable, Codable, Equatable {

    /// Energy, kcal.
    public let energyKcal: Double?

    /// Energy, kJ.
    public let energyKJ: Double?

    /// Fat, g.
    public let fat: Double?

    /// Of which saturated fat, g.
    public let saturatedFat: Double?

    /// Carbohydrate, g.
    public let carbohydrates: Double?

    /// Of which sugars, g.
    public let sugars: Double?

    /// Fibre, g.
    public let fiber: Double?

    /// Protein, g.
    public let proteins: Double?

    /// Salt, g.
    public let salt: Double?

    /// Sodium, g.
    public let sodium: Double?
}
