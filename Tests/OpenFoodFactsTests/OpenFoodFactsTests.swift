//
//  OpenFoodFactsTests.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//
//  The client on recorded responses — real Open Food Facts output captured
//  2026-10-11 into Recordings/ — so the suite needs no network.
//

import Foundation
import XCTest
@testable import OpenFoodFacts

final class OpenFoodFactsTests: XCTestCase {

    /// A recording's bytes.
    static func recording(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Recordings"))
        return try Data(contentsOf: url)
    }

    /// A transport that answers from a script and records what was asked.
    final class Script: @unchecked Sendable {
        private let lock = NSLock()
        private(set) var requests: [URLRequest] = []
        let answer: @Sendable (URLRequest) -> (Int, Data, [String: String])

        init(_ answer: @escaping @Sendable (URLRequest) -> (Int, Data, [String: String])) { self.answer = answer }

        private func record(_ request: URLRequest) { lock.lock(); requests.append(request); lock.unlock() }

        func transport(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            record(request)
            let (code, data, headers) = answer(request)
            return (data, HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: headers)!)
        }
    }

    /// A client answering every request with one recording.
    func client(_ name: String, status: Int = 200) throws -> (OpenFoodFacts, Script) {
        let data = try Self.recording(name)
        let script = Script { _ in (status, data, [:]) }
        return (OpenFoodFacts(transport: script.transport, sleeper: { _ in }), script)
    }

    // MARK: Products

    func testCocaCola() async throws {
        let (food, script) = try client("coca-cola")
        let productFound = try await food.product(barcode: "5449000000996")
        let product = try XCTUnwrap(productFound)
        XCTAssertEqual(product.barcode, "5449000000996")
        XCTAssertEqual(product.name, "Coca-Cola")                 // the English name over the Spanish main one
        XCTAssertEqual(product.language, "es")
        XCTAssertEqual(product.nutriScore, .e)
        XCTAssertEqual(product.novaGroup, .ultraProcessed)
        XCTAssertNil(product.ecoScore)                             // "not-applicable"
        XCTAssertEqual(product.allergens, [])
        let nutrition = try XCTUnwrap(product.nutrition)
        XCTAssertEqual(nutrition.basis, .hundredMillilitres)
        XCTAssertEqual(nutrition.perHundred.energyKcal, 42.4)
        XCTAssertEqual(nutrition.perHundred.energyKJ, 180)
        XCTAssertEqual(nutrition.perHundred.sugars, 10.6)
        XCTAssertEqual(nutrition.perHundred.salt, 0)
        XCTAssertEqual(nutrition.perServing?.sugars, 35)
        XCTAssertEqual(nutrition.perServing?.energyKcal, 140)
        XCTAssertNotNil(product.imageURL)
        XCTAssertEqual(product.pageURL.absoluteString, "https://world.openfoodfacts.org/product/5449000000996")
        let request = try XCTUnwrap(script.requests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), OpenFoodFacts.defaultUserAgent)
        XCTAssertTrue(request.url!.absoluteString.contains("product_name_en"))
    }

    func testNutellaAllergensAndNoServing() async throws {
        let (food, _) = try client("nutella")
        let productFound = try await food.product(barcode: "3017620422003")
        let product = try XCTUnwrap(productFound)
        XCTAssertEqual(product.allergens, ["Milk", "Nuts", "Soybeans"])
        XCTAssertEqual(product.nutriScore, .e)
        XCTAssertEqual(product.language, "fr")
        XCTAssertEqual(product.nutrition?.basis, .hundredGrams)
        XCTAssertNil(product.nutrition?.perServing)
        XCTAssertNotNil(product.ingredients)
    }

    func testMissProductIsNil() async throws {
        // The live service answers an unknown code with 404 and this body.
        let (food, _) = try client("missing", status: 404)
        let product = try await food.product(barcode: "4006381999991")
        XCTAssertNil(product)
        let (food200, _) = try client("missing")
        let product200 = try await food200.product(barcode: "4006381999991")
        XCTAssertNil(product200)
    }

    func testBadCheckDigitSendsNothing() async throws {
        let (food, script) = try client("coca-cola")
        do {
            _ = try await food.product(barcode: "5449000000997")
            XCTFail("should have thrown")
        } catch OpenFoodFactsError.invalidBarcode {}
        XCTAssertTrue(script.requests.isEmpty)
    }

    func testUPCAIsAskedForAsEAN13() async throws {
        let (food, script) = try client("upc-a")
        let productFound = try await food.product(barcode: "041196910759")
        let product = try XCTUnwrap(productFound)
        XCTAssertEqual(product.barcode, "0041196910759")
        XCTAssertTrue(script.requests[0].url!.path.hasSuffix("/0041196910759.json"))
        XCTAssertGreaterThan(product.ingredients?.count ?? 0, 600)   // a long list comes back whole
    }

    func testEAN8() async throws {
        let (food, _) = try client("ean-8")
        let productFound = try await food.product(barcode: "20724696")
        let product = try XCTUnwrap(productFound)
        XCTAssertEqual(product.barcode, "20724696")
        XCTAssertNotNil(product.nutrition)
    }

    func testNoNutritionAndNoName() async throws {
        let (food, _) = try client("no-nutrition")
        let carrotsFound = try await food.product(barcode: "0209004013843")
        let carrots = try XCTUnwrap(carrotsFound)
        XCTAssertNil(carrots.nutrition)
        XCTAssertEqual(carrots.name, "Grandes carottes râpées")    // no English name: the French one
        let (food2, _) = try client("no-name")
        let unnamedFound = try await food2.product(barcode: "3481010108615")
        let unnamed = try XCTUnwrap(unnamedFound)
        XCTAssertNil(unnamed.name)
        XCTAssertEqual(unnamed.displayName, unnamed.brands.first ?? "3481010108615")
    }

    // MARK: Search

    func testSearch() async throws {
        let (food, script) = try client("search-oat-milk")
        let page = try await food.search("oat milk (barista)", pageSize: 3)
        XCTAssertEqual(page.products.count, 3)
        XCTAssertEqual(page.total, 10_000)
        XCTAssertFalse(page.isTotalExact)
        XCTAssertFalse(page.products[0].brands.isEmpty)            // brands is an array here
        let query = URLComponents(url: script.requests[0].url!, resolvingAgainstBaseURL: false)!.queryItems!
        XCTAssertEqual(query.first { $0.name == "q" }?.value, #"oat milk \(barista\)"#)
    }

    func testSearchWithNoResults() async throws {
        let (food, _) = try client("search-empty")
        let page = try await food.search("zzqxjvkw plorptang")
        XCTAssertTrue(page.products.isEmpty)
        XCTAssertEqual(page.total, 0)
        XCTAssertTrue(page.isTotalExact)
    }

    func testSearchRefusesBeforeSending() async throws {
        let (food, script) = try client("search-empty")
        for (text, page, size) in [("  ", 1, 20), ("milk", 0, 20), ("milk", 1, 101), ("milk", 101, 100)] {
            do {
                _ = try await food.search(text, page: page, pageSize: size)
                XCTFail("\(text) \(page) \(size)")
            } catch OpenFoodFactsError.invalidQuery {}
        }
        XCTAssertTrue(script.requests.isEmpty)
    }

    // MARK: Failures

    func testRateLimitRetriesThenGivesUp() async throws {
        let script = Script { _ in (429, Data(), ["Retry-After": "30"]) }
        let waits = Waits()
        let food = OpenFoodFacts(transport: script.transport, sleeper: { waits.add($0) })
        do {
            _ = try await food.product(barcode: "5449000000996")
            XCTFail("should have thrown")
        } catch OpenFoodFactsError.rateLimited(let after) {
            XCTAssertEqual(after, 30)
        }
        XCTAssertEqual(script.requests.count, 3)
        XCTAssertEqual(waits.all, [10, 10])                         // capped
    }

    func testRateLimitRecovers() async throws {
        let data = try Self.recording("coca-cola")
        let count = Counter()
        let script = Script { _ in count.next() == 1 ? (429, Data(), [:]) : (200, data, [:]) }
        let food = OpenFoodFacts(transport: script.transport, sleeper: { _ in })
        let product = try await food.product(barcode: "5449000000996")
        XCTAssertNotNil(product)
    }

    func testServerErrorAndGarbage() async throws {
        let (food, _) = try client("coca-cola", status: 503)
        do { _ = try await food.product(barcode: "5449000000996"); XCTFail() } catch OpenFoodFactsError.http(let code) { XCTAssertEqual(code, 503) }
        let script = Script { _ in (200, Data("<html>".utf8), [:]) }
        let garbage = OpenFoodFacts(transport: script.transport)
        do { _ = try await garbage.product(barcode: "5449000000996"); XCTFail() } catch OpenFoodFactsError.malformed {}
    }

    func testLanguageIsSanitised() {
        XCTAssertEqual(OpenFoodFacts(language: "DE").language, "de")
        XCTAssertEqual(OpenFoodFacts(language: "../x").language, "en")
    }

    /// Thread-safe recorders for the closures above.
    final class Waits: @unchecked Sendable {
        private let lock = NSLock(); private var values: [Int] = []
        func add(_ value: Int) { lock.lock(); values.append(value); lock.unlock() }
        var all: [Int] { lock.lock(); defer { lock.unlock() }; return values }
    }
    final class Counter: @unchecked Sendable {
        private let lock = NSLock(); private var value = 0
        func next() -> Int { lock.lock(); defer { lock.unlock() }; value += 1; return value }
    }
}
