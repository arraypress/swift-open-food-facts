# Swift Open Food Facts

[Open Food Facts](https://world.openfoodfacts.org) as typed values — products by barcode and full-text search over the open food database. Keyless, on any Apple platform.

```swift
import OpenFoodFacts

let food = OpenFoodFacts()                    // or OpenFoodFacts(language: "de")
if let coke = try await food.product(barcode: "5449000000996") {
    print(coke.displayName)                   // Coca-Cola
    print(coke.nutriScore?.letter ?? "?")     // E
    print(coke.nutrition?.perHundred.sugars)  // 10.6 — per 100 ml, because it is a drink
    print(coke.nutrition?.perServing?.sugars) // 35
}
let page = try await food.search("oat milk (barista)", pageSize: 10)
```

## Features

- 🏷️ **Barcodes checked before anything is sent** — EAN-13, EAN-8, UPC-A and GTIN-14 on the GS1 mod-10 check digit; spaces and hyphens ignored; a wrong check digit throws `invalidBarcode` and names the digit it should end in. UPC-A is asked for as EAN-13 with a leading zero, which is how the database keys it. `GTIN.expandUPCE` turns a six- or eight-digit UPC-E into its UPC-A
- 🫙 **A missing product is `nil`, not an error** — the service answers an unknown code with HTTP 404 *and* a JSON body, and a code it cannot key with 200 and `status: 0`; both come back `nil`
- 🥗 **Typed nutrition** — per 100 g or per 100 ml (the basis is read from the pack's unit, so Coca-Cola is per 100 ml — and from the printed size when the unit is missing, as it is in every search result: before that, a 1 l oat milk read as per 100 g), and per serving when the pack gives one. Masses in grams, energy in kcal and kJ (each derived from the other when only one is given). `nil` means *not given*; a real 0 g of salt stays 0
- 🅰️ **Scores** — Nutri-Score (A–E), NOVA group (1–4), Green-Score/Eco-Score (A+–F); "unknown" and "not-applicable" are `nil`
- 🥜 **Allergens, traces, categories, countries** as words (`en:skimmed-milk` → "Skimmed milk"), plus the ingredients list, front-of-pack image URLs and the product page
- 🌍 **Localised where the database allows** — a product's `product_name` is in *its* main language (Nutella's is French, Coca-Cola's Spanish) and the service's `lc=` does not change that, so the client asks for `product_name_<language>` and `ingredients_text_<language>` too and falls back to the product's own
- 🔎 **Search that means what it says** — the search service reads Lucene syntax, so "oat milk (barista)" found nothing until its brackets were escaped; the text is escaped, page sizes 1–100 are enforced, and a page past the service's 10,000-result ceiling is refused before it is sent
- 🚦 **429s handled** — two retries, waiting the service's Retry-After when it sends one, else 5 s; then a typed `rateLimited` error
- 🧩 **Tolerant of the data's shape** — `brands` is a string from one endpoint and an array from the other, `nova_group` a number or a numeric string; products are read as a JSON tree and mapped, so one odd record cannot fail a page

## Measured (2026-10-11, live)

| What | Result |
|---|---|
| Product by barcode | 0.77–0.79 s |
| Search, 20 results | 1.1 s when the client asks only for the fields it maps; 4.2–5.4 s for whole records |
| Unknown valid code (4006381999991) | HTTP 404 + `{"status":0,"status_verbose":"product not found"}` → `nil` |
| UPC-A 041196910759 | answered as 0041196910759 |
| Rate limit | 429 after about 13 product reads in quick succession — HTML body, no Retry-After — and clear within 10 s; 14 back-to-back searches were all served |
| Search total | capped at 10,000 with `isTotalExact` false ("oat milk") |
| Records with no nutrition / no name | both exist (0209004013843, 3481010108615) and map to `nil` fields |

The legacy `/cgi/search.pl` search answered 503 to 8 of 12 rapid requests on the same day; this library uses the newer search service instead.

## Tests

32 tests: check digits, UPC-E, tags, escaping, pack-size units and the nutriment reader offline; the client on real responses recorded 2026-10-11 (Coca-Cola, Nutella, a UPC-A soup with a 654-character ingredient list, an EAN-8, a miss, a record with no nutrition, one with no name, a search and an empty search); and four live tests that skip when the service is unreachable or rate-limiting.

## Requirements

macOS 13+ / iOS 16+ / tvOS 16+ / watchOS 9+ / visionOS 1+, Swift 6. Foundation only.

## Data

Product data is © Open Food Facts contributors under the [Open Database License](https://opendatacommons.org/licenses/odbl/1-0/); images under CC BY-SA. Set a User-Agent that identifies your app.

## License

MIT — see LICENSE.
