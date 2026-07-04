import Foundation

/// One clean, app-facing exchange rate.
public struct Rate: Identifiable, Equatable, Codable {
    public let currency: String   // ISO 4217, e.g. "EUR"
    public let value: Double      // units of `currency` per 1 unit of base

    public var id: String { currency }

    public init(currency: String, value: Double) {
        self.currency = currency
        self.value = value
    }
}

/// The clean domain snapshot the UI renders: a base currency, a real date,
/// and rates sorted for stable display. Built once at the normalize boundary.
public struct RateBoard: Equatable, Codable {
    public let base: String
    public let date: Date
    public let rates: [Rate]

    public init(base: String, date: Date, rates: [Rate]) {
        self.base = base
        self.date = date
        self.rates = rates
    }

    /// Convert an amount of the base currency into another currency,
    /// or `nil` when the currency isn't on the board.
    public func convert(_ amount: Double, to currency: String) -> Double? {
        guard let rate = rates.first(where: { $0.currency == currency.uppercased() })
        else { return nil }
        return amount * rate.value
    }
}
