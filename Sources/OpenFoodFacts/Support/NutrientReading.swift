//
//  NutrientReading.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The `nutriments` object read into typed values.
enum NutrientReading {

    /// The amounts with one suffix — `_100g` or `_serving` — or nil when none is given.
    static func nutrients(_ nutriments: [String: JSONValue], suffix: String) -> Nutrients? {
        func value(_ key: String) -> Double? { nutriments[key + suffix]?.number }
        let kj = value("energy-kj") ?? value("energy")          // bare `energy` is kJ
        let kcal = value("energy-kcal") ?? kj.map { ($0 / 4.184 * 10).rounded() / 10 }
        let nutrients = Nutrients(
            energyKcal: kcal, energyKJ: kj ?? kcal.map { ($0 * 4.184 * 10).rounded() / 10 },
            fat: value("fat"), saturatedFat: value("saturated-fat"),
            carbohydrates: value("carbohydrates"), sugars: value("sugars"),
            fiber: value("fiber"), proteins: value("proteins"),
            salt: value("salt"), sodium: value("sodium"))
        let any = [nutrients.energyKcal, nutrients.fat, nutrients.carbohydrates, nutrients.sugars,
                   nutrients.proteins, nutrients.salt, nutrients.fiber, nutrients.saturatedFat].contains { $0 != nil }
        return any ? nutrients : nil
    }

    /// A product's nutrition, or nil when the database holds none.
    ///
    /// - Parameter quantityUnit: `product_quantity_unit` — `ml`, `cl` or `l`
    ///   make the basis 100 ml (Coca-Cola: 330 ml, per 100 ml).
    static func nutrition(_ nutriments: [String: JSONValue]?, quantityUnit: String?) -> Nutrition? {
        guard let nutriments, let perHundred = nutrients(nutriments, suffix: "_100g") else { return nil }
        let liquid = ["ml", "cl", "dl", "l"].contains(quantityUnit?.lowercased() ?? "")
        return Nutrition(basis: liquid ? .hundredMillilitres : .hundredGrams, perHundred: perHundred,
                         perServing: nutrients(nutriments, suffix: "_serving"))
    }
}
