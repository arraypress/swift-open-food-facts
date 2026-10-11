//
//  FoodProduct+Display.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

public extension FoodProduct {

    /// What to call the product: its name, else its brand, else its barcode —
    /// a record without a name is common.
    var displayName: String { name ?? brands.first ?? barcode }
}
