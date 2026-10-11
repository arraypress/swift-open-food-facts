//
//  NovaGroup.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The NOVA classification: how processed a food is, 1 to 4.
public enum NovaGroup: Int, Sendable, Codable, CaseIterable {
    /// Unprocessed or minimally processed foods.
    case unprocessed = 1
    /// Processed culinary ingredients — oils, butter, sugar, salt.
    case culinaryIngredients = 2
    /// Processed foods.
    case processed = 3
    /// Ultra-processed food and drink products.
    case ultraProcessed = 4

    /// A short description.
    public var description: String {
        switch self {
        case .unprocessed: return "unprocessed or minimally processed"
        case .culinaryIngredients: return "processed culinary ingredient"
        case .processed: return "processed"
        case .ultraProcessed: return "ultra-processed"
        }
    }
}
