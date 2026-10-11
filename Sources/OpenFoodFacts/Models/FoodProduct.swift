//
//  FoodProduct.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One product from Open Food Facts. Every field the database can leave empty is
/// optional or an empty list — a product with no name, no nutrition or no image is
/// common, and none of those is an error.
public struct FoodProduct: Sendable, Codable, Identifiable {

    /// The barcode, as the database keys it (13 digits for EAN-13 and UPC-A).
    public let barcode: String

    /// The name, in the requested language where the database has it.
    public let name: String?

    /// A generic description ("Hazelnut spread with cocoa").
    public let genericName: String?

    /// The brands, as listed.
    public let brands: [String]

    /// The pack size as printed ("330 ml").
    public let quantity: String?

    /// The serving size as printed ("1 cup (249 g)").
    public let servingSize: String?

    /// Nutrition, or `nil` when the database has none.
    public let nutrition: Nutrition?

    /// The Nutri-Score, when computed.
    public let nutriScore: NutriScore?

    /// The NOVA processing group, when computed.
    public let novaGroup: NovaGroup?

    /// The Green-Score (Eco-Score), when computed.
    public let ecoScore: EcoScore?

    /// Allergens declared ("Milk", "Nuts").
    public let allergens: [String]

    /// Possible traces ("May contain…").
    public let traces: [String]

    /// The ingredients list as printed, in the requested language where available.
    public let ingredients: String?

    /// Categories, most general first.
    public let categories: [String]

    /// Countries where it is sold.
    public let countries: [String]

    /// The front-of-pack photo.
    public let imageURL: URL?

    /// A small front-of-pack photo.
    public let thumbnailURL: URL?

    /// The product's main language code, e.g. `fr`.
    public let language: String?

    /// The product's page on Open Food Facts.
    public let pageURL: URL

    /// The barcode.
    public var id: String { barcode }
}
