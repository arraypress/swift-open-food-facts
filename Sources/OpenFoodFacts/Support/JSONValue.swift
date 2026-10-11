//
//  JSONValue.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//
//  Any JSON value. Product fields change type between records — `brands` is a
//  string on the product endpoint and an array in search results, `nova_group`
//  a number or a numeric string — so a product is read as a tree first and
//  mapped by ProductMapping, rather than decoded into fixed types that one odd
//  record would fail.
//

import Foundation

/// A JSON value of any type.
enum JSONValue: Decodable, Sendable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: JSONValue].self)) }
    }

    /// Text, from a string, or a number written plainly.
    var text: String? {
        switch self {
        case .string(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case .number(let value): return value == value.rounded() ? String(Int(value)) : String(value)
        default: return nil
        }
    }

    /// A number, from a number or a numeric string ("4", "10.6").
    var number: Double? {
        switch self {
        case .number(let value): return value.isFinite ? value : nil
        case .string(let value): return Double(value.trimmingCharacters(in: .whitespaces)).flatMap { $0.isFinite ? $0 : nil }
        default: return nil
        }
    }

    /// Strings from an array, or a comma-separated string ("Nutella, Ferrero").
    var list: [String] {
        switch self {
        case .array(let items): return items.compactMap(\.text)
        case .string(let value):
            return value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        default: return []
        }
    }

    /// The members of an object.
    var object: [String: JSONValue]? {
        if case .object(let members) = self { return members }
        return nil
    }
}
