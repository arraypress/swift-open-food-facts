//
//  EcoScore.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The Green-Score (formerly Eco-Score): the environmental impact, A+ (lowest) to F.
public enum EcoScore: String, Sendable, Codable, CaseIterable {
    /// The lowest impact.
    case aPlus = "a-plus"
    /// Low impact.
    case a
    /// Moderately low impact.
    case b
    /// Moderate impact.
    case c
    /// High impact.
    case d
    /// Very high impact.
    case e
    /// The highest impact.
    case f

    /// The grade as printed, `A+`–`F`.
    public var letter: String { self == .aPlus ? "A+" : rawValue.uppercased() }
}
