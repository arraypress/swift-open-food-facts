//
//  GTIN.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//
//  Barcodes: the GS1 mod-10 check digit shared by EAN-8, UPC-A, EAN-13 and
//  GTIN-14, and UPC-E's expansion to UPC-A. swift-isbn-validator computes the
//  same mod-10 for ISBN-13 only, behind internal functions, so it cannot be
//  reused here.
//

import Foundation

/// GS1 barcode rules, as pure functions.
public enum GTIN {

    /// The GS1 check digit for a code's body (every digit but the last):
    /// weights 3 and 1 alternating from the right.
    public static func checkDigit(forBody body: String) -> Int? {
        guard !body.isEmpty, body.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        let sum = body.reversed().enumerated().reduce(0) { total, item in
            total + Int(String(item.element))! * (item.offset.isMultiple(of: 2) ? 3 : 1)
        }
        return (10 - sum % 10) % 10
    }

    /// Whether a code of 8, 12, 13 or 14 digits has the right check digit.
    public static func isValid(_ code: String) -> Bool {
        guard [8, 12, 13, 14].contains(code.count), let last = code.last.flatMap({ Int(String($0)) }),
              let expected = checkDigit(forBody: String(code.dropLast())) else { return false }
        return last == expected
    }

    /// Spaces and hyphens removed — what a person types or a scanner prints.
    public static func cleaned(_ text: String) -> String {
        text.filter { !$0.isWhitespace && $0 != "-" }
    }

    /// The code as Open Food Facts keys it: UPC-A's 12 digits become EAN-13 with
    /// a leading zero (the service does the same: 041196910759 answers as
    /// 0041196910759). Throws for anything that is not a valid code.
    public static func normalized(_ text: String) throws(OpenFoodFactsError) -> String {
        let code = cleaned(text)
        guard !code.isEmpty, code.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            throw OpenFoodFactsError.invalidBarcode("'\(text)' has characters other than digits")
        }
        guard [8, 12, 13, 14].contains(code.count) else {
            throw OpenFoodFactsError.invalidBarcode("'\(code)' is \(code.count) digits; barcodes are 8, 12, 13 or 14")
        }
        guard isValid(code) else {
            let expected = checkDigit(forBody: String(code.dropLast())) ?? 0
            throw OpenFoodFactsError.invalidBarcode("'\(code)' fails its check digit (it should end in \(expected))")
        }
        return code.count == 12 ? "0" + code : code
    }

    /// A UPC-E code (8 digits, or 6 without number system and check digit)
    /// expanded to its 12-digit UPC-A — the form the database stores. `nil` when
    /// it is not UPC-E: the number system must be 0 or 1, and an 8-digit code
    /// must carry the right check digit.
    public static func expandUPCE(_ text: String) -> String? {
        let code = cleaned(text)
        guard code.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        let system: Character, digits: [Character], check: Character?
        switch code.count {
        case 6: (system, digits, check) = ("0", Array(code), nil)
        case 8: (system, digits, check) = (code.first!, Array(code.dropFirst().dropLast()), code.last!)
        default: return nil
        }
        guard system == "0" || system == "1" else { return nil }
        let d = digits.map(String.init)
        let body: String
        switch d[5] {
        case "0", "1", "2": body = d[0] + d[1] + d[5] + "0000" + d[2] + d[3] + d[4]
        case "3": body = d[0] + d[1] + d[2] + "00000" + d[3] + d[4]
        case "4": body = d[0] + d[1] + d[2] + d[3] + "00000" + d[4]
        default: body = d[0] + d[1] + d[2] + d[3] + d[4] + "0000" + d[5]
        }
        let partial = String(system) + body
        guard let digit = checkDigit(forBody: partial) else { return nil }
        if let check, Int(String(check)) != digit { return nil }
        return partial + String(digit)
    }
}
