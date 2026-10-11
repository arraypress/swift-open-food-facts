//
//  SupportTests.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//
//  The pure functions: check digits, UPC-E, tags, search escaping and the
//  nutriment reader. No network.
//

import XCTest
@testable import OpenFoodFacts

final class SupportTests: XCTestCase {

    // MARK: GTIN

    func testCheckDigitOnRealCodes() {
        XCTAssertTrue(GTIN.isValid("5449000000996"))   // EAN-13, Coca-Cola
        XCTAssertTrue(GTIN.isValid("3017620422003"))   // EAN-13, Nutella
        XCTAssertTrue(GTIN.isValid("041196910759"))    // UPC-A
        XCTAssertTrue(GTIN.isValid("20724696"))        // EAN-8
        XCTAssertEqual(GTIN.checkDigit(forBody: "544900000099"), 6)
        XCTAssertEqual(GTIN.checkDigit(forBody: "2072469"), 6)
    }

    func testEveryWrongCheckDigitIsCaught() {
        for digit in 0...9 where digit != 6 {
            XCTAssertFalse(GTIN.isValid("544900000099\(digit)"), "\(digit)")
        }
    }

    func testNormalizedPadsUPCAAndStripsSeparators() throws {
        XCTAssertEqual(try GTIN.normalized("041196910759"), "0041196910759")
        XCTAssertEqual(try GTIN.normalized("5 449000 000996"), "5449000000996")
        XCTAssertEqual(try GTIN.normalized("3017-6204-22003"), "3017620422003")
        XCTAssertEqual(try GTIN.normalized("20724696"), "20724696")
    }

    func testNormalizedRefusesNonBarcodes() {
        for bad in ["5449000000997", "12345", "abc", "", "544900000099X", "123456789012345"] {
            XCTAssertThrowsError(try GTIN.normalized(bad), bad) { error in
                guard case OpenFoodFactsError.invalidBarcode = error else { return XCTFail("\(error)") }
            }
        }
    }

    func testWrongCheckDigitMessageNamesTheRightOne() {
        XCTAssertThrowsError(try GTIN.normalized("5449000000997")) { error in
            XCTAssertTrue((error as? LocalizedError)?.errorDescription?.contains("end in 6") == true)
        }
    }

    func testUPCEExpansion() {
        // The four UPC-E patterns, against GS1's published expansions.
        XCTAssertEqual(GTIN.expandUPCE("01234505"), "012000003455")   // last digit 5: XXXXX0000N
        XCTAssertEqual(GTIN.expandUPCE("04252614"), "042100005264")   // last digit 1
        XCTAssertEqual(GTIN.expandUPCE("123453"), "012300000451")     // last digit 3, six-digit form
        XCTAssertNil(GTIN.expandUPCE("01234500"))                     // wrong check digit
        XCTAssertNil(GTIN.expandUPCE("21234505"))                     // number system 2
        XCTAssertNil(GTIN.expandUPCE("0123"))
        for code in ["01234505", "04252614"] { XCTAssertTrue(GTIN.isValid(GTIN.expandUPCE(code)!)) }
    }

    // MARK: Tags and text

    func testTagsAreWords() {
        XCTAssertEqual(Tags.readable("en:skimmed-milk"), "Skimmed milk")
        XCTAssertEqual(Tags.readable("fr:lait"), "Lait")
        XCTAssertEqual(Tags.readable("nuts"), "Nuts")
        XCTAssertNil(Tags.readable("en:"))
        XCTAssertEqual(Tags.readable(["en:milk", "en:nuts", "fr:milk"]), ["Milk", "Nuts"])
    }

    func testSearchTextIsLiteral() {
        XCTAssertEqual(SearchText.escaped("oat milk (barista)"), #"oat milk \(barista\)"#)
        XCTAssertEqual(SearchText.escaped("50% off: 2-for-1"), #"50% off\: 2\-for\-1"#)
        XCTAssertEqual(SearchText.escaped("plain words"), "plain words")
    }

    func testJSONValueAcceptsEitherShape() throws {
        let decoded = try JSONDecoder().decode([String: JSONValue].self, from: Data(#"{"a":"Nutella, Ferrero","b":["x","y"],"n":"4","m":3,"e":"  "}"#.utf8))
        XCTAssertEqual(decoded["a"]?.list, ["Nutella", "Ferrero"])
        XCTAssertEqual(decoded["b"]?.list, ["x", "y"])
        XCTAssertEqual(decoded["n"]?.number, 4)
        XCTAssertEqual(decoded["m"]?.text, "3")
        XCTAssertNil(decoded["e"]?.text)
    }

    // MARK: Nutrients

    func testEnergyFallsBackFromKilojoules() throws {
        let nutriments: [String: JSONValue] = ["energy_100g": .number(418.4), "fat_100g": .number(1)]
        let read = try XCTUnwrap(NutrientReading.nutrients(nutriments, suffix: "_100g"))
        XCTAssertEqual(read.energyKJ, 418.4)
        XCTAssertEqual(read.energyKcal, 100)
    }

    func testNoFiguresIsNoNutrition() {
        XCTAssertNil(NutrientReading.nutrition([:], quantityUnit: "g"))
        XCTAssertNil(NutrientReading.nutrition(["nova-group_100g": .number(4)], quantityUnit: "g"))
        XCTAssertNil(NutrientReading.nutrition(nil, quantityUnit: nil))
    }

    func testZeroIsKeptNotDropped() throws {
        let read = try XCTUnwrap(NutrientReading.nutrients(["salt_100g": .number(0), "sugars_100g": .number(10.6)], suffix: "_100g"))
        XCTAssertEqual(read.salt, 0)
        XCTAssertNil(read.fat)
    }

    func testLiquidsArePerHundredMillilitres() {
        let nutriments: [String: JSONValue] = ["sugars_100g": .number(10.6)]
        XCTAssertEqual(NutrientReading.nutrition(nutriments, quantityUnit: "ml")?.basis, .hundredMillilitres)
        XCTAssertEqual(NutrientReading.nutrition(nutriments, quantityUnit: "L")?.basis, .hundredMillilitres)
        XCTAssertEqual(NutrientReading.nutrition(nutriments, quantityUnit: "g")?.basis, .hundredGrams)
        XCTAssertEqual(NutrientReading.nutrition(nutriments, quantityUnit: nil)?.basis, .hundredGrams)
    }
}
