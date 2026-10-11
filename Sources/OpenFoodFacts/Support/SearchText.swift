//
//  SearchText.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Plain text made literal for the search service, which reads Lucene syntax:
/// "oat milk (barista)" found nothing until its brackets were escaped, and a
/// bare `*` matched nothing at all.
enum SearchText {

    /// The characters Lucene gives meaning to.
    static let special: Set<Character> = ["+", "-", "&", "|", "!", "(", ")", "{", "}", "[", "]", "^", "\"", "~", "*", "?", ":", "\\", "/"]

    /// Every special character backslash-escaped.
    static func escaped(_ text: String) -> String {
        text.reduce(into: "") { result, character in
            if special.contains(character) { result.append("\\") }
            result.append(character)
        }
    }
}
