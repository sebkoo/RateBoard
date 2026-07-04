import Foundation

/// Raw Frankfurter `/latest` payload, exactly as the API returns it.
///
/// Example:
/// `{"amount":1.0,"base":"USD","date":"2026-07-03","rates":{"EUR":0.91,"KRW":1372.4}}`
///
/// The wire shape stays honest here; cleanup happens in exactly one place —
/// `RateBoard.init(from:)` — so the UI never touches raw dictionaries.
public struct RawRatesResponse: Decodable {
    public let amount: Double?
    public let base: String?
    public let date: String?
    public let rates: [String: Double]?
}
