//
//  Tags.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Open Food Facts taxonomy tags as words.
enum Tags {

    /// "en:skimmed-milk" → "Skimmed milk"; the language prefix goes, hyphens
    /// become spaces, the first letter is capitalised. A tag without a prefix
    /// is read the same way.
    static func readable(_ tag: String) -> String? {
        let body = tag.firstIndex(of: ":").map { tag[tag.index(after: $0)...] } ?? Substring(tag)
        let words = body.replacingOccurrences(of: "-", with: " ").trimmingCharacters(in: .whitespaces)
        guard !words.isEmpty else { return nil }
        return words.prefix(1).uppercased() + words.dropFirst()
    }

    /// Readable tags, duplicates removed, order kept.
    static func readable(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        return tags.compactMap(readable).filter { seen.insert($0.lowercased()).inserted }
    }
}
