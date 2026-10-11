//
//  ProductMapping.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A product's JSON as a ``FoodProduct``.
enum ProductMapping {

    /// The fields asked for, in `language` as well as the product's own: a
    /// product's `product_name` is in ITS main language (Nutella's is French),
    /// and `lc=` does not change that — the translations are `product_name_de`
    /// and so on.
    static func fields(language: String) -> [String] {
        ["code", "product_name", "product_name_\(language)", "generic_name", "generic_name_\(language)", "brands",
         "quantity", "serving_size", "product_quantity_unit", "nutriments", "nutriscore_grade", "nova_group",
         "ecoscore_grade", "allergens_tags", "traces_tags", "ingredients_text", "ingredients_text_\(language)",
         "categories_tags", "countries_tags", "image_front_url", "image_front_small_url", "lang"]
    }

    /// A product, or nil without a barcode.
    static func product(_ json: [String: JSONValue], language: String) -> FoodProduct? {
        guard let code = json["code"]?.text else { return nil }
        func localized(_ field: String) -> String? { json["\(field)_\(language)"]?.text ?? json[field]?.text }
        func url(_ field: String) -> URL? { json[field]?.text.flatMap(URL.init(string:)) }
        let nova = json["nova_group"]?.number.flatMap { NovaGroup(rawValue: Int($0)) }
        return FoodProduct(
            barcode: code,
            name: localized("product_name"),
            genericName: localized("generic_name"),
            brands: json["brands"]?.list ?? [],
            quantity: json["quantity"]?.text,
            servingSize: json["serving_size"]?.text,
            nutrition: NutrientReading.nutrition(json["nutriments"]?.object, quantityUnit: json["product_quantity_unit"]?.text),
            nutriScore: json["nutriscore_grade"]?.text.flatMap { NutriScore(rawValue: $0.lowercased()) },
            novaGroup: nova,
            ecoScore: json["ecoscore_grade"]?.text.flatMap { EcoScore(rawValue: $0.lowercased()) },
            allergens: Tags.readable(json["allergens_tags"]?.list ?? []),
            traces: Tags.readable(json["traces_tags"]?.list ?? []),
            ingredients: localized("ingredients_text"),
            categories: Tags.readable(json["categories_tags"]?.list ?? []),
            countries: Tags.readable(json["countries_tags"]?.list ?? []),
            imageURL: url("image_front_url"),
            thumbnailURL: url("image_front_small_url"),
            language: json["lang"]?.text,
            pageURL: URLs.page(barcode: code))
    }
}
