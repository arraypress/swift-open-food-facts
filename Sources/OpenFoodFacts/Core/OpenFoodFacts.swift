//
//  OpenFoodFacts.swift
//  OpenFoodFacts
//
//  Created by David Sherlock on 2026.
//
//  Open Food Facts as typed values, keyless: products by barcode and full-text
//  search over the world's largest open food database. Every request carries a
//  User-Agent that names the client, as the service asks (AppName/Version
//  (contact)). It documents 100 product reads a minute and 10 searches; in
//  practice it answered 429 after about 13 product reads in a burst.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A keyless client for Open Food Facts.
///
/// ```swift
/// let food = OpenFoodFacts()
/// if let coke = try await food.product(barcode: "5449000000996") {
///     print(coke.name ?? coke.barcode, coke.nutriScore?.letter ?? "?")
/// }
/// let oatMilks = try await food.search("oat milk", pageSize: 5)
/// ```
public struct OpenFoodFacts: Sendable {

    /// How requests are performed — injectable so tests run on recordings.
    public typealias Transport = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    /// How a retry waits — injectable so rate-limit tests cost no wall-clock.
    public typealias Sleeper = @Sendable (_ seconds: Int) async throws -> Void

    /// The User-Agent sent when none is chosen. No personal contact is baked
    /// in; override with something identifying your use.
    public static let defaultUserAgent = "swift-open-food-facts/0.1 (+https://github.com/arraypress/swift-open-food-facts)"

    /// The User-Agent every request carries.
    public let userAgent: String

    /// The language names, ingredients and generic names are wanted in, e.g. `en`, `de`;
    /// a product without that translation answers in its own language.
    public let language: String

    private let transport: Transport
    private let sleeper: Sleeper

    /// A client.
    ///
    /// - Parameters:
    ///   - userAgent: Identify yourself: `AppName/Version (contact)`.
    ///   - language: A two-letter language code (default `en`).
    ///   - transport: Leave `nil` for the shared URLSession.
    ///   - sleeper: How a 429 retry waits; leave `nil` for real sleeping.
    public init(userAgent: String = OpenFoodFacts.defaultUserAgent, language: String = "en",
                transport: Transport? = nil, sleeper: Sleeper? = nil) {
        self.userAgent = userAgent
        let code = language.lowercased().trimmingCharacters(in: .whitespaces)
        self.language = code.count == 2 && code.allSatisfy(\.isLetter) ? code : "en"
        self.sleeper = sleeper ?? { seconds in try await Task.sleep(nanoseconds: UInt64(max(seconds, 1)) * 1_000_000_000) }
        self.transport = transport ?? { request in
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw OpenFoodFactsError.malformed("not an HTTP response") }
            return (data, http)
        }
    }

    /// A product by barcode — EAN-13, EAN-8, UPC-A (12 digits) or GTIN-14;
    /// spaces and hyphens are ignored.
    ///
    /// - Returns: The product, or `nil` when the database has no record of it.
    /// - Throws: ``OpenFoodFactsError/invalidBarcode(_:)`` before any request
    ///   for text that cannot be a barcode, including a wrong check digit.
    public func product(barcode: String) async throws(OpenFoodFactsError) -> FoodProduct? {
        let code = try GTIN.normalized(barcode)
        let data: Data
        do throws(OpenFoodFactsError) { data = try await perform(URLs.product(barcode: code, language: language)) }
        // An unknown code answers HTTP 404 with `status` 0 ("product not
        // found"); a code the service cannot key answers 200 with `status` 0.
        // Both are a miss.
        catch .http(404) { return nil }
        catch { throw error }
        let envelope: ProductEnvelope
        do { envelope = try JSONDecoder().decode(ProductEnvelope.self, from: data) } catch {
            throw OpenFoodFactsError.malformed("product: \(error)")
        }
        guard envelope.status == 1, let product = envelope.product else { return nil }
        return ProductMapping.product(product, language: language)
    }

    /// Products matching text, best first.
    ///
    /// The text is searched literally — brackets, quotes and colons are not
    /// query syntax here.
    ///
    /// - Parameters:
    ///   - text: What to look for
    ///   - page: From 1
    ///   - pageSize: 1–100 (default 20)
    /// - Returns: The page; empty when nothing matches
    /// - Throws: ``OpenFoodFactsError/invalidQuery(_:)`` for empty text, a page
    ///   size out of range, or a page past the service's 10,000-result ceiling
    public func search(_ text: String, page: Int = 1, pageSize: Int = 20) async throws(OpenFoodFactsError) -> FoodSearchPage {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { throw OpenFoodFactsError.invalidQuery("the search text is empty") }
        guard (1...100).contains(pageSize) else { throw OpenFoodFactsError.invalidQuery("page size must be 1–100, not \(pageSize)") }
        guard page >= 1 else { throw OpenFoodFactsError.invalidQuery("pages start at 1") }
        guard page * pageSize <= URLs.searchCeiling else {
            throw OpenFoodFactsError.invalidQuery("page \(page) of \(pageSize) passes the service's 10,000-result ceiling")
        }
        let data = try await perform(URLs.search(text: query, page: page, pageSize: pageSize, language: language))
        let envelope: SearchEnvelope
        do { envelope = try JSONDecoder().decode(SearchEnvelope.self, from: data) } catch {
            throw OpenFoodFactsError.malformed("search: \(error)")
        }
        return FoodSearchPage(products: envelope.hits.compactMap { ProductMapping.product($0, language: language) },
                              total: envelope.count ?? envelope.hits.count, isTotalExact: envelope.is_count_exact ?? true,
                              page: envelope.page ?? page, pageCount: envelope.page_count ?? 0)
    }

    // MARK: - Plumbing

    /// A GET with the User-Agent, retrying a 429 twice before giving up.
    ///
    /// Measured 2026-10-11: product reads answered 429 after about 13 in quick
    /// succession — an HTML body, no Retry-After — and were back within ten
    /// seconds. So a retry waits the service's Retry-After when it sends one
    /// (capped at ten seconds), else five.
    func perform(_ url: URL, retriesLeft: Int = 2) async throws(OpenFoodFactsError) -> Data {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20
        let data: Data, response: HTTPURLResponse
        do { (data, response) = try await transport(request) } catch { throw Self.closed(error) }
        switch response.statusCode {
        case 200...299:
            return data
        case 429:
            let after = response.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            guard retriesLeft > 0 else { throw OpenFoodFactsError.rateLimited(retryAfter: after) }
            do { try await sleeper(min(after ?? 5, 10)) } catch { throw Self.closed(error) }
            return try await perform(url, retriesLeft: retriesLeft - 1)
        default:
            throw OpenFoodFactsError.http(response.statusCode)
        }
    }

    /// Any error from the injected transport or sleeper as the closed type the
    /// public API throws.
    static func closed(_ error: any Error) -> OpenFoodFactsError {
        switch error {
        case let error as OpenFoodFactsError: return error
        case is CancellationError: return .cancelled
        case let error as URLError where error.code == .cancelled: return .cancelled
        default: return .network(error.localizedDescription)
        }
    }
}
