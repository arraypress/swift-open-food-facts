//
//  NutriScore.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The Nutri-Score: A (best) to E (worst), from nutrients per 100 g or 100 ml.
public enum NutriScore: String, Sendable, Codable, CaseIterable, Comparable {
    /// The healthiest grade.
    case a
    /// The second grade.
    case b
    /// The middle grade.
    case c
    /// The fourth grade.
    case d
    /// The least healthy grade.
    case e

    /// The grade as printed on packs, `A`–`E`.
    public var letter: String { rawValue.uppercased() }

    /// A before E.
    public static func < (lhs: NutriScore, rhs: NutriScore) -> Bool { lhs.rawValue < rhs.rawValue }
}
