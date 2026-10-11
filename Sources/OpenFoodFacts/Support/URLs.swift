//
//  URLs.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Every URL the library calls or hands back.
enum URLs {

    /// The most results the search service will page to: page × size ≤ 10,000.
    static let searchCeiling = 10_000

    /// A product by barcode, asking only for the fields that are mapped.
    static func product(barcode: String, language: String) -> URL {
        var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json")!
        components.queryItems = [URLQueryItem(name: "fields", value: ProductMapping.fields(language: language).joined(separator: ","))]
        return components.url!
    }

    /// A page of full-text search results (search-a-licious).
    static func search(text: String, page: Int, pageSize: Int, language: String) -> URL {
        var components = URLComponents(string: "https://search.openfoodfacts.org/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: SearchText.escaped(text)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize)),
            URLQueryItem(name: "langs", value: language),
            URLQueryItem(name: "fields", value: ProductMapping.fields(language: language).joined(separator: ",")),
        ]
        return components.url!
    }

    /// A product's page on the website.
    static func page(barcode: String) -> URL {
        URL(string: "https://world.openfoodfacts.org/product/\(barcode)")!
    }
}
