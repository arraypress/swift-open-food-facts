//
//  LiveTests.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//
//  Against the real service. Each test skips, rather than fails, when Open
//  Food Facts cannot be reached or is rate-limiting — the service's state is
//  not this library's.
//

import XCTest
import OpenFoodFacts

final class LiveTests: XCTestCase {

    let food = OpenFoodFacts()

    /// Runs `body`, turning an unreachable or refusing service into a skip.
    func live<T>(_ body: () async throws -> T) async throws -> T {
        do { return try await body() }
        catch OpenFoodFactsError.rateLimited { throw XCTSkip("Open Food Facts is rate-limiting") }
        catch OpenFoodFactsError.http(let code) where code >= 500 { throw XCTSkip("Open Food Facts answered \(code)") }
        catch OpenFoodFactsError.network(let why) { throw XCTSkip("offline: \(why)") }
    }

    func testProductFound() async throws {
        let product = try await live { try await food.product(barcode: "5449000000996") }
        XCTAssertEqual(product?.nutrition?.basis, .hundredMillilitres)
        XCTAssertNotNil(product?.nutriScore)
    }

    func testValidCodeWithNoProduct() async throws {
        let product = try await live { try await food.product(barcode: "4006381999991") }
        XCTAssertNil(product)
    }

    func testUPCA() async throws {
        let product = try await live { try await food.product(barcode: "041196910759") }
        XCTAssertEqual(product?.barcode, "0041196910759")
    }

    func testSearch() async throws {
        let page = try await live { try await food.search("oat milk", pageSize: 5) }
        XCTAssertFalse(page.products.isEmpty)
        let none = try await live { try await food.search("zzqxjvkw plorptang") }
        XCTAssertEqual(none.total, 0)
    }
}
