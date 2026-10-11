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
    /// - Parameters:
    ///   - quantityUnit: `product_quantity_unit` — a volume makes the basis
    ///     100 ml (Coca-Cola: 330 ml, per 100 ml).
    ///   - quantity: The printed pack size, read for its unit when
    ///     `quantityUnit` is missing — as it is in every search result: the
    ///     search index does not carry it, so a 1 l oat milk read as per 100 g.
    static func nutrition(_ nutriments: [String: JSONValue]?, quantityUnit: String?, quantity: String? = nil) -> Nutrition? {
        guard let nutriments, let perHundred = nutrients(nutriments, suffix: "_100g") else { return nil }
        let unit = quantityUnit ?? quantity.flatMap(unit(inQuantity:))
        return Nutrition(basis: isVolume(unit) ? .hundredMillilitres : .hundredGrams, perHundred: perHundred,
                         perServing: nutrients(nutriments, suffix: "_serving"))
    }

    /// Whether a unit measures volume.
    static func isVolume(_ unit: String?) -> Bool {
        ["ml", "cl", "dl", "l", "fl oz", "floz", "gal", "pt", "qt"].contains(unit?.lowercased() ?? "")
    }

    /// The unit of the last amount in a printed pack size: "1 l" → `l`,
    /// "6 x 330 ml" → `ml`, "1,5L" → `l`, "12 fl oz (355 mL)" → `ml`, "400 g e" → `g`.
    static func unit(inQuantity quantity: String) -> String? {
        let pattern = #"\d(?:[\d.,]*)\s*(fl\.?\s?oz|ml|cl|dl|kg|mg|gal|oz|lb|pt|qt|l|g)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(quantity.startIndex..., in: quantity)
        guard let match = regex.matches(in: quantity, range: range).last,
              let unit = Range(match.range(at: 1), in: quantity) else { return nil }
        let text = quantity[unit].lowercased().replacingOccurrences(of: ".", with: "").replacingOccurrences(of: " ", with: "")
        return text == "floz" ? "fl oz" : text
    }
}
